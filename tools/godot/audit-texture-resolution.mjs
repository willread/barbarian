// Read PNG headers and runtime layout metadata. This audit never changes artwork.
import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd(), assets=path.join(root,'godot/assets');
function dimensions(file){
 const fd=fs.openSync(file,'r'),b=Buffer.alloc(24);
 try{fs.readSync(fd,b,0,24,0);}finally{fs.closeSync(fd);}
 return [b.readUInt32BE(16),b.readUInt32BE(20)];
}
function entry(file,display,extra={}){
 const [w,h]=dimensions(file);
 return {file:path.relative(root,file).replaceAll('\\','/'),source:[w,h],rgbaMiB:+(w*h*4/1048576).toFixed(2),display4k:display,...extra};
}
const backgrounds=[],loops=[];
for(const chapter of ['citadel','swamp','ashen']){
 for(const screen of JSON.parse(fs.readFileSync('godot/worlds/'+chapter+'.json','utf8'))){
  backgrounds.push(entry(path.join(assets,screen.key+'-base.png'),[3840,2160]));
  for(const region of screen.regions){
   const a=region.animation,file=path.join(assets,a.atlas),[w,h]=dimensions(file);
   const columns=a.columns??8,rows=a.rows??8;
   loops.push(entry(file,[a.rect[2]*3,a.rect[3]*3],{framePixels:[w/columns,h/rows],frames:a.count,sourcePixelsPer4kPixel:+Math.min(w/columns/(a.rect[2]*3),h/rows/(a.rect[3]*3)).toFixed(3)}));
  }
 }
}
const small=[entry(path.join(root,'godot/art/ember-core-v1.png'),[74*3840/1440,82*2160/810],{note:'Fixed-size bomb body; rotation changes its bounding box, not texel density.'})];
const ui=[entry(path.join(root,'godot/art/title-background.png'),[3840,2160]),entry(path.join(root,'godot/art/controls/dialog-plaque.png'),[600*3840/1440,250*2160/810])];
const panoramas=['intro/revenge-panorama-v1.png','ending/reunion-panorama-v1.png'].map(name=>{
 const file=path.join(root,'godot/art',name),[w,h]=dimensions(file);
 return entry(file,[7680,7680*h/w],{note:'Two-screen-wide panning artwork; comparing only to the visible viewport would undercount required detail.'});
});
const actors=[];
for(const [name,height] of [['minotaur',292],['archer',255],['witch',250],['bearer',260],['king',390],['saint-walk',420]]){
 const meta=JSON.parse(fs.readFileSync('godot/art/'+name+'-atlas.json','utf8'));
 const reference=meta.referenceHeight??meta.cels[0].height;
 const largest=meta.cels.map(cel=>{
  const scale=height/reference*3840/1440*1.38;
  return entry(path.resolve(assets,cel.file),[cel.width*scale,cel.height*scale],{note:'Conservative 1.38x actor size; large variants need more pixels, not fewer.'});
 }).sort((a,b)=>b.rgbaMiB-a.rgbaMiB)[0];
 actors.push(largest);
}
for(const [id,weapon] of Object.entries(JSON.parse(fs.readFileSync('godot/art/armory.json','utf8')))){
 const scale=3840/1440;
 small.push(entry(path.resolve(assets,weapon.file),[weapon.length*weapon.width/weapon.height*scale,weapon.length*scale],{note:id+' gameplay size only; inspect weapon-picker presentation before reducing.'}));
}
const all=fs.readdirSync(assets).filter(f=>f.endsWith('.png')).map(f=>entry(path.join(assets,f),null)).sort((a,b)=>b.rgbaMiB-a.rgbaMiB);
const result={target:[3840,2160],note:'RGBA estimates are not measured VRAM. Animation sheets are compared per frame, not by total atlas dimensions. No resize performed.',backgrounds,loops,small,ui,panoramas,actors,largestAssetFiles:all.slice(0,20)};
fs.writeFileSync('docs/texture-resolution-audit.json',JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({small,largestLoop:loops.sort((a,b)=>b.rgbaMiB-a.rgbaMiB)[0],backgrounds:backgrounds.map(x=>({file:x.file,source:x.source}))},null,2));
