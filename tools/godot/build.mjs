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
run(process.execPath,['tools/godot/bake-world.mjs']);
run(process.execPath,['tools/godot/bake-episodes.mjs']);
run(process.execPath,['tools/godot/bake-mire-oil.mjs']);
if(!fs.existsSync('godot/assets/cheat-letters.json'))run(process.execPath,['tools/godot/bake-cheats.mjs']);
const menuManifest=JSON.parse(fs.readFileSync('godot/assets/manifest.json','utf8'));
if(!menuManifest.menu['NEW JOURNEY']||!menuManifest.menu['EASY']||!menuManifest.menu['NORMAL']||!menuManifest.menu['HARD']||!menuManifest.menu['HALL OF LEGENDS']||!menuManifest.menu['CONTROLS']||!menuManifest.menu['WEAPON: CANDY CANE']||!menuManifest.menu['8X']||!menuManifest.menu['AREA 4/4']||!menuManifest.menu['WEAPON: GRAVECLEAVER']||!menuManifest.menu['EP 1: THE FALLEN CITADEL']||!menuManifest.menu['EP 2: THE SUNKEN WILDS']||!menuManifest.menu['EP 3: THE ASHEN DEPTHS']||!menuManifest.menu['VOICE: ON']||!menuManifest.menu['VOICE: OFF']||!menuManifest.menu['QUIT']||!menuManifest.menu['RETURN TO BATTLE']||!menuManifest.menu['SOUND']||!menuManifest.menu['VOLUME: 100'])run(process.execPath,['tools/godot/bake-menu.mjs']);
if(!fs.existsSync('godot/art/results/lettering.json'))run(process.execPath,['tools/godot/bake-results.mjs']);
if(!fs.existsSync('godot/art/controls/hall-of-legends.png'))run(process.execPath,['tools/godot/bake-controls.mjs','--hall']);
if(!menuManifest.menu['HUD 10X']||menuManifest.hudSmallLabelVersion!==1||menuManifest.hudMultiplierWeightVersion!==1)run(process.execPath,['--expose-gc','tools/godot/bake-score-hud.mjs']);
run(binary,['--headless','--path','godot','--editor','--import','--quit']);
if(process.argv.includes('--test')){
 run(process.execPath,['tools/godot/check-episode-sprites.mjs']);
 run(process.execPath,['tools/godot/parity-fixtures.mjs']);
 run(binary,['--headless','--path','godot','--script','tests/run_records.gd']);
 run(binary,['--headless','--path','godot','--script','tests/difficulty.gd']);
 run(binary,['--headless','--path','godot','--script','tests/results_ui.gd']);
 run(binary,['--headless','--path','godot','--script','tests/parity.gd']);
 run(binary,['--headless','--path','godot','--script','tests/bindings.gd']);
 run(binary,['--headless','--path','godot','--script','tests/variant_holiday.gd']);
 run(binary,['--headless','--path','godot','--script','tests/weapon_unlocks.gd']);
 run(binary,['--headless','--path','godot','--script','tests/combat_moves.gd']);
 run(binary,['--headless','--path','godot','--script','tests/audio_assets.gd']);
 run(binary,['--headless','--path','godot','--script','tests/episode_music.gd']);
 run(binary,['--headless','--path','godot','--script','tests/audio_mix.gd']);
 run(binary,['--headless','--path','godot','--script','tests/creature_art.gd']);
 run(binary,['--headless','--path','godot','--script','tests/settings_menu.gd']);
 run(binary,['--headless','--path','godot','--script','tests/pause_menu.gd']);
 run(binary,['--headless','--path','godot','--script','tests/chapter.gd']);
 run(binary,['--headless','--path','godot','--script','tests/episodes.gd']);
 run(binary,['--headless','--path','godot','--script','tests/king_glass.gd']);
 run(binary,['--headless','--path','godot','--script','tests/mire.gd']);
 run(binary,['--headless','--path','godot','--script','tests/mire_audio.gd']);
 run(binary,['--headless','--path','godot','--script','tests/swamp_fog.gd']);
 run(binary,['--headless','--path','godot','--script','tests/debug_console.gd']);
 run(binary,['--headless','--path','godot','--script','tests/combo.gd']);
 run(binary,['--headless','--path','godot','--script','tests/eggs.gd']);
 run(binary,['--headless','--path','godot','--script','tests/wave_audio.gd']);
 run(binary,['--headless','--path','godot','--script','tests/soundboard.gd']);
 run(binary,['--headless','--path','godot','--script','tests/hero_voice.gd']);
 run(binary,['--headless','--path','godot','--','--smoke-test']);
 run(binary,['--headless','--path','godot','--','--integration-test']);
 run(binary,['--headless','--path','godot','--','--moves-test']);
 run(binary,['--headless','--path','godot','--','--archer-test']);
 process.exit(0);
}
const targets=process.argv.includes('--web')?['Web']:process.argv.includes('--windows')?['Windows']:['Web','Windows'];
for(const target of targets){
 const file=path.join(output,target==='Web'?'web/index.html':'windows/Cairn.exe');fs.mkdirSync(path.dirname(file),{recursive:true});
 run(binary,['--headless','--path','godot','--export-release',target,file]);
 run(binary,['--headless','--main-pack',target==='Web'?path.join(path.dirname(file),'index.pck'):file,'--script',path.join(root,'godot/tests/soundboard.gd')]);
 // Exercise the actual exported pack: source-directory tests miss import remapping bugs.
 run(binary,['--headless','--main-pack',target==='Web'?path.join(path.dirname(file),'index.pck'):file,'--script',path.join(root,'godot/tests/audio_assets.gd')]);
 if(target==='Web'){
  // The shell comes from Godot; this deterministic post-step skins its loader.
  let html=fs.readFileSync(file,'utf8');
  const ring=`<div id="cairn-loader" aria-label="Loading Cairn"><div class="studio-art"><svg class="metal-logo" viewBox="0 0 1774 887" preserveAspectRatio="none" aria-label="Maximum Force"><image href="maximum-force-logo.png" width="1774" height="887" /></svg><svg class="flat-logo" viewBox="0 0 1774 887" preserveAspectRatio="none" aria-hidden="true"><defs><mask id="studio-white-shape" maskUnits="userSpaceOnUse" x="0" y="0" width="1774" height="887" style="mask-type:luminance"><image href="maximum-force-white-v2.png" width="1774" height="887" /></mask></defs><rect width="1774" height="887" fill="white" mask="url(#studio-white-shape)" /></svg></div><svg class="cairn-stack" viewBox="0 0 256 256" aria-label="Loading"><defs>${[[0,158,256,98],[0,102,256,56],[0,0,256,102]].map((r,i)=>`<clipPath id="stone-${i}"><rect x="${r[0]}" y="${r[1]}" width="${r[2]}" height="${r[3]}"/></clipPath>`).join('')}</defs>${[0,1,2].map(i=>`<g class="stone stone-${i}"><image href="cairn-icon-256.png" width="256" height="256" clip-path="url(#stone-${i})"/></g>`).join('')}</svg></div>`;
  html=html.replace('</head>',`<link rel="icon" type="image/png" sizes="32x32" href="cairn-icon-32.png?v=2"><link rel="icon" href="cairn.ico?v=2"><link rel="apple-touch-icon" href="cairn-icon-180.png?v=2"><link rel="preload" as="image" href="maximum-force-logo.png"><link rel="preload" as="image" href="maximum-force-white-v2.png"><link rel="preload" as="image" href="studio-background.png"><style>
html,body{background:#000!important}
#cairn-loader{position:fixed;inset:0;width:100vw;height:100dvh;display:grid;place-items:center;background:#000 url(studio-background.png) center/cover no-repeat;z-index:9999;pointer-events:auto}
#cairn-loader .studio-art{position:relative;width:min(47.6vw,71.19vh);aspect-ratio:2/1;z-index:1}
#cairn-loader .studio-art > svg{position:absolute;inset:0;width:100%;height:100%}
#cairn-loader .metal-logo{animation:metal-out 1.2s ease-in-out 3s both}
#cairn-loader .flat-logo{animation:flat-in 1.2s ease-in-out 3s both}
#cairn-loader::before{content:"";position:absolute;inset:0;background:#000;animation:flat-in 1.2s ease-in-out 3s both}
@keyframes flat-in{from{opacity:0}to{opacity:1}}@keyframes metal-out{from{opacity:1}to{opacity:0}}
#cairn-loader > .cairn-stack{z-index:2;position:absolute;right:max(24px,env(safe-area-inset-right));bottom:max(24px,env(safe-area-inset-bottom));width:clamp(60px,9vmin,96px);height:clamp(60px,9vmin,96px);overflow:hidden}
${[0,1,2].map(i=>{const t=i*16;return `.stone-${i}{animation:stone-${i} 2.8s linear infinite}@keyframes stone-${i}{0%,${t}%{transform:translateY(-256px);opacity:0;animation-timing-function:cubic-bezier(.55,0,1,.45)}${t+1}%{opacity:1}${t+12}%{transform:translateY(0);opacity:1;animation-timing-function:ease-out}${t+14}%{transform:translateY(-7px);animation-timing-function:ease-in}${t+17}%{transform:translateY(0)}${t+19}%{transform:translateY(-1.5px)}${t+21}%,82%{transform:translateY(0);opacity:1;animation-timing-function:ease-in}99%,100%{transform:translateY(270px);opacity:0}}`}).join('')}
#status-progress,#status-splash{visibility:hidden}
</style></head>`).replace('<body>',`<body>${ring}<script>window.cairnSplashStart=performance.now();</script>`);
  html=html.replace('</body>',`<script>
let cairnDone=false, cairnImagesReady=false;
const cairnStudy=new URLSearchParams(location.search).has('fire-study')||new URLSearchParams(location.search).has('enemy-fire-study');
const cairnCheck=()=>{
 const status=document.getElementById('status');
 const failed=document.getElementById('status-notice')?.style.display==='block';
 if(failed){document.getElementById('cairn-loader')?.remove();cairnWatch.disconnect();return;}
 if(cairnDone||!cairnImagesReady||(!window.cairnMenuReady&&!cairnStudy)||(status&&getComputedStyle(status).display!=='none'))return;
 cairnDone=true;
 setTimeout(()=>{document.getElementById('cairn-loader')?.remove();cairnWatch.disconnect();},Math.max(0,6000-(performance.now()-window.cairnSplashStart)));
};
const cairnWatch=new MutationObserver(cairnCheck);
cairnWatch.observe(document.body,{subtree:true,childList:true,attributes:true,attributeFilter:['style','class']});
window.addEventListener('cairn-menu-ready',cairnCheck);
Promise.all(['maximum-force-logo.png','maximum-force-white-v2.png','studio-background.png'].map(src=>{
 const image=new Image();image.src=src;return image.decode();
})).then(()=>{cairnImagesReady=true;cairnCheck();}).catch(error=>{
 console.error('Splash image failed to load',error);
 document.getElementById('cairn-loader').setAttribute('aria-label','Artwork failed to load. Please reload.');
});
cairnCheck();
</script></body>`);
  fs.copyFileSync('godot/art/maximum-force-white-v2.png',path.join(path.dirname(file),'maximum-force-white-v2.png'));
  fs.copyFileSync('godot/art/maximum-force-reference.png',path.join(path.dirname(file),'maximum-force-reference.png'));
  fs.copyFileSync('godot/art/studio-background.png',path.join(path.dirname(file),'studio-background.png'));
  fs.copyFileSync('godot/art/maximum-force-logo.png',path.join(path.dirname(file),'maximum-force-logo.png'));
  for(const icon of ['cairn.ico','cairn-icon-32.png','cairn-icon-180.png','cairn-icon-256.png'])fs.copyFileSync('godot/art/branding/'+icon,path.join(path.dirname(file),icon));
  fs.cpSync('studies/backgrounds',path.join(path.dirname(file),'background-study'),{recursive:true});
  fs.writeFileSync(file,html);
 }
 console.log(`${target}: ${file}`);
}
