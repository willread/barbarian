import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const audio=/\.(ogg|mp3|wav|m4a|flac)$/i;
const rank={'.ogg':0,'.wav':1,'.flac':2,'.mp3':3,'.m4a':4};
const read=p=>{try{return JSON.parse(fs.readFileSync(p,'utf8'))}catch{return {}}};
const title=s=>s.replace(/[-_]/g,' ').replace(/\b\w/g,c=>c.toUpperCase());
export function musicLibrary(root=process.cwd()){
 const candidates=new Map();
 function add(file,meta={}){
  if(!fs.existsSync(file)||!audio.test(file)||/-source\./i.test(file)||path.basename(file)==='current-ep2.ogg')return;
  const stem=path.basename(file,path.extname(file)),key=meta.key||stem;
  const previous=candidates.get(key);
  if(previous&&(rank[path.extname(previous.path)]??9)<=(rank[path.extname(file)]??9))return;
  candidates.set(key,{...meta,key,path:file,name:meta.name||title(stem),collection:meta.collection||'Music',description:meta.description||'',bpm:meta.bpm||null,duration:meta.loop?.duration||null});
 }
 const legacy=read(path.join(root,'soundboard/manifest.json'));
 const metadata=new Map((legacy.jobs||[]).filter(j=>j.music).map(j=>[j.id,j]));
 for(const directory of ['godot/audio','godot/audio_options','soundboard']){
  const dir=path.join(root,directory);if(!fs.existsSync(dir))continue;
  for(const name of fs.readdirSync(dir))if(/^music[_-]/i.test(name)&&audio.test(name)){
   const id=name.replace(audio,''),job=metadata.get(id)||{};
   add(path.join(dir,name),{...job,name:job.name||(id==='music_menu'?'Original menu theme':id==='music_game'?'Original battle theme':title(id)),collection:id.startsWith('music_menu')?'Menu themes':'Battle themes',bpm:id.startsWith('music_menu')?80:120});
  }
 }
 // A music-named folder or manifest with music:true/type:music opts future tracks in.
 function walk(dir,musicFolder=false){
  if(!fs.existsSync(dir))return;
  musicFolder=musicFolder||/music/i.test(path.basename(dir));
  const manifest=read(path.join(dir,'manifest.json'));
  const jobs=manifest.tracks||manifest.jobs||[];
  for(const job of jobs){
   if(!(musicFolder||manifest.type==='music'||job.music===true))continue;
   const key=path.relative(root,dir).replaceAll('\\','/')+'/'+job.id;
   const meta={...job,key,collection:manifest.collection||(/ep2/i.test(dir)?'EP2 · Sunken Wilds':title(path.basename(dir)))};
   if(job.file)add(path.resolve(dir,job.file),meta);
   else for(const ext of ['ogg','wav','mp3'])add(path.join(dir,job.id+'.'+ext),meta);
  }
  for(const item of fs.readdirSync(dir,{withFileTypes:true})){
   if(item.isDirectory())walk(path.join(dir,item.name),musicFolder);
   else if(musicFolder&&audio.test(item.name)&&!jobs.some(j=>(j.file||j.id+'.'+path.extname(item.name).slice(1))===item.name))add(path.join(dir,item.name),{key:path.relative(root,dir).replaceAll('\\','/')+'/'+item.name.replace(audio,''),collection:title(path.basename(dir))});
  }
 }
 // Root soundboard legacy jobs are handled above; scan new collections underneath it.
 for(const parent of ['soundboard','asset-sources/audio']){
  const dir=path.join(root,parent);if(!fs.existsSync(dir))continue;
  for(const item of fs.readdirSync(dir,{withFileTypes:true}))if(item.isDirectory())walk(path.join(dir,item.name));
 }
 const defaults=read(path.join(root,'godot/audio_defaults.json')).choices||{};
 const assigned=new Map([[defaults.music_menu||'music_menu','Menu default'],[defaults.music_game||'music_game','EP1 default'],['music_game-3','EP2 default'],['music_game-4','EP3 default']]);
 return [...candidates.values()].map(t=>({...t,pathExtension:path.extname(t.path).slice(1),id:crypto.createHash('sha256').update(t.key).digest('hex').slice(0,20),assignment:assigned.get(t.key)||'',url:'/music/audio/'+crypto.createHash('sha256').update(t.key).digest('hex').slice(0,20)})).sort((a,b)=>a.collection.localeCompare(b.collection)||a.name.localeCompare(b.name));
}
