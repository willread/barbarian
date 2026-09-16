import fs from 'node:fs';

// Keep source assets intact; only the two shareware export presets are stripped.
const omitted = [
 'assets/swamp-*','assets/ashen-*','assets/cinder-*','assets/crucible-brazier.png','assets/mire-*','assets/king-*',
 'assets/enemy-witch-*','assets/enemy-bearer-*','assets/enemy-king-*','assets/enemy-saint-*',
 'art/witch-*','art/bearer-*','art/king-*','art/saint-*','art/ember-core-*','art/ending/*',
 'worlds/swamp.json','worlds/ashen.json','audio/mire_loop.*',
 'voice/boss-king.*','voice/boss-saint.*','scripts/soundboard.gd',
];
const defaults=JSON.parse(fs.readFileSync('godot/audio_defaults.json','utf8'));
const active=new Set([...Object.values(defaults.choices),...Object.values(defaults.pools).flat()]);
const retained=new Set();
for(const id of active){
 for(const ext of ['ogg','mp3']){
  const file=`${id}.${ext}`;
  if(fs.existsSync(`godot/audio_options/${file}`)){retained.add(file);break;}
 }
}
for(const file of fs.readdirSync('godot/audio_options').sort()){
 if(/\.(ogg|mp3|wav)$/.test(file)&&!retained.has(file))omitted.push(`audio_options/${file}`);
}
const file='godot/export_presets.cfg';
const original=fs.readFileSync(file,'utf8');
const updated=original.replace(/(\[preset\.[23]\][\s\S]*?exclude_filter=")[^"]*(")/g,(_,before,after)=>{
 const native=before.includes('platform="Web"')?'native/*,':'';
 return before+native+'tests/*,audio/*.mp3,audio/foot_*,audio/bow_draw*,audio/arrow_ground*,'+omitted.join(',')+after;
});
if(updated!==original)fs.writeFileSync(file,updated);
console.log(`Shareware: omit later-episode assets and unused audio; retain ${retained.size} selected audio variants.`);
