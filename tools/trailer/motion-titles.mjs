import fs from 'node:fs';
import {spawn,spawnSync} from 'node:child_process';
import {once} from 'node:events';
import {createCanvas,loadImage,GlobalFonts} from '@napi-rs/canvas';

GlobalFonts.registerFromPath('asset-sources/fonts/anton.ttf','Anton');
GlobalFonts.registerFromPath('asset-sources/fonts/oswald.ttf','Oswald');
const clamp=x=>Math.max(0,Math.min(1,x));
const smooth=x=>{x=clamp(x);return x*x*(3-2*x)};
const hash=(x,y)=>{const n=Math.sin(x*127.1+y*311.7)*43758.5453;return n-Math.floor(n)};
function noise(x,y){const a=Math.floor(x),b=Math.floor(y),u=smooth(x-a),v=smooth(y-b);return (hash(a,b)*(1-u)+hash(a+1,b)*u)*(1-v)+(hash(a,b+1)*(1-u)+hash(a+1,b+1)*u)*v;}
function ff(args){const p=spawnSync('ffmpeg',['-y','-hide_banner','-loglevel','error',...args],{windowsHide:true});if(p.status!==0)throw Error(p.stderr.toString());}

export async function renderMotionTitle({id,duration,source,start,previous,out,dest}){
 const dir=`${out}/motion-${id}`;fs.mkdirSync(dir,{recursive:true});
 ff(['-ss',String(start),'-i',source,'-t',String(duration),'-vf','fps=60','-q:v','2',dir+'/%04d.jpg']);
 let previousImage;
 if(previous){ff(['-ss',String(previous.start),'-i',previous.source,'-frames:v','1',dir+'/previous.png']);previousImage=await loadImage(dir+'/previous.png');}
 const canvas=createCanvas(1920,1080),g=canvas.getContext('2d');
 const flame=createCanvas(320,180),fg=flame.getContext('2d'),pixels=fg.createImageData(320,180);
 const encoder=spawn('ffmpeg',['-y','-hide_banner','-loglevel','error','-f','rawvideo','-pixel_format','rgba','-video_size','1920x1080','-framerate','60','-i','pipe:0','-an','-c:v','libx264','-preset','fast','-crf','17','-pix_fmt','yuv420p',dir+'/visual.mp4'],{windowsHide:true,stdio:['pipe','ignore','pipe']});
 let errors='';encoder.stderr.on('data',x=>errors+=x);const finished=once(encoder,'close');
 for(let f=0;f<duration*60;f++){
  const t=f/60,isLogo=id==='logo',enter=smooth((t-.08)/.38),leave=isLogo?1:smooth((duration-t)/.25),alpha=enter*leave;
  g.globalAlpha=1;g.globalCompositeOperation='source-over';g.drawImage(await loadImage(`${dir}/${String(f+1).padStart(4,'0')}.jpg`),0,0);
  if(previousImage&&t<.24){g.globalAlpha=1-smooth(t/.24);g.drawImage(previousImage,0,0);g.globalAlpha=1;}
  // Preserve the recorded camera and HUD; editorial shading grows smoothly over the scene.
  const shade=g.createLinearGradient(0,100,0,1080);shade.addColorStop(0,`rgba(5,7,9,${alpha*(isLogo?.82:0)})`);shade.addColorStop(.09,`rgba(5,7,9,${alpha*(isLogo?.85:.4)})`);shade.addColorStop(.55,`rgba(5,7,9,${alpha*(isLogo?.91:.12)})`);shade.addColorStop(1,`rgba(5,7,9,${alpha*(isLogo?.94:.18)})`);
  g.fillStyle=shade;g.fillRect(0,isLogo?0:100,1920,1080);
  // Animated turbulent flame field. Warm wisps rise with coherent noise rather than random flicker.
  const surge=isLogo?Math.exp(-Math.pow((t-.5)/.29,2)):Math.exp(-Math.pow((t-.3)/.21,2))*.18;
  const height=isLogo?250+surge*950:95+surge*350;
  for(let y=0;y<180;y++)for(let x=0;x<320;x++){
   const up=(180-y)/180,warp=noise(x*.023,t*.8+up*2)*2;
   const n=noise(x*.039+warp,up*3.8-t*2)*.64+noise(x*.09,up*9-t*4)*.26+noise(x*.2,up*17-t*6)*.1;
   const heat=clamp((n-up*.83-.12)*2.7),i=(y*320+x)*4;
   pixels.data[i]=255;pixels.data[i+1]=Math.round(clamp((heat-.15)*1.6)*220);pixels.data[i+2]=Math.round(clamp((heat-.67)*3)*155);pixels.data[i+3]=Math.round(smooth(heat*2)*220*alpha);
  }
  fg.putImageData(pixels,0,0);g.globalCompositeOperation='screen';g.drawImage(flame,0,1080-height,1920,height);g.globalCompositeOperation='source-over';
  for(let p=0;p<(isLogo?160:42);p++){
   const speed=90+hash(p,2)*230,age=(t+hash(p,4)*7)%5;
   const x=hash(p,7)*1920+Math.sin(t*1.7+p)*24,y=1100-age*speed;
   g.globalAlpha=alpha*clamp((1100-y)/120)*clamp(y/300)*(.25+hash(p,9)*.7);
   g.strokeStyle=p%4===0?'#fff0bd':'#ed7c2b';g.lineWidth=1+hash(p,12)*2;g.beginPath();g.moveTo(x,y);g.lineTo(x-3,y+5+speed/35);g.stroke();
  }
  g.globalAlpha=alpha;g.fillStyle='#f1eee5';g.shadowColor='#080706';g.shadowBlur=16;
  if(isLogo){
   const reveal=smooth((t-.25)/.6),scale=1+.14*(1-reveal);g.save();g.translate(960,555);g.scale(scale,scale);g.textAlign='center';g.font='430px Anton';
   g.beginPath();g.rect(-960,-540,1920,1080*reveal);g.clip();g.fillText('CAIRN',0,110);g.restore();
   g.shadowBlur=0;g.globalAlpha=alpha*smooth((t-1.15)/.5);g.textAlign='center';g.font='32px Oswald';g.fillStyle='#bbb8b0';g.fillText('DARK FANTASY. ARCADE COMBAT.',960,770);
   if(f===150)fs.writeFileSync(out+'/logo.png',canvas.toBuffer('image/png'));
  }else{
   g.save();g.translate(140,28*(1-enter));g.textAlign='left';
   g.font='116px Anton';g.fillText(id==='worlds'?'THREE WORLDS':id==='arsenal'?'DASH. CHARGE.':'CHAIN HITS.',0,264);
   g.font=id==='combo'?'92px Anton':'116px Anton';g.fillText(id==='worlds'?'TO CONQUER':id==='arsenal'?'UNLEASH MAGIC.':'CRUSH YOUR HIGH SCORE.',0,394);
   if(id==='worlds'){g.shadowBlur=0;g.font='32px Oswald';g.fillStyle='#d4cdc0';g.fillText('TWELVE ARENAS',4,455);}g.restore();
  }
  g.shadowBlur=0;g.globalAlpha=1;
  if(isLogo&&t>4.65){g.fillStyle=`rgba(0,0,0,${smooth((t-4.65)/.35)})`;g.fillRect(0,0,1920,1080);}
  if(f===60)fs.writeFileSync(out+'/'+id+'-motion-check.png',canvas.toBuffer('image/png'));
  if(!encoder.stdin.write(g.getImageData(0,0,1920,1080).data))await once(encoder.stdin,'drain');
 }
 encoder.stdin.end();const [code]=await finished;if(code!==0)throw Error(errors);
 ff(['-i',dir+'/visual.mp4','-ss',String(start),'-i',source,'-map','0:v','-map','1:a','-t',String(duration),'-af',`afade=t=in:d=0.03,afade=t=out:st=${duration-.12}:d=0.12,volume=${id==='logo'?.2:1}`,'-c:v','copy','-c:a','pcm_s16le',dest]);
}
