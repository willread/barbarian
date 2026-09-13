export const duration=8;
export const screens=[
 {name:'Leechwater Crossing',file:'01-crossing.png',mood:'The forest opens its mouth.',motion:'Marsh gas breaks the surface in expanding rings; gnats circle above the water.',effects:['Water rings','Gnat swarms'],bounds:[[.27,.48,.7,.15],[.3,.36,.6,.21]]},
 {name:'The Witch’s Hollow',file:'02-hollow.png',mood:'Something has made a home here.',motion:'Pale fungal spores rise from the hollow; small marsh lights wander over the distant pool.',effects:['Fungal spores','Marsh lights'],bounds:[[.13,.26,.44,.34],[.65,.4,.3,.19]]},
 {name:'The Drowned Procession',file:'03-procession.png',mood:'The old road remembers its dead.',motion:'Water drips from the funeral arches and leaves brief splash rings in the flooded avenue.',effects:['Falling droplets','Splash rings'],bounds:[[.18,.31,.66,.27],[.17,.53,.69,.08]]},
 {name:'The Sunken Throne',file:'04-throne.png',mood:'The king has only stepped away.',motion:'Amber sap breathes inside the split trunk; low mist coils around the roots.',effects:['Sap heartbeat','Root mist'],bounds:[[.4,.26,.2,.28],[.15,.5,.7,.13]]}
];
const tau=Math.PI*2,fract=x=>x-Math.floor(x),noise=i=>fract(Math.sin(i*127.1+311.7)*43758.5453);
function ellipse(g,x,y,rx,ry,color){g.beginPath();g.ellipse(x,y,rx,ry,0,0,tau);g.strokeStyle=color;g.lineWidth=.0007;g.stroke()}
function glow(g,x,y,r,color,alpha){g.save();g.globalAlpha=alpha;const grad=g.createRadialGradient(x,y,0,x,y,r);grad.addColorStop(0,color);grad.addColorStop(1,'transparent');g.fillStyle=grad;g.fillRect(x-r,y-r,r*2,r*2);g.restore()}
// All frequencies divide eight seconds. Wrapped particles fade to zero at reset.
// The background image is never resampled or displaced by these overlay effects.
export function drawEffects(g,index,time,enabled=[true,true]){
 const t=((time%duration)+duration)%duration,p=t/duration;
 g.save();g.scale(g.canvas.width,g.canvas.height);
 if(index===0){
  if(enabled[0])for(let i=0;i<16;i++){const a=fract(p*2+noise(i)),x=.29+noise(i+44)*.64,y=.53+noise(i+66)*.067;ellipse(g,x,y,.004+a*.029,.001+a*.006,`rgba(195,192,152,${Math.sin(a*Math.PI)*.42})`)}
  if(enabled[1])for(let i=0;i<35;i++){const a=tau*(p+noise(i)),x=.31+noise(i+9)*.55+Math.sin(a*2+i)*.014,y=.43+noise(i+54)*.12+Math.cos(a*3+i)*.009;glow(g,x,y,.0019,'#d3c7a0',.35+.2*Math.sin(a))}
 }
 if(index===1){
  if(enabled[0])for(let i=0;i<60;i++){const a=fract(p+noise(i)),x=.19+noise(i+77)*.31+Math.sin(a*tau+i)*.022,y=.58-a*.27;glow(g,x,y,.0015+noise(i+1)*.0013,'#cbbf91',Math.sin(a*Math.PI)*.7)}
  if(enabled[1])for(let i=0;i<8;i++){const a=tau*(p+noise(i)),x=.68+noise(i+20)*.23+Math.sin(a)*.012,y=.49+Math.cos(a*2+i)*.025;glow(g,x,y,.004,'#b2c18b',.3+.25*Math.sin(a*3))}
 }
 if(index===2){
  for(let i=0;i<20;i++){const a=fract(p*4+noise(i)),x=i<10?.195+noise(i+2)*.074:.737+noise(i+2)*.068,y0=i<10?.32:.37,y1=.56+noise(i+3)*.02;
   if(enabled[0]&&a<.7){const q=a/.7,y=y0+(y1-y0)*q*q;g.globalAlpha=Math.sin(q*Math.PI)*.65;g.strokeStyle='#b9c6bd';g.lineWidth=.00065;g.beginPath();g.moveTo(x,y);g.lineTo(x,y+.008);g.stroke();g.globalAlpha=1}
   if(enabled[1]&&a>=.7){const q=(a-.7)/.3;ellipse(g,x,y1,.002+q*.017,.001+q*.004,`rgba(192,205,187,${Math.sin(q*Math.PI)*.5})`)}
  }
 }
 if(index===3){
  if(enabled[0]){const beat=Math.pow((1+Math.cos(p*tau*2))/2,10)*.2+Math.pow((1+Math.cos(p*tau*2-.85))/2,18)*.09;g.save();g.globalCompositeOperation='screen';for(const [x,y,r]of [[.454,.303,.026],[.543,.302,.025],[.478,.397,.02],[.532,.417,.019]])glow(g,x,y,r,'#c18a36',.09+beat);g.restore()}
  if(enabled[1])for(let i=0;i<11;i++){const a=tau*(p+noise(i)),x=.2+noise(i+21)*.59+Math.sin(a)*.035,y=.564+Math.cos(a*2+i)*.009;g.save();g.translate(x,y);g.scale(1,.14);glow(g,0,0,.07,'#aeb6a4',.07+.025*Math.sin(a));g.restore()}
 }
 g.restore();
}
