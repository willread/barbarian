import {screens,duration,assetFiles,prepareAssets,drawScenery,drawAtmosphere,drawForeground,drawActor} from './scene.js';
const $=id=>document.getElementById(id),canvas=$('scene-layer'),g=canvas.getContext('2d');
const actorCanvas=$('actor-layer'),actorContext=actorCanvas.getContext('2d');
const foregroundCanvas=$('foreground-layer'),foregroundContext=foregroundCanvas.getContext('2d');
const guideCanvas=$('guide-layer'),guideContext=guideCanvas.getContext('2d');
let selected=0,time=0,running=!matchMedia('(prefers-reduced-motion: reduce)').matches,last=performance.now(),enabled=[true,true],actor={x:.5,y:.85};
const load=src=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=()=>reject(Error('Unable to load '+src));im.src=src});
const [images,entries]=await Promise.all([Promise.all(screens.map(s=>load(s.file))),Promise.all(Object.entries(assetFiles).map(async([name,file])=>[name,await load(file)]))]).catch(e=>{$('description').textContent=e.message;throw e});
const assets=prepareAssets(images,Object.fromEntries(entries),(w,h)=>{const c=document.createElement('canvas');c.width=w;c.height=h;return c});
screens.forEach((s,i)=>{const b=document.createElement('button');b.innerHTML=`<img src="${s.file}" alt=""><span>0${i+1} / ${s.name}</span>`;b.onclick=()=>select(i);document.querySelector('nav').append(b)});
function select(i){selected=i;time=0;enabled=[true,true];document.querySelectorAll('nav button').forEach((b,j)=>b.setAttribute('aria-pressed',String(i===j)));$('name').textContent=screens[i].name;$('description').textContent=screens[i].mood+' '+screens[i].motion;$('effects').replaceChildren();screens[i].effects.forEach((name,j)=>{const l=document.createElement('label'),c=document.createElement('input');c.type='checkbox';c.checked=true;c.onchange=()=>enabled[j]=c.checked;l.append(c,' '+name);$('effects').append(l)});history.replaceState(null,'','#'+(i+1));draw()}
function draw(){
  const still=$('still').checked,frameTime=still?0:time;
  drawScenery(g,selected,images[selected],assets,frameTime,still?[false,false]:enabled);
  if(!still)drawAtmosphere(g,selected,time,enabled);
  actorContext.clearRect(0,0,1280,720);
  if($('scale').checked)drawActor(actorContext,actor.x,actor.y);
  foregroundContext.clearRect(0,0,1280,720);
  drawForeground(foregroundContext,selected,assets,frameTime,{visible:$('foreground').checked,motion:!still&&$('wind').checked});
  const only=$('foreground-only').checked;
  canvas.style.visibility=actorCanvas.style.visibility=only?'hidden':'visible';
  guideContext.clearRect(0,0,1280,720);
  const q=guideContext;
  if(!only&&$('lane').checked){q.fillStyle='#8ccd8b22';q.fillRect(0,720*.68,1280,720*.22);q.strokeStyle='#b1d2a1';q.strokeRect(1,720*.68,1278,720*.22)}
  if(!only&&$('bounds').checked){q.strokeStyle='#dec584';q.setLineDash([5,6]);screens[selected].bounds.forEach(([x,y,w,h])=>q.strokeRect(x*1280,y*720,w*1280,h*720));q.setLineDash([])}
  if(!only&&$('crop').checked){q.fillStyle='#070a09cc';q.fillRect(0,0,1280,720*.23);q.fillStyle='#ddd5b7';q.font='13px system-ui';q.fillText('Upper band cropped in the native 16:9 arena',18,26)}
  $('clock').textContent=time.toFixed(2)+' / '+duration.toFixed(2)+'s';$('timeline').value=time;
}
function setRunning(value){running=value;$('play').textContent=running?'Pause':'Play'}
$('play').onclick=()=>setRunning(!running);
$('reset').onclick=()=>{time=0;draw()};
$('step').onclick=()=>{setRunning(false);time=(time+1/30)%duration;draw()};
$('timeline').max=duration;$('timeline').oninput=e=>{setRunning(false);time=Number(e.target.value);draw()};
$('fullscreen').onclick=()=>$('stage').requestFullscreen();
$('foreground-only').onchange=()=>{if($('foreground-only').checked)$('foreground').checked=true;draw()};
$('export-foreground').onclick=()=>{
  draw();foregroundCanvas.toBlob(blob=>{if(!blob)return;const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download=`swamp-0${selected+1}-foreground-${time.toFixed(2)}s.png`;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)},'image/png');
};
$('stage').onclick=e=>{if($('foreground-only').checked)return;const r=canvas.getBoundingClientRect();actor={x:Math.max(.02,Math.min(.98,(e.clientX-r.left)/r.width)),y:Math.max(.68,Math.min(.9,(e.clientY-r.top)/r.height))};$('scale').checked=true;draw()};
document.addEventListener('keydown',e=>{if(e.code==='Space'&&!['INPUT','SELECT','BUTTON'].includes(e.target.tagName)){e.preventDefault();setRunning(!running)}});
function frame(now){if(running){const dt=Math.min(.1,(now-last)/1000)*Number($('speed').value);time=(time+dt)%duration;if($('seam').checked&&time>.35&&time<duration-.35)time=duration-.35}last=now;draw();requestAnimationFrame(frame)}
select(Math.max(0,Math.min(3,(Number(location.hash.slice(1))||1)-1)));setRunning(running);requestAnimationFrame(frame);
