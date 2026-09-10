'use client';
import {useEffect} from 'react';
export default function Home(){useEffect(()=>{
  let disposed=false;
  const scripts:HTMLScriptElement[]=[];
  const load=(src:string)=>new Promise<void>((resolve,reject)=>{
    const script=document.createElement('script');script.src=src;script.onload=()=>resolve();script.onerror=reject;
    scripts.push(script);document.body.appendChild(script);
  });
  load('/mechanics.js?v=8').then(()=>{if(!disposed)return load('/animation.js?v=8')}).then(()=>{if(!disposed)return load('/hero-rig.js?v=8')}).then(()=>{if(!disposed)return load('/blood.js?v=1')}).then(()=>{if(!disposed)return load('/game.js?v=14')}).catch(()=>{
    const button=document.getElementById('start');if(button)button.textContent='UNABLE TO LOAD · PLEASE REFRESH';
  });
  return()=>{disposed=true;scripts.forEach(script=>script.remove());(window as Window & {stopGame?:()=>void}).stopGame?.()};
},[]);return <main>
<header><a href="/">⚔ <b>ASHEN AXE</b></a><span>A SWORD & SORCERY ARCADE</span><small>● &nbsp; SINGLE PLAYER</small></header>
<section className="heading"><div><small>THE BORDERLANDS</small><h1>Valley of the Fallen</h1></div><span>01 <small>/ THE ASHEN LEGION</small></span></section>
<div id="stage"><canvas id="game" width="1440" height="810" aria-label="Battle arena. WASD to move, J attack, Space jump, hold K to channel magic."/><div id="hud" hidden><div><small>KAEL · THE EXILE</small><div className="health"><i id="health"/></div><div id="magic"><div className="magic-label"><span>STORMCALL</span><b id="magic-state">HOLD K</b></div><div id="magic-meter" role="progressbar" aria-label="Stormcall charge" aria-valuemin={0} aria-valuemax={100} aria-valuenow={100}><i id="magic-fill"/></div><span className="magic-hint">Weapon hits +12 · Kills +20</span></div></div><div className="score"><small>SCORE</small><strong id="score">000000</strong><small id="wave">WAVE 1 / 4</small></div></div>
<div id="title"><small>STEEL. SORCERY. SURVIVAL.</small><h2>ASHEN<br/><em>AXE</em></h2><p>The old gods are dead.<br/>Their armies are not.</p><button id="start" className="primary" disabled>SUMMONING THE WORLD…</button><span>Four waves. One last stand.</span></div>
<div id="overlay" hidden><small id="outcome"/><h2 id="message"/><p id="result"/><button className="primary" id="resume">RESUME BATTLE</button></div>
<div className="stage-bottom"><small>✧ &nbsp; THE FORGOTTEN KINGDOM</small><div><label className="weapon-choice">WEAPON <select id="weapon" aria-label="Weapon"><option value="axe">Axe</option><option value="sword">Sword</option></select></label><button id="sound" aria-label="Enable sound">SOUND OFF</button><button id="pause" aria-label="Pause battle">Ⅱ</button><button id="full" aria-label="Fullscreen">⛶</button></div></div></div>
<div className="touch">{[['a','←'],['w','↑'],['s','↓'],['d','→'],['j','ATTACK'],[' ','JUMP'],['k','HOLD MAGIC']].map(([key,label])=><button key={key} data-key={key}>{label}</button>)}</div>
<footer><div><kbd>W A S D</kbd><p>Move<small>double-tap left/right to run</small></p></div><div><kbd>J</kbd><p>Attack<small>tap after each strike</small></p></div><div><kbd>SPACE</kbd><p>Jump<small>J in air · J + Space: back attack</small></p></div><div><kbd>K</kbd><p>Magic<small>hold to cast / break stun · hits refill</small></p></div><div><kbd>P</kbd><p>Pause</p></div></footer><div className="footnote"><span>FORGED IN THE AGE OF SWORD & SORCERY</span><span>Headphones recommended ↗</span></div></main>}
