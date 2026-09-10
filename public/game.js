(() => {
  window.stopGame?.();
  const $ = id => document.getElementById(id);
  const canvas = $('game'), ctx = canvas.getContext('2d');
  const W = 1440, H = 810;
  const { Atlas, LivingBackground, clips, pose, decodeChroma, clamp, smooth } = window.AshenAnimation;
  const M = window.AshenMechanics;
  const { HeroRig, weapons } = window.AshenHeroRig;
  let heroRig, weaponId = 'axe', weaponAtlas;
  const keys = new Set(), pressed = new Set(), atlases = {};
  const bounds = { left: 70, right: W - 70, top: 560, bottom: 755 };
  const reducedMotion = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches || false;
  let running = true, ready = false, raf, last = null, clock = 0, accumulator = 0, spell = null;
  let phase = 'title', wave = 1, score = 0, kills = 0, magic = 100, stormTexture;
  let shake = 0, banner = 0, combo = 0, comboTime = 0;
  let muted = true, audio, background, sparks = [];
  let nextId = 0;
  const make = (x, y, hp = 100, player = false) => M.init({
    id: nextId++, x, y, hp, max: hp, player, dir: 1, attack: null, cool: 0,
    recoil: 0, invulnerable: 0, jump: null, moving: false, death: 0,
    stride: 0, clock: Math.random() * 4.8, velocityX: 0, velocityY: 0,
  });
  let hero = make(910, 718, 100, true), enemies = [];
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
    syncMagic();
    $('score').textContent = String(score).padStart(6, '0');
    $('wave').textContent = `WAVE ${wave} / 4`;
  }

  function canCast() {
    return phase === 'playing' && magic > 0 && !hero.air && !hero.attack && !hero.hurtTicks && !hero.down && !hero.recovering;
  }
  function syncMagic() {
    const ready = canCast();
    $('magic-fill').style.width = magic + '%';
    $('magic-meter').setAttribute('aria-valuenow', String(magic));
    $('magic-meter').setAttribute('aria-valuetext', `${Math.ceil(magic)} percent. Hold K to channel Stormcall; release to stop. Charge with weapon hits and kills.`);
    $('magic-state').textContent = spell ? 'CHANNELING' : ready ? 'HOLD K' : magic > 0 ? Math.ceil(magic) + '% · FINISH MOVE' : 'EMPTY · LAND HITS';
    $('magic').setAttribute('data-ready', String(ready));
  }

  function change(next) {
    if (next !== 'playing') spell = null;
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
        wave === 4 && i === 0 ? 32 : wave >= 3 ? 24 : 16);
      e.dir = -1; e.boss = wave === 4 && i === 0;
      return e;
    });
    banner = 2.5; sync();
  }

  function start() {
    if (!ready) throw new Error('Artwork is still loading');
    hero = make(470, 660, 100, true); wave = 1; score = 0; kills = 0; magic = 100;
    combo = 0; sparks = []; shake = 0; spell = null; accumulator = 0;
    keys.clear(); pressed.clear(); change('playing'); spawn();
  }

  function burst(x, y, count, color = '#ffc473') {
    for (let i = 0; i < count; i++) sparks.push({
      x, y, vx: (Math.random() - .5) * 460, vy: (Math.random() - .65) * 390,
      life: .3 + Math.random() * .4, color,
    });
  }

  function damage(e, attack, attacker) {
    if (e.hp <= 0) return;
    const isHero = e === hero;
    e.hp = Math.max(0, e.hp - attack.damage * (isHero ? 100 / 48 : 1));
    if (!attack.continuous || e.hp <= 0) {
      M.hurt(e, attack, isHero, attacker);
      burst(e.x, e.y - 105, 12, isHero ? '#e97b4f' : '#ffc473');
      shake = attack.knock ? 5 : 2; beep(isHero ? 60 : 100);
    }
    // No global hit-stop: source action and stagger windows run continuously.
    if (e.hp <= 0) {
      e.death = 0;
      if (isHero) change('dying');
      else { kills++; score += e.boss ? 1500 : 250; combo++; comboTime = 2.2; }
    }
    if (!isHero && attacker === hero && !attack.magic) magic = Math.min(100, magic + 12 + (e.hp <= 0 ? 20 : 0));
    sync();
  }

  function action(key, on) {
    key = ({ arrowleft: 'a', arrowright: 'd', arrowup: 'w', arrowdown: 's' })[key] || key;
    if (!on) { keys.delete(key); if (key === 'k') { spell = null; syncMagic(); } return; }
    if (key === 'p') {
      keys.clear(); pressed.clear(); accumulator = 0;
      if (phase === 'playing') change('paused');
      else if (phase === 'paused') change('playing');
      return;
    }
    if (phase !== 'playing') return;
    if (!keys.has(key)) pressed.add(key);
    keys.add(key);
  }

  function tickActor(f, dt) {
    f.clock += dt; f.cool = Math.max(0, f.cool - dt);
    M.stepReaction(f, f === hero);
    if (f.down) f.x = clamp(f.x, bounds.left, bounds.right);
    if (f.hp <= 0) { f.death += dt; f.moving = false; }
  }

  function update(dt) {
    if (!['playing', 'dying', 'title'].includes(phase)) return;
    if (phase === 'title') { hero.clock += dt; return; }
    if (keys.has('k') && canCast()) {
      spell ??= { age: 0, targets: [] };
      spell.age++;
      // Fixed-step channel: a full meter lasts 200 ticks (~3.34 seconds).
      // Continuous damage, without restarting stagger, impact flashes or sound.
      magic = Math.max(0, magic - .5);
      spell.targets = enemies.filter(e => e.x >= 0 && e.x <= W && e.hp > 0).map(e => ({ id: e.id, x: e.x, y: e.y }));
      for (const e of enemies) if (e.x >= 0 && e.x <= W && e.hp > 0)
        damage(e, { damage: 1 / 9, knock: false, magic: true, continuous: true, direction: e.x > hero.x ? 1 : -1 }, hero);
      if (magic === 0) spell = null;
    } else spell = null;
    tickActor(hero, dt);
    for (const e of enemies) tickActor(e, dt);
    if (phase === 'dying') {
      if (hero.death > clips.heroDeath.duration + .7) change('lost');
      pressed.clear(); return;
    }
    banner -= dt; comboTime -= dt;
    if (comboTime < 0) combo = 0;
    const dx = Number(keys.has('d')) - Number(keys.has('a'));
    const dy = Number(keys.has('s')) - Number(keys.has('w'));
    const edge = pressed.has('a') ? -1 : pressed.has('d') ? 1 : 0;
    if (!spell && pressed.has('j') && pressed.has(' ') && !hero.air) M.begin(hero, 'back');
    else if (!spell && pressed.has(' ')) {
      if (M.startJump(hero)) beep(160, .12, 'sine');
    } else if (!spell && pressed.has('j')) {
      if (M.begin(hero, M.selectStrike(hero, enemies))) beep(230, .15);
    }
    M.stepMotion(hero, dx, dy, edge, bounds);
    M.tickAttack(hero, enemies, damage);
    pressed.clear();
    // Reserve one approach position per side; other fighters wait farther out.
    const engaged = new Set();
    for (const side of [-1, 1]) {
      const candidate = enemies.filter(e => e.hp > 0 && !e.down && Math.sign(e.x - hero.x) === side)
        .sort((a, b) => Math.abs(a.x - hero.x) - Math.abs(b.x - hero.x))[0];
      if (candidate) engaged.add(candidate.id);
    }
    for (const e of enemies) {
      if (e.hp <= 0) continue;
      const [ex, ey] = M.enemyIntent(e, hero, engaged.has(e.id));
      if (e.attack) M.stepMotion(e, 0, 0);
      else if (!e.hurtTicks && !e.down && !e.recovering) {
        // Enemy direction table C5DE: independent half-unit axes; harder types .625.
        const speed = wave >= 3 ? .625 : .5;
        e.velocityX = ex * speed; e.velocityY = ey * speed;
        e.x += e.velocityX * M.SCALE; e.y += e.velocityY * M.SCALE;
        e.y = clamp(e.y, bounds.top, bounds.bottom);
        e.moving = !!(ex || ey);
        if (e.moving) e.stride = (e.stride + 1 / 56) % 1;
      }
      const finished = M.tickAttack(e, [hero], damage);
      if (finished) {
        if (finished.connected && hero.hp > 0 && !hero.down && e.aiChain < 2 && finished.type !== 'enemyCharge') {
          e.aiChain++; M.begin(e, e.aiChain === 1 ? 'enemyFollow' : 'enemyFinish');
        } else { e.aiChain = 0; e.aiRest = 40; }
      }
      if (phase !== 'playing') break;
    }
    if (phase === 'playing' && enemies.every(e => e.hp <= 0 && e.death > clips.enemyDeath.duration + .8)) {
      if (wave === 4) change('won');
      else { wave++; hero.hp = Math.min(100, hero.hp + 20); spawn(); }
    }
    syncMagic();
  }

  function drawFighter(f, isHero) {
    const duration = isHero ? clips.heroDeath.duration : clips.enemyDeath.duration;
    const opacity = f.hp <= 0 ? 1 - smooth((f.death - duration - .3) / .55) : 1;
    if (opacity <= 0) return;
    const p = pose(f, isHero), atlas = atlases[p.atlas];
    if (!atlas) return;
    const size = f.boss ? 345 : 292;
    const height = (f.height || 0) * M.SCALE;
    ctx.save();
    ctx.save(); ctx.globalAlpha = opacity * Math.max(.12, 1 - height / 450);
    ctx.translate(f.x, f.y - 2); ctx.scale(1, .24);
    const radius = size * .23 + height * .035;
    const shadow = ctx.createRadialGradient(0, 0, 0, 0, 0, radius);
    shadow.addColorStop(0, '#05060565'); shadow.addColorStop(.35, '#05060545'); shadow.addColorStop(1, '#05060500');
    ctx.fillStyle = shadow; ctx.fillRect(-radius, -radius, radius * 2, radius * 2); ctx.restore();
    ctx.globalAlpha = opacity;
    ctx.translate(f.x, f.y - height);
    ctx.scale(f.dir, 1);
    if (!isHero && f.invulnerable > 0 && f.hp > 0 && Math.floor(f.invulnerable * 16) % 2) ctx.filter = 'brightness(1.25)';
    if (isHero && heroRig) heroRig.paint(ctx, p, size, opacity, reducedMotion ? null : f.clock, weaponId);
    else atlas.paint(ctx, p.frame, size, opacity);
    ctx.restore();
    if (!isHero && f.hp > 0 && f.hp < f.max) {
      ctx.fillStyle = '#180e0c'; ctx.fillRect(f.x - 35, f.y - size + 20, 70, 4);
      ctx.fillStyle = f.boss ? '#c470d9' : '#d89969'; ctx.fillRect(f.x - 35, f.y - size + 20, 70 * f.hp / f.max, 4);
    }
  }

  // Seeded, multi-scale fractures: a channel stays rigid between discharges.
  // New leaders find new paths; the bolt never bends like a waving rope.
  function lightningChannel(seed, ground) {
    let state = seed >>> 0;
    const random = () => { state = (Math.imul(state, 1664525) + 1013904223) >>> 0; return state / 4294967296; };
    function fracture(a, b, spread, depth) {
      if (!depth) return [a, b];
      const mid = [(a[0] + b[0]) / 2 + (random() - .5) * spread, (a[1] + b[1]) / 2];
      return [...fracture(a, mid, spread * .53, depth - 1).slice(0, -1), ...fracture(mid, b, spread * .53, depth - 1)];
    }
    const main = fracture([(random() - .5) * 190, -45], [0, ground], 190, 6);
    const branches = [];
    for (let i = 5; i < 57; i += 4 + Math.floor(random() * 3)) {
      const start = main[i], side = random() < .5 ? -1 : 1;
      const end = [start[0] + side * (35 + random() * 110), Math.min(ground - 12, start[1] + 65 + random() * 160)];
      const points = fracture(start, end, 50, 4);
      branches.push({points, width: .55 + random() * .5});
      const fork = points[7];
      branches.push({points: fracture(fork, [fork[0] + side * 45, Math.min(ground - 8, fork[1] + 65)], 24, 3), width: .35});
    }
    return {main, branches};
  }

  function drawSpell() {
    if (!spell || !stormTexture) return;
    spell.channels ??= new Map();
    const elapsed = Math.max(0, spell.age - 1) * M.STEP;
    const cw = stormTexture.width / 4, ch = stormTexture.height / 2;
    ctx.save(); ctx.globalCompositeOperation = 'screen'; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
    for (const target of spell.targets) {
      // 50 ms downward leader, 20 ms upward return stroke, then an energized
      // after-channel. Damage and meter drain remain continuous while held.
      const cycle = reducedMotion ? 0 : Math.floor(elapsed / .24);
      const age = reducedMotion ? Math.min(elapsed, .12) : elapsed - cycle * .24;
      let entry = spell.channels.get(target.id);
      if (!entry || entry.cycle !== cycle) {
        entry = {cycle, previous: entry?.current, current: lightningChannel(target.id * 7919 + cycle * 104729 + 17, target.y)};
        spell.channels.set(target.id, entry);
      }
      const front = -45 + (target.y + 45) * clamp(age / .05);
      const connected = age >= .05;
      const surge = connected ? Math.exp(-(age - .05) * 24) : 0;
      const paint = (channel, alpha, bottom, returnOnly = false) => {
        ctx.save(); ctx.translate(target.x, 0);
        ctx.beginPath(); ctx.rect(-300, returnOnly ? target.y - (target.y + 45) * clamp((age - .05) / .02) : -45, 600,
          returnOnly ? (target.y + 45) * clamp((age - .05) / .02) + 5 : bottom + 45); ctx.clip();
        const stroke = (points, width, color) => {
          ctx.beginPath(); ctx.moveTo(...points[0]); for (let i = 1; i < points.length; i++) ctx.lineTo(...points[i]);
          ctx.lineWidth = width; ctx.strokeStyle = color; ctx.stroke();
        };
        ctx.globalAlpha = alpha;
        ctx.shadowColor = '#bcd7ff'; ctx.shadowBlur = reducedMotion ? 5 : 13;
        stroke(channel.main, 7, '#9bbfff35');
        ctx.shadowBlur = 0;
        stroke(channel.main, 3.5, '#d5e4ff80');
        for (const branch of channel.branches) stroke(branch.points, branch.width, '#c7d9ef90');
        stroke(channel.main, returnOnly ? 2.2 : 1.25, '#fffdf0');
        ctx.restore();
      };
      // Residual conduction bridges successive leaders, avoiding on/off casts.
      if (entry.previous) paint(entry.previous, .2 * (1 - clamp(age / .09)), target.y);
      paint(entry.current, reducedMotion ? .42 : connected ? .65 : .55, front);
      if (connected && !reducedMotion) paint(entry.current, .45 * surge, target.y, true);
      if (connected || entry.previous) {
        ctx.globalAlpha = reducedMotion ? .2 : .24 + .12 * surge;
        const h = 210, w = h * cw / ch;
        ctx.drawImage(stormTexture, cw, ch, cw, ch, target.x - w / 2, target.y - h * .78, w, h);
        ctx.save(); ctx.translate(target.x, target.y); ctx.scale(1, .3);
        const light = ctx.createRadialGradient(0, 0, 0, 0, 0, 110);
        light.addColorStop(0, '#dce8ff88'); light.addColorStop(1, '#bedbff00');
        ctx.fillStyle = light; ctx.fillRect(-110, -110, 220, 220); ctx.restore();
      }
    }
    ctx.restore();
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
    drawSpell();
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
    const raw = last === null ? 0 : Math.min(.25, Math.max(0, (now - last) / 1000)); last = now;
    const frozen = ['paused', 'won', 'lost'].includes(phase);
    const dt = frozen ? 0 : raw;
    clock += dt;
    if (frozen || !ready) accumulator = 0;
    else {
      accumulator += dt;
      while (accumulator + 1e-10 >= M.STEP) {
        update(M.STEP); accumulator -= M.STEP;
        if (['won', 'lost'].includes(phase)) { accumulator = 0; break; }
      }
    }
    shake = Math.max(0, shake - dt * 35);
    render(dt); raf = requestAnimationFrame(loop);
  }

  const down = event => {
    const key = event.key.toLowerCase();
    if ([' ', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright', 'w', 'a', 's', 'd', 'j', 'k', 'p'].includes(key)) {
      event.preventDefault(); if (!event.repeat) action(key, true);
    }
  };
  const up = event => action(event.key.toLowerCase(), false);
  const blur = () => { keys.clear(); pressed.clear(); accumulator = 0; if (phase === 'playing') change('paused'); };
  window.addEventListener('keydown', down); window.addEventListener('keyup', up); window.addEventListener('blur', blur);
  $('start').onclick = start;
  $('resume').onclick = () => phase === 'paused' ? change('playing') : start();
  $('pause').onclick = () => action('p', true);
  $('sound').onclick = () => {
    muted = !muted; $('sound').textContent = muted ? 'SOUND OFF' : 'SOUND ON';
    $('sound').setAttribute('aria-label', muted ? 'Enable sound' : 'Mute sound'); beep(280, .2, 'sine');
  };
  $('weapon').onchange = event => {
    if (Object.hasOwn(weapons, event.target.value)) weaponId = event.target.value;
  };
  $('full').onclick = () => document.fullscreenElement ? document.exitFullscreen() : $('stage').requestFullscreen();
  document.querySelectorAll('[data-key]').forEach(button => {
    button.onpointerdown = event => { button.setPointerCapture(event.pointerId); action(button.dataset.key, true); };
    button.onpointerup = button.onpointercancel = button.onlostpointercapture = () => action(button.dataset.key, false);
  });

  const loadImage = src => new Promise((resolve, reject) => {
    const image = new Image(); image.onload = () => resolve(image); image.onerror = reject; image.src = src;
  });
  const names = ['hero-reactions-unarmed-v8', 'hero-walk-unarmed-v8', 'hero-actions-unarmed-v8', 'hero-extra-unarmed-v8', 'hero-close-unarmed-v8', 'enemy-walk-v4', 'enemy-attack-v4', 'enemy-charge-v5', 'enemy-combat-v3'];
  const atlasConfig = {
    'hero-walk-unarmed-v8': { columns: 4, rows: 1, frames: 4 },
    'hero-actions-unarmed-v8': { columns: 4, rows: 2, frames: 8, breathRegion: [.5,.275,.3,.11] },
    'hero-reactions-unarmed-v8': { columns: 4, rows: 3, frames: 12 },
    'hero-extra-unarmed-v8': { columns: 4, rows: 3, frames: 12 },
    'hero-close-unarmed-v8': { columns: 4, rows: 3, frames: 12 },
    'enemy-walk-v4': { columns: 4, rows: 1, frames: 4, scale: .88, facing: -1 },
    'enemy-attack-v4': { columns: 4, rows: 1, frames: 4, scale: 1.08, facing: -1 },
    'enemy-charge-v5': { columns: 4, rows: 1, frames: 4, scale: 1.2, facing: -1 },
    'enemy-combat-v3': { scale: 1.07 },
  };
  Promise.all([
    loadImage('/art/weapons-v8.png').then(image => { weaponAtlas = new Atlas(decodeChroma(image), { columns: 2, rows: 1, frames: 2 }); }),
    loadImage('/art/storm-strike-v7.png').then(image => { stormTexture = image; }),
    loadImage('/art/valley.png').then(image => { if (running) background = new LivingBackground(image, W, H); }),
    ...names.map(name => loadImage(`/art/${name}.png`).then(image => {
      atlases[name] = new Atlas(decodeChroma(image), atlasConfig[name]);
    })),
  ]).then(() => {
    if (!running) return;
    heroRig = new HeroRig(atlases, weaponAtlas);
    const idle = atlases['hero-actions-unarmed-v8'];
    if (!reducedMotion && idle.cels?.[0]) for (let i = 0; i < 48; i++) idle.breathingCel(idle.cels[0], i * .1 + .00001);
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
    status: () => ({ phase, health: Math.round(hero.hp), wave, score, magic, magicMax: 100, magicReady: canCast(), channeling: !!spell, weapon: weaponId, kills }), start,
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
