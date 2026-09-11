'use client';
import {useEffect,useLayoutEffect,useState,useRef} from 'react';
export default function Home(){
const [loading,setLoading]=useState(true);
const [options,setOptions]=useState(false),[sound,setSound]=useState(false),[full,setFull]=useState(false);
const switching=useRef(false),mounted=useRef(true);
const departing=useRef<Animation[]>([]);
useLayoutEffect(()=>{departing.current.forEach(animation=>animation.cancel());departing.current=[];switching.current=false;},[options]);
const switchMenu=async(next:boolean)=>{
 if(switching.current||next===options)return;switching.current=true;
 const menu=document.querySelector(options?'.title-options':'.title-menu');
 const buttons=Array.from(menu?.querySelectorAll('button')||[]);
 const reduced=window.matchMedia('(prefers-reduced-motion: reduce)').matches;
 const animations=buttons.map((button,i)=>button.animate([{transform:'translateY(0)',opacity:1},{transform:'translateY(70cqw)',opacity:0}],{duration:reduced?0:260,delay:reduced?0:(buttons.length-1-i)*60+40,easing:'cubic-bezier(.55,0,1,.5)',fill:'forwards'}));
 departing.current=animations;
 await Promise.all(animations.map(animation=>animation.finished.catch(()=>{})));
 if(!mounted.current)return;
 setOptions(next);
};
useEffect(()=>{document.getElementById(options?'option-sound':'start')?.focus();},[options]);
useEffect(()=>{
 mounted.current=true;
 const fullscreen=()=>setFull(!!document.fullscreenElement);
 document.addEventListener('fullscreenchange',fullscreen);fullscreen();
 const node=document.getElementById('sound');const observer=new MutationObserver(()=>setSound(node?.textContent==='SOUND ON'));
 if(node)observer.observe(node,{childList:true,characterData:true,subtree:true});
 return()=>{mounted.current=false;observer.disconnect();document.removeEventListener('fullscreenchange',fullscreen)};
},[]);
useEffect(()=>{
  let disposed=false;
  const art=new Image();art.src='/art/cairn-title-v1.png';
  const readyCheck=setInterval(()=>{if(!disposed&&art.complete&&art.naturalWidth&&document.getElementById('start')?.getAttribute('disabled')===null&&document.documentElement.dataset.stoneReady==='true'){setLoading(false);clearInterval(readyCheck);}},80);
  const scripts:HTMLScriptElement[]=[];
  const load=(src:string)=>new Promise<void>((resolve,reject)=>{
    const script=document.createElement('script');script.src=src;script.onload=()=>resolve();script.onerror=reject;
    scripts.push(script);document.body.appendChild(script);
  });
  load('/mechanics.js?v=11').then(()=>{if(!disposed)return load('/animation.js?v=9')}).then(()=>{if(!disposed)return load('/environments.js?v=3')}).then(()=>{if(!disposed)return load('/hero-rig.js?v=12')}).then(()=>{if(!disposed)return load('/blood.js?v=5')}).then(()=>{if(!disposed)return load('/events.js?v=10')}).then(()=>{if(!disposed)return load('/enemies.js?v=5')}).then(()=>{if(!disposed)return load('/enemy-art.js?v=1')}).then(()=>{if(!disposed)return load('/enemy-rig.js?v=2')}).then(()=>{if(!disposed)return load('/game.js?v=50')}).then(()=>{if(!disposed)return load('/stone-text.js?v=25')}).catch(()=>{
    const button=document.getElementById('start');if(button)button.textContent='UNABLE TO LOAD · PLEASE REFRESH';
  });
  return()=>{disposed=true;clearInterval(readyCheck);scripts.forEach(script=>script.remove());(window as Window & {stopGame?:()=>void}).stopGame?.();(window as Window & {stopStoneText?:()=>void}).stopStoneText?.()};
},[]);return <main>
<div id="stage" data-loading={loading}><div className="arena"><div className="loading-screen" hidden={!loading} role="status" aria-label="Loading Cairn"><svg className="loading-ring" viewBox="0 0 120 120" aria-hidden="true"><defs><linearGradient id="ring-metal" x2=".8" y2="1"><stop stopColor="#e0ddd2"/><stop offset=".3" stopColor="#656961"/><stop offset=".5" stopColor="#252d2c"/><stop offset=".7" stopColor="#a3a79c"/><stop offset="1" stopColor="#343c39"/></linearGradient></defs><g fill="url(#ring-metal)" stroke="#a3a797" strokeWidth=".6">{Array.from({length:12},(_,i)=><path key={i} transform={`rotate(${i*30} 60 60)`} d="M54 25 L60 5 L65 26 L61 32 Z"/>)}<path fillRule="evenodd" d="M60 22a38 38 0 1 0 0 76a38 38 0 1 0 0-76M60 31a29 29 0 1 1 0 58a29 29 0 1 1 0-58"/></g></svg></div><canvas id="game" width="1440" height="810" aria-label="Battle arena. WASD to move, J attack, Space jump, press K at full charge to cast magic."/><div id="title" aria-label="Cairn title screen"><h1 className="sr-only">Cairn</h1><nav className="title-menu" aria-label="Main menu" hidden={options}><button id="start" disabled>LOADING…</button><button onClick={()=>switchMenu(true)}>OPTIONS</button></nav><div className="title-options" aria-label="Options" hidden={!options}><button id="option-sound" onClick={()=>document.getElementById('sound')?.click()}>SOUND: {sound?'ON':'OFF'}</button><button onClick={()=>document.getElementById('full')?.click()}>FULLSCREEN: {full?'ON':'OFF'}</button><button id="options-back" onClick={()=>switchMenu(false)}>BACK</button></div></div>

<div id="overlay" role="dialog" aria-labelledby="message" hidden><div className="pause-panel"><small id="outcome"/><h2 id="message"/><p id="result"/><button className="primary" id="resume">RESUME BATTLE</button><div id="pause-actions" hidden><button id="pause-sound">TOGGLE SOUND</button><button id="return-title">RETURN TO TITLE</button><p className="menu-hint">↑ ↓ Choose · Enter Select · Esc Resume</p></div></div></div>
</div><div id="hud"><canvas id="game-hud" width="1440" height="296" aria-label="Health, mana, current weapon, score and wave"/>
<div className="sr-only"><div><div className="health"><i id="health"/></div><div id="magic"><b id="magic-state"/><div id="magic-meter" role="progressbar" aria-label="Mana" aria-valuemin={0} aria-valuemax={100} aria-valuenow={100}><i id="magic-fill"/></div></div></div><span id="score"/><span id="wave"/></div>
<button id="weapon" aria-label="Axe equipped. Activate to equip sword" title="Change weapon"/></div></div>
<div className="stage-bottom"><div><button id="sound" aria-label="Enable sound">SOUND OFF</button><button id="pause" aria-label="Pause battle">Ⅱ</button><button id="full" aria-label="Fullscreen">⛶</button></div></div>
<div className="touch">{[['a','←'],['w','↑'],['s','↓'],['d','→'],['j','ATTACK'],[' ','JUMP'],['k','MAGIC']].map(([key,label])=><button key={key} data-key={key}>{label}</button>)}</div>
<footer><div><kbd>W A S D</kbd><p>Move<small>double-tap left/right to run</small></p></div><div><kbd>J</kbd><p>Attack<small>tap after each strike</small></p></div><div><kbd>SPACE</kbd><p>Jump<small>J in air · J + Space: back attack</small></p></div><div><kbd>K</kbd><p>Magic<small>full charge · 1.5s burst / break stun</small></p></div><div><kbd>P</kbd><p>Pause</p></div></footer></main>}


