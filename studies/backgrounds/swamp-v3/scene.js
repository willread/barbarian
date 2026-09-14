export const duration=24;
export const screens=[
 {name:'Leechwater Crossing',file:'crossing.png',mood:'Open water. Wind in the cypress.',motion:'A flock of marsh birds crosses the water with staggered wingbeats. Longer moss strands catch the wind while reeds bow along the bank.',effects:['Hanging moss','Crossing marsh flock','Bank reeds'],bounds:[[.08,.1,.38,.4],[0,.24,1,.3],[.84,.48,.14,.15]]},
 {name:'The Witch’s Hollow',file:'hollow.png',mood:'An inhabited hollow, dense with old rituals.',motion:'A dense mix of skull charms, paired bones and rib mobiles swings at different lengths. Rag strips flutter between them and fungal spores drift from the hollow.',effects:['Bone charms','Rag strips','Fungal spores'],bounds:[[.2,.22,.3,.32],[.29,.22,.2,.34],[.22,.3,.22,.25]]},
 {name:'The Drowned Procession',file:'procession.png',mood:'Two bell towers. A broken ceremonial route.',motion:'Two bells swing on short iron suspension brackets, with clappers seated inside their mouths. A funeral brazier burns beside the processional route, shedding rising embers.',effects:['Great funeral bell','Small funeral bell','Funeral brazier and embers'],bounds:[[.14,.12,.2,.35],[.7,.2,.16,.3],[.58,.29,.09,.24]]},
 {name:'The Sunken Throne',file:'throne.png',mood:'The court survives. The king still rules.',motion:'Two tattered royal standards ripple below their fixed crossbars. Corroded ceremonial pendants turn and sway beside the raised throne.',effects:['Royal standards','Iron pendants'],bounds:[[.28,.25,.14,.29],[.61,.25,.13,.29]]}
];
export const assetFiles=Object.fromEntries(['moss','charm','rag','bell','banner','pendant','reeds','branch','heron'].map(key=>[key,key+'.png']));
assetFiles.fire='fire.png';
for(const key of ['paired-bones','ribs','brazier','bird-skull'])assetFiles[key]=key+'.png';
const TAU=Math.PI*2;
const sine=(t,period,offset=0)=>Math.sin(TAU*(t/period+offset));
const random=i=>{const a=Math.sin(i*127.1+311.7)*43758.5453;return a-Math.floor(a)};
const gust=(t,p=0)=>.62*sine(t,8,p)+.25*sine(t,6,p*.7)+.13*sine(t,3,p*1.3);
export function prepareAssets(images,art){return art}
function sprite(g,image,x,y,w,h,angle=0,pivot=.5,tint=1){
 const fit=Math.min(w/image.width,h/image.height);w=image.width*fit;h=image.height*fit;
 g.save();g.translate(x,y);g.rotate(angle);g.globalAlpha=tint;g.drawImage(image,-w*pivot,0,w,h);g.restore();
}
// Thin opaque texture strips deform the material without crossfades or blur.
// The top attachment and bottom root can remain stationary while the rest bends.
function ribbon(g,image,x,y,w,h,t,phase,amplitude,mode='hang'){
 const fit=Math.min(w/image.width,h/image.height);w=image.width*fit;h=image.height*fit;
 g.save();g.translate(x,y);
 const rows=Math.ceil(h/2);
 for(let i=0;i<rows;i++){
  const v=i/rows,v2=(i+1)/rows;
  const weight=mode==='root'?Math.pow(1-v,1.8):mode==='bird'?Math.pow(Math.max(0,1-v/.65),2):v*v;
  const offset=amplitude*weight*(.7*gust(t,phase)+.3*sine(t,4,phase-v*.45));
  g.drawImage(image,0,v*image.height,image.width,(v2-v)*image.height,-w/2+offset,v*h,w,h/rows+.35);
 }
 g.restore();
}
function rope(g,x,y,length,angle,width=1.4){
 g.save();g.translate(x,y);g.rotate(angle);g.lineWidth=width;g.strokeStyle='#352f22';g.beginPath();g.moveTo(0,0);g.lineTo(0,length);g.stroke();g.lineWidth=.45;g.strokeStyle='#8e8369';g.beginPath();g.moveTo(-.4,0);g.lineTo(-.4,length);g.stroke();g.restore();
}
function charm(g,im,x,y,w,h,t,phase,active){
 const a=active?.09*gust(t,phase):0;
 rope(g,x,y,13,a);sprite(g,im,x+Math.sin(-a)*13,y+Math.cos(a)*13,w,h,a);
}
function chain(g,x,y,length,t,active,phase=0){
 const a=active?.025*sine(t,8,phase):0;
 g.save();g.translate(x,y);g.rotate(a);
 for(let yy=0;yy<length;yy+=5){g.lineWidth=1.5;g.strokeStyle=yy%10?'#595a4c':'#272d2b';g.beginPath();g.ellipse(0,yy,yy%10?1.3:2.7,3.8,0,0,TAU);g.stroke()}
 g.restore();
}
function bell(g,image,x,y,w,h,t,period,phase,active){
 const a=active?.105*sine(t,period,phase):0;
 const fit=Math.min(w/image.width,h/image.height);w=image.width*fit;h=image.height*fit;
 // Short fixed iron yoke. Only the bell and its internal clapper pivot.
 g.save();g.translate(x,y);
 g.strokeStyle='#232825';g.lineWidth=5;g.beginPath();g.moveTo(-9,3);g.lineTo(9,3);g.moveTo(0,0);g.lineTo(0,12);g.stroke();
 g.strokeStyle='#8b8872';g.lineWidth=1;g.beginPath();g.moveTo(-9,1);g.lineTo(9,1);g.stroke();
 g.translate(0,12);g.rotate(a);
 g.drawImage(image,-w/2,0,w,h);
 g.save();g.translate(0,h*.86);g.rotate(active?-.17*sine(t,period,phase+.14):0);
 g.strokeStyle='#242820';g.lineWidth=2.7;g.beginPath();g.moveTo(0,0);g.lineTo(0,h*.075);g.stroke();
 g.fillStyle='#69644b';g.beginPath();g.ellipse(0,h*.075,3.4,4.5,0,0,TAU);g.fill();g.restore();
 g.restore();
}
function flock(g,t,active){
 const ft=active?t:0;
 for(let i=0;i<7;i++){
  // Reset well outside the viewport; each flock follows a wide diagonal route.
  const p=((ft/12+.2+i*.019)%1);
  const x=-200+p*1680+i*12,y=206+Math.sin(p*Math.PI)*48+random(i+60)*76;
  const size=19+(i%3)*3,flap=sine(ft, .75,i*.17);
  g.save();g.translate(x,y);g.rotate(-.07);g.fillStyle='#262e2b';
  g.beginPath();g.ellipse(0,0,7,2.8,-.08,0,TAU);g.fill();
  g.beginPath();g.moveTo(-3,0);g.quadraticCurveTo(-size*.55,-7-flap*size*.7,-size,-3-flap*size);
  g.lineTo(-size*.7,2-flap*size*.75);g.quadraticCurveTo(-size*.25,5,3,2);g.fill();
  g.beginPath();g.moveTo(1,0);g.quadraticCurveTo(size*.3,-8-flap*size*.55,size*.8,-3-flap*size*.85);
  g.lineTo(size*.6,3-flap*size*.55);g.lineTo(0,2);g.fill();
  g.beginPath();g.moveTo(5,-1);g.lineTo(11,-4);g.lineTo(16,-3);g.lineTo(9,-1);g.lineTo(6,2);g.fill();
  g.beginPath();g.moveTo(-5,0);g.lineTo(-14,3);g.lineTo(-6,3);g.fill();g.restore();
 }
}
function brazier(g,fire,t,active,body){
 const x=789,y=373,ft=active?t:0;
 g.save();g.translate(x,y);
 // Existing 8x8 game fire atlas: discrete frames, no frame blending.
 const frame=Math.floor(ft*24)%64,sw=fire.width/8,sh=fire.height/8;
 g.globalCompositeOperation='screen';
 g.drawImage(fire,frame%8*sw,Math.floor(frame/8)*sh,sw,sh,-43,-159,86,99);
 g.globalCompositeOperation='source-over';
 sprite(g,body,0,-94,84,96);
 if(active)for(let i=0;i<10;i++){
  const p=(ft/3+random(i))%1;g.globalAlpha=Math.sin(p*Math.PI);
  g.fillStyle=i%2?'#e9a94d':'#cc6629';g.fillRect(Math.sin(p*5+i)*12,-67-p*76,1.5,2.5);
 }
 g.restore();
}
export function drawScenery(g,index,image,a,time,enabled=[true,true,true]){
 const t=((time%duration)+duration)%duration;
 g.clearRect(0,0,1280,720);g.drawImage(image,0,0,1280,720);
 if(index===0){
  for(const [x,y,w,h,p] of [[187,74,48,184,.1],[329,105,38,154,.4],[479,145,31,128,.7]])ribbon(g,a.moss,x,y,w,h,enabled[0]?t:0,p,enabled[0]?12:0);
  flock(g,t,enabled[1]);
  for(const [x,y,w,h,p] of [[1170,386,72,81,.1],[1219,395,46,61,.6]])ribbon(g,a.reeds,x,y,w,h,t,p,enabled[2]?4:0,'root');
 }else if(index===1){
  for(const [x,y,w,h,p] of [[290,180,38,122,.1],[515,207,32,108,.45],[558,180,35,133,.8],[361,124,26,104,.63],[459,149,31,139,.27]])charm(g,p===.63||p===.8?a['bird-skull']:a.charm,x,y,w,h,t,p,enabled[0]);
  for(const [x,y,l,p,k] of [[321,154,57,.13,0],[405,126,67,.51,1],[487,185,63,.76,0],[538,186,96,.33,1]])charm(g,k===0?a['paired-bones']:a.ribs,x,y,40,l+46,t,p,enabled[0]);
  for(const [x,y,w,h,p] of [[335,171,19,103,.3],[488,183,16,88,.8]])ribbon(g,a.rag,x,y,w,h,t,p,enabled[1]?8:0);
 }else if(index===2){
  bell(g,a.bell,307,98,91,105,t,8,.06,enabled[0]);
  bell(g,a.bell,1005,180,63,77,t,6,.39,enabled[1]);
  brazier(g,a.fire,t,enabled[2],a.brazier);
 }else{
  for(const [x,y,w,h,p] of [[412,99,80,163,.12],[872,99,80,163,.68]])ribbon(g,a.banner,x,y,w,h,t,p,enabled[0]?11:0);
  for(const [x,y,w,h,p] of [[357,106,24,78,.2],[921,106,24,78,.7]]){
   const angle=enabled[1]?.055*gust(t,p):0;
   const width=w*(enabled[1]?.78+.22*Math.cos(TAU*t/12+p*TAU):1);
   rope(g,x,y,12,angle);g.save();g.translate(x-Math.sin(angle)*12,y+12);g.rotate(angle);g.scale(width/w,1);sprite(g,a.pendant,0,0,w,h);g.restore();
  }
 }
}
export function drawAtmosphere(g,index,time,enabled=[true,true,true]){
 if(index!==1||!enabled[2])return;
 for(let i=0;i<17;i++){
  const p=(time/8+random(i))%1;
  const alpha=Math.sin(p*Math.PI)**2*.25;
  g.fillStyle=`rgba(182,170,123,${alpha})`;g.beginPath();g.arc(320+random(i+30)*150+Math.sin(p*TAU+i)*10,340-p*115,.65+random(i+80)*.7,0,TAU);g.fill();
 }
}
export function drawForeground(g,index,a,t,{visible=true,motion=true}={}){
 if(!visible)return;
 // Keep near details sharp and small. No foreground at all in the royal court.
 if(index===0){sprite(g,a.branch,63,679,150,36,-.05,.5);ribbon(g,a.reeds,1241,665,56,55,t,.2,motion?2:0,'root')}
 if(index===1){sprite(g,a.branch,1243,687,113,28,.13,.5)}
 if(index===2){sprite(g,a.branch,39,690,105,25,-.06,.5)}
}
export function drawActor(g,x,y){
 g.save();g.translate(x*1280,y*720);g.fillStyle='#d9c9a1';g.strokeStyle='#181c17';g.lineWidth=2;
 g.beginPath();g.arc(0,-122,10,0,TAU);g.fill();g.stroke();
 g.beginPath();g.moveTo(-12,-108);g.lineTo(12,-108);g.lineTo(21,-74);g.lineTo(12,-68);g.lineTo(9,-84);g.lineTo(7,-56);g.lineTo(12,0);g.lineTo(1,0);g.lineTo(-2,-47);g.lineTo(-12,0);g.lineTo(-22,0);g.lineTo(-11,-57);g.lineTo(-11,-86);g.lineTo(-24,-65);g.lineTo(-30,-72);g.closePath();g.fill();g.stroke();g.restore();
}

