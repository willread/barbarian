import {spawnSync} from 'node:child_process';
const source='soundboard/character-shout-options-v2';
const picks={marauder:'marauder-4',warden:'warden-1',bearer:'bearer-4',king:'king-1',saint:'saint-2-with-1-preview'};
for(const [enemy,pick] of Object.entries(picks)){
 const result=spawnSync('ffmpeg',['-v','error','-y','-i',`${source}/${pick}.mp3`,'-ar','44100','-c:a','libvorbis','-q:a','5',`godot/audio/roar_${enemy}.ogg`],{stdio:'inherit',windowsHide:true});
 if(result.status!==0)throw Error(`Failed to bake ${enemy}`);
}
