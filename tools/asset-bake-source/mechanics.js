(() => {
  // Original implementation from measured NTSC World-ROM behavior. Coordinates
  // and velocities stay in ROM units until integration into the painted scene.
  const HZ = 59.92274340431231, STEP = 1 / HZ, SCALE = 4.5;
  const approach = (v, target, amount) => v < target ? Math.min(target, v + amount) : Math.max(target, v - amount);
  const weaponStats={axe:{speed:1.22,damage:1.5,reach:35},sword:{speed:.78,damage:1,reach:48}};
  const attacks = {
    whiff: { ticks: 22, from: 0, to: -1, damage: 0, reach: 43 },
    slash: { ticks: 18, from: 8, to: 12, damage: 2, reach: 43, box: [16,24,-64,40] },
    pommel: { ticks: 22, from: 13, to: 17, damage: 2, reach: 40, box: [16,16,-40,16] },
    kick: { ticks: 39, from: 15, to: 20, damage: 4, reach: 40, box: [16,40,-48,24], knock: true },
    air: { ticks: 11, from: 7, to: 10, damage: 6, reach: 36, knock: true },
    back: { ticks: 45, from: 27, to: 32, damage: 12, reach: 38, knock: true },
    charge: { ticks: 32, from: 2, to: 31, damage: 4, reach: 24, knock: true },
    enemy: { ticks: 51, from: 29, to: 36, damage: 2, reach: 43, box: [-5,31,-46,13] },
    enemyFollow: { ticks: 40, from: 18, to: 25, damage: 2, reach: 43, box: [-13,39,-75,23] },
    enemyFinish: { ticks: 41, from: 18, to: 25, damage: 4, reach: 43, box: [-5,31,-46,13], knock: true },
    enemyCharge: { ticks: 36, from: 2, to: 35, damage: 4, reach: 24, box: [-4,13,-44,28], knock: true },
  };
  function init(f) {
    Object.assign(f, { velocityX: 0, velocityY: 0, running: false, runDir: 0,
      tapDir: 0, tapTicks: -1, air: null, height: 0, jump: null, jumpLaunch: 5.5,
      stagger: 0, hurtTicks: 0, hurtAge: 0, down: null, recovering: 0,
      invTicks: 0, attack: null, lastSlash: 0, aiClock: 0, aiRest: 0, aiChain: 0,
      aiChargeRest: 0, aiDx: 0, aiDy: 0, moving: false });
    return f;
  }
  function startJump(f) {
    if (f.air || f.attack || f.hurtTicks || f.down || f.recovering) return false;
    f.jumpLaunch = 5.5;
    f.air = { age: 0, launch: f.jumpLaunch, vz: 0 }; f.jump = 0;
    f.velocityX = f.velocityY = 0; f.running = false; return true;
  }
  function stepMotion(f, dx, dy, horizontalEdge = 0, bounds) {
    if (f.hurtTicks || f.down || f.recovering) { f.moving = false; return; }
    if (f.air) {
      const a = f.air; a.age++; f.jump = a.age * STEP;
      if (a.age === 3) a.vz = -a.launch;
      else if (a.age > 3 && f.height > 0) {
        a.vz = Math.min(8, a.vz + .25);
        f.velocityX = dx ? approach(f.velocityX, dx * 1.5, .0625) : 0;
      }
      if (a.age >= 3 && !a.land) { f.height = Math.max(0, f.height - a.vz); f.x += f.velocityX * SCALE; }
      if (a.age >= 3 && f.height === 0 && a.vz >= 0) {
        a.land ??= 3;
        if (a.land < 3) { f.velocityX = 0; a.vz = 0; }
        if (--a.land === 0) { f.air = null; f.jump = null; f.velocityX = 0; f.attack = null; }
      }
      f.moving = false;
    } else if (f.attack) {
      f.moving = false;
      if (f.attack.type === 'charge' || f.attack.type === 'enemyCharge') {
        const a = f.attack;
        f.velocityX = a.connected ? 0 : approach(f.velocityX, a.direction * 4, .5);
        f.x += f.velocityX * SCALE;
        // A charge is a low committed hop, not an ordinary walking slash.
        if (a.type === 'enemyCharge' || a.age >= 1) {
          const initialized = a.vz !== undefined;
          a.vz ??= a.type === 'charge' ? -2.125 : -4;
          if (initialized) a.vz += a.type === 'enemyCharge' ? .25 : (a.vz < 0 || a.vz >= 2 ? .125 : .25);
          f.height = Math.max(0, f.height - a.vz);
        }
      }
    } else {
      let justRan = false;
      if (f.running && dx !== f.runDir) { f.running = false; justRan = true; }
      if (horizontalEdge) {
        if (horizontalEdge === f.tapDir && f.tapTicks >= 0) {
          f.running = true; f.runDir = horizontalEdge; f.tapDir = 0; f.tapTicks = -1;
        } else if (f.tapDir) { f.tapDir = 0; f.tapTicks = -1; }
        else { f.tapDir = horizontalEdge; f.tapTicks = 16; }
      } else if (--f.tapTicks < 0) f.tapDir = 0;
      if (!justRan) {
        const target = dx * (f.running ? 4 : 1.5);
        // Re-entering walk from a faster state clamps to its held-direction cap.
        if (dx && Math.sign(f.velocityX) === dx && Math.abs(f.velocityX) > Math.abs(target)) f.velocityX = target;
        else f.velocityX = approach(f.velocityX, target, .5);
      }
      f.velocityY = f.running || justRan ? 0 : dy;
      let vx = f.velocityX;
      if (f.velocityY && vx) vx -= Math.sign(vx) * .5;
      f.x += vx * SCALE; f.y += f.velocityY * SCALE;
      f.moving = !!(dx || dy || f.velocityX);
      if (f.moving) f.stride = (f.stride + 1 / (f.running ? 32 : 40)) % 1;
      if (dx) f.dir = dx;
    }
    if (bounds) {
      const x = Math.max(bounds.left, Math.min(bounds.right, f.x));
      if (x !== f.x) { f.velocityX = 0; f.running = false; }
      f.x = x; f.y = Math.max(bounds.top, Math.min(bounds.bottom, f.y));
    }
  }
  const standing = f => f.hp > 0 && !f.down && !f.recovering;
  function targetInFront(f, targets, reach = 43) {
    return targets.filter(e => standing(e) && Math.abs(e.y - f.y) < 8 * SCALE &&
      (e.x - f.x) * f.dir >= 0 && (e.x - f.x) * f.dir <= reach * SCALE)
      .sort((a, b) => Math.abs(a.x - f.x) - Math.abs(b.x - f.x))[0];
  }
  function selectStrike(f, targets) {
    if (f.air) return 'air';
    if (f.running) return 'charge';
    const e = targetInFront(f, targets, weaponStats[f.weapon]?.reach || 43);
    if (!e) return weaponStats[f.weapon] ? 'slash' : 'whiff';
    if (e.stagger >= 2 && e.hurtTicks > 0) {
      const distance = Math.abs(e.x - f.x) / SCALE + 4;
      if (distance < 44) return e.stagger >= 4 ? 'kick' : 'pommel';
      return 'kick';
    }
    return 'slash';
  }
  function begin(f, type) {
    if (!attacks[type]) return false;
    if (!standing(f) || f.attack || f.hurtTicks || (f.air && type !== 'air')) return false;
    if (type === 'air' && (!f.air || (f.air.vz >= 0 && f.height < 24))) return false;
    const direction = type === 'back' ? -f.dir : f.dir;
    if (type === 'back') f.dir = direction;
    f.attack = { type, age: 0, elapsed: 0, direction, connected: false, hits: new Set(), ...attacks[type] };
    if (type === 'slash') { f.lastSlash ^= 1; if (!f.lastSlash) f.attack.box = [20,32,-64,40]; }
    if(f.player && weaponStats[f.weapon] && ['slash','whiff','air','back'].includes(type)){
      const w=weaponStats[f.weapon],a=f.attack;a.weapon=f.weapon;a.animationRate=1/w.speed;
      a.ticks=Math.round(a.ticks*w.speed);a.from=Math.round(a.from*w.speed);a.to=type==='whiff'?-1:Math.round(a.to*w.speed);
      a.damage*=w.damage;a.reach=w.reach;a.box=[0,w.reach,-64,64];
    }
    if (type !== 'air' && type !== 'charge') f.velocityX = f.velocityY = 0;
    if (type === 'enemyCharge') f.velocityX = direction * 4;
    f.running = false; f.tapDir = 0; f.tapTicks = -1; f.moving = false;
    return true;
  }
  function canHit(f, e, a) {
    if (e.hp <= 0 || e.down || e.invTicks || Math.abs(e.y - f.y) >= 8 * SCALE) return false;
    const body = e.player ? (e.recovering || e.hurtTicks ? (e.stagger === 1 ? [-16,32,-56,56] : [-8,24,-40,40]) : [-16,28,-60,60]) :
      e.hurtTicks ? [-19,25,-37,37] : e.attack ? [-25,24,-45,45] : [-15,18,-47,47];
    const weapon = a.box || [-4,a.reach+4,-48,a.type === 'air' ? 64 : 48];
    const rectangle = (actor, box, dir) => {
      box=box.map(v=>v*(actor.size||1));
      const x = actor.x / SCALE + (dir > 0 ? box[0] : -box[0]-box[1]);
      const y = actor.y / SCALE - (actor.height || 0) + box[2];
      return [x,y,x+box[1],y+box[3]];
    };
    const r=rectangle(f,weapon,a.direction), b=rectangle(e,body,e.dir);
    return r[0]<=b[2] && r[2]>=b[0] && r[1]<=b[3] && r[3]>=b[1];
  }
  function tickAttack(f, targets, hit) {
    const a = f.attack; if (!a) return;
    a.age++; a.elapsed = a.age * STEP; f.dir = a.direction;
    if (a.age >= a.from && a.age <= a.to) for (const e of targets) {
      if (!a.hits.has(e.id) && canHit(f, e, a)) { a.hits.add(e.id); a.connected = true; hit(e, a, f); }
    }
    if (a.age >= a.ticks) {
      f.attack = null;
      if (!f.air) f.height = 0;
      return a;
    }
  }
  function hurt(f, attack, isHero, attacker) {
    f.attack = null; f.running = false; f.air = null; f.jump = null;
    f.height = 0; f.velocityX = f.velocityY = 0; f.moving = false;
    f.hurtAge = 0; f.aiChain = 0; f.recovering = 0;
    const heavy = attack.knock || f.hp <= 0;
    if (heavy) {
      f.down = { age: 0, vz: isHero ? -4.25 : -4, vx: attack.direction * (isHero ? 2 : 3.375), ground: 0 };
      f.hurtTicks = 0; f.stagger = 0; f.invTicks = 0;
    } else {
      f.stagger = Math.min(4, f.stagger + 1);
      f.hurtTicks = isHero ? (f.stagger === 1 ? 6 : 11) : (f.stagger === 1 ? 36 : 61);
      // Player stagger remains interruptible; get-up protection is a separate state.
      if (isHero) f.recovering = 65;
    }
    f.recoil = f.hurtTicks * STEP;
  }
  function stepReaction(f, isHero) {
    if (f.invTicks > 0) f.invTicks--;
    if (f.aiRest > 0) f.aiRest--;
    if (f.aiChargeRest > 0) f.aiChargeRest--;
    if (f.down) {
      const d = f.down; d.age++;
      if (!d.ground) {
        f.x += d.vx * SCALE;
        f.height = Math.max(0, f.height - d.vz); d.vz = Math.min(8, d.vz + .25);
        if (!f.height && d.vz >= 0) d.ground = isHero ? 62 : 32;
      } else if (--d.ground === 0) {
        if (f.hp > 0) { f.down = null; f.invTicks = isHero ? 96 : 30; f.stagger = 0; f.aiRest = 20; }
        else d.ground = 1;
      }
    } else if (f.hurtTicks > 0) {
      f.hurtTicks--; f.hurtAge++;
      if (!f.hurtTicks && !isHero) f.stagger = 0;
    } else if (f.recovering > 0) {
      if (--f.recovering === 0) f.stagger = 0;
    }
    f.recoil = f.hurtTicks * STEP;
    f.invulnerable = f.invTicks * STEP;
  }
  function enemyIntent(e, hero, engaged) {
    if (!standing(e) || e.hurtTicks || e.attack || e.aiRest || !standing(hero)) return [0, 0];
    const x = (hero.x - e.x) / SCALE, y = (hero.y - e.y) / SCALE;
    e.dir = x < 0 ? -1 : 1;
    // Two approach positions, one on each side (ROM C700/C708 target slots).
    const post = engaged ? 33 : 74;
    if (engaged && Math.abs(y) < 8 && Math.abs(x) <= 43 && canHit(e, hero, { ...attacks.enemy, direction: e.dir })) {
      begin(e, 'enemy'); e.aiChain = 0; return [0, 0];
    }
    if (engaged && Math.abs(x) > 120 && Math.abs(x) < 200 && Math.abs(y) < 8 && !e.aiChargeRest && !hero.invTicks) {
      begin(e, 'enemyCharge'); e.aiChargeRest = 240; return [0, 0];
    }
    if (e.aiClock++ % 3 === 0) {
      e.aiDx = Math.abs(x) > post + 7 ? Math.sign(x) : Math.abs(x) < post - 9 ? -Math.sign(x) : 0;
      e.aiDy = Math.abs(y) > 2 ? Math.sign(y) : 0;
    }
    return [e.aiDx, e.aiDy];
  }
  window.AshenMechanics = { HZ, STEP, SCALE, attacks, init, startJump, stepMotion,
    selectStrike, targetInFront, begin, canHit, tickAttack, hurt, stepReaction, enemyIntent };
})();
