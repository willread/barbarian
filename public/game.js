(() => {
  window.stopGame?.();
  const $ = id => document.getElementById(id);
  const canvas = $('game'), ctx = canvas.getContext('2d');
  const W = 1440, H = 810;
  const { Atlas, LivingBackground, clips, pose, jumpHeight, decodeChroma, clamp, smooth } = window.AshenAnimation;
  const keys = new Set(), atlases = {};
  const reducedMotion = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches || false;
  let running = true, ready = false, raf, last = 0, clock = 0;
  let phase = 'title', wave = 1, score = 0, kills = 0, magic = 3;
  let flash = 0, shake = 0, banner = 0, combo = 0, comboTime = 0, hitStop = 0;
  let muted = true, audio, background, sparks = [];
  let nextId = 0;
  const make = (x, y, hp = 100) => ({
    id: nextId++, x, y, hp, max: hp, dir: 1, attack: null, cool: 0,
    recoil: 0, invulnerable: 0, jump: null, moving: false, death: 0,
    stride: 0, clock: Math.random() * 4.8, velocityX: 0, velocityY: 0,
  });
  let hero = make(910, 718), enemies = [];
  function beep(freq, duration = .12, type = 'sawtooth') {
    if (muted) return;
    audio ??= new AudioContext(); audio.resume();
    const oscillator = audio.createOscillator(), gain = audio.createGain();
    oscillator.type = type;
    oscillator.frequency.setValueAtTime(freq, audio.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(freq * .35, audio.currentTime + duration);
    gain.gain.setValueAtTime(.035, audio.currentTime);
    gain.gain.exponentialRampToValueAtTime(.001, audio.currentTime + duration);
    oscillator.connect(gain); gain.connect(audio.destination);
    oscillator.start(); oscillator.stop(audio.currentTime + duration);
  }

  function sync() {
    $('health').style.width = Math.max(0, hero.hp) + '%';
    $('health').parentElement.setAttribute('aria-label', `Health ${Math.max(0, hero.hp)} of 100`);
    $('magic').textContent = 'STORMCALL  ' + '◆ '.repeat(magic) + '◇ '.repeat(3 - magic);
    $('score').textContent = String(score).padStart(6, '0');
    $('wave').textContent = `WAVE ${wave} / 4`;
  }

  function change(next) {
    phase = next;
    $('title').hidden = next !== 'title';
    $('hud').hidden = next === 'title';
    $('overlay').hidden = !['paused', 'won', 'lost'].includes(next);
    $('outcome').textContent = next === 'paused' ? 'TAKE A BREATH' : next === 'won' ? 'THE VALLEY IS FREE' : 'THE LEGION ENDURES';
    $('message').textContent = next === 'paused' ? 'Battle paused' : next === 'won' ? 'A legend rises.' : 'Even heroes fall.';
    $('result').textContent = next === 'paused' ? '' : `${kills} enemies slain · ${score.toLocaleString()} points`;
    $('resume').textContent = next === 'paused' ? 'RESUME BATTLE' : 'RISE AGAIN';
    $('pause').textContent = next === 'paused' ? '▷' : 'Ⅱ';
  }

  function spawn() {
    enemies = Array.from({ length: wave === 4 ? 3 : wave + 2 }, (_, i) => {
      const e = make(i % 2 ? -80 - i * 100 : W + 80 + i * 110, 580 + (i % 3) * 65,
        wave === 4 && i === 0 ? 280 : 55 + wave * 10);
      e.dir = -1; e.boss = wave === 4 && i === 0;
      return e;
    });
    banner = 2.5; sync();
  }

  function start() {
    if (!ready) throw new Error('Artwork is still loading');
    hero = make(470, 660); wave = 1; score = 0; kills = 0; magic = 3;
    combo = 0; sparks = []; hitStop = 0; flash = 0; shake = 0;
    keys.clear(); change('playing'); spawn();
  }

  function burst(x, y, count, color = '#ffc473') {
    for (let i = 0; i < count; i++) sparks.push({
      x, y, vx: (Math.random() - .5) * 460, vy: (Math.random() - .65) * 390,
      life: .3 + Math.random() * .4, color,
    });
  }

  function damage(e, amount, direction) {
    if (e.hp <= 0) return;
    e.hp -= amount;
    // Recoil cancels the pending strike, including its not-yet-reached contact event.
    e.recoil = .24; e.attack = null; e.cool = Math.max(e.cool, .45);
    e.velocityX = direction * 115; e.moving = false;
    burst(e.x, e.y - 105, 16); shake = 4; hitStop = .035; beep(100);
    if (e.hp <= 0) {
      e.death = 0; kills++; score += e.boss ? 1500 : 250; combo++; comboTime = 2.2;
    }
    sync();
  }

  function beginAttack(f, isHero) {
    if (f.hp <= 0 || f.attack || f.recoil > 0 || f.cool > 0) return;
    f.attack = { elapsed: 0, direction: f.dir, connected: false };
    f.cool = isHero ? clips.heroAttack.duration + .06 : clips.enemyAttack.duration + .65;
    f.moving = false; f.velocityX = 0; f.velocityY = 0;
    if (isHero) beep(230, .15);
  }

  function action(key, on) {
    if (on) keys.add(key); else keys.delete(key);
    if (!on) return;
    if (key === 'p') {
      keys.clear();
      if (phase === 'playing') change('paused');
      else if (phase === 'paused') change('playing');
      return;
    }
    if (phase !== 'playing') return;
    if (key === 'j') beginAttack(hero, true);
    if (key === ' ' && hero.jump === null && !hero.attack && hero.recoil <= 0) {
      hero.jump = 0; beep(160, .12, 'sine');
    }
    if (key === 'k' && magic > 0 && hero.recoil <= 0) {
      magic--; flash = 1.1; shake = 10; beep(70, .8);
      for (const e of enemies) if (e.x > -20 && e.x < W + 20) damage(e, 95, e.x > hero.x ? 1 : -1);
      burst(hero.x, hero.y - 120, 70, '#b3ebff'); sync();
    }
  }

  function tickAttack(f, isHero, dt) {
    if (!f.attack) return;
    const attack = f.attack, clip = isHero ? clips.heroAttack : clips.enemyAttack;
    const previous = attack.elapsed;
    attack.elapsed += dt;
    f.dir = attack.direction;
    if (!attack.connected && previous < clip.contact && attack.elapsed >= clip.contact) {
      attack.connected = true;
      if (isHero) {
        for (const e of enemies) {
          if (Math.abs(e.y - f.y) < 67 && Math.abs(e.x - f.x) < 167 &&
              (e.x - f.x) * attack.direction > -20) damage(e, 35 + (combo % 3) * 7, attack.direction);
        }
      } else if (hero.hp > 0 && Math.abs(hero.x - f.x) < 131 && Math.abs(hero.y - f.y) < 50 &&
        (hero.x - f.x) * attack.direction > -20 &&
        (hero.jump === null || jumpHeight(hero.jump) < 24) && hero.invulnerable <= 0) {
        hero.hp -= f.boss ? 19 : 9;
        hero.invulnerable = .8; hero.recoil = .22; hero.attack = null;
        hero.velocityX = attack.direction * 100;
        burst(hero.x, hero.y - 110, 12, '#e97b4f'); shake = 5; hitStop = .045; beep(60);
        if (hero.hp <= 0) { hero.death = 0; hero.jump = null; change('dying'); }
        sync();
      }
    }
    if (attack.elapsed >= clip.duration) f.attack = null;
  }

  function tickActor(f, dt) {
    f.clock += dt; f.cool = Math.max(0, f.cool - dt);
    f.recoil = Math.max(0, f.recoil - dt); f.invulnerable = Math.max(0, f.invulnerable - dt);
    if (f.hp <= 0) { f.death += dt; f.moving = false; return; }
    if (f.jump !== null) {
      f.jump += dt;
      if (f.jump >= clips.jump.duration) { f.jump = null; burst(f.x, f.y - 3, 5, '#96856c'); }
    }
  }

  function move(f, dx, dy, speed, dt, isHero) {
    if (f.attack || f.recoil > 0) {
      f.moving = false;
      if (f.recoil > 0) { f.x += f.velocityX * dt; f.velocityX *= Math.exp(-10 * dt); }
      return;
    }
    const length = Math.hypot(dx, dy);
    if (length > 1) { dx /= length; dy /= length; }
    // Short acceleration/deceleration makes the weight transfer visible.
    const ease = 1 - Math.exp(-18 * dt);
    f.velocityX += (dx * speed - f.velocityX) * ease;
    f.velocityY += (dy * speed * .55 - f.velocityY) * ease;
    if (Math.abs(f.velocityX) < .5) f.velocityX = 0;
    if (Math.abs(f.velocityY) < .5) f.velocityY = 0;
    const oldX = f.x, oldY = f.y;
    const crouching = f.jump !== null && (f.jump < clips.jump.launch || f.jump > clips.jump.land);
    f.x += f.velocityX * dt * (crouching ? .2 : 1);
    f.y += f.velocityY * dt * (crouching ? .2 : 1);
    if (isHero) {
      f.x = clamp(f.x, 70, W - 70); f.y = clamp(f.y, 560, 755);
    }
    const distance = Math.hypot(f.x - oldX, (f.y - oldY) * 1.2);
    f.moving = distance > .08 && f.jump === null;
    if (speed > 0) f.gaitSpeed = speed;
    if (f.moving) f.stride = (f.stride + distance / Math.max(1, (f.gaitSpeed || speed) * (isHero ? 40 : 56) / 60)) % 1;
    if (dx) f.dir = dx > 0 ? 1 : -1;
  }

  function update(dt) {
    tickActor(hero, dt);
    for (const e of enemies) tickActor(e, dt);
    if (phase === 'dying') {
      if (hero.death > clips.heroDeath.duration + .7) change('lost');
      return;
    }
    if (phase !== 'playing') return;
    banner -= dt; comboTime -= dt;
    if (comboTime < 0) combo = 0;
    const dx = Number(keys.has('d') || keys.has('arrowright')) - Number(keys.has('a') || keys.has('arrowleft'));
    const dy = Number(keys.has('s') || keys.has('arrowdown')) - Number(keys.has('w') || keys.has('arrowup'));
    move(hero, dx, dy, 230, dt, true);
    tickAttack(hero, true, dt);
    for (const e of enemies) {
      if (e.hp <= 0) continue;
      const x = hero.x - e.x, y = hero.y - e.y;
      if (!e.attack && e.recoil <= 0) {
        e.dir = x < 0 ? -1 : 1;
        if (Math.abs(x) > 101 || Math.abs(y) > 33) {
          move(e, Math.abs(x) > 88 ? Math.sign(x) : 0, Math.abs(y) > 12 ? Math.sign(y) : 0,
            e.boss ? 65 : 80 + wave * 7, dt, false);
        } else { move(e, 0, 0, 0, dt, false); beginAttack(e, false); }
      } else move(e, 0, 0, 0, dt, false);
      tickAttack(e, false, dt);
      if (phase !== 'playing') break;
    }
    if (phase === 'playing' && enemies.every(e => e.hp <= 0 && e.death > clips.enemyDeath.duration + .8)) {
      if (wave === 4) change('won');
      else { wave++; hero.hp = Math.min(100, hero.hp + 20); magic = Math.min(3, magic + 1); spawn(); }
    }
  }

  function drawFighter(f, isHero) {
    const duration = isHero ? clips.heroDeath.duration : clips.enemyDeath.duration;
    const opacity = f.hp <= 0 ? 1 - smooth((f.death - duration - .3) / .55) : 1;
    if (opacity <= 0) return;
    const p = pose(f, isHero), atlas = atlases[p.atlas];
    if (!atlas) return;
    const size = f.boss ? 345 : 292;
    const height = f.jump === null ? 0 : jumpHeight(f.jump);
    ctx.save();
    ctx.globalAlpha = opacity * (1 - height / 220);
    ctx.fillStyle = '#07090680'; ctx.beginPath();
    ctx.ellipse(f.x, f.y - 2, size * .17 * (1 - height / 330), 10, 0, 0, Math.PI * 2); ctx.fill();
    ctx.globalAlpha = opacity;
    ctx.translate(f.x, f.y - height);
    ctx.scale(f.dir, 1);
    if (f.invulnerable > 0 && f.hp > 0 && Math.floor(f.invulnerable * 16) % 2) ctx.filter = 'brightness(1.25)';
    atlas.paint(ctx, reducedMotion && !f.moving && !f.attack && f.jump === null && f.hp > 0 && f.recoil <= 0 ? 0 : p.frame, size, opacity);
    ctx.restore();
    if (!isHero && f.hp > 0 && f.hp < f.max) {
      ctx.fillStyle = '#180e0c'; ctx.fillRect(f.x - 35, f.y - size + 20, 70, 4);
      ctx.fillStyle = f.boss ? '#c470d9' : '#d89969'; ctx.fillRect(f.x - 35, f.y - size + 20, 70 * f.hp / f.max, 4);
    }
  }

  function render(dt) {
    ctx.save(); ctx.clearRect(0, 0, W, H);
    if (!reducedMotion && phase !== 'paused') ctx.translate((Math.random() - .5) * shake, (Math.random() - .5) * shake);
    if (background) background.draw(ctx, clock, reducedMotion);
    else { ctx.fillStyle = '#151c23'; ctx.fillRect(0, 0, W, H); }
    const shade = ctx.createLinearGradient(0, 0, 0, H);
    shade.addColorStop(0, '#080b0f77'); shade.addColorStop(.3, '#080b0f00'); shade.addColorStop(1, '#080b0f44');
    ctx.fillStyle = shade; ctx.fillRect(0, 0, W, H);
    if (phase === 'title') drawFighter(hero, true);
    else [...enemies, hero].sort((a, b) => a.y - b.y).forEach(f => drawFighter(f, f === hero));
    if (!reducedMotion) for (let i = 0; i < 20; i++) {
      const x = (i * 167 + clock * (9 + i % 5)) % W, y = H - ((i * 67 + clock * (12 + i % 8)) % H);
      ctx.fillStyle = `rgba(255,183,98,${.12 + (i % 4) * .06})`; ctx.fillRect(x, y, i % 2 + 1, i % 2 + 1);
    }
    sparks = sparks.filter(s => {
      s.life -= dt; s.x += s.vx * dt; s.y += s.vy * dt; s.vy += 450 * dt;
      ctx.globalAlpha = Math.max(0, s.life * 2); ctx.fillStyle = s.color; ctx.fillRect(s.x, s.y, 4, 2);
      return s.life > 0;
    });
    ctx.globalAlpha = 1;
    if (flash > 0) {
      ctx.fillStyle = `rgba(137,213,255,${flash * (reducedMotion ? .08 : .22)})`; ctx.fillRect(0, 0, W, H);
      ctx.strokeStyle = `rgba(190,236,255,${Math.min(1, flash)})`; ctx.lineWidth = 5;
      for (let i = 0; i < 6; i++) {
        ctx.beginPath(); const x = (i + .5) * W / 6; ctx.moveTo(x, 0);
        for (let y = 0; y < H; y += 70) ctx.lineTo(x + Math.sin(i * 17 + y * .12 + Math.floor(clock * 15)) * 40, y);
        ctx.stroke();
      }
    }
    if (phase === 'playing' && banner > 0) {
      ctx.textAlign = 'center'; ctx.fillStyle = '#f4dfb6'; ctx.font = 'small-caps 36px Georgia';
      ctx.fillText(wave === 4 ? 'The Warden approaches' : `Wave ${wave} · The Ashen Legion`, W / 2, 190);
    }
    if (combo > 1 && comboTime > 0 && phase === 'playing') {
      ctx.textAlign = 'right'; ctx.fillStyle = '#ffe0a7'; ctx.font = 'italic 40px Georgia'; ctx.fillText(`${combo} slain`, W - 65, 240);
    }
    ctx.restore();
  }

  function loop(now) {
    if (!running) return;
    const raw = Math.min(.04, (now - last) / 1000 || .016); last = now;
    const dt = phase === 'paused' || phase === 'won' || phase === 'lost' ? 0 : raw;
    clock += dt;
    if (hitStop > 0) hitStop -= dt;
    else if (ready) update(dt);
    flash = Math.max(0, flash - dt); shake = Math.max(0, shake - dt * 35);
    render(dt); raf = requestAnimationFrame(loop);
  }

  const down = event => {
    const key = event.key.toLowerCase();
    if ([' ', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright', 'w', 'a', 's', 'd', 'j', 'k', 'p'].includes(key)) {
      event.preventDefault(); if (!event.repeat) action(key, true);
    }
  };
  const up = event => action(event.key.toLowerCase(), false);
  const blur = () => { keys.clear(); if (phase === 'playing') change('paused'); };
  window.addEventListener('keydown', down); window.addEventListener('keyup', up); window.addEventListener('blur', blur);
  $('start').onclick = start;
  $('resume').onclick = () => phase === 'paused' ? change('playing') : start();
  $('pause').onclick = () => action('p', true);
  $('sound').onclick = () => {
    muted = !muted; $('sound').textContent = muted ? 'SOUND OFF' : 'SOUND ON';
    $('sound').setAttribute('aria-label', muted ? 'Enable sound' : 'Mute sound'); beep(280, .2, 'sine');
  };
  $('full').onclick = () => document.fullscreenElement ? document.exitFullscreen() : $('stage').requestFullscreen();
  document.querySelectorAll('[data-key]').forEach(button => {
    button.onpointerdown = event => { button.setPointerCapture(event.pointerId); action(button.dataset.key, true); };
    button.onpointerup = button.onpointercancel = () => action(button.dataset.key, false);
  });

  const loadImage = src => new Promise((resolve, reject) => {
    const image = new Image(); image.onload = () => resolve(image); image.onerror = reject; image.src = src;
  });
  const names = ['hero-motion-v3', 'hero-combat-v3', 'hero-walk-v4', 'hero-actions-v4', 'enemy-walk-v4', 'enemy-attack-v4', 'enemy-combat-v3'];
  const atlasConfig = {
    'hero-walk-v4': { columns: 4, rows: 1, frames: 4, scale: .87 },
    'hero-actions-v4': { columns: 4, rows: 2, frames: 8, scale: 1.16 },
    'hero-combat-v3': { scale: 1.2 },
    'enemy-walk-v4': { columns: 4, rows: 1, frames: 4, scale: .88, facing: -1 },
    'enemy-attack-v4': { columns: 4, rows: 1, frames: 4, scale: 1.08, facing: -1 },
    'enemy-combat-v3': { scale: 1.07 },
  };
  Promise.all([
    loadImage('/art/valley.png').then(image => { if (running) background = new LivingBackground(image, W, H); }),
    ...names.map(name => loadImage(`/art/${name}.png`).then(image => {
      atlases[name] = new Atlas(decodeChroma(image), atlasConfig[name]);
    })),
  ]).then(() => {
    if (!running) return;
    ready = true; $('start').disabled = false; $('start').textContent = '⚔  ENTER THE VALLEY   →';
  }).catch(error => {
    console.error('Animation assets failed to load', error);
    if (running) $('start').textContent = 'ARTWORK FAILED · RELOAD TO RETRY';
  });
  raf = requestAnimationFrame(loop);
  window.stopGame = () => {
    running = false; cancelAnimationFrame(raf);
    window.removeEventListener('keydown', down); window.removeEventListener('keyup', up); window.removeEventListener('blur', blur);
    background?.dispose(); audio?.close();
  };
  window.ashenAxe = {
    status: () => ({ phase, health: hero.hp, wave, score, magic, kills }), start,
    pause: () => action('p', true),
  };
})();

(() => {
  const context = document.modelContext, lifecycle = new AbortController();
  if (context?.registerTool) for (const [name, description, execute, readOnly] of [
    ['get_battle_status', 'Read the current battle health, wave, score and magic.', () => window.ashenAxe.status(), true],
    ['start_new_battle', 'Restart the four-wave battle, resetting score and health.', () => {
      window.ashenAxe.start(); return window.ashenAxe.status();
    }, false],
  ]) {
    try {
      Promise.resolve(context.registerTool({ name, description,
        inputSchema: { type: 'object', properties: {}, additionalProperties: false },
        annotations: { readOnlyHint: readOnly },
        execute: input => {
          if (!input || typeof input !== 'object' || Object.keys(input).length) throw new Error('Expected an empty object');
          return execute();
        },
      }, { signal: lifecycle.signal })).catch(() => {});
    } catch {}
  }
  const cleanup = window.stopGame;
  window.stopGame = () => { lifecycle.abort(); cleanup(); };
})();
