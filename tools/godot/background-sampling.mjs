// Build a generic inset from the approved mask, without image-specific exclusions.
export function interiorWeights(mask,w,h,inset=3,feather=7){
 const d=new Float32Array(w*h);d.fill(w+h);
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=y*w+x;if(mask[i*4+3]<254||x===0||y===0||x===w-1||y===h-1)d[i]=0;else d[i]=Math.min(d[i],d[i-1]+1,d[i-w]+1)}
 for(let y=h-2;y>=0;y--)for(let x=w-2;x>=0;x--){const i=y*w+x;d[i]=Math.min(d[i],d[i+1]+1,d[i+w]+1)}
 return d.map(v=>{const t=Math.max(0,Math.min(1,(v-inset)/feather));return t*t*(3-2*t)});
}
export function sampleInterior(pixels,weights,w,h,x,y,k){
 if(x<0||y<0||x>=w-1||y>=h-1)return null;
 const ix=Math.floor(x),iy=Math.floor(y),fx=x-ix,fy=y-iy;
 let sum=0,total=0;
 for(let j=0;j<2;j++)for(let i=0;i<2;i++){const n=(iy+j)*w+ix+i,weight=(i?fx:1-fx)*(j?fy:1-fy)*weights[n];sum+=pixels[n*4+k]*weight;total+=weight}
 return total>1e-6?sum/total:null;
}
