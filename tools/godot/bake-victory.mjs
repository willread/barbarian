import fs from 'node:fs';
import {createCanvas,GlobalFonts} from '@napi-rs/canvas';
GlobalFonts.registerFromPath('asset-sources/fonts/anton.ttf','Anton');
const c=createCanvas(1440,1062),g=c.getContext('2d');
g.fillStyle='white';g.font='900 310px Anton';g.textAlign='center';g.fillText('YOU WIN',720,655);
const pixels=g.getImageData(0,0,1440,1062).data;
let seed=517;const random=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296};
// Drips emerge from actual letter bottoms; satellite spatters stay close to the lettering.
for(let x=150;x<1290;x+=17){let bottom=0;for(let y=300;y<690;y++)if(pixels[(y*1440+x)*4+3]>200)bottom=y;if(!bottom||random()>.65)continue;const length=12+random()*75,width=2+random()*5;g.beginPath();g.moveTo(x-width,bottom-7);g.quadraticCurveTo(x+width,bottom+length*.45,x+width*.4,bottom+length);g.quadraticCurveTo(x-width*.5,bottom+length+7,x-width*.6,bottom+length);g.closePath();g.fill();}
for(let i=0;i<100;i++){const x=130+random()*1180,y=315+random()*420;if(pixels[(Math.floor(y)*1440+Math.floor(x))*4+3]>0)continue;g.beginPath();g.ellipse(x,y,1+random()*5,1+random()*8,random()*3.14,0,Math.PI*2);g.fill();}
fs.writeFileSync('godot/art/victory-blood-mask.png',c.toBuffer('image/png'));
