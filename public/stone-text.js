/* Dynamic stone lettering. DOM labels remain the accessible source of truth. */
(()=>{
 delete document.documentElement.dataset.stoneReady;
 const selector='#title button,#overlay button,#overlay h2,#title h3,.font-sample';
 const fire=new Image();fire.src='/art/fluid-fire-v2-0.png';fire.onload=()=>{cache.clear();refresh()};
 const cache=new Map(),material=new Image();material.src='/art/menu-stone-material-v1.png';material.onload=()=>{cache.clear();refresh()};
 function paint(el){
  const label=el.textContent.trim();if(!label||!el.getClientRects().length)return;
  const style=getComputedStyle(el),size=parseFloat(style.fontSize),spacing=parseFloat(style.letterSpacing)||0;
  const family=el.dataset.stoneFont||'Anton';
  const key=label+'|'+size+'|'+spacing+'|'+family;
  let result=cache.get(key);
  if(!result){
   const scale=3,pad=Math.max(8,size*.28),c=document.createElement('canvas'),g=c.getContext('2d');
   const font=`900 ${size*scale}px "${family}", Georgia, serif`;g.font=font;
   const letters=[...label],width=letters.reduce((sum,ch)=>sum+g.measureText(ch).width,0)+Math.max(0,letters.length-1)*spacing*scale;
   c.width=Math.ceil(width+pad*scale*2);c.height=Math.ceil(size*scale*1.15+pad*scale*2);
   g.font=font;g.textBaseline='top';g.fillStyle='#fff';let x=pad*scale;
   for(const ch of letters){g.fillText(ch,x,pad*scale);x+=g.measureText(ch).width+spacing*scale;}
   const mask=g.getImageData(0,0,c.width,c.height),out=g.createImageData(c.width,c.height),w=c.width,h=c.height;
   const alpha=(x,y)=>x<0||y<0||x>=w||y>=h?0:mask.data[(y*w+x)*4+3]/255;
   const distance=new Float32Array(w*h);
   for(let i=0;i<distance.length;i++)distance[i]=mask.data[i*4+3]>127?1000:0;
   for(let y=1;y<h;y++)for(let x=1;x<w;x++){const i=y*w+x;distance[i]=Math.min(distance[i],distance[i-1]+1,distance[i-w]+1,distance[i-w-1]+1.414);}
   for(let y=h-2;y>=0;y--)for(let x=w-2;x>=0;x--){const i=y*w+x;distance[i]=Math.min(distance[i],distance[i+1]+1,distance[i+w]+1,distance[i+w+1]+1.414);}
   const bevelWidth=Math.max(2,size*scale*.045);
   const height=(x,y)=>Math.min(bevelWidth,distance[Math.max(0,Math.min(h-1,y))*w+Math.max(0,Math.min(w-1,x))]);
   g.clearRect(0,0,w,h);
   if(material.complete&&material.naturalWidth){const tile=size*scale*5;for(let y=0;y<h;y+=tile)for(let x=0;x<w;x+=tile)g.drawImage(material,x,y,tile,tile);}
   else {g.fillStyle='#8c7250';g.fillRect(0,0,w,h);}
   const tex=g.getImageData(0,0,w,h).data;
   for(let y=0;y<h;y++)for(let x=0;x<w;x++){
    const i=(y*w+x)*4,a=alpha(x,y);if(!a)continue;
    const dx=height(x+1,y)-height(x-1,y),dy=height(x,y+1)-height(x,y-1);
    const light=(dx*.55+dy*.8)/Math.sqrt(1+dx*dx+dy*dy);
    const edge=distance[y*w+x]<bevelWidth;
    const shine=edge?(light>.28?48:light<-.28?-36:8):0;
    const stone=tex[i]*.25+tex[i+1]*.6+tex[i+2]*.15;
    // Charcoal-grey stone with faint earthy dirt in the recesses.
    out.data[i]=stone*.78+shine*.72+8;out.data[i+1]=stone*.77+shine*.73+8;out.data[i+2]=stone*.74+shine*.75+7;out.data[i+3]=Math.round(a*255);
   }
   // Extruded sidewalls: a solid volume behind the lit front face.
   const face=document.createElement('canvas');face.width=w;face.height=h;
   face.getContext('2d').putImageData(out,0,0);
   const side=document.createElement('canvas');side.width=w;side.height=h;
   const sg=side.getContext('2d');sg.putImageData(mask,0,0);
   const sidePixels=sg.createImageData(w,h);
   for(let y=0;y<h;y++)for(let x=0;x<w;x++){
    const i=(y*w+x)*4;
    const mineral=tex[i]*.25+tex[i+1]*.6+tex[i+2]*.15;
    const shade=.23-.07*y/h;
    sidePixels.data[i]=mineral*shade+5;
    sidePixels.data[i+1]=mineral*shade+6;
    sidePixels.data[i+2]=mineral*shade+5;
    sidePixels.data[i+3]=mask.data[i+3];
   }
   sg.putImageData(sidePixels,0,0);
   g.clearRect(0,0,w,h);
   const depth=Math.max(5,Math.round(size*scale*.12));
   for(let z=depth;z>0;z--)g.drawImage(side,z*.55,z);
   g.drawImage(face,0,0);
   const flameMask=document.createElement('canvas');flameMask.width=w;const firePad=Math.ceil(size*scale*.7);flameMask.height=h+firePad;
   const fg=flameMask.getContext('2d');
   const glyph=document.createElement('canvas');glyph.width=w;glyph.height=h;glyph.getContext('2d').putImageData(mask,0,0);
   const rise=Math.max(6,Math.round(size*scale*.8));
   for(let dy=rise;dy>=0;dy--){fg.globalAlpha=.12+.75*(1-dy/rise);fg.drawImage(glyph,0,firePad-dy);fg.drawImage(glyph,-2,firePad-dy);fg.drawImage(glyph,2,firePad-dy);}
   const sidePad=Math.ceil(size*.35),fw=Math.ceil(w/scale)+sidePad*2,fh=Math.ceil((h+firePad)/scale)+sidePad;
   const sw=Math.max(96,Math.ceil(fw*.65)),sh=Math.ceil(fh*.65),sourceCanvas=document.createElement('canvas');sourceCanvas.width=sw;sourceCanvas.height=sh;
   const sourceCtx=sourceCanvas.getContext('2d'),sourceScaleX=sw/fw,sourceScaleY=sh/fh;
   // Match the displayed canvas even when the minimum simulation width applies.
   const fuelSpread=size*.025;
   // Expand each glyph contour, rather than scaling the word away from its face.
   for(let sample=0;sample<9;sample++){
    const angle=sample*Math.PI/4,radius=sample===8?0:fuelSpread;
    sourceCtx.drawImage(glyph,(sidePad+Math.cos(angle)*radius)*sourceScaleX,(firePad/scale+Math.sin(angle)*radius)*sourceScaleY,w/scale*sourceScaleX,h/scale*sourceScaleY);
   }
   const sourcePixels=sourceCtx.getImageData(0,0,sw,sh).data;
   const fuel=new Float32Array(sw*sh);
   for(let i=0;i<fuel.length;i++)fuel[i]=sourcePixels[i*4+3]/255;
   result={url:c.toDataURL(),flame:flameMask.toDataURL(),fw,fh,sw,sh,fuel,heat:new Float32Array(sw*sh),next:new Float32Array(sw*sh),time:0,last:0,pixels:sourceCtx.createImageData(sw,sh),fireWidth:fw,fireHeight:fh,firePad:firePad/scale,width:w/scale,height:h/scale};
   if(cache.size>160)cache.clear();cache.set(key,result);
  }
  el._stoneFrames=result;
  if(!el.querySelector('.letter-fire')){const layer=document.createElement('canvas');layer.className='letter-fire';layer.setAttribute('aria-hidden','true');el.appendChild(layer);}
  el.classList.add('stone-label');el.style.setProperty('--stone-image',`url("${result.url}")`);
  el.style.setProperty('--stone-fire-width',result.fireWidth+'px');
  el.style.setProperty('--stone-fire-height',result.fireHeight+'px');el.style.setProperty('--stone-fire-pad',result.firePad+'px');
  el.style.setProperty('--stone-fire-mask',`url("${result.flame}")`);
  el.style.setProperty('--stone-width',result.width+'px');el.style.setProperty('--stone-height',result.height+'px');
 }
 let frame=0;const refresh=()=>{if(frame)return;frame=requestAnimationFrame(()=>{frame=0;document.querySelectorAll(selector).forEach(paint);ensureSelection();if(material.complete&&material.naturalWidth&&fire.complete&&fire.naturalWidth&&document.fonts.check('900 64px "Anton"')&&!document.getElementById('start')?.disabled)document.documentElement.dataset.stoneReady='true';});};
 let fireFrame=0;
 const animateFire=now=>{
  document.querySelectorAll('.stone-selected').forEach(el=>{
   const data=el._stoneFrames,layer=el.querySelector('.letter-fire');if(!data||!layer||!el.getClientRects().length)return;
   const {sw,sh,fuel}=data;
   if(layer.width!==sw||layer.height!==sh){layer.width=sw;layer.height=sh;}
   const reduced=window.matchMedia('(prefers-reduced-motion: reduce)').matches;
   const steps=data.last?Math.min(4,Math.floor((now-data.last)/16.667)):35;
   if(reduced&&data.last)return;
   if(!steps)return;
   data.last=now;
   for(let step=0;step<steps;step++){
    data.time+=1/60;const src=data.heat,dst=data.next;
    for(let y=0;y<sh;y++)for(let x=0;x<sw;x++){
     const i=y*sw+x;
     // Continuous heat transport from every inked pixel, rising and curling.
     const drift=.16*Math.sin(x*.71+y*.33+data.time*7.1)+.12*Math.sin(x*.37-y*.19-data.time*9.3);
     const sx=Math.max(0,Math.min(sw-1.001,x+drift)),sy=Math.min(sh-1.001,y+.55);
     const ix=Math.floor(sx),iy=Math.floor(sy),fx=sx-ix,fy=sy-iy;
     const transported=(src[iy*sw+ix]*(1-fx)+src[iy*sw+ix+1]*fx)*(1-fy)+(src[(iy+1)*sw+ix]*(1-fx)+src[(iy+1)*sw+ix+1]*fx)*fy;
     const cooling=.065+.025*(.5+.5*Math.sin(x*.57+y*.13-data.time*6));
     dst[i]=Math.max(fuel[i]*(.88+.1*Math.sin(x*.11+data.time*3)),transported*.96-cooling,0);
     if(x===0||y===0||x===sw-1||y===sh-1)dst[i]=0;
    }
    data.heat=dst;data.next=src;
   }
   const pixels=data.pixels.data;
   for(let i=0;i<data.heat.length;i++){
    const heat=data.heat[i],k=i*4;
    pixels[k]=Math.min(255,heat*850);pixels[k+1]=Math.max(0,Math.min(255,(heat-.2)*430));pixels[k+2]=Math.max(0,(heat-.68)*650);
    pixels[k+3]=Math.min(230,Math.max(0,(heat-.07)*450));
   }
   layer.getContext('2d').putImageData(data.pixels,0,0);
  });fireFrame=requestAnimationFrame(animateFire);
 };fireFrame=requestAnimationFrame(animateFire);
 const menuButtons=()=>Array.from(document.querySelectorAll('#title button,#overlay button')).filter(el=>!el.disabled&&el.getClientRects().length);
 const select=item=>{document.querySelectorAll('.stone-selected').forEach(el=>{if(el!==item)el.classList.remove('stone-selected')});item?.classList.add('stone-selected');};
 const ensureSelection=()=>{const buttons=menuButtons();if(!buttons.some(el=>el.classList.contains('stone-selected')))select(buttons[0]);};
 const highlight=e=>{const item=e.target.closest?.('#title button,#overlay button');if(item&&!item.disabled){select(item);if(e.type==='pointerover'&&document.activeElement!==item)item.focus({preventScroll:true});}};
 document.addEventListener('pointerover',highlight);document.addEventListener('focusin',highlight);
 // Selection tremor uses translate independently of the drop transform.
 const lastQuake=new WeakMap();
 const quake=e=>{
  const item=e.target.closest?.('#title button,#overlay button');
  if(!item||item.disabled||window.matchMedia('(prefers-reduced-motion: reduce)').matches)return;
  if(e.type==='pointerover'&&item.contains(e.relatedTarget))return;
  const now=performance.now();if(now-(lastQuake.get(item)||-1000)<240)return;lastQuake.set(item,now);
  item.animate([
   {translate:'0 0'},{translate:'-2px 1px'},{translate:'2px -1px'},
   {translate:'-1.5px 0'},{translate:'1px 1px'},{translate:'-.5px 0'},
   {translate:'0 0'}
  ],{duration:210,easing:'linear'});
 };
 document.addEventListener('click',quake,true);
 document.addEventListener('pointerover',quake);document.addEventListener('focusin',quake);
 const observer=new MutationObserver(refresh);observer.observe(document.querySelector('main'),{childList:true,subtree:true,characterData:true,attributes:true,attributeFilter:['hidden','disabled']});
 window.addEventListener('resize',refresh);Promise.all(Array.from(document.querySelectorAll('[data-stone-font]')).map(el=>document.fonts.load(`900 64px "${el.dataset.stoneFont}"`)).concat([document.fonts.load('900 64px "Anton"')])).then(()=>{cache.clear();refresh()});refresh();
 window.stopStoneText=()=>{cancelAnimationFrame(fireFrame);document.removeEventListener('pointerover',highlight);document.removeEventListener('focusin',highlight);document.removeEventListener('click',quake,true);document.removeEventListener('pointerover',quake);document.removeEventListener('focusin',quake);observer.disconnect();window.removeEventListener('resize',refresh);cancelAnimationFrame(frame);cache.clear()};
})();


