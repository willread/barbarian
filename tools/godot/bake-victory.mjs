import fs from 'node:fs';
import {createCanvas,GlobalFonts} from '@napi-rs/canvas';
GlobalFonts.registerFromPath('asset-sources/fonts/anton.ttf','Anton');
const c=createCanvas(1440,1062),g=c.getContext('2d');
g.fillStyle='white';g.font='900 310px Anton';g.textAlign='center';g.fillText('YOU WIN',720,655);
// Placement guide only; runtime splats create the visible lettering.
fs.writeFileSync('godot/art/victory-blood-mask.png',c.toBuffer('image/png'));
