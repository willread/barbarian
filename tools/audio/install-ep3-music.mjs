import fs from 'node:fs';
const directory='soundboard/ep3-music';
const manifest=JSON.parse(fs.readFileSync(directory+'/manifest.json','utf8'));
for(const job of manifest.jobs){
 if(!job.loop)throw Error('Prepare the music loops before installation');
 fs.copyFileSync(directory+'/'+job.file,'godot/audio_options/'+job.file);
}
fs.writeFileSync('godot/audio_options/ep3-music.json',JSON.stringify(manifest,null,2)+'\n');
console.log('Installed four Furnace Heart candidates for the internal music player.');
