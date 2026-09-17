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
third.id='citadel-03-v4';third.title='The silent foundry — rectangular floor and foreground rubble';
third.status='Revised walkable depth and foreground occlusion';
third.frames=['base.png'];
for(const r of third.regions)r.animation.atlas='../citadel-03-v1/'+r.animation.atlas;
third.regions[1].protect_dark_structure=true;
third.regions[1].animation.atlas='../citadel-03-v3/brazier-2.png';
third.walkable.polygon=[[0,.625],[1,.625],[1,.93],[0,.93]];
third.walkable.description='Rectangular fighting floor with a level front edge; overlapping rocks render in the foreground.';
const shape=(name,points)=>({name,polygon:points.map(([x,y])=>[x/1672,y/941])});
third.foreground=[
 shape('Front center loose rock',[[650,906],[656,887],[670,879],[689,882],[705,893],[714,915],[701,922],[663,919]]),
 shape('Front center broken slab',[[795,895],[807,881],[835,872],[865,878],[879,889],[914,894],[947,894],[968,910],[964,927],[919,938],[865,930],[824,922]]),
 shape('Left foreground rocks',[[0,827],[38,817],[78,827],[114,819],[158,803],[179,795],[209,811],[242,831],[266,855],[302,844],[338,836],[372,847],[402,858],[414,878],[452,883],[485,904],[493,941],[0,941]]),
 shape('Right foreground rocks',[[1358,941],[1362,918],[1398,907],[1431,895],[1430,844],[1448,813],[1481,817],[1512,833],[1547,838],[1580,829],[1615,823],[1635,802],[1672,800],[1672,941]]),
];
third.notes='Foreground sticks removed from the painting. Rectangular fighting floor with rocks-only foreground occlusion; fixed forge grate animation retained.';
save(third.id,third);
const foundryOriginal=await loadImage(root+'citadel-03-v1/base.png');
const foundryClean=await loadImage(root+third.id+'/rocks-only-source.png');
const foundry=createCanvas(foundryOriginal.width,foundryOriginal.height),fg=foundry.getContext('2d');
fg.drawImage(foundryOriginal,0,0);
// Only the two near corners are replaced. All animation pixels stay original.
for(const [x,y,w,h] of [[0,650,150,291],[1530,650,142,291]]){
 fg.drawImage(foundryClean,x/foundryOriginal.width*foundryClean.width,y/foundryOriginal.height*foundryClean.height,w/foundryOriginal.width*foundryClean.width,h/foundryOriginal.height*foundryClean.height,x,y,w,h);
}
fs.writeFileSync(root+third.id+'/base.png',foundry.toBuffer('image/png'));

const second=read('citadel-02-v1');
second.id='citadel-02-v2';
second.status='Original composition and floor; revised foreground rock masks';
second.frames=['../citadel-02-v1/base.png'];
for(const r of second.regions)r.animation.atlas='../citadel-02-v1/'+r.animation.atlas;
second.foreground=[
 shape('Foreground — left rock silhouettes',[[0,781],[24,784],[57,775],[81,774],[90,797],[97,825],[116,832],[130,826],[147,837],[160,849],[173,858],[185,863],[210,858],[235,854],[250,863],[263,878],[273,898],[299,906],[320,899],[341,885],[359,887],[371,895],[381,912],[404,923],[421,941],[0,941]]),
 shape('Foreground — right rock silhouettes',[[1232,941],[1264,925],[1293,919],[1305,888],[1318,866],[1341,858],[1370,856],[1400,857],[1426,862],[1452,858],[1456,826],[1466,800],[1484,782],[1507,784],[1530,798],[1568,801],[1604,804],[1638,812],[1672,812],[1672,941]]),
 shape('Foreground — loose center stones',[[1008,940],[1016,925],[1031,922],[1040,914],[1061,909],[1081,911],[1096,923],[1120,930],[1136,941]])
];
second.notes+=' Revised foreground contours include the overlapping front rocks and loose center stones. Artwork, animation and walkable polygon unchanged.';
save(second.id,second);
const fourth=read('citadel-04-v1');
fourth.id='citadel-04-v2';
fourth.status='Expanded rectangular floor and foreground rubble';
fourth.frames=['../citadel-04-v1/base.png'];
for(const r of fourth.regions)r.animation.atlas='../citadel-04-v1/'+r.animation.atlas;
fourth.walkable.polygon=[[0,.65],[1,.65],[1,.95],[0,.95]];
fourth.walkable.description='Continuous rectangular fighting floor ending 5% above the bottom; overlapping rubble renders in front of actors.';
fourth.movement_y=[.65*810,.95*810];
fourth.foreground=[
 shape('Left foreground rubble',[[0,826],[10,831],[15,852],[42,850],[59,847],[79,849],[80,874],[108,869],[119,871],[124,898],[145,896],[158,884],[192,879],[210,887],[212,894],[228,888],[251,890],[270,882],[283,884],[286,918],[311,917],[327,913],[350,918],[369,915],[394,911],[400,941],[0,941]]),
 shape('Right foreground rubble',[[1052,941],[1056,911],[1081,907],[1082,900],[1108,901],[1112,889],[1131,887],[1144,898],[1157,895],[1159,884],[1185,879],[1208,888],[1240,886],[1241,921],[1265,915],[1304,919],[1321,916],[1353,924],[1358,912],[1390,906],[1427,910],[1442,900],[1455,899],[1475,869],[1490,863],[1520,870],[1531,868],[1532,848],[1553,840],[1578,849],[1593,850],[1596,834],[1609,834],[1626,843],[1655,847],[1656,823],[1672,821],[1672,941]])
];
fourth.notes='Original painting and brazier animation retained. Floor extends to a consistent 5% bottom margin, with front rubble silhouettes drawn over actors.';
save(fourth.id,fourth);
console.log('Rebuilt citadel ground revisions');
