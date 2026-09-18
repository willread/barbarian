import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import {createCanvas,loadImage} from '@napi-rs/canvas';
export const clips=['2026-09-17 19-12-14.mp4','2026-09-17 19-15-19.mp4','2026-09-17 19-21-11.mp4','2026-09-17 19-28-41.mp4'].map(x=>'C:/Users/will/Videos/'+x);
const output='E:/Cairn-build-tools/trailer/footage-review';fs.mkdirSync(output,{recursive:true});
const index=process.argv.indexOf('--detail');
const jobs=index>=0?[{clip:Number(process.argv[index+1]),start:Number(process.argv[index+2]),end:Number(process.argv[index+3]),step:Number(process.argv[index+4]||1)}]:clips.map((file,i)=>{const p=spawnSync('ffprobe',['-v','error','-show_entries','format=duration','-of','json',file],{encoding:'utf8',windowsHide:true});return {clip:i+1,start:0,end:Number(JSON.parse(p.stdout).format.duration),step:15}});
for(const job of jobs){
 const times=[];for(let t=job.start;t<job.end;t+=job.step)times.push(t);
 const canvas=createCanvas(1920,Math.ceil(times.length/4)*292),g=canvas.getContext('2d');g.fillStyle='#111';g.fillRect(0,0,canvas.width,canvas.height);
 for(let i=0;i<times.length;i++){
  const p=spawnSync('ffmpeg',['-hide_banner','-loglevel','error','-ss',String(times[i]),'-i',clips[job.clip-1],'-frames:v','1','-vf','scale=480:270','-f','image2pipe','-vcodec','png','pipe:1'],{windowsHide:true,maxBuffer:4*1024*1024});
  if(p.status!==0)throw Error(p.stderr.toString());
  const x=i%4*480,y=Math.floor(i/4)*292;
  g.drawImage(await loadImage(p.stdout),x,y);g.fillStyle='#fff';g.font='17px sans-serif';g.fillText('Clip '+job.clip+'  '+Math.floor(times[i]/60)+':'+String(Math.floor(times[i]%60)).padStart(2,'0')+' ('+times[i]+'s)',x+8,y+287);
 }
 const name=`clip-${job.clip}-${job.start}-${job.end.toFixed(0)}-${job.step}.jpg`;
 fs.writeFileSync(output+'/'+name,canvas.toBuffer('image/jpeg'));console.log(output+'/'+name);
}
