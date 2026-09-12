import fs from 'node:fs';
import vm from 'node:vm';
const context={window:{},Math,Set};vm.createContext(context);
vm.runInContext(fs.readFileSync('tools/asset-bake-source/mechanics.js','utf8'),context);
const M=context.window.AshenMechanics;
const make=()=>M.init({id:1,x:720,y:660,hp:100,player:true,dir:1,stride:0,weapon:'axe'});
const pick=f=>Object.fromEntries(['x','y','height','velocityX','velocityY','running','stride','hurtTicks','stagger','recovering','invTicks'].map(k=>[k,f[k]]));
const fixtures=[];
for(const name of ['walk','diagonal','run','jump','run-jump','hurt','knockdown']){
 const f=make(),samples=[];
 for(let tick=0;tick<120;tick++){
  if(name==='jump'&&tick===0||name==='run-jump'&&tick===18)M.startJump(f);
  if(tick===0&&['hurt','knockdown'].includes(name))M.hurt(f,{direction:1,knock:name==='knockdown'},true);
  let dx=['walk','diagonal','run','run-jump'].includes(name)?1:0;
  if(tick>=60)dx=0;
  M.stepReaction(f,true);
  M.stepMotion(f,dx,name==='diagonal'?1:0,['run','run-jump'].includes(name)&&[0,8].includes(tick)?1:0,{left:70,right:1370,top:560,bottom:755});
  samples.push(pick(f));
 }
 fixtures.push({name,samples});
}
fs.writeFileSync('godot/tests/parity.json',JSON.stringify(fixtures));
console.log('Saved 840 original-engine state snapshots');
