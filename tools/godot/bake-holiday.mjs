import fs from 'node:fs';import {createCanvas,loadImage} from '@napi-rs/canvas';
const image=await loadImage('asset-sources/art/holiday-v1.png'),cell=Math.floor(image.width/3),data={};
for(const [i,id] of ['santa','pumpkin','candy'].entries()){
 const c=createCanvas(cell,image.height),ctx=c.getContext('2d');ctx.drawImage(image,i*cell,0,cell,image.height,0,0,cell,image.height);const p=ctx.getImageData(0,0,cell,image.height).data;let l=cell,t=image.height,r=0,b=0;for(let y=0;y<image.height;y++)for(let x=0;x<cell;x++)if(p[(y*cell+x)*4+3]>30){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}
 const out=createCanvas(r-l+1,b-t+1);out.getContext('2d').drawImage(c,l,t,out.width,out.height,0,0,out.width,out.height);fs.writeFileSync(`godot/art/holiday-${id}.png`,out.toBuffer('image/png'));data[id]={width:out.width,height:out.height};
}
// Derive reusable attachment coordinates from each prepared hero pose.
const manifest=JSON.parse(fs.readFileSync('godot/assets/manifest.json'));const atlases=manifest.atlases;
atlases['hero-spin']=JSON.parse(fs.readFileSync('godot/art/spin-atlas.json'));atlases['hero-eat']=JSON.parse(fs.readFileSync('godot/art/eat-atlas.json'));
const anchors={};for(const [name,a] of Object.entries(atlases)){if(!name.startsWith('hero-'))continue;anchors[name]=[];for(const cel of a.cels){const img=await loadImage('godot/assets/'+cel.file),c=createCanvas(img.width,img.height),g=c.getContext('2d');g.drawImage(img,0,0);const p=g.getImageData(0,0,img.width,img.height).data;let points=[];for(let y=0;y<img.height*.32;y++)for(let x=Math.floor(img.width*.18);x<img.width*.85;x++){const j=(y*img.width+x)*4;if(p[j+3]>220&&p[j]>90&&p[j]>p[j+1]*1.08&&p[j+1]>p[j+2]*1.06)points.push([x,y]);}const minY=points.length?Math.min(...points.map(p=>p[1])):0;points=points.filter(p=>p[1]<minY+img.height*.12);const x=points.length?points.reduce((s,p)=>s+p[0],0)/points.length:img.width*.5;const y=points.length?points.reduce((s,p)=>s+p[1],0)/points.length:img.height*.1;const s=cel.rig?.scale||.8;anchors[name].push([(cel.left-a.cellWidth*.5+x)*s,(-cel.height+y)*s]);}}
fs.writeFileSync('godot/art/holiday-anchors.json',JSON.stringify(anchors));
