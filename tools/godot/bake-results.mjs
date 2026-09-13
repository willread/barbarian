// Bake live UI glyphs using the project's fonts and stone material. No screenshot text.
import fs from 'node:fs';
import {createCanvas,loadImage,GlobalFonts} from '@napi-rs/canvas';
const out='godot/art/results';
fs.mkdirSync(out,{recursive:true});
GlobalFonts.registerFromPath('asset-sources/fonts/cinzel.ttf','Cinzel');
GlobalFonts.registerFromPath('asset-sources/fonts/oswald.ttf','Oswald');
const material=await loadImage(`${out}/slate.png`);
const manifest={glyphs:{},labels:{}};
function render(text,family,size,weight,tracking=0){
 const pad=Math.ceil(size*.16),c=createCanvas(1,1);let g=c.getContext('2d');
 const font=`${weight} ${size}px "${family}"`;g.font=font;
 const advance=[...text].reduce((sum,ch)=>sum+g.measureText(ch).width+tracking,0)-tracking;
 const cap=g.measureText('0').actualBoundingBoxAscent;
 c.width=Math.ceil(advance+pad*2+size*.06);c.height=Math.ceil(size*1.5);
 g=c.getContext('2d');g.font=font;g.textBaseline='alphabetic';g.fillStyle='white';
 const baseline=size*1.15;let x=pad;
 for(const ch of text){g.fillText(ch,x,baseline);x+=g.measureText(ch).width+tracking;}
 const w=c.width,h=c.height,mask=g.getImageData(0,0,w,h),dist=new Float32Array(w*h);
 for(let i=0;i<dist.length;i++)dist[i]=mask.data[i*4+3]>127?10000:0;
 for(let y=1;y<h;y++)for(let x=1;x<w;x++){const i=y*w+x;dist[i]=Math.min(dist[i],dist[i-1]+1,dist[i-w]+1,dist[i-w-1]+1.414);}
 for(let y=h-2;y>=0;y--)for(let x=w-2;x>=0;x--){const i=y*w+x;dist[i]=Math.min(dist[i],dist[i+1]+1,dist[i+w]+1,dist[i+w+1]+1.414);}
 const tx=createCanvas(w,h),tg=tx.getContext('2d');tg.drawImage(material,0,0,material.width,material.height,0,0,material.width*.55,material.height*.55);
 const stone=tg.getImageData(0,0,w,h).data,pixels=g.createImageData(w,h),bevel=Math.max(2,size*.017);
 const height=(x,y)=>Math.min(bevel,dist[Math.max(0,Math.min(h-1,y))*w+Math.max(0,Math.min(w-1,x))]);
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  const i=(y*w+x)*4,a=mask.data[i+3];if(!a)continue;
  const dx=height(x+1,y)-height(x-1,y),dy=height(x,y+1)-height(x,y-1);
  const normal=(dx*.65+dy*.85)/Math.sqrt(1+dx*dx+dy*dy);
  const edge=dist[y*w+x]<bevel,light=edge?normal*110-22:0;
  const grain=((Math.imul(x+7,374761393)^Math.imul(y+31,668265263))>>>24)/255;
  const mineral=stone[i]*.3+stone[i+1]*.5+stone[i+2]*.2;
  const texture=(mineral-30)*.40+(grain-.5)*12;
  pixels.data[i]=232+texture+light;pixels.data[i+1]=216+texture+light;pixels.data[i+2]=180+texture+light;
  pixels.data[i+3]=a;
 }
 const face=createCanvas(w,h),fg=face.getContext('2d');fg.putImageData(pixels,0,0);
 // Fine angular fissures in the ivory face, clipped to the live glyph mask.
 // Fixed seeds keep the material stable during score count-up.
 if(family==='Cinzel' && size>100){
  fg.globalCompositeOperation='source-atop';
  let seed=[...text].reduce((n,ch)=>n*31+ch.codePointAt(0),17)>>>0;
  const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296};
  for(let i=0;i<Math.ceil(advance/size*9);i++){
   let x=pad+random()*advance,y=baseline-cap+random()*cap;
   fg.beginPath();fg.moveTo(x,y);
   for(let j=0;j<4;j++){x+=(random()-.5)*size*.14;y+=size*(.025+random()*.06);fg.lineTo(x,y)}
   fg.strokeStyle='rgba(74,47,25,.52)';fg.lineWidth=size*.0035;fg.stroke();
  }
 }
 const side=createCanvas(w,h),sg=side.getContext('2d');sg.putImageData(mask,0,0);sg.globalCompositeOperation='source-in';sg.fillStyle='#493323';sg.fillRect(0,0,w,h);
 g.clearRect(0,0,w,h);g.shadowColor='#000c';g.shadowBlur=size*.028;g.shadowOffsetY=size*.024;
 for(let z=Math.ceil(size*.035);z>0;z--)g.drawImage(side,z*.45,z);
 g.shadowBlur=0;g.shadowOffsetY=0;g.drawImage(face,0,0);
 return {canvas:c,advance,pad,baseline,cap};
}
for(const [kind,family,size,weight,chars] of [['score','Cinzel',240,600,'0123456789,'],['stat','Oswald',150,700,'0123456789,:×HITS ']]){
 manifest.glyphs[kind]={};
 for(const ch of chars){
  const r=render(ch,family,size,weight),file=`${kind}-${ch.codePointAt(0)}.png`;
  fs.writeFileSync(`${out}/${file}`,r.canvas.toBuffer('image/png'));
  manifest.glyphs[kind][ch]={file,width:r.canvas.width,height:r.canvas.height,advance:r.advance,pad:r.pad,baseline:r.baseline,cap:r.cap};
 }
}
for(const text of ['EVEN HEROES FALL.','THE VALLEY IS FREE.','FINAL SCORE','THIS RUN','ENEMIES SLAIN','TIME SURVIVED','RUN TIME','BEST COMBO','PEAK MULTIPLIER','DAMAGE DEALT','DAMAGE TAKEN','NEW']){
 const headline=text.endsWith('.');
 const display=headline?text.toLowerCase().replace(/\b\w/g,ch=>ch.toUpperCase()):text;
 const tracking=['FINAL SCORE','THIS RUN','NEW'].includes(text)?10:6;
 const r=render(display,'Cinzel',headline?110:54,600,headline?1.5:tracking);
 const file=`label-${text.toLowerCase().replace(/[^a-z]+/g,'-').replace(/-$/,'')}.png`;
 fs.writeFileSync(`${out}/${file}`,r.canvas.toBuffer('image/png'));
 manifest.labels[text]={file,width:r.canvas.width,height:r.canvas.height,advance:r.advance,pad:r.pad,baseline:r.baseline,cap:r.cap};
}
fs.writeFileSync(`${out}/lettering.json`,JSON.stringify(manifest));
console.log('Baked results typography: textured Cinzel score/headings and Oswald stat glyphs.');
