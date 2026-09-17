import {createCanvas} from '@napi-rs/canvas';

// Generated figures can cross nominal grid lines. Assign pixels to complete
// connected figures before cropping, rather than letting adjacent cells steal limbs.
export function splitEpisodeSheet(image,kind){
 const w=image.width,h=image.height,c=createCanvas(w,h),g=c.getContext('2d');g.drawImage(image,0,0);
 const pixels=g.getImageData(0,0,w,h),d=pixels.data,labels=new Int32Array(w*h),parts=[];
 // The falling King and corpse touch along a diagonal silhouette seam.
 const kingSide=(p)=>{const x=p%w,y=Math.floor(p/w);if(y<h/2)return 0;const seam=y<820?1166:y<890?1166-(y-820)*1.12:y<950?1088+(y-890)*1.30:1166;return x<seam?0:1};
 let next=0;
 for(let start=0;start<labels.length;start++){
  if(labels[start]||d[start*4+3]<128)continue;
  const id=++next,stack=[start],points=[];labels[start]=id;let x0=w,y0=h,x1=0,y1=0;
  while(stack.length){
   const p=stack.pop(),x=p%w,y=Math.floor(p/w);points.push(p);x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);
   for(const q of [x?p-1:-1,x<w-1?p+1:-1,p-w,p+w])if(q>=0&&q<labels.length&&!labels[q]&&d[q*4+3]>=128){if(kind==='king'&&kingSide(p)!==kingSide(q))continue;labels[q]=id;stack.push(q)}
  }
  parts.push({id,points,x0,y0,x1,y1});
 }
 const count=kind==='warden'?16:kind==='king-roots'?4:8;
 const figures=parts.sort((a,b)=>b.points.length-a.points.length).slice(0,count);
 if(figures.length!==count||figures.some(p=>p.points.length<10000))throw Error(kind+': expected '+count+' complete figures '+JSON.stringify(figures.map(p=>[p.points.length,p.x0,p.y0,p.x1,p.y1])));
 const row=p=>kind==='warden'?Math.floor((p.y0+p.y1)*.5/(h/4)):['king-polish','king-roots'].includes(kind)?Number((p.y0+p.y1)*.5>=h/2):Number(p.y0>=h/2);
 figures.sort((a,b)=>row(a)-row(b)||a.x0-b.x0);
 const kept=new Set(figures.map(p=>p.id));
 for(let p=0;p<labels.length;p++)if(!kept.has(labels[p]))labels[p]=0;
 // Preserve the original antialiased edge without including a neighboring pose.
 let frontier=figures.flatMap(p=>p.points);
 for(let pass=0;pass<6;pass++){
  const expanded=[];
  for(const p of frontier){const x=p%w;for(const q of [x?p-1:-1,x<w-1?p+1:-1,p-w,p+w])if(q>=0&&q<labels.length&&!labels[q]&&d[q*4+3]>1){if(kind==='king'&&kingSide(p)!==kingSide(q))continue;labels[q]=labels[p];expanded.push(q)}}
  frontier=expanded;
 }
 return figures.map((part,i)=>{
  let x0=w,y0=h,x1=0,y1=0;
  for(let p=0;p<labels.length;p++)if(labels[p]===part.id){const x=p%w,y=Math.floor(p/w);x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}
  const width=x1-x0+1,height=y1-y0+1,frame=createCanvas(width,height),fg=frame.getContext('2d'),result=fg.createImageData(width,height);
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){const p=(y+y0)*w+x+x0;if(labels[p]===part.id)result.data.set(d.subarray(p*4,p*4+4),(y*width+x)*4)}
  fg.putImageData(result,0,0);
  const columns=kind==='king-roots'?2:4;
  const cw=Math.floor(w/columns),ch=Math.floor(h/(kind==='warden'?4:2)),flip=kind==='witch'&&i<2;
  let left=x0-(i%columns)*cw;
  if(flip){const mirrored=createCanvas(width,height),mg=mirrored.getContext('2d');mg.translate(width,0);mg.scale(-1,1);mg.drawImage(frame,0,0);fg.clearRect(0,0,width,height);fg.drawImage(mirrored,0,0);left=cw-left-width}
  return {image:frame,left,top:y0-Math.floor(i/columns)*ch,width,height,sourceBounds:[x0,y0,x1,y1],corePixels:part.points.length};
 });
}
