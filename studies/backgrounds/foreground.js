// Shared by the native asset bake and workshop: thin twigs need pixel coverage,
// not an opaque polygon containing the paving between their branches.
export function foregroundRegion(image,region,width,height,create){
 const canvas=create(width,height),g=canvas.getContext('2d');
 g.save();g.beginPath();region.polygon.forEach(([x,y],i)=>i?g.lineTo(x*width,y*height):g.moveTo(x*width,y*height));g.closePath();g.clip();g.drawImage(image,0,0,width,height);g.restore();
 if(region.dark_silhouette){
  const pixels=g.getImageData(0,0,width,height),d=pixels.data;
  for(let i=0;i<d.length;i+=4){
   if(!d[i+3])continue;
   const brightness=d[i]*.2126+d[i+1]*.7152+d[i+2]*.0722;
   const coverage=Math.max(0,Math.min(1,(43-brightness)/22));
   d[i+3]=Math.round(d[i+3]*coverage*coverage*(3-2*coverage));
  }
  g.clearRect(0,0,width,height);g.putImageData(pixels,0,0);
 }
 return canvas;
}
