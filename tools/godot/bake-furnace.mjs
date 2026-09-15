import fs from 'node:fs';
// Apply the revised still after the shared episode bake, including clean builds.
// It has no dependency on the large, unchanged swamp animation atlases.
const source='studies/backgrounds/ashen-v2/02-mouth.png';
const target='godot/assets/ashen-2-base.png';
const paint=fs.readFileSync(source);
if(!fs.existsSync(target)||!paint.equals(fs.readFileSync(target))){
 fs.copyFileSync(source,target);
 console.log('Updated Furnace Mouth: banner-free painting prepared for animated exhaust.');
}
