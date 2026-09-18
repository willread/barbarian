import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const run=(exe,args,timeout=120000)=>{const p=spawnSync(exe,args,{windowsHide:true,encoding:'utf8',timeout,maxBuffer:6*1024*1024});if(p.status!==0)throw Error(p.error?.message||p.stderr||p.stdout);return p;};
export async function renderMotionTitle({id,duration,source,start,previous,out,dest}){
 const project=out+'/native-project',frames=out+'/native-'+id;fs.mkdirSync(project+'/scripts',{recursive:true});fs.mkdirSync(project+'/shaders',{recursive:true});fs.mkdirSync(frames,{recursive:true});
 fs.writeFileSync(project+'/project.godot','config_version=5\n[display]\nwindow/size/viewport_width=1920\nwindow/size/viewport_height=1080\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
 fs.copyFileSync('godot/scripts/contour_fire.gd',project+'/scripts/contour_fire.gd');
 for(const name of ['contour_fire_flow','contour_fire_surface','stone_temperature','hot_stone'])fs.copyFileSync('godot/shaders/'+name+'.gdshader',project+'/shaders/'+name+'.gdshader');
 fs.copyFileSync('tools/trailer/native-titles.gd',project+'/native-titles.gd');
 let texture=path.resolve('godot/art/cairn-logo.png');
 if(id!=='logo'){
  const sheet=await loadImage('asset-sources/marketing/trailer-stone-titles.png');
  const c=createCanvas(sheet.width,sheet.height),g=c.getContext('2d');g.drawImage(sheet,0,0);const data=g.getImageData(0,0,c.width,c.height).data;
  const [a,b]={worlds:[0,500],combo:[500,850],arsenal:[850,1280]}[id];let x0=c.width,y0=b,x1=0,y1=a;
  for(let y=a;y<Math.min(b,c.height);y++)for(let x=0;x<c.width;x++)if(data[(y*c.width+x)*4+3]>24){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);}
  const crop=createCanvas(x1-x0+25,y1-y0+25);crop.getContext('2d').drawImage(c,x0,y0,x1-x0+1,y1-y0+1,12,12,x1-x0+1,y1-y0+1);
  texture=frames+'/type.png';fs.writeFileSync(texture,crop.toBuffer('image/png'));
 }
 run('ffmpeg',['-y','-hide_banner','-loglevel','error','-ss',String(start),'-i',source,'-t',String(duration),'-vf','fps=60','-q:v','2',frames+'/%04d.jpg']);
 run('ffmpeg',['-y','-hide_banner','-loglevel','error','-ss',String(previous?.start??start),'-i',previous?.source??source,'-frames:v','1',frames+'/previous.png']);
 const config={id,duration,texture:texture.replaceAll('\\','/'),frames,previous:frames+'/previous.png',title_art:path.resolve('godot/art/title-background.png').replaceAll('\\','/')};fs.writeFileSync(frames+'/config.json',JSON.stringify(config));
 const p=run('E:/Cairn-build-tools/godot/Godot_v4.7.2-stable_win64_console.exe',['--path',project,'--script','res://native-titles.gd','--resolution','1920x1080','--position','-32000,-32000','--write-movie',frames+'/render.avi','--fixed-fps','60','--rendering-driver','opengl3','--',frames+'/config.json']);
 fs.writeFileSync(frames+'/render.log',p.stdout+p.stderr);
 const vf=id==='logo'?'fade=t=out:st=4.65:d=0.35':'null';
 run('ffmpeg',['-y','-hide_banner','-loglevel','error','-ss','1','-i',frames+'/render.avi','-ss',String(start),'-i',source,'-map','0:v','-map','1:a','-vf',vf,'-t',String(duration),'-af',`afade=t=in:d=0.03,afade=t=out:st=${duration-.12}:d=0.12,volume=${id==='logo'?.2:1}`,'-c:v','libx264','-preset','fast','-crf','17','-pix_fmt','yuv420p','-c:a','pcm_s16le',dest]);
 run('ffmpeg',['-y','-hide_banner','-loglevel','error','-ss',id==='logo'?'2.5':'1','-i',dest,'-frames:v','1',out+'/'+(id==='logo'?'logo.png':id+'-native-check.png')]);
}
