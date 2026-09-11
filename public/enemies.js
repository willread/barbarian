/* Enemy commitments and run composition; shared hitboxes remain in mechanics.js. */
(() => {
  const M=window.AshenMechanics;
  const roster={
    legion:{name:'Ashen Legion',hp:16,speed:.5},
    bone:{name:'Bone Soldier',hp:8,speed:.43},
    shield:{name:'Shield Revenant',hp:16,speed:.32},
    marauder:{name:'Axe Marauder',hp:20,speed:.83},
    champion:{name:'Cairn Champion',hp:84,speed:.47},
  };
  const strike=(ticks,from,to,damage,reach,extra={})=>({ticks,from,to,damage,reach,box:[0,reach,-55,52],...extra});
  Object.assign(M.attacks,{
    boneCut:strike(57,25,31,2,40,{lunge:.8}), boneFollow:strike(70,34,40,3,42),
    shieldBash:strike(72,29,38,3,30,{lunge:2.3,bash:true,knock:true}),shieldCut:strike(57,22,28,2,35),
    marauderChop:strike(60,23,31,5,46,{lunge:1}),marauderOverhead:strike(102,32,39,7,42,{overhead:true,knock:true}),
    marauderRush:strike(72,30,53,5,36,{lunge:4.2,rush:true,knock:true}),
    championCleave:strike(77,33,42,5,53,{lunge:1.2}),championExecution:strike(97,44,51,8,43,{overhead:true,knock:true}),
    championCheck:strike(61,23,30,3,27,{lunge:1.8,bash:true,knock:true}),
  });
  const shuffle=(a,rng)=>{for(let i=a.length-1;i>0;i--){const j=Math.floor(rng()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a};
  function plan(rng=Math.random){
    const themes=shuffle(['legion','bone','shield','marauder','bone','shield','marauder'],rng);
    return themes.map((kind,index)=>shuffle([kind,kind,...Array.from({length:1+Math.floor(index/2)},()=>['legion','bone','shield','marauder'][Math.floor(rng()*4)])],rng)).concat([['champion']]);
  }
  function init(e,kind){Object.assign(e,{kind,boss:kind==='champion',turnTicks:0,brace:0,moveIndex:0,retreatTicks:0,phaseTwo:false,hopCooldown:90+Math.random()*90,hopTicks:0,thinkTicks:0,tactic:0,rushCooldown:50,variant:'regular',size:1,speedFactor:1});return e}
  function variant(e,rng=Math.random){
    if(e.boss)return e;
    const roll=rng();e.variant=roll<.18?'brute':roll<.4?'swift':'regular';
    e.size=e.variant==='brute'?1.18:e.variant==='swift'?.9:1;
    e.speedFactor=e.variant==='swift'?1.3:e.variant==='brute'?.85:1;
    e.hp=e.max=Math.round(e.hp*(e.variant==='brute'?1.45:e.variant==='swift'?.85:1));return e;
  }
  function guarding(e){if(e.kind!=='shield'||e.hp<=0||e.hurtTicks||e.down||e.recovering||e.turnTicks)return false;const frame=pose(e).frame;return [0,1,2,3,4,15].includes(frame)&&(!e.attack||e.attack.bash&&e.attack.age<e.attack.from);}
  function block(e,attack,attacker){
    if(!guarding(e)||attack.magic||!attacker||(attacker.x-e.x)*e.dir<=0)return false;
    e.x-=e.dir*(attack.knock?35:10);e.brace=14;e.aiRest=Math.max(e.aiRest,12);return true;
  }
  function intent(e,h,engaged){
    if(e.kind==='legion')return M.enemyIntent(e,h,engaged);
    e.brace=Math.max(0,e.brace-1);e.hopCooldown=Math.max(0,e.hopCooldown-1);e.rushCooldown=Math.max(0,e.rushCooldown-1);
    if(e.hopTicks && !e.down && !e.hurtTicks){e.hopTicks--;e.height=Math.sin(e.hopTicks/20*Math.PI)*9;e.x-=e.dir*2.4*M.SCALE;e.moving=true;return [0,0];}
    if(e.hopTicks){e.hopTicks=0;e.height=0;}
    if(e.hp<=0||e.down||e.hurtTicks||e.recovering)return [0,0];
    if(e.kind==='champion'&&e.hp<=e.max*.5)e.phaseTwo=true;
    const x=(h.x-e.x)/M.SCALE,y=(h.y-e.y)/M.SCALE,face=x<0?-1:1;
    if(e.attack){
      // Marauders may aim during preparation, never during the committed blow.
      if(e.kind==='marauder'&&!e.attack.rush&&!e.rushCombo&&e.attack.age<e.attack.from-6){e.dir=face;e.attack.direction=face}
      return [0,0];
    }
    if(e.aiRest && e.kind==='marauder')return [0,0];
    if(e.dir!==face){
      e.turnTicks++;
      if(e.turnTicks<(e.kind==='shield'?22:10))return [0,0];
      e.dir=face;e.turnTicks=0;e.aiRest=Math.max(e.aiRest,8);
    }else e.turnTicks=0;
    if(e.aiRest||h.hp<=0||h.down)return [0,0];
    if(!engaged)return [Math.abs(x)<75?-face:Math.abs(x)>95?face:0,Math.abs(y)<12?(e.id%2?1:-1):Math.abs(y)>24?-Math.sign(y):0];
    if(e.kind==='bone'){
      if(--e.thinkTicks<=0){e.thinkTicks=25+Math.floor(Math.random()*45);e.tactic=Math.random();
        if(!e.hopCooldown&&Math.abs(x)<64&&Math.abs(y)<12&&(h.attack||h.velocityX*face<0)&&Math.random()<.6){e.hopTicks=20;e.hopCooldown=210+Math.random()*100;return [0,0]}}
      if(e.tactic<.2&&Math.abs(x)>38)return [0,0];
      if(e.tactic>.8&&Math.abs(x)<58)return [-face,0];
    }
    if(e.kind==='marauder'&&!e.rushCooldown&&Math.abs(y)<7&&Math.abs(x)>38&&Math.abs(x)<150){
      M.begin(e,'marauderRush');e.rushCooldown=260;e.rushCombo=true;e.roarPending=true;return [0,0];
    }
    const range=e.kind==='champion'?48:e.kind==='shield'?34:43;
    if(Math.abs(y)<5&&Math.abs(x)<range){
      let type=e.kind==='bone'?'boneCut':e.kind==='shield'?'shieldBash':'marauderChop';
      if(e.kind==='champion')type=Math.abs(x)<23?'championCheck':(e.moveIndex++%2?'championExecution':'championCleave');
      M.begin(e,type);e.aiChain=0;return [0,0];
    }
    return [Math.abs(x)>range-4?face:Math.abs(x)<range-12?-face:0,Math.abs(y)>2?Math.sign(y):0];
  }
  function motion(e){
    if(e.kind==='legion'){M.stepMotion(e,0,0);return}
    const a=e.attack;if(!a)return;
    e.moving=false;e.velocityX=0;e.velocityY=0;
    if(a.lunge&&a.age>=(a.rush?a.from:a.from-4)&&a.age<=a.to){e.velocityX=a.direction*a.lunge;e.x+=e.velocityX*M.SCALE}
  }
  function finish(e,a,h){
    if(e.kind==='legion'){
      if(a.connected&&h.hp>0&&!h.down&&e.aiChain<2&&a.type!=='enemyCharge'){e.aiChain++;M.begin(e,e.aiChain===1?'enemyFollow':'enemyFinish')}
      else {e.aiChain=0;e.aiRest=40}return;
    }
    let next=null;
    if(h.hp>0){
      if(a.type==='boneCut'&&a.connected&&!h.down)next='boneFollow';
      if(a.type==='shieldBash'&&a.connected&&Math.random()<.45&&!h.down)next='shieldCut';
      if(a.type==='marauderRush')next='marauderChop';
      if(a.type==='marauderChop')next='marauderOverhead';
      if(a.type==='championCleave'&&e.phaseTwo)next='championExecution';
    }
    if(next)M.begin(e,next);else {e.rushCombo=false;e.aiRest=e.kind==='marauder'?72:e.kind==='champion'?36:20+Math.floor(Math.random()*25);}
  }
  function pose(e){
    let frame=0;
    if(e.down)frame=e.down.ground?(e.hp>0&&e.down.ground<=20?14:13):12;
    else if(e.hp<=0)frame=13;
    else if(e.hurtTicks||e.recovering)frame=11;
    else if(e.brace&&(!e.attack||e.attack.age<e.attack.from))frame=15;
    else if(e.turnTicks)frame=2;
    else if(e.attack){const a=e.attack;frame=a.age<a.from?(a.overhead?8:a.bash?15:5):a.age<=a.to?(a.overhead?9:6):(a.overhead?10:7)}
    else if(e.hopTicks)frame=3;
    else if(e.moving)frame=1+Math.floor(e.stride*4)%4;
    return {atlas:'enemy-'+e.kind+'-v1',frame};
  }
  window.AshenEnemies={roster,plan,init,variant,guarding,block,intent,motion,finish,pose};
})();
