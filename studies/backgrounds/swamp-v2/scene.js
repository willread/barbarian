// Separate scenery, atmosphere, actors and foreground passes; no combat dependencies.
export const duration = 24;
export const screens = [
  {name:'Leechwater Crossing', file:'../swamp-v1/01-crossing.png', mood:'Something lives here.', motion:'A submerged wake crosses the pool and dissolves into bubbles. Gnats gather and disperse; reeds stir beside a fallen foreground branch.', effects:['Creature wake & bubbles','Gnat swarms'], bounds:[[.3,.49,.55,.12],[.3,.39,.55,.18]]},
  {name:'The Witch’s Hollow', file:'../swamp-v1/02-hollow.png', mood:'Something practices here.', motion:'The hollow exhales fungal spores. Bone charms sway at different rhythms beneath a close moss-draped bough.', effects:['Spore breaths','Swaying bone charms'], bounds:[[.17,.28,.37,.31],[.17,.2,.34,.27]]},
  {name:'The Drowned Procession', file:'../swamp-v1/03-procession.png', mood:'Something died here.', motion:'The left funeral bell swings without wind; the right stays still. Falling droplets leave rings in the flooded avenue. Foreground framing is sparse.', effects:['Solitary funeral bell','Droplets & splash rings'], bounds:[[.17,.12,.13,.24],[.17,.32,.65,.28]]},
  {name:'The Sunken Throne', file:'../swamp-v1/04-throne.png', mood:'Something still rules here.', motion:'Roots swell beneath the empty throne, followed by an amber sap pulse and outward water rings. The heavy foreground roots breathe with them.', effects:['Breathing roots & sap','Root-water ripples'], bounds:[[.17,.29,.66,.34],[.15,.56,.7,.06]]}
];
export const assetFiles={branch:'fallen-branch.png',bough:'hanging-bough.png',roots:'roots.png',bell:'bell.png',clean:'procession-clean.png'};
const TAU=Math.PI*2, fract=x=>x-Math.floor(x), rand=i=>fract(Math.sin(i*127.1+311.7)*43758.5453);
const phase=(t,period,offset=0)=>fract(((t%duration)+duration)%duration/period+offset);
function strokeEllipse(g,x,y,rx,ry,alpha){g.beginPath();g.ellipse(x,y,rx,ry,0,0,TAU);g.strokeStyle=`rgba(186,190,160,${alpha})`;g.lineWidth=.00065;g.stroke()}
function haze(g,x,y,rx,ry,alpha,color='#b7b6a0'){
  g.save();g.translate(x,y);g.scale(rx,ry);g.globalAlpha=alpha;
  const gradient=g.createRadialGradient(0,0,0,0,0,1);gradient.addColorStop(0,color);gradient.addColorStop(1,'transparent');g.fillStyle=gradient;g.fillRect(-1,-1,2,2);g.restore();
}
function normalized(g,fn){g.save();g.scale(g.canvas.width,g.canvas.height);fn();g.restore()}

// Feathered texture patches are created once, not on every animation frame.
// Only the erased bell region uses the generated clean plate, preserving all other pixels.
export function prepareAssets(images,art,makeCanvas){
  function patch(image,box,edge){
    const [x,y,w,h]=box,c=makeCanvas(Math.ceil(w*1280),Math.ceil(h*720)),g=c.getContext('2d');
    g.drawImage(image,x*image.width,y*image.height,w*image.width,h*image.height,0,0,c.width,c.height);
    const mask=makeCanvas(c.width,c.height),m=mask.getContext('2d');
    m.translate(c.width/2,c.height/2);m.scale(c.width/2,c.height/2);
    const gradient=m.createRadialGradient(0,0,edge,0,0,1);gradient.addColorStop(0,'white');gradient.addColorStop(1,'transparent');m.fillStyle=gradient;m.fillRect(-1,-1,2,2);
    g.globalCompositeOperation='destination-in';g.drawImage(mask,0,0);
    return {image:c,box};
  }
  return {...art,cleanPatch:patch(art.clean,[.163,.114,.133,.252],.8),rootPatches:[patch(images[3],[.17,.405,.27,.19],.55),patch(images[3],[.565,.405,.27,.19],.55)]};
}

export function drawScenery(g,index,image,assets,time,enabled=[true,true]){
  g.drawImage(image,0,0,g.canvas.width,g.canvas.height);
  normalized(g,()=>{
    if(index===2){
      const patch=assets.cleanPatch;g.drawImage(patch.image,...patch.box);
      // Pendulum rotation in physical pixel coordinates avoids aspect-ratio skew.
      g.save();g.translate(.225,.124);g.scale(1,1280/720);
      g.rotate(enabled[0]?Math.sin(phase(time,8)*TAU)*.075:0);
      g.strokeStyle='#25291e';g.lineWidth=.002;g.beginPath();g.moveTo(0,0);g.lineTo(0,.03);g.stroke();
      g.filter='brightness(0.65) saturate(0.55)';
      g.drawImage(assets.bell,-.044,.024,.088,.114);g.restore();
    }
    if(index===3&&enabled[0]){
      const b=(1-Math.cos(phase(time,8)*TAU))/2;
      assets.rootPatches.forEach(({image:root,box:[x,y,w,h]},i)=>{
        g.save();g.translate(x+w/2,y+h);g.scale(1+.009*b*(i?1:.8),1+.028*b);g.drawImage(root,-w/2,-h,w,h);g.restore();
      });
    }
  });
}

export function drawAtmosphere(g,index,time,enabled=[true,true]){
  normalized(g,()=>{
    if(index===0){
      if(enabled[0]){
        const p=phase(time,12),travel=Math.min(1,p/.72),x=.34+travel*.43,y=.54+Math.sin(travel*Math.PI)*.022;
        if(p<.72){
          const fade=Math.sin(travel*Math.PI);
          // Two diverging ripples imply a body below water, never expose a creature.
          for(let i=0;i<7;i++){
            const tip=x-i*.009;g.beginPath();g.moveTo(tip-.045,y-.009-i*.0018);g.quadraticCurveTo(tip-.009,y-.002,tip,y);g.quadraticCurveTo(tip-.009,y+.003,tip-.045,y+.009+i*.0018);
            g.strokeStyle=`rgba(177,184,152,${fade*(.36-i*.035)})`;g.lineWidth=.0007;g.stroke();
          }
          haze(g,x-.021,y,.028,.003,fade*.1,'#151b13');
        } else {
          const q=(p-.72)/.28;
          for(let i=0;i<6;i++){const a=fract(q+i*.13);strokeEllipse(g,.753+rand(i)*.029,.54+rand(i+6)*.012,.002+a*.018,.0008+a*.004,Math.sin(q*Math.PI)*Math.sin(a*Math.PI)*.4)}
        }
      }
      if(enabled[1])for(let i=0;i<55;i++){
        const p=phase(time,6,rand(i)),a=TAU*p,cluster=Math.sin(phase(time,12)*TAU)*.5+.5;
        const x=.49+(rand(i+3)-.5)*(.22+cluster*.18)+Math.sin(a*2+i)*.011,y=.46+(rand(i+81)-.5)*(.055+cluster*.04)+Math.cos(a*3)*.008;
        haze(g,x,y,.0012,.0017,.2+rand(i+55)*.34,'#c9bea0');
      }
    }
    if(index===1){
      if(enabled[0]){
        for(let i=0;i<85;i++){
          const p=phase(time,8,i*.003),spread=.012+p*.105,x=.338+(rand(i+23)-.5)*spread*2+Math.sin(p*TAU+i)*.012,y=.544-p*.21+rand(i+4)*.025;
          const envelope=Math.pow(Math.sin(p*Math.PI),1.8);
          haze(g,x,y,.001+rand(i)*.001,.0014+rand(i)*.001,envelope*.58,'#cbc29d');
        }
        for(let i=0;i<5;i++){const p=phase(time,8,i*.065);haze(g,.338+Math.sin(p*TAU+i)*.014,.53-p*.14,.018+p*.04,.007+p*.018,Math.sin(p*Math.PI)*.024,'#b9b496')}
      }
      if(enabled[1]){
        // Small physical charms, staggered six- and eight-second pendulum loops.
        [[.218,.226,6,.4],[.466,.273,8,1.8]].forEach(([x,y,period,offset])=>{
          g.save();g.translate(x,y);g.scale(1,1280/720);g.rotate(Math.sin(phase(time,period)*TAU+offset)*.08);
          g.strokeStyle='#423e29';g.lineWidth=.0008;g.beginPath();g.moveTo(0,0);g.lineTo(0,.035);g.stroke();
          g.strokeStyle='#8e896c';g.lineWidth=.0025;g.beginPath();g.moveTo(-.001,.036);g.lineTo(.001,.054);g.stroke();
          for(const yy of [.036,.054]){g.fillStyle='#a39b7c';g.beginPath();g.ellipse(0,yy,.0026,.0018,0,0,TAU);g.fill()}g.restore();
        });
      }
    }
    if(index===2&&enabled[1])for(let i=0;i<24;i++){
      const p=phase(time,3,rand(i)),x=i<12?.195+rand(i+2)*.074:.737+rand(i+2)*.068,y0=i<12?.335:.37,y1=.567+rand(i+3)*.012;
      if(p<.72){const q=p/.72,y=y0+(y1-y0)*q*q;g.strokeStyle=`rgba(178,195,184,${Math.sin(q*Math.PI)*.65})`;g.lineWidth=.00065;g.beginPath();g.moveTo(x,y);g.lineTo(x,y+.008);g.stroke()}
      else{const q=(p-.72)/.28;strokeEllipse(g,x,y1,.001+q*.015,.0006+q*.0035,Math.sin(q*Math.PI)*.45)}
    }
    if(index===3){
      const p=phase(time,8);
      if(enabled[0]){
        const light=Math.pow(Math.max(0,Math.sin((p-.18)*TAU)),6);
        g.save();g.globalCompositeOperation='screen';
        [[.452,.316,.009,.044],[.544,.333,.008,.038],[.476,.427,.016,.024]].forEach(([x,y,w,h])=>haze(g,x,y,w,h,.025+light*.19,'#b17a2c'));g.restore();
      }
      if(enabled[1])for(let i=0;i<5;i++){
        const q=phase(time,8,i*.06+.48),fade=Math.sin(q*Math.PI)*.3;
        strokeEllipse(g,.5,.582,.045+q*.28,.002+q*.011,fade);
      }
    }
  });
}

function reeds(g,x,y,mirror,time,strength=1){
  g.save();g.translate(x,y);g.scale(mirror,1);
  for(let i=0;i<11;i++){
    const h=.06+rand(i+18)*.055,lean=(rand(i+41)-.5)*.045+Math.sin(phase(time,6)*TAU+i*.4)*.003*strength;
    g.beginPath();g.moveTo(i*.003,0);g.quadraticCurveTo(i*.003+lean*.3,-h*.55,i*.003+lean,-h);
    g.lineWidth=.0012;g.strokeStyle=i%2?'#303829':'#454833';g.stroke();
    if(i%3===0){g.lineWidth=.003;g.strokeStyle='#24291d';g.beginPath();g.moveTo(i*.003+lean,-h);g.lineTo(i*.003+lean*.93,-h+.015);g.stroke()}
  }g.restore();
}

export function drawForeground(g,index,assets,time,{visible=true,motion=true}={}){
  if(!visible)return;
  normalized(g,()=>{
    g.filter='brightness(0.8) saturate(0.7)';
    if(index===0){
      g.drawImage(assets.branch,-.075,.862,.34,.24);
      reeds(g,.99,1,-1,time,motion?1:0);
    }
    if(index===1){
      // Horizontal mesh strips preserve bark texture; displacement grows below attachment.
      const im=assets.bough,x=.765,y=.105,w=.27,h=.40;
      for(let sy=0;sy<im.height;sy+=12){const sh=Math.min(12,im.height-sy),v=sy/im.height;
        const sway=motion?Math.sin(phase(time,8)*TAU+v*1.8)*.0025*v*v:0;
        g.drawImage(im,0,sy,im.width,sh,x+sway,y+v*h,w,sh/im.height*h+.0003);
      }
    }
    if(index===2){reeds(g,.008,1,1,time,motion?.7:0);g.drawImage(assets.branch,-.105,.954,.22,.11)}
    if(index===3){
      const b=motion?(1-Math.cos(phase(time,8)*TAU))/2:0;
      for(const [x,flip,w,h]of [[-.038,1,.33,.205],[1.038,-1,.29,.18]]){
        g.save();g.translate(x,1.02);g.scale(flip,1);g.scale(1+b*.007,1+b*.023);g.drawImage(assets.roots,0,-h,w,h);g.restore();
      }
    }
  });
}

export function drawActor(g,x=.5,y=.84){
  // A neutral human-scale silhouette, drawn BEFORE foreground for occlusion review.
  normalized(g,()=>{
    g.save();g.translate(x,y);g.scale(1,1280/720);g.fillStyle='#bba276';g.strokeStyle='#26291e';g.lineWidth=.0015;
    g.beginPath();g.arc(0,-.112,.009,0,TAU);g.fill();g.stroke();
    g.beginPath();g.moveTo(-.013,-.101);g.lineTo(.013,-.101);g.lineTo(.018,-.06);g.lineTo(.008,-.046);g.lineTo(.013,0);g.lineTo(.003,0);g.lineTo(-.002,-.042);g.lineTo(-.009,0);g.lineTo(-.019,0);g.lineTo(-.014,-.051);g.lineTo(-.02,-.067);g.closePath();g.fill();g.stroke();
    g.lineWidth=.006;g.strokeStyle='#bba276';g.beginPath();g.moveTo(.01,-.096);g.lineTo(.03,-.065);g.moveTo(-.01,-.096);g.lineTo(-.028,-.07);g.stroke();g.restore();
  });
}
