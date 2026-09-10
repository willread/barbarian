/* Enemy commitments and run composition; shared hitboxes remain in mechanics.js. */
(() => {
  const M=window.AshenMechanics;
  const roster={
    legion:{name:'Ashen Legion',hp:16,speed:.5},
    bone:{name:'Bone Soldier',hp:12,speed:.43},
    shield:{name:'Shield Revenant',hp:16,speed:.32},
    marauder:{name:'Axe Marauder',hp:20,speed:.83},
    champion:{name:'Cairn Champion',hp:84,speed:.47},
  };
  const strike=(ticks,from,to,damage,reach,extra={})=>({ticks,from,to,damage,reach,box:[0,reach,-55,52],...extra});
  Object.assign(M.attacks,{
    boneCut:strike(57,25,31,2,40,{lunge:.8}), boneFollow:strike(70,34,40,3,42),
    shieldBash:strike(72,29,38,3,30,{lunge:2.3,bash:true,knock:true}),shieldCut:strike(57,22,28,2,35),
    marauderChop:strike(57,23,31,3,46,{lunge:1}),marauderOverhead:strike(81,32,39,5,42,{overhead:true,knock:true}),
    marauderRush:strike(78,32,41,4,43,{lunge:3,rush:true,knock:true}),
    championCleave:strike(77,33,42,5,53,{lunge:1.2}),championExecution:strike(97,44,51,8,43,{overhead:true,knock:true}),
    championCheck:strike(61,23,30,3,27,{lunge:1.8,bash:true,knock:true}),
  });
  const shuffle=(a,rng)=>{for(let i=a.length-1;i>0;i--){const j=Math.floor(rng()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a};
  function plan(rng=Math.random){
    const order=shuffle(['bone','shield','marauder'],rng);
    return order.map((kind,index)=>shuffle([kind,kind,...Array.from({length:index+1},()=>['legion','bone','shield','marauder'][Math.floor(rng()*4)])],rng)).concat([['champion']]);
  }
  function init(e,kind){Object.assign(e,{kind,boss:kind==='champion',turnTicks:0,brace:0,moveIndex:0,retreatTicks:0,phaseTwo:false});return e}
  function guarding(e){return e.kind==='shield'&&e.hp>0&&(!e.attack||(e.attack.bash&&e.attack.age<=e.attack.to))&&!e.hurtTicks&&!e.down&&!e.recovering&&!e.turnTicks}
  function block(e,attack,attacker){
    if(!guarding(e)||attack.magic||!attacker||(attacker.x-e.x)*e.dir<=0)return false;
    e.x-=e.dir*(attack.knock?35:10);e.brace=14;e.aiRest=Math.max(e.aiRest,12);return true;
  }
  function intent(e,h,engaged){
    if(e.kind==='legion')return M.enemyIntent(e,h,engaged);
    e.brace=Math.max(0,e.brace-1);
    if(e.hp<=0||e.down||e.hurtTicks||e.recovering)return [0,0];
    if(e.kind==='champion'&&e.hp<=e.max*.5)e.phaseTwo=true;
    const x=(h.x-e.x)/M.SCALE,y=(h.y-e.y)/M.SCALE,face=x<0?-1:1;
    if(e.attack){
      // Marauders may aim during preparation, never during the committed blow.
      if(e.kind==='marauder'&&e.attack.age<e.attack.from-6){e.dir=face;e.attack.direction=face}
      return [0,0];
    }
    if(e.dir!==face){
      e.turnTicks++;
      if(e.turnTicks<(e.kind==='shield'?22:10))return [0,0];
      e.dir=face;e.turnTicks=0;e.aiRest=Math.max(e.aiRest,8);
    }else e.turnTicks=0;
    if(e.aiRest||h.hp<=0||h.down)return [0,0];
    if(!engaged)return [Math.abs(x)<75?-face:Math.abs(x)>95?face:0,Math.abs(y)<12?(e.id%2?1:-1):Math.abs(y)>24?-Math.sign(y):0];
    if(Math.abs(x)>70&&Math.abs(y)<9)e.retreatTicks++;else e.retreatTicks=Math.max(0,e.retreatTicks-2);
    if(e.kind==='marauder'&&e.retreatTicks>65&&Math.abs(x)<150){M.begin(e,'marauderRush');e.retreatTicks=0;return [0,0]}
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
    if(a.lunge&&a.age>=a.from-4&&a.age<=a.to){e.velocityX=a.direction*a.lunge;e.x+=e.velocityX*M.SCALE}
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
      if(a.type==='marauderChop')next='marauderOverhead';
      if(a.type==='championCleave'&&e.phaseTwo)next='championExecution';
    }
    if(next)M.begin(e,next);else e.aiRest=e.kind==='marauder'?25:e.kind==='champion'?36:30;
  }
  function pose(e){
    let frame=0;
    if(e.down)frame=e.down.ground?(e.hp>0&&e.down.ground<=20?14:13):12;
    else if(e.hp<=0)frame=13;
    else if(e.hurtTicks||e.recovering)frame=11;
    else if(e.brace)frame=15;
    else if(e.turnTicks)frame=2;
    else if(e.attack){const a=e.attack;frame=a.age<a.from?(a.overhead?8:a.bash?15:5):a.age<=a.to?(a.overhead?9:6):(a.overhead?10:7)}
    else if(e.moving)frame=1+Math.floor(e.stride*4)%4;
    return {atlas:'enemy-'+e.kind+'-v1',frame};
  }
  window.AshenEnemies={roster,plan,init,guarding,block,intent,motion,finish,pose};
})();
