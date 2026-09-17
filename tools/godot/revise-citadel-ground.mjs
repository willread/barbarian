// Rebuild the expanded terrace and source geometry without altering earlier studies.
import fs from 'node:fs';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const root='studies/backgrounds/';
const read=id=>JSON.parse(fs.readFileSync(root+id+'/screen.json','utf8'));
const save=(id,m)=>{fs.mkdirSync(root+id,{recursive:true});fs.writeFileSync(root+id+'/screen.json',JSON.stringify(m,null,2)+'\n')};
const first=read('citadel-01-v5');
first.id='citadel-01-v6';
first.title='Aqueduct approach — expanded stone terrace';
first.status='Revised foreground ground depth';
first.frames=['base.png'];
for(const r of first.regions)r.animation.atlas='../citadel-01-v5/'+r.animation.atlas;
for(const p of first.walkable.polygon.slice(2))p[1]=(1+p[1])*.5;
first.walkable.description='Original rear boundary; front boundary extends halfway through the former foreground gap.';
first.framing={bottom_crop:.025};
first.notes='Expanded foreground paving. Original scenery above 76% remains pixel-identical, preserving the waterfall and brazier alignment.';
delete first.approval;
save(first.id,first);
const original=await loadImage(root+'citadel-01-v3/base.png');
const revised=await loadImage(root+first.id+'/ground-source.png');
const canvas=createCanvas(original.width,original.height),g=canvas.getContext('2d');
g.drawImage(original,0,0);
// Fade only within the existing paving, safely below both animation regions.
const overlay=createCanvas(original.width,original.height),o=overlay.getContext('2d');
o.drawImage(revised,0,0,original.width,original.height);
o.globalCompositeOperation='destination-in';
const mask=o.createLinearGradient(0,original.height*.76,0,original.height*.80);
mask.addColorStop(0,'transparent');mask.addColorStop(1,'white');
o.fillStyle=mask;o.fillRect(0,0,original.width,original.height);
g.drawImage(overlay,0,0);
fs.writeFileSync(root+first.id+'/base.png',canvas.toBuffer('image/png'));

const third=read('citadel-03-v1');
third.id='citadel-03-v2';third.title='The silent foundry — deeper floor and foreground rubble';
third.status='Revised walkable depth and foreground occlusion';
third.frames=['../citadel-03-v1/base.png'];
for(const r of third.regions)r.animation.atlas='../citadel-03-v1/'+r.animation.atlas;
third.walkable.polygon=[[0,.625],[1,.625],[1,.92],[.9,.93],[.22,.93],[0,.92]];
third.walkable.description='Extended fighting floor; foreground rocks and branches overlap actors at the near edge.';
const shape=(name,points)=>({name,polygon:points.map(([x,y])=>[x/1672,y/941])});
third.foreground=[
 shape('Left foreground rocks',[[0,827],[38,817],[78,827],[114,819],[158,803],[179,795],[209,811],[242,831],[266,855],[302,844],[338,836],[372,847],[402,858],[414,878],[452,883],[485,904],[493,941],[0,941]]),
 shape('Right foreground rocks',[[1358,941],[1362,918],[1398,907],[1431,895],[1430,844],[1448,813],[1481,817],[1512,833],[1547,838],[1580,829],[1615,823],[1635,802],[1672,800],[1672,941]]),
 shape('Left foreground branch',[[41,822],[47,790],[44,760],[39,731],[37,701],[30,678],[33,677],[40,699],[43,731],[49,756],[64,733],[75,714],[78,715],[69,735],[52,765],[51,781],[72,764],[89,744],[94,746],[75,769],[53,790],[48,823]]),
 shape('Left branch fork',[[50,795],[30,776],[21,749],[19,718],[23,718],[25,747],[33,772],[53,788]]),
 shape('Right foreground branch',[[1619,842],[1622,811],[1627,779],[1636,747],[1641,717],[1649,704],[1651,706],[1645,719],[1640,751],[1632,782],[1629,812],[1625,841]]),
 shape('Right branch fork',[[1627,817],[1606,795],[1596,769],[1583,748],[1586,746],[1600,767],[1610,792],[1631,811]])
];
third.notes='Original painting and fire loops retained. Expanded front foot area; traced foreground rocks and branches now render over characters.';
save(third.id,third);
console.log('Rebuilt citadel ground revisions');
