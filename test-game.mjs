import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
let next, now=0;
const elements=new Map(), events={}, tools=new Map();
const context=new Proxy({createLinearGradient:()=>({addColorStop(){}}),getImageData:()=>({data:new Uint8ClampedArray(0)})},{get:(o,k)=>o[k]??(()=>{})});
const element=id=>{if(!elements.has(id))elements.set(id,{parentElement:{setAttribute(){}},style:{},hidden:false,disabled:id==='start',setAttribute(){},getContext:type=>type==='webgl'?null:context});return elements.get(id)};
const sandbox={console,Math,Set,Promise,Float32Array,Uint8ClampedArray,AbortController,
  Image:class{constructor(){this.width=2048;this.height=2048;this.complete=true;this.naturalWidth=2048}set src(v){queueMicrotask(()=>this.onload())}},
  document:{getElementById:element,createElement:()=>({width:444,height:444,getContext:type=>type==='webgl'?null:context}),querySelectorAll:()=>[],modelContext:{registerTool:t=>tools.set(t.name,t)}},
  requestAnimationFrame:f=>(next=f,1),cancelAnimationFrame(){}};
sandbox.window={addEventListener:(k,f)=>events[k]=f,removeEventListener(){}};
vm.runInNewContext(fs.readFileSync('public/mechanics.js','utf8'),sandbox);
vm.runInNewContext(fs.readFileSync('public/animation.js','utf8'),sandbox);
let source=fs.readFileSync('public/game.js','utf8');
source=source.replace('window.ashenAxe = {','window.__test = { get hero(){return hero}, get enemies(){return enemies}, get clock(){return clock} }; window.ashenAxe = {');
vm.runInNewContext(source,sandbox);await new Promise(r=>setImmediate(r));
const M=sandbox.window.AshenMechanics;
next(0);
const step=n=>{for(let i=0;i<n;i++){now+=M.STEP*1000;next(now)}};
const press=key=>events.keydown({key,repeat:false,preventDefault(){}}),release=key=>events.keyup({key});
const A=sandbox.window.AshenAnimation,T=sandbox.window.__test,G=sandbox.window.ashenAxe;
assert.equal(tools.size,2);assert.throws(()=>tools.get('start_new_battle').execute({bad:true}));
assert.equal(tools.get('start_new_battle').execute({}).health,100);
// Every locomotion pose selects one intact frame from its 4x4 atlas.
for(const hero of [true,false]) {
  const seen=new Set();
  const count=4;
  for(let i=0;i<count;i++) { const p=A.pose({hp:100,recoil:0,attack:null,jump:null,moving:true,stride:i/count+.000001,clock:0},hero); seen.add(p.frame); assert.equal(p.atlas,hero?'hero-walk-v4':'enemy-walk-v4'); }
  assert.equal(seen.size,count); assert.deepEqual([...seen],[0,1,2,3]);
}
let draws=0;new A.Atlas({width:2048,height:2048}).paint({drawImage(){draws++}},7,292);assert.equal(draws,1);
// A connected sword overhang belongs to its whole figure, not the next cell.
const texture=new Uint8ClampedArray(12*8*4);
for(let y=0;y<3;y++)for(let x=0;x<8;x++)texture[(y*12+x)*4+3]=255;
for(let y=4;y<8;y++)for(let x=8;x<12;x++)texture[(y*12+x)*4+3]=255;
const createElement=sandbox.document.createElement;
sandbox.document.createElement=()=>({getContext:()=>({createImageData:(w,h)=>({data:new Uint8ClampedArray(w*h*4)}),putImageData(){}})});
const unpacked=new A.Atlas({width:12,height:8,getContext:()=>({getImageData:()=>({data:texture})})},{columns:2,rows:1,frames:2});
assert.equal(unpacked.cels[0].image.width,8);assert.equal(unpacked.cels[1].image.width,4);
sandbox.document.createElement=createElement;
for(const period of [3,8,24,48]){const a=A.flowPhase(.7,period),b=A.flowPhase(48+.7,period);assert.ok(Math.abs(a.a-b.a)<1e-12);assert.ok(Math.abs(a.blend-b.blend)<1e-12)}
assert.equal(A.jumpHeight(0),0);assert.equal(A.jumpHeight(.96),0);assert.ok(A.jumpHeight(.4083)>118);
// A melee strike cannot damage anything before the traced active window.
T.enemies.forEach((e,i)=>{e.x=i?1300:610;e.y=660;e.aiRest=1000});
const target=T.enemies[0],initial=target.hp;
press('j');step(7);assert.equal(target.hp,initial);step(1);assert.equal(target.hp,initial-2);
step(10);assert.equal(target.hp,initial-2);assert.equal(T.hero.attack,null);
// Held attack does not auto-repeat; an early tap is not queued.
step(20);assert.equal(target.hp,initial-2);release('j');press('j');step(3);release('j');press('j');step(30);
assert.equal(target.hp,initial-4);assert.equal(T.hero.attack,null);release('j');
// Pausing freezes actor clocks and discards inputs made while paused.
press('p');const status=G.status(),time=T.clock,actorTime=T.hero.clock;
press('d');press('j');step(100);assert.deepEqual(G.status(),status);assert.equal(T.clock,time);assert.equal(T.hero.clock,actorTime);
press('p');const x=T.hero.x;step(2);assert.equal(T.hero.x,x);assert.equal(T.hero.attack,null);
press(' ');step(1);release(' ');assert.ok(T.hero.air);step(24);assert.equal(T.hero.height,63.25);step(24);assert.equal(T.hero.jump,null);
// Display refresh cannot change simulation distance or number of updates.
for(const fps of [30,60,120,144]) {
  G.start();T.enemies.forEach(e=>{e.aiRest=100000});press('d');const x=T.hero.x;
  for(let i=0;i<fps;i++){now+=1000/fps;next(now)}release('d');
  assert.equal(T.hero.x-x,87*M.SCALE,`one second of movement at ${fps} Hz`);
}
// Double tap and charge remain distinct actions; jumping resets run momentum.
G.start();T.enemies.forEach(e=>{e.aiRest=1000});press('d');step(1);release('d');step(1);press('d');step(8);
assert.equal(T.hero.velocityX,4);assert.equal(T.hero.running,true);press(' ');step(1);release(' ');
assert.equal(T.hero.jumpLaunch,7);assert.equal(T.hero.velocityX,0);step(25);assert.ok(T.hero.height>98);
// Focus loss pauses and releases all held inputs.
events.blur();const before=G.status();step(20);assert.deepEqual(G.status(),before);press('p');
G.start();T.enemies.forEach((e,i)=>{e.x=650+i*200;e.y=660;e.aiRest=1000});
const enemyHP=T.enemies[0].hp;press('k');step(1);release('k');assert.equal(G.status().magic,0);
const frozenX=T.enemies[0].x;step(265);assert.equal(T.enemies[0].x,frozenX);assert.equal(T.enemies[0].hp,enemyHP);
step(1);assert.equal(T.enemies[0].hp,enemyHP-8);assert.ok(T.enemies[0].down);
// An interrupted enemy strike cannot deliver its pending contact event.
G.start();T.enemies.forEach((e,i)=>{e.x=i?1300:610;e.y=660;e.aiRest=1000});
const victim=T.enemies[0];M.begin(victim,'enemy');victim.attack.age=21;victim.dir=-1;victim.attack.direction=-1;
press('j');step(8);release('j');assert.equal(victim.attack,null);assert.equal(G.status().health,100);
// An unattended battle is winnable by the enemies and can be restarted.
G.start();T.enemies.forEach((e,i)=>{e.x=i?1300:T.hero.x+32*M.SCALE;e.y=660;e.aiRest=i?1000:0});
step(120);assert.ok(T.hero.hp<=100-8*100/48+1e-8,'enemy follows connected blows with a knockdown finisher');assert.ok(T.hero.down);
G.start();step(14000);assert.equal(G.status().phase,'lost');
element('resume').onclick();assert.equal(G.status().health,100);assert.equal(G.status().score,0);
// Wave progression and victory are exercised through damage, not phase mutation.
for(let wave=1;wave<=4;wave++) {
  for(const e of T.enemies){e.hp=0;M.hurt(e,{direction:1,knock:true},false)}
  step(140);
}
assert.equal(G.status().phase,'won');
console.log('PASS: complete sprites, combat windows, input edges, fixed-step refresh independence, running jumps, pause, magic, interruptions, defeat, restart and victory.');
sandbox.window.stopGame();
