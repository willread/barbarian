(() => {
  window.stopGame?.();
  const $ = id => document.getElementById(id);
  const canvas = $('game'), ctx = canvas.getContext('2d');
  const W = 1440, H = 810;
  const blood = new window.AshenBlood(W, H);
  const aftermath=new window.AshenEvents.Aftermath(),field=new window.AshenEvents.FieldEvents();
  let fireTexture,smokeTexture,chickenAtlas;
  const { Atlas, LivingBackground, clips, pose, decodeChroma, clamp, smooth } = window.AshenAnimation;
  const M = window.AshenMechanics;
  const E = window.AshenEnemies;
  let encounters = E.plan();
  const { HeroRig, weapons } = window.AshenHeroRig;
  let heroRig, enemyRig, enemyEquipment, weaponId = 'axe', weaponAtlas;
  const keys = new Set(), pressed = new Set(), atlases = {};
  const bounds = { left: 70, right: W - 70, top: 560, bottom: 755 };
  const reducedMotion = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches || false;
  let running = true, ready = false, raf, last = null, clock = 0, accumulator = 0, spell = null;
  let phase = 'title', wave = 1, score = 0, kills = 0, magic = 100, stormTexture, hudTexture, hudCrests;
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
    $('wave').textContent = `${wave===encounters.length?'FINAL DUEL':'THE VALLEY'}`;
  }

  function canCast() {
    return phase === 'playing' && magic >= 100 && !spell && !hero.air && !hero.attack && !hero.down;
  }
  function syncMagic() {
    const ready = canCast();
    $('magic-fill').style.width = magic + '%';
    $('magic-meter').setAttribute('aria-valuenow', String(magic));
    $('magic-meter').setAttribute('aria-valuetext', `${Math.ceil(magic)} percent. Press K at full charge for a 1.5 second nearby lightning burst. Charge with weapon hits and kills.`);
    $('magic-state').textContent = spell ? 'STORM ACTIVE' : ready ? 'READY · PRESS K' : magic > 0 ? Math.ceil(magic) + '% · CHARGING' : 'EMPTY · LAND HITS';
    $('magic').setAttribute('data-ready', String(ready));
  }

  function change(next) {
    if (next !== 'playing') spell = null;
    phase = next;
    $('title').hidden = next !== 'title';
    $('hud').hidden = false;
    $('overlay').style.backdropFilter=next==='lost'?'none':'';
    $('overlay').hidden = !['paused', 'won', 'lost'].includes(next);
    $('outcome').textContent = next === 'paused' ? 'TAKE A BREATH' : next === 'won' ? 'THE VALLEY IS FREE' : 'THE LEGION ENDURES';
    $('message').textContent = next === 'paused' ? 'Battle paused' : next === 'won' ? 'A legend rises.' : 'Even heroes fall.';
    $('result').textContent = next === 'paused' ? '' : `${kills} enemies slain · ${score.toLocaleString()} points`;
    $('resume').textContent = next === 'paused' ? 'RESUME BATTLE' : 'RISE AGAIN';
    $('pause').textContent = next === 'paused' ? '▷' : 'Ⅱ';
  }

  function spawn() {
    enemies = encounters[wave-1].map((kind, i) => {
      const left = wave !== encounters.length && Math.random() < .5;
      const e = E.init(make(left ? -80-i*90 : W+80+i*90, wave===encounters.length?660:570+Math.random()*150, E.roster[kind].hp),kind);
      E.variant(e);e.dir = left ? 1 : -1;
      return e;
    });
    field.wave();banner = 0; sync();
  }

  function start() {
    if (!ready) throw new Error('Artwork is still loading');
    hero = make(470, 660, 100, true); hero.weapon=weaponId; wave = 1; score = 0; kills = 0; magic = 100;
    combo = 0; sparks = []; shake = 0; spell = null; accumulator = 0;
    blood.reset();aftermath.reset();field.reset();
    encounters = E.plan();
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
    if (!isHero && E.block(e, attack, attacker)) {
      e.x=clamp(e.x,bounds.left,bounds.right);burst(e.x+e.dir*40,e.y-110,8,'#cfbd94');beep(380,.08,'triangle');return;
    }
    e.hp = Math.max(0, e.hp - attack.damage * (isHero ? 100 / 48 : 1));
    if (attack.magic && e.hp > 0) {
      e.attack=null;e.electricTicks=9;
      if(!e.down){e.hurtTicks=9;e.recovering=0;e.stagger=0;e.moving=false;e.velocityX=e.velocityY=0;}
    }
    if (!attack.continuous || e.hp <= 0) {
      const impact = { ...e };
      const committed = e.kind==='marauder' && e.attack && e.attack.age>=e.attack.from && e.attack.age<=e.attack.to && !attack.knock;
      const bossCommitted = e.kind==='champion' && !e.down && (!e.attack || e.attack.age<=e.attack.to);
      const savedAttack = committed || bossCommitted ? e.attack : null;
      const bossRecovery = e.kind==='champion' && e.attack && e.attack.age>e.attack.to;
      const reactionAttack = bossCommitted ? {...attack,knock:false} : attack;
      M.hurt(e, reactionAttack, isHero, attacker);
      if(e.hp>0 && (committed || bossCommitted)){
        e.hurtTicks=0;e.recoil=e.hurtTicks*M.STEP;e.stagger=0;e.recovering=0;
        if(savedAttack)e.attack=savedAttack;
      } else if(e.hp>0 && bossRecovery && !reactionAttack.knock){
        e.hurtTicks=12;e.recoil=12*M.STEP;e.stagger=0;e.aiRest=0;e.invTicks=30;
      }
      if(e.hp<=0&&!isHero&&e.down)e.down.vx*=.48;
      // Keep the wound's original height, but inherit the launch just applied.
      blood.hit({ ...impact, down: e.down || impact.down }, attack.direction || 1, e.hp <= 0);
      if(e.hp<=0&&!isHero)for(let i=0;i<(e.boss?4:1);i++)blood.hit({...impact,down:e.down},attack.direction||1,true);
      burst(e.x, e.y - 105, 12, isHero ? '#e97b4f' : '#ffc473');
      shake = attack.knock ? 5 : 2; beep(isHero ? 60 : 100);
    }
    // No global hit-stop: source action and stagger windows run continuously.
    if (e.hp <= 0) {
      e.death = 0;
      const gear=[];
      const add=(cel,h)=>{if(cel)gear.push({image:cel.image,h})};
      if(isHero)add(weaponAtlas?.cels?.[weapons[weaponId].frame],weapons[weaponId].length);
      else if(e.kind==='champion')add(weaponAtlas?.cels?.[0],182);
      else {add(enemyEquipment?.cels?.[e.kind==='bone'?0:e.kind==='shield'?1:2],e.kind==='shield'?108:140);if(e.kind==='shield')add(enemyEquipment?.cels?.[3],158)}
      aftermath.death(e,gear);
      if (isHero) change('dying');
      else { kills++; score += e.boss ? 1500 : 250; combo++; comboTime = 2.2; }
    }
    if (!isHero && attacker === hero && !attack.magic) magic = Math.min(100, magic + 6 + (e.hp <= 0 ? 8 : 0));
    sync();
  }

  function action(key, on) {
    key = ({ arrowleft: 'a', arrowright: 'd', arrowup: 'w', arrowdown: 's' })[key] || key;
    if (!on) { keys.delete(key);  return; }
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
    f.electricTicks=Math.max(0,(f.electricTicks||0)-1);
    f.clock += dt; f.cool = Math.max(0, f.cool - dt);
    M.stepReaction(f, f === hero);
    if (f.down) f.x = clamp(f.x, bounds.left, bounds.right);
    if (f.hp <= 0) { f.death += dt; f.moving = false; }
  }

  function update(dt) {
    if (!['playing', 'dying', 'title'].includes(phase)) return;
    if (phase === 'title') { hero.clock += dt; return; }
    blood.step(dt, [hero, ...enemies]);aftermath.step(dt,[hero,...enemies]);
    if(phase==='playing'){const hp=hero.hp;field.step(dt,wave,hero);if(hero.hp!==hp)sync();}
    if (pressed.has('k') && canCast()) {
      if (hero.hurtTicks || hero.recovering) {
        hero.hurtTicks = hero.hurtAge = hero.recovering = hero.recoil = hero.stagger = 0;
        // Brief protection makes the escape usable against overlapping blows.
        // It is not renewed by ordinary channeling, and cannot bypass knockdown.
        hero.invTicks = Math.max(hero.invTicks, 24);
      }
      spell = { age: 0, targets: [] };
      magic = 0;
    }
    if (spell) {
      spell.age++;
      // One full charge buys 90 fixed ticks (about 1.5 seconds).
      // Damage and electrical interruption persist for the timed burst.
      
      spell.targets = enemies.filter(e => inStorm(e)).map(e => ({ id: e.id, x: e.x, y: e.y }));
      for (const e of enemies) if (spell.age>=20 && spell.age<77 && inStorm(e))
        damage(e, { damage: .12, knock: false, magic: true, continuous: true, direction: e.x > hero.x ? 1 : -1 }, hero);
      if (spell && spell.age >= 90) spell = null;
    }
    tickActor(hero, dt);
    for (const e of enemies) tickActor(e, dt);
    if (phase === 'dying') {
      if (hero.death > 2.2 && hero.down?.ground) change('lost');
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
    M.stepMotion(hero, spell ? 0 : dx, spell ? 0 : dy, spell ? 0 : edge, bounds);
    if(hero.attack?.weapon && heroRig){
      const nextPose=pose({...hero,attack:{...hero.attack,age:hero.attack.age+1}},true);
      hero.attack.box=heroRig.hitBox(nextPose,hero.attack.weapon)||hero.attack.box;
    }
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
      const [ex, ey] = E.intent(e, hero, engaged.has(e.id));
      if(e.roarPending){e.roarPending=false;roar();}
      if (e.attack) E.motion(e);
      else if (!e.hurtTicks && !e.down && !e.recovering) {
        // Enemy direction table C5DE: independent half-unit axes; harder types .625.
        const speed = (E.roster[e.kind]?.speed || .5)*(e.speedFactor||1);
        e.velocityX = ex * speed; e.velocityY = ey * speed;
        e.x += e.velocityX * M.SCALE; e.y += e.velocityY * M.SCALE;
        e.y = clamp(e.y, bounds.top, bounds.bottom);
        e.moving = !!(ex || ey);
        if (e.moving) e.stride = (e.stride + 1 / 56) % 1;
      }
      e.x=clamp(e.x,-180,W+180);
      const finished = M.tickAttack(e, [hero], damage);
      if (finished) E.finish(e, finished, hero);
      if (phase !== 'playing') break;
    }
    if (phase === 'playing' && enemies.every(e => e.hp <= 0 && e.death > 3.4)) {
      if (wave === encounters.length) change('won');
      else { wave++; spawn(); }
    }
    syncMagic();
  }

  function drawHUD() {
    if(!hudTexture)return;
    const h=$('game-hud').getContext('2d');
    h.save();h.clearRect(0,0,1440,296);h.translate(0,44);h.scale(1440/2172,252/380);
    if(hudCrests)h.drawImage(hudCrests,0,-66,2172,66);
    h.drawImage(hudTexture,0,0,2172,380,0,0,2172,380);
    // Center the pair in the stone panel (y40..350), with equal 30px margins.
    h.drawImage(hudTexture,270,445,970,160,270,55,970,290);
    h.drawImage(hudTexture,280,80,940,124,280,70,940,110);
    h.drawImage(hudTexture,280,80,940,124,280,210,940,110);
    const gauge=(y,value,colors,glow)=>{
      const x=294,w=912,height=90;h.save();h.beginPath();h.rect(x,y,w,height);h.clip();
      const fill=h.createLinearGradient(0,y,0,y+height);colors.forEach((c,i)=>fill.addColorStop(i/(colors.length-1),c));
      h.fillStyle=fill;h.fillRect(x,y,w*clamp(value/100),height);
      h.save();h.beginPath();h.rect(x,y,w*clamp(value/100),height);h.clip();h.globalCompositeOperation='soft-light';h.globalAlpha=.6;h.drawImage(hudTexture,300,102,895,78,x,y,w,height);h.restore();
      h.globalAlpha=.35;h.fillStyle='#fff4d3';h.fillRect(x,y+3,w*clamp(value/100),3);h.restore();
      if(glow){h.save();h.strokeStyle=`rgba(154,219,255,${reducedMotion?.65:.5+.3*Math.sin(clock*5)})`;h.shadowColor='#63baff';h.shadowBlur=16;h.lineWidth=4;h.strokeRect(x,y,w,height);h.restore();}
    };
    gauge(81,hero.hp,['#f59d91','#bf221e','#710807','#a41413'],false);
    gauge(221,magic,['#d5f5ff','#269bff','#074891','#1585e2'],canCast());
    // Paint the bronze rim LAST. Its aperture masks the liquid's corners.
    for(const top of [70,210]){
      h.save();h.beginPath();h.rect(280,top,940,110);
      const x=298,y=top+17,w=901,b=top+94,c=7;
      h.moveTo(x+c,y);h.lineTo(x+w-c,y);h.lineTo(x+w,y+c);h.lineTo(x+w,b-c);
      h.lineTo(x+w-c,b);h.lineTo(x+c,b);h.lineTo(x,b-c);h.lineTo(x,y+c);h.closePath();
      h.clip('evenodd');h.drawImage(hudTexture,280,80,940,124,280,top,940,110);h.restore();
    }
    const weapon=weapons[weaponId],cel=weaponAtlas?.cels?.[weapon.frame];
    if(cel){const height=245,width=height*cel.image.width/cel.image.height;h.save();h.translate(1400,193);h.rotate(.5);h.drawImage(cel.image,-width/2,-height/2,width,height);h.restore();}
    h.textAlign='center';h.textBaseline='middle';h.shadowColor='#000';h.shadowBlur=4;h.shadowOffsetY=3;h.fillStyle='#eedbb0';
    h.font='bold 32px Georgia';h.fillText('SCORE',1758,83);
    h.font='bold 78px Georgia';h.fillText(String(score).padStart(6,'0'),1758,182);
    h.font='bold 33px Georgia';h.fillText(`${wave===encounters.length?'FINAL DUEL':'THE VALLEY'}`,1758,281);
    h.restore();
  }

  function drawFighter(f, isHero) {
    const duration = isHero ? clips.heroDeath.duration : clips.enemyDeath.duration;
    const opacity = !isHero && f.hp<=0 && f.death>.15+(f.engulf||1)+.6 ? 0 : 1;
    if (opacity <= 0) return;
    const castFrame = spell ? (spell.age<5?0:spell.age<9?1:spell.age<13?2:spell.age<17?3:spell.age<45?4:spell.age<77?5:spell.age<84?6:7) : null;
    const p = isHero && spell && !f.down && !f.hurtTicks ? {atlas:'hero-cast-unarmed-v1',frame:castFrame} : !isHero && f.kind!=='legion' ? E.pose(f) : pose(f, isHero), atlas = atlases[p.atlas];
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
    ctx.scale(f.dir*(f.size||1), f.size||1);
    if (!isHero && f.electricTicks > 0) ctx.filter = `brightness(${Math.floor(clock*30)%3===0?3.5:1.7}) saturate(.15) drop-shadow(0 0 7px #c6e7ff)`;
    else if (!isHero && f.invulnerable > 0 && f.hp > 0 && Math.floor(f.invulnerable * 16) % 2) ctx.filter = 'brightness(1.25)';
    const paint=g=>{
      if(isHero&&heroRig)heroRig.paint(g,p,size,opacity,reducedMotion?null:f.clock,f.gearDropped?'none':f.attack?.weapon||weaponId);
      else if(!isHero&&f.kind!=='legion'&&enemyRig)enemyRig.paint(g,f,p,opacity);
      else atlas.paint(g,p.frame,size,opacity);
    };
    if(!isHero&&f.hp<=0)aftermath.body(ctx,f,paint);else paint(ctx);
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

  function inStorm(e){return e.hp>0 && Math.hypot(e.x-hero.x,(e.y-hero.y)*3)<420;}
  function roar(){
    if(muted)return;try{audio??=new(window.AudioContext||window.webkitAudioContext)();const n=audio.createBuffer(1,audio.sampleRate*.45,audio.sampleRate),d=n.getChannelData(0);for(let i=0;i<d.length;i++)d[i]=(Math.random()*2-1)*Math.sin(i/audio.sampleRate*85*Math.PI*2);const s=audio.createBufferSource(),filter=audio.createBiquadFilter(),gain=audio.createGain();s.buffer=n;filter.type='lowpass';filter.frequency.value=700;gain.gain.setValueAtTime(.17,audio.currentTime);gain.gain.exponentialRampToValueAtTime(.001,audio.currentTime+.45);s.connect(filter);filter.connect(gain);gain.connect(audio.destination);s.start()}catch{}
  }
  function drawSpell() {
    if(!spell||spell.age<17||spell.age>=77)return;
    const cast={atlas:'hero-cast-unarmed-v1',frame:spell.age<45?4:5},l=heroRig.layout(cast);
    if(!l)return;const weapon=weapons[weaponId];
    const start=[hero.x+(l.grip[0]+Math.sin(l.angle)*weapon.length*weapon.grip)*hero.dir,hero.y+l.grip[1]-Math.cos(l.angle)*weapon.length*weapon.grip];
    spell.origin=start;spell.channels??=new Map();
    const elapsed=(spell.age-17)*M.STEP,cycle=Math.floor(elapsed/.16),age=elapsed-cycle*.16;
    ctx.save();ctx.globalCompositeOperation='screen';ctx.lineCap='round';ctx.lineJoin='round';
    for(const target of spell.targets){
      let entry=spell.channels.get(target.id);
      if(!entry||entry.cycle!==cycle){entry={cycle,current:lightningChannel(target.id*7919+cycle*104729,500)};spell.channels.set(target.id,entry)}
      const points=entry.current.main.map((p,i,a)=>{const t=i/(a.length-1);return [start[0]+(target.x-start[0])*t+p[0]*.4,start[1]+(target.y-100-start[1])*t]});
      const count=Math.max(2,Math.ceil(points.length*clamp(age/.04)));
      for(const [width,color] of [[8,'#89baff35'],[3,'#bfe2ff99'],[1.3,'#fff9dd']]){ctx.beginPath();ctx.moveTo(...points[0]);for(let i=1;i<count;i++)ctx.lineTo(...points[i]);ctx.lineWidth=width;ctx.strokeStyle=color;ctx.stroke()}
      for(let i=5;i<count-4;i+=9){ctx.beginPath();ctx.moveTo(...points[i]);ctx.lineTo(points[i][0]+(i%2?1:-1)*25,points[i][1]+12);ctx.lineTo(points[i][0]+(i%2?1:-1)*38,points[i][1]+35);ctx.lineWidth=.7;ctx.strokeStyle='#c8e5ff88';ctx.stroke()}
    }
    ctx.restore();
  }

  function render(dt) {
    drawHUD();
    ctx.save(); ctx.clearRect(0, 0, W, H);
    if (!reducedMotion && phase !== 'paused') ctx.translate((Math.random() - .5) * shake, (Math.random() - .5) * shake);
    if (background) background.draw(ctx, clock, reducedMotion);
    else { ctx.fillStyle = '#151c23'; ctx.fillRect(0, 0, W, H); }
    const shade = ctx.createLinearGradient(0, 0, 0, H);
    shade.addColorStop(0, '#080b0f77'); shade.addColorStop(.3, '#080b0f00'); shade.addColorStop(1, '#080b0f44');
    ctx.fillStyle = shade; ctx.fillRect(0, 0, W, H);
    blood.drawGround(ctx);aftermath.ground(ctx);
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
    field.draw(ctx,chickenAtlas);
    for(const e of enemies)if(e.hp<=0)aftermath.flames(ctx,e,fireTexture,smokeTexture);
    aftermath.sparks(ctx);blood.drawAir(ctx);
    drawSpell();
    const champion=enemies.find(e=>e.kind==='champion'&&e.hp>0);
    if(champion && phase!=='title'){
      ctx.textAlign='center';ctx.font='small-caps 20px Georgia';ctx.fillStyle='#e6d2aa';
      ctx.fillText(champion.phaseTwo?'Cairn Champion · Unbound':'Cairn Champion',W/2,43);
      ctx.fillStyle='#160f0e';ctx.fillRect(W/2-210,54,420,8);
      ctx.fillStyle=champion.phaseTwo?'#ab4935':'#9e7750';ctx.fillRect(W/2-210,54,420*champion.hp/champion.max,8);
    }
    ctx.restore();
  }

  function loop(now) {
    if (!running) return;
    const raw = last === null ? 0 : Math.min(.25, Math.max(0, (now - last) / 1000)); last = now;
    const frozen = ['paused', 'won', 'lost'].includes(phase);
    const dt = frozen ? 0 : raw*(phase==='dying'&&hero.death<1.3?.3:1);
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
    hero.weapon=weaponId;
    $('weapon').setAttribute('aria-label',`${weaponId} equipped. Activate to change weapon`);
  };
  $('weapon').onclick=()=>{ $('weapon').onchange({target:{value:weaponId==='axe'?'sword':'axe'}}); };
  $('full').onclick = () => document.fullscreenElement ? document.exitFullscreen() : $('stage').requestFullscreen();
  document.querySelectorAll('[data-key]').forEach(button => {
    button.onpointerdown = event => { button.setPointerCapture(event.pointerId); action(button.dataset.key, true); };
    button.onpointerup = button.onpointercancel = button.onlostpointercapture = () => action(button.dataset.key, false);
  });

  const loadImage = src => new Promise((resolve, reject) => {
    const image = new Image(); image.onload = () => resolve(image); image.onerror = reject; image.src = src;
  });
  const names = ['hero-cast-unarmed-v1', 'hero-reactions-unarmed-v8', 'hero-walk-unarmed-v8', 'hero-actions-unarmed-v8', 'hero-extra-unarmed-v8', 'hero-close-unarmed-v8', 'enemy-walk-v4', 'enemy-attack-v4', 'enemy-charge-v5', 'enemy-combat-v3', 'enemy-bone-v1', 'enemy-shield-v1', 'enemy-marauder-v1', 'enemy-champion-v1'];
  const atlasConfig = {
    'hero-cast-unarmed-v1': { columns:4, rows:2, frames:8 },
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
    loadImage('/art/fluid-fire-v1.png').then(i=>fireTexture=i),
    loadImage('/art/fluid-smoke-v1.png').then(i=>smokeTexture=i),
    loadImage('/art/chicken-v1.png').then(i=>{const c=decodeChroma(i),g=c.getContext('2d'),p=g.getImageData(0,0,c.width,c.height),d=p.data;for(let n=0;n<d.length;n+=4){const chroma=d[n]-Math.min(d[n+1],d[n+2]);d[n+3]*=clamp((chroma-7)/18)}g.putImageData(p,0,0);chickenAtlas=new Atlas(c,{columns:4,rows:3,frames:12})}),
    loadImage('/art/hud-bronze-top-extended-v2.png').then(image => {
      const crest=document.createElement('canvas');crest.width=2172;crest.height=66;const c=crest.getContext('2d');
      c.drawImage(image,0,0,2172,66,0,0,2172,66);
      const pixels=c.getImageData(0,0,2172,66),d=pixels.data;
      for(let i=0;i<d.length;i+=4){const x=(i/4)%2172;d[i+3]=x>110&&x<2062?0:Math.round(255*clamp((d[i]-Math.max(d[i+1],d[i+2])*1.12-6)/18));}
      c.putImageData(pixels,0,0);hudCrests=crest;
    }),
    loadImage('/art/hud-bronze-v1.png').then(image => { hudTexture = image; }),
    loadImage('/art/enemy-equipment-v1.png').then(image => { enemyEquipment = new Atlas(decodeChroma(image), {columns:4,rows:1,frames:4}); }),
    loadImage('/art/weapons-v8.png').then(image => { weaponAtlas = new Atlas(decodeChroma(image), { columns: 2, rows: 1, frames: 2 }); }),
    loadImage('/art/storm-strike-v7.png').then(image => { stormTexture = image; }),
    loadImage('/art/valley.png').then(image => { if (running) background = new LivingBackground(image, W, H); }),
    ...names.map(name => loadImage(`/art/${name}.png`).then(image => {
      atlases[name] = new Atlas(decodeChroma(image), atlasConfig[name]);
    })),
  ]).then(() => {
    if (!running) return;
    heroRig = new HeroRig(atlases, weaponAtlas);
    enemyRig = new window.AshenEnemyRig(atlases, enemyEquipment, weaponAtlas);
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
    status: () => ({ phase, health: Math.round(hero.hp), wave, score, magic, magicMax: 100, magicReady: canCast(), channeling: !!spell, weapon: weaponId, kills,
      enemies:enemies.filter(e=>e.hp>0).map(e=>({type:e.kind,name:E.roster[e.kind].name,health:e.hp,maxHealth:e.max,phaseTwo:!!e.phaseTwo})) }), start,
    pause: () => action('p', true),
  };
})();

(() => {
  const context = document.modelContext, lifecycle = new AbortController();
  if (context?.registerTool) for (const [name, description, execute, readOnly] of [
    ['get_battle_status', 'Read the current battle health, wave, score and magic.', () => window.ashenAxe.status(), true],
    ['start_new_battle', 'Restart the eight-encounter battle, resetting score and health.', () => {
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
