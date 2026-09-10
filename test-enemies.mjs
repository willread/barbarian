import fs from 'node:fs';import vm from 'node:vm';import assert from 'node:assert/strict';
const box={window:{},Math};for(const f of ['mechanics','enemies'])vm.runInNewContext(fs.readFileSync('public/'+f+'.js','utf8'),box);
const M=box.window.AshenMechanics,E=box.window.AshenEnemies;
const fighter=(kind,x=500,dir=1)=>E.init(M.init({id:1,x,y:660,hp:E.roster[kind].hp,max:E.roster[kind].hp,dir}),kind);
const hero=()=>M.init({id:2,x:620,y:660,hp:100,max:100,dir:-1,player:true});
let seed=123;const rng=()=>((seed=Math.imul(seed,1664525)+1013904223>>>0)/4294967296);
const signatures=new Set();for(let i=0;i<50;i++){
 const p=E.plan(rng);assert.equal(p.length,4);assert.equal(p[3].join(','),'champion');
 for(const k of ['bone','shield','marauder'])assert.ok(p.slice(0,3).flat().includes(k));
 assert.equal(p[0].length,3);assert.equal(p[1].length,4);assert.equal(p[2].length,5);signatures.add(JSON.stringify(p));
}assert.ok(signatures.size>40);
let e=fighter('shield'),h=hero();
assert.ok(E.block(e,{damage:2},h));assert.ok(E.block(e,{damage:4,knock:true},h));
assert.equal(E.block(e,{magic:true},h),false);h.x=e.x-60;assert.equal(E.block(e,{damage:2},h),false);
E.intent(e,h,true);assert.equal(e.dir,1);assert.equal(E.guarding(e),false);for(let i=0;i<22;i++)E.intent(e,h,true);assert.equal(e.dir,-1);
e=fighter('shield');h=hero();M.begin(e,'shieldBash');assert.equal(E.guarding(e),false);e.attack=null;E.finish(e,{type:'shieldBash',connected:false},h);assert.equal(e.attack,null);
e=fighter('bone');h=hero();M.begin(e,'boneCut');const dir=e.attack.direction;h.x=300;E.intent(e,h,true);assert.equal(e.attack.direction,dir);
e.attack=null;E.finish(e,{type:'boneCut',connected:false},h);assert.equal(e.attack,null);e.aiRest=0;E.finish(e,{type:'boneCut',connected:true},h);assert.equal(e.attack.type,'boneFollow');
e=fighter('marauder');h=hero();E.finish(e,{type:'marauderChop',connected:false},h);assert.equal(e.attack.type,'marauderOverhead');assert.ok(e.attack.from>=30);assert.ok(e.attack.ticks-e.attack.to>=35);
e.attack.age=e.attack.from;const locked=e.attack.direction;h.x=200;E.intent(e,h,true);assert.equal(e.attack.direction,locked);
e=fighter('champion');h=hero();e.hp=e.max/2;E.intent(e,h,true);assert.equal(e.phaseTwo,true);e.attack=null;E.finish(e,{type:'championCleave',connected:false},h);assert.equal(e.attack.type,'championExecution');
for(const k of ['bone','shield','marauder','champion']){e=fighter(k);e.down={ground:10};assert.equal(E.pose(e).frame,14);assert.deepEqual(Array.from(E.intent(e,hero(),true)),[0,0]);}
console.log('PASS: randomized encounters, fixed solo boss, shield flank/turn/bash openings, committed combos and get-up safety.');
