'use client';
import {useEffect} from 'react';
export default function Home(){useEffect(()=>{
  let disposed=false;
  const scripts:HTMLScriptElement[]=[];
  const load=(src:string)=>new Promise<void>((resolve,reject)=>{
    const script=document.createElement('script');script.src=src;script.onload=()=>resolve();script.onerror=reject;
    scripts.push(script);document.body.appendChild(script);
  });
  load('/mechanics.js?v=11').then(()=>{if(!disposed)return load('/animation.js?v=9')}).then(()=>{if(!disposed)return load('/hero-rig.js?v=11')}).then(()=>{if(!disposed)return load('/blood.js?v=4')}).then(()=>{if(!disposed)return load('/events.js?v=3')}).then(()=>{if(!disposed)return load('/enemies.js?v=3')}).then(()=>{if(!disposed)return load('/enemy-art.js?v=1')}).then(()=>{if(!disposed)return load('/enemy-rig.js?v=2')}).then(()=>{if(!disposed)return load('/game.js?v=25')}).catch(()=>{
    const button=document.getElementById('start');if(button)button.textContent='UNABLE TO LOAD · PLEASE REFRESH';
  });
  return()=>{disposed=true;scripts.forEach(script=>script.remove());(window as Window & {stopGame?:()=>void}).stopGame?.()};
},[]);return <main>
<div id="stage"><div className="arena"><canvas id="game" width="1440" height="810" aria-label="Battle arena. WASD to move, J attack, Space jump, press K at full charge to cast magic."/><div id="title"><small>STEEL. SORCERY. SURVIVAL.</small><h2>ASHEN<br/><em>AXE</em></h2><p>The old gods are dead.<br/>Their armies are not.</p><button id="start" className="primary" disabled>SUMMONING THE WORLD…</button><span>Seven battles. One final duel.</span></div>
<div id="overlay" hidden><small id="outcome"/><h2 id="message"/><p id="result"/><button className="primary" id="resume">RESUME BATTLE</button></div>
</div><div id="hud"><canvas id="game-hud" width="1440" height="296" aria-label="Health, mana, current weapon, score and wave"/>
<div className="sr-only"><div><div className="health"><i id="health"/></div><div id="magic"><b id="magic-state"/><div id="magic-meter" role="progressbar" aria-label="Mana" aria-valuemin={0} aria-valuemax={100} aria-valuenow={100}><i id="magic-fill"/></div></div></div><span id="score"/><span id="wave"/></div>
<button id="weapon" aria-label="Axe equipped. Activate to equip sword" title="Change weapon"/></div></div>
<div className="stage-bottom"><div><button id="sound" aria-label="Enable sound">SOUND OFF</button><button id="pause" aria-label="Pause battle">Ⅱ</button><button id="full" aria-label="Fullscreen">⛶</button></div></div>
<div className="touch">{[['a','←'],['w','↑'],['s','↓'],['d','→'],['j','ATTACK'],[' ','JUMP'],['k','MAGIC']].map(([key,label])=><button key={key} data-key={key}>{label}</button>)}</div>
<footer><div><kbd>W A S D</kbd><p>Move<small>double-tap left/right to run</small></p></div><div><kbd>J</kbd><p>Attack<small>tap after each strike</small></p></div><div><kbd>SPACE</kbd><p>Jump<small>J in air · J + Space: back attack</small></p></div><div><kbd>K</kbd><p>Magic<small>full charge · 1.5s burst / break stun</small></p></div><div><kbd>P</kbd><p>Pause</p></div></footer></main>}
