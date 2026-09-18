import fs from 'node:fs';
// Revised stills and separate animation layers follow the shared episode bake.
// They do not invalidate the large, unchanged swamp animation atlases.
const sources={
 '02-mouth.png':'ashen-2-base.png',
 '03-crucible.png':'ashen-3-base.png',
 '03-brazier.png':'crucible-brazier.png',
 '04-reliquary-edges-v2.png':'ashen-4-base.png',
 '04-lantern.png':'sanctuary-lantern.png',
 '01-track-clear.png':'ashen-track-clear.png',
};
for(const [file,asset] of Object.entries(sources)){
 const source='studies/backgrounds/ashen-v2/'+file;
 const target='godot/assets/'+asset;
 const paint=fs.readFileSync(source);
 if(!fs.existsSync(target)||!paint.equals(fs.readFileSync(target))){
  fs.copyFileSync(source,target);
  console.log('Updated Ashen animation asset: '+asset);
 }
}
