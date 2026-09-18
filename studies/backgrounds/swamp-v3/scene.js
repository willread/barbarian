export const duration=120;
export const lane={top:.63,bottom:.95};
// Source-pixel silhouettes: follow the rock tops, including gaps between spires.
// These polygons are also used by the native foreground atlas baker.
export const throneForeground=[
 [[0,831],[8,830],[16,844],[23,861],[32,864],[39,854],
  [47,850],[52,833],[59,831],[62,804],[69,794],[79,793],
  [87,798],[91,818],[98,830],[103,859],[111,870],[118,866],
  [125,850],[132,849],[138,857],[140,877],[147,885],[154,887],
  [158,897],[166,897],[177,887],[190,884],[204,882],[215,889],
  [222,909],[229,928],[239,941],[0,941]],
 [[1450,941],[1458,924],[1463,914],[1476,911],[1482,917],
  [1490,902],[1501,897],[1509,880],[1520,876],[1527,882],
  [1536,869],[1544,867],[1550,855],[1558,853],[1568,861],
  [1576,848],[1582,844],[1588,823],[1597,813],[1605,810],
  [1615,818],[1620,843],[1627,850],[1631,871],[1640,879],
  [1647,872],[1653,849],[1662,844],[1672,849],[1672,941]]
];
export const screens=[
 {name:'Leechwater Crossing',file:'crossing.png',mood:'Open water. Wind in the cypress.',motion:'Occasional small groups of distant marsh birds cross the water with varied routes, spacing and wingbeats. Longer moss strands catch the wind while reeds bow along the bank.',effects:['Hanging moss','Crossing marsh flock','Bank reeds'],bounds:[[.08,.1,.38,.4],[0,.24,1,.3],[.84,.48,.14,.15]]},
 {name:'The Witch’s Hollow',file:'hollow.png',mood:'An inhabited hollow, dense with old rituals.',motion:'A dense mix of skull charms, paired bones and rib mobiles swings at different lengths. Rag strips flutter between them and fungal spores drift from the hollow.',effects:['Bone charms','Rag strips','Fungal spores'],bounds:[[.2,.22,.3,.32],[.29,.22,.2,.34],[.22,.3,.22,.25]]},
 {name:'The Drowned Procession',file:'procession.png',mood:'Two bell towers. A broken ceremonial route.',motion:'Two weathered bells swing in the shade of their stone arches on short iron suspension brackets.',effects:['Great funeral bell','Small funeral bell'],bounds:[[.14,.12,.2,.35],[.7,.2,.16,.3]]},
 {name:'The Sunken Throne',file:'throne.png',mood:'The court survives. The king still rules.',motion:'Two tattered royal standards ripple below their fixed crossbars. Corroded ceremonial pendants turn and sway beside the raised throne.',effects:['Royal standards','Iron pendants'],bounds:[[.28,.25,.14,.29],[.61,.25,.13,.29]]}
];
export const assetFiles=Object.fromEntries(['moss','charm','rag','bell','banner','pendant','reeds','branch','heron'].map(key=>[key,key+'.png']));
for(const key of ['paired-bones','ribs','bird-skull'])assetFiles[key]=key+'.png';
const TAU=Math.PI*2;
const sine=(t,period,offset=0)=>Math.sin(TAU*(t/period+offset));
const random=i=>{const a=Math.sin(i*127.1+311.7)*43758.5453;return a-Math.floor(a)};
const gust=(t,p=0)=>.62*sine(t,8,p)+.25*sine(t,6,p*.7)+.13*sine(t,3,p*1.3);
export function prepareAssets(images,art,create){
 const painting=create(1280,720),pg=painting.getContext('2d');pg.drawImage(images[0],0,0,1280,720);
 const pixels=pg.getImageData(0,0,1280,720),d=pixels.data;
 // Actual painted tree silhouettes occlude the distant flight plane, pixel for pixel.
 for(let y=0;y<720;y++)for(let x=0;x<1280;x++){
  const i=(y*1280+x)*4,luma=(d[i]*.2126+d[i+1]*.7152+d[i+2]*.0722)/255;
  const edge=Math.max(0,Math.min(1,(x-455)/75,(1070-x)/80));
  const visibility=Math.max(0,Math.min(1,(luma-.20)/.22));
  d[i]=d[i+1]=d[i+2]=255;d[i+3]=Math.round(255*visibility*edge);
 }
 pg.putImageData(pixels,0,0);art.birdMask=painting;art.birdLayer=create(1280,720);
 return art;
}
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
function charm(g,im,x,y,w,h,t,phase,active,flip=1,tilt=0){
 const a=tilt+(active?.09*gust(t,phase):0);
 rope(g,x,y,13,a);g.save();g.translate(x+Math.sin(-a)*13,y+Math.cos(a)*13);g.rotate(a);g.scale(flip,1);sprite(g,im,0,0,w,h);g.restore();
}
function bell(g,image,x,y,w,h,t,period,phase,active){
 const a=active?.105*sine(t,period,phase):0;
 const fit=Math.min(w/image.width,h/image.height);w=image.width*fit;h=image.height*fit;
 // Fixed iron yoke; shaded bell with no exposed clapper.
 g.save();g.translate(x,y);
 g.strokeStyle='#232825';g.lineWidth=5;g.beginPath();g.moveTo(-9,3);g.lineTo(9,3);g.moveTo(0,0);g.lineTo(0,12);g.stroke();
 g.strokeStyle='#8b8872';g.lineWidth=1;g.beginPath();g.moveTo(-9,1);g.lineTo(9,1);g.stroke();
 g.translate(0,12);g.rotate(a);
 g.filter='brightness(0.70) saturate(0.72)';g.drawImage(image,-w/2,0,w,h);
 g.restore();
}

function flock(destination,art,t,active){
 if(!active)return;
 const g=art.birdLayer.getContext('2d');g.clearRect(0,0,1280,720);
 for(let group=0;group<3;group++){
 const seed=31+group*19,start=3+group*40+random(seed)*6;
 const travel=12+random(seed+1)*5,elapsed=t-start;
 if(elapsed<0||elapsed>travel+3)continue;
 const count=2+Math.floor(random(seed+2)*3),direction=random(seed+3)>.5?1:-1;
 for(let i=0;i<count;i++){
  const birdSeed=seed+i*7,p=(elapsed-random(birdSeed+4)*2)/travel;
  const x=direction===1?-90+p*1460:1370-p*1460;
  const y=205+random(seed+5)*60+random(birdSeed+6)*35+Math.sin(p*Math.PI)*13;
  const scale=.42+random(birdSeed+8)*.22;
  const size=18+random(birdSeed+9)*6;
  const flap=Math.sin(elapsed*(6+random(birdSeed+10)*3)+i*2.4);
  g.save();g.translate(x,y);g.scale(direction*scale,scale);g.rotate(-.04);
  // Muted distant plumage shares the gray-green atmospheric values of the trees.
  g.fillStyle='#69695d';g.globalAlpha=.46+.12*Math.sin(x*.013+t*.3);
  g.beginPath();g.ellipse(0,0,7,2.8,-.08,0,TAU);g.fill();
  g.beginPath();g.moveTo(-3,0);g.quadraticCurveTo(-size*.55,-7-flap*size*.7,-size,-3-flap*size);
  g.lineTo(-size*.7,2-flap*size*.75);g.quadraticCurveTo(-size*.25,5,3,2);g.fill();
  g.beginPath();g.moveTo(1,0);g.quadraticCurveTo(size*.3,-8-flap*size*.55,size*.8,-3-flap*size*.85);
  g.lineTo(size*.6,3-flap*size*.55);g.lineTo(0,2);g.fill();
  g.beginPath();g.moveTo(5,-1);g.lineTo(11,-4);g.lineTo(16,-3);g.lineTo(9,-1);g.lineTo(6,2);g.fill();
  g.beginPath();g.moveTo(-5,0);g.lineTo(-14,3);g.lineTo(-6,3);g.fill();g.restore();
 }
 }
 g.save();g.globalCompositeOperation='destination-in';g.drawImage(art.birdMask,0,0);g.restore();
 destination.drawImage(art.birdLayer,0,0);
}
export function drawScenery(g,index,image,a,time,enabled=[true,true,true]){
 const t=((time%duration)+duration)%duration;
 g.clearRect(0,0,1280,720);g.drawImage(image,0,0,1280,720);
 if(index===0){
  for(const [x,y,w,h,p] of [[187,74,48,184,.1],[329,105,38,154,.4],[479,145,31,128,.7]])ribbon(g,a.moss,x,y,w,h,enabled[0]?t:0,p,enabled[0]?12:0);
  flock(g,a,t,enabled[1]);
  for(const [x,y,w,h,p] of [[1170,386,72,81,.1],[1219,395,46,61,.6]])ribbon(g,a.reeds,x,y,w,h,t,p,enabled[2]?4:0,'root');
 }else if(index===1){
  for(const [x,y,w,h,p] of [[290,180,38,122,.1],[515,207,32,108,.45],[558,180,35,133,.8],[361,124,26,104,.63],[459,149,31,139,.27]])charm(g,p===.63||p===.8?a['bird-skull']:a.charm,x,y,w,h,t,p,enabled[0],p===.45||p===.63?-1:1,p===.27?.11:p===.8?-.08:0);
  for(const [x,y,l,p,k] of [[321,154,57,.13,0],[405,126,67,.51,1],[487,185,63,.76,0],[538,186,96,.33,1]])charm(g,k===0?a['paired-bones']:a.ribs,x,y,40,l+46,t,p,enabled[0]);
  for(const [x,y,w,h,p] of [[335,171,19,103,.3],[488,183,16,88,.8]])ribbon(g,a.rag,x,y,w,h,t,p,enabled[1]?8:0);
 }else if(index===2){
  bell(g,a.bell,307,98,91,105,t,8,.06,enabled[0]);
  bell(g,a.bell,1005,180,63,77,t,6,.39,enabled[1]);
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
export function drawForeground(g,index,a,t,{visible=true,image=null}={}){
 if(!visible||index!==3||!image)return;
 // Only existing painted rocks occlude the actors; no added foreground effects.
 for(const polygon of throneForeground){g.save();g.beginPath();polygon.forEach(([x,y],i)=>i?g.lineTo(x/1672*1280,y/941*720):g.moveTo(x/1672*1280,y/941*720));g.closePath();g.clip();g.drawImage(image,0,0,1280,720);g.restore()}
}
export function drawActor(g,x,y){
 g.save();g.translate(x*1280,y*720);g.fillStyle='#d9c9a1';g.strokeStyle='#181c17';g.lineWidth=2;
 g.beginPath();g.arc(0,-122,10,0,TAU);g.fill();g.stroke();
 g.beginPath();g.moveTo(-12,-108);g.lineTo(12,-108);g.lineTo(21,-74);g.lineTo(12,-68);g.lineTo(9,-84);g.lineTo(7,-56);g.lineTo(12,0);g.lineTo(1,0);g.lineTo(-2,-47);g.lineTo(-12,0);g.lineTo(-22,0);g.lineTo(-11,-57);g.lineTo(-11,-86);g.lineTo(-24,-65);g.lineTo(-30,-72);g.closePath();g.fill();g.stroke();g.restore();
}

