import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const sandbox = { window: {}, Set, Math };
vm.runInNewContext(fs.readFileSync('public/mechanics.js', 'utf8'), sandbox);
const M = sandbox.window.AshenMechanics;
const fixture = JSON.parse(fs.readFileSync('research/golden-axe-fixtures.json', 'utf8'));
const make = (x=0,y=0) => M.init({id:Math.random(),x,y,hp:16,max:16,dir:1,stride:0});
for (const [name, scenario] of Object.entries(fixture.scenarios)) {
  const f = make(); let previous = [], index = 0;
  for (const [ticks, input] of scenario.input) for (let i=0;i<ticks;i++) {
    const edge = input.filter(k=>!previous.includes(k)); previous=input;
    if (edge.includes('C')) M.startJump(f);
    if (edge.includes('B')) M.begin(f,M.selectStrike(f,[]));
    const dx=Number(input.includes('RIGHT'))-Number(input.includes('LEFT'));
    const dy=Number(input.includes('DOWN'))-Number(input.includes('UP'));
    M.stepMotion(f,dx,dy,edge.includes('RIGHT')?1:edge.includes('LEFT')?-1:0);
    M.tickAttack(f,[],()=>{});
    const r=scenario.samples[++index];
    // Clamp the ROM's retained -0.125 landing fraction to our ground plane.
    for (const [key,actual,expected] of [['x',f.x/M.SCALE,r.x],['y',f.y/M.SCALE,r.y],['height',f.height,Math.max(0,r.height)],['vx',f.velocityX,r.vx],['vy',f.velocityY,r.vy]]) {
      assert.ok(Math.abs(actual-expected)<.0001,`${name} tick ${index} ${key}: got ${actual}, ROM ${expected}`);
    }
    assert.equal(f.air?4:f.attack?.type==='charge'?52:f.running?8:0,r.state,`${name} tick ${index} state`);
  }
}
for (const gap of [16,17]) {
  const f=make();M.stepMotion(f,1,0,1);for(let i=0;i<gap;i++)M.stepMotion(f,0,0);M.stepMotion(f,1,0,1);
  assert.equal(f.running,gap===16);
}
const h=make(), e=make(32*M.SCALE);e.id=2;
assert.equal(M.selectStrike(h,[e]),'slash');M.begin(h,'slash');
let hits=0;
for(let tick=1;tick<=18;tick++) {
  M.tickAttack(h,[e],(target,attack)=>{hits++;target.hp-=attack.damage;M.hurt(target,attack,false)});
  assert.equal(hits,tick<8?0:1);
  if(tick===10)assert.equal(M.begin(h,'slash'),false,'early attack must be discarded');
}
assert.equal(e.hp,14);assert.equal(e.hurtTicks,36);assert.equal(h.attack,null);
M.begin(h,'slash');for(let i=0;i<18;i++)M.tickAttack(h,[e],(target,a)=>M.hurt(target,a,false));assert.equal(e.hurtTicks,61);
assert.equal(M.selectStrike(h,[e]),'pommel');e.x=16*M.SCALE;assert.equal(M.selectStrike(h,[e]),'throw');
for(const [x,y,selected] of [[43,7,'slash'],[44,0,'whiff'],[43,8,'whiff'],[-20,0,'whiff']]) {
  e.x=x*M.SCALE;e.y=y*M.SCALE;e.stagger=0;assert.equal(M.selectStrike(h,[e]),selected);
}
// A target entering late in the five-tick active window is still hit, only once.
e.x=32*M.SCALE;e.y=8*M.SCALE;M.begin(h,'slash');hits=0;
for(let t=1;t<=18;t++){if(t===11)e.y=0;M.tickAttack(h,[e],()=>hits++)}assert.equal(hits,1);
// Heavy hits launch, land, recover and then grant get-up protection.
M.hurt(h,{direction:-1,knock:true},true);let highest=0;
for(let i=0;i<130;i++){M.stepReaction(h,true);highest=Math.max(highest,h.height)}
assert.ok(highest>35);assert.equal(h.down,null);assert.ok(h.invTicks>0);
// Enemy strikes commit to their facing, use narrow lanes, and stop after one hit.
const enemy=make(0,0), player=make(33*M.SCALE,0);player.player=true;M.begin(enemy,'enemy');let contacts=0;
for(let age=1;age<=51;age++) {M.tickAttack(enemy,[player],()=>contacts++);assert.equal(contacts,age<29?0:1)}
assert.equal(enemy.attack,null);player.y=8*M.SCALE;M.begin(enemy,'enemy');contacts=0;
for(let i=0;i<51;i++)M.tickAttack(enemy,[player],()=>contacts++);assert.equal(contacts,0);
player.y=0;player.height=20;assert.equal(M.canHit(enemy,player,{...M.attacks.enemy,direction:1}),true);
player.height=50;assert.equal(M.canHit(enemy,player,{...M.attacks.enemy,direction:1}),false);player.height=0;
// Waiting fighters do not begin a strike; a reserved approach slot can.
enemy.aiRest=0;player.y=0;M.enemyIntent(enemy,player,false);assert.equal(enemy.attack,null);
M.enemyIntent(enemy,player,true);assert.equal(enemy.attack.type,'enemy');
console.log('PASS: ROM movement traces, tap boundary, active windows, contextual follow-ups, stagger and knockdown.');
