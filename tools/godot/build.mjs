import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const root=process.cwd();
const candidates=[process.env.GODOT_BIN,'E:/Cairn-build-tools/godot/Godot_v4.7.2-stable_win64_console.exe',path.join(root,'.tools/godot/Godot_v4.7.2-stable_win64_console.exe')].filter(Boolean);
const binary=candidates.find(p=>fs.existsSync(p));
if(!binary)throw Error('Install Godot 4.7.2 and set GODOT_BIN to its executable. See godot/README.md.');
const output=path.resolve(process.env.CAIRN_BUILD_DIR||(fs.existsSync('E:/Cairn-build-tools')?'E:/Cairn-build-tools/build':'godot/build'));
function run(command,args){
 const result=spawnSync(command,args,{stdio:['inherit','pipe','pipe'],encoding:'utf8',maxBuffer:32*1024*1024,windowsHide:true});
 if(result.stdout)process.stdout.write(result.stdout);if(result.stderr)process.stderr.write(result.stderr);
 if(result.error)throw result.error;
 if(result.status!==0||/^(?:SCRIPT ERROR|SHADER ERROR|ERROR):/m.test((result.stdout||'')+(result.stderr||'')))process.exit(result.status||1);
}
if(!fs.existsSync('godot/assets/manifest.json')||process.argv.includes('--prepare')){
 run(process.execPath,['tools/godot/bake-assets.mjs']);
 run(process.execPath,['tools/godot/bake-extras.mjs']);
}
run(binary,['--headless','--path','godot','--editor','--import','--quit']);
if(process.argv.includes('--test')){
 run(process.execPath,['tools/godot/parity-fixtures.mjs']);
 run(binary,['--headless','--path','godot','--script','tests/parity.gd']);
 run(binary,['--headless','--path','godot','--','--smoke-test']);
 run(binary,['--headless','--path','godot','--','--integration-test']);
 process.exit(0);
}
const targets=process.argv.includes('--web')?['Web']:process.argv.includes('--windows')?['Windows']:['Web','Windows'];
for(const target of targets){
 const file=path.join(output,target==='Web'?'web/index.html':'windows/Cairn.exe');fs.mkdirSync(path.dirname(file),{recursive:true});
 run(binary,['--headless','--path','godot','--export-release',target,file]);
 if(target==='Web'){
  // The shell comes from Godot; this deterministic post-step skins its loader.
  let html=fs.readFileSync(file,'utf8');
  const ring=`<div id="cairn-loader" aria-label="Loading Cairn"><div class="studio-art"><img class="metal-logo" src="maximum-force-logo.png" alt="Maximum Force" /><img class="flat-logo" src="maximum-force-logo.png" alt="" aria-hidden="true" /></div><svg viewBox="0 0 120 120"><defs><linearGradient id="metal"><stop stop-color="#d7d1c4"/><stop offset=".45" stop-color="#615f5b"/><stop offset=".7" stop-color="#242522"/><stop offset="1" stop-color="#aaa494"/></linearGradient></defs><g fill="url(#metal)" stroke="#161713">${Array.from({length:12},(_,i)=>`<path d="M55 19 L60 3 L68 24 L63 32 L54 30Z" transform="rotate(${i*30} 60 60)"/>`).join('')}<path fill-rule="evenodd" d="M60 20a40 40 0 1 1 0 80a40 40 0 1 1 0-80 M60 31a29 29 0 1 0 0 58a29 29 0 1 0 0-58"/></g></svg></div>`;
  html=html.replace('</head>',`<link rel="preload" as="image" href="maximum-force-logo.png"><style>
html,body{background:#000!important}
#cairn-loader{position:fixed;inset:0;display:grid;place-items:center;background:#000 url(studio-background.png) center/cover no-repeat;z-index:9999;pointer-events:auto}
#cairn-loader .studio-art{position:relative;width:min(68vw,104vh);height:52vh;display:grid;place-items:center;z-index:1}
#cairn-loader .studio-art img{width:100%;height:100%;object-fit:contain}
#cairn-loader .studio-art .flat-logo{position:absolute;inset:0;width:100%;height:100%;filter:brightness(0) invert(1);animation:flat-in .45s ease-in-out 1.5s both}
#cairn-loader::before{content:"";position:absolute;inset:0;background:#000;animation:flat-in .45s ease-in-out 1.5s both}
@keyframes flat-in{from{opacity:0}to{opacity:1}}@keyframes metal-out{from{opacity:1}to{opacity:0}}
#cairn-loader > svg{z-index:2;position:absolute;right:max(24px,env(safe-area-inset-right));bottom:max(24px,env(safe-area-inset-bottom));width:clamp(40px,7vmin,76px);height:clamp(40px,7vmin,76px);animation:spin 1.8s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}#status-progress,#status-splash{visibility:hidden}
</style></head>`).replace('<body>',`<body>${ring}<script>window.cairnSplashStart=performance.now();</script>`);
  html=html.replace('</body>',`<script>
let cairnDone=false;
const cairnCheck=()=>{
 const status=document.getElementById('status');
 const failed=document.getElementById('status-notice')?.style.display==='block';
 if(failed){document.getElementById('cairn-loader')?.remove();cairnWatch.disconnect();return;}
 if(cairnDone||status&&getComputedStyle(status).display!=='none')return;
 cairnDone=true;
 const image=document.querySelector('.studio-art img');
 Promise.resolve(image?.decode()).catch(()=>{}).then(()=>{
  setTimeout(()=>{document.getElementById('cairn-loader')?.remove();cairnWatch.disconnect();},Math.max(0,3000-(performance.now()-window.cairnSplashStart)));
 });
};
const cairnWatch=new MutationObserver(cairnCheck);
cairnWatch.observe(document.body,{subtree:true,childList:true,attributes:true,attributeFilter:['style','class']});
cairnCheck();
</script></body>`);
  fs.copyFileSync('godot/art/maximum-force-reference.png',path.join(path.dirname(file),'maximum-force-reference.png'));
  fs.copyFileSync('godot/art/studio-background.png',path.join(path.dirname(file),'studio-background.png'));
  fs.copyFileSync('godot/art/maximum-force-logo.png',path.join(path.dirname(file),'maximum-force-logo.png'));
  fs.writeFileSync(file,html);
 }
 console.log(`${target}: ${file}`);
}
