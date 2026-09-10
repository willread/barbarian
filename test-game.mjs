import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
let next, now=0;
const elements=new Map(), events={}, tools=new Map();
const context=new Proxy({createLinearGradient:()=>({addColorStop(){}}),getImageData:()=>({data:new Uint8ClampedArray(0)})},{get:(o,k)=>o[k]??(()=>{})});
const element=id=>{if(!elements.has(id))elements.set(id,{parentElement:{setAttribute(){}},style:{},hidden:false,disabled:id==='start',setAttribute(){},getContext:type=>type==='webgl'?null:context});return elements.get(id)};
const sandbox={console,Math,Set,Promise,Float32Array,Uint8ClampedArray,AbortController,
  Image:class{constructor(){this.width=1774;this.height=887;this.complete=true;this.naturalWidth=1774}set src(v){queueMicrotask(()=>this.onload())}},
  document:{getElementById:element,createElement:()=>({width:444,height:444,getContext:type=>type==='webgl'?null:context}),querySelectorAll:()=>[],modelContext:{registerTool:t=>tools.set(t.name,t)}},
  requestAnimationFrame:f=>(next=f,1),cancelAnimationFrame(){}};
sandbox.window={addEventListener:(k,f)=>events[k]=f,removeEventListener(){}};
vm.runInNewContext(fs.readFileSync('public/animation.js','utf8'),sandbox);
let source=fs.readFileSync('public/game.js','utf8');
source=source.replace('window.ashenAxe = {','window.__test = { get hero(){return hero}, get enemies(){return enemies}, get clock(){return clock} }; window.ashenAxe = {');
vm.runInNewContext(source,sandbox);await new Promise(r=>setImmediate(r));
const step=n=>{for(let i=0;i<n;i++){now+=16;next(now)}};
const press=key=>events.keydown({key,repeat:false,preventDefault(){}}),release=key=>events.keyup({key});
const A=sandbox.window.AshenAnimation,T=sandbox.window.__test,G=sandbox.window.ashenAxe;
assert.equal(tools.size,2);assert.throws(()=>tools.get('start_new_battle').execute({bad:true}));
assert.equal(tools.get('start_new_battle').execute({}).health,100);
// The stance foot cancels root travel; opposing legs are half a cycle apart.
for(const p of [.05,.2,.4]){const a=A.footPath(p,103,23),b=A.footPath(p+.01,103,23);assert.equal(a.y,0);assert.ok(Math.abs((b.x-a.x)+1.03)<1e-8)}
assert.equal(A.footPath(.8,103,23).planted,false);assert.equal(A.footPath(.3,103,23).planted,true);
for(const period of [3,8,24,48]){const a=A.flowPhase(.7,period),b=A.flowPhase(48+.7,period);assert.ok(Math.abs(a.a-b.a)<1e-12);assert.ok(Math.abs(a.blend-b.blend)<1e-12)}
assert.equal(A.jumpHeight(0),0);assert.equal(A.jumpHeight(.96),0);assert.ok(A.jumpHeight(.46)>115);
// A melee strike cannot damage anything before its painted contact frame.
T.enemies.forEach((e,i)=>{e.x=i?1300:560;e.y=660;e.cool=100});
const target=T.enemies[0],initial=target.hp;press('j');assert.equal(target.hp,initial);step(20);assert.equal(target.hp,initial);step(5);assert.ok(target.hp<initial);const after=target.hp;step(8);assert.equal(target.hp,after);
// Pausing freezes animation clocks as well as health and combat state.
press('p');const status=G.status(),time=T.clock,actorTime=T.hero.clock;step(100);assert.deepEqual(G.status(),status);assert.equal(T.clock,time);assert.equal(T.hero.clock,actorTime);press('p');
step(30);press(' ');assert.equal(T.hero.jump,0);step(20);assert.ok(A.jumpHeight(T.hero.jump)>70);step(50);assert.equal(T.hero.jump,null);
G.start();step(400);press('k');assert.equal(G.status().magic,2);assert.ok(G.status().score>0);step(3500);assert.equal(G.status().phase,'lost');
element('resume').onclick();assert.equal(G.status().health,100);assert.equal(G.status().score,0);
// A killed enemy cancels its queued contact and uses a complete death sequence.
T.enemies.forEach((e,i)=>{e.x=i?1300:550;e.y=660;e.cool=100});const victim=T.enemies[0];victim.hp=1;victim.attack={elapsed:.48,direction:-1,connected:false};press('k');const hp=G.status().health;step(20);assert.equal(G.status().health,hp);assert.equal(victim.attack,null);assert.ok(A.pose(victim,false).frame>0);
console.log('PASS: planted feet, alternating gait, seamless flow phases, jump trajectory, delayed single contact, frozen pause, magic, defeat, restart and interrupted attacks.');sandbox.window.stopGame();
