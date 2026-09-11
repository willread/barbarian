/* Dynamic stone lettering. DOM labels remain the accessible source of truth. */
(()=>{
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
   const scale=3,pad=Math.max(8,size*.16),c=document.createElement('canvas'),g=c.getContext('2d');
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
   const fw=Math.ceil(w/scale),fh=Math.ceil((h+firePad)/scale),flames=document.createElement('canvas');
   flames.width=fw*8;flames.height=fh*8;const flamesCtx=flames.getContext('2d');
   if(fire.complete&&fire.naturalWidth){
    for(let frame=0;frame<64;frame++){
     const ox=frame%8*fw,oy=Math.floor(frame/8)*fh;
     flamesCtx.save();flamesCtx.beginPath();flamesCtx.rect(ox,oy,fw,fh);flamesCtx.clip();
     const spacing=Math.max(4,Math.floor(size*scale*.18));
     for(let py=0;py<h;py+=spacing)for(let px=0;px<w;px+=spacing){
      if(alpha(px,py)<.5)continue;
      const r=spacing*.7;
      if(alpha(Math.floor(px-r),py)>.5&&alpha(Math.floor(px+r),py)>.5&&alpha(px,Math.floor(py-r))>.5&&alpha(px,Math.floor(py+r))>.5)continue;
      const phase=(frame/64+(px*7+py*13)/137)%1;
      const flameH=size*(.58+.12*Math.sin(px+py)),flameW=size*.43;
      // Two overlapping passages through the source avoid its hard loop seam.
      for(let pass=0;pass<2;pass++){
       const t=(phase+pass*.5)%1,idx=8+Math.floor(t*48);
       flamesCtx.globalAlpha=Math.sin(Math.PI*t)**2*.8;
       flamesCtx.drawImage(fire,idx%8*128,Math.floor(idx/8)*192,128,192,ox+px/scale-flameW/2,oy+(firePad+py)/scale+size*.13-flameH,flameW,flameH);
      }
     }
     flamesCtx.restore();
    }
   }
   result={sheet:flames,fw,fh,fire:flames.toDataURL(),url:c.toDataURL(),flame:flameMask.toDataURL(),fireHeight:(h+firePad)/scale,firePad:firePad/scale,width:c.width/scale,height:c.height/scale};
   if(cache.size>160)cache.clear();cache.set(key,result);
  }
  el._stoneFrames=result;
  if(!el.querySelector('.letter-fire')){const layer=document.createElement('canvas');layer.className='letter-fire';layer.setAttribute('aria-hidden','true');el.appendChild(layer);}
  el.classList.add('stone-label');el.style.setProperty('--stone-image',`url("${result.url}")`);
  el.style.setProperty('--stone-flames',`url("${result.fire}")`);
  el.style.setProperty('--stone-fire-height',result.fireHeight+'px');el.style.setProperty('--stone-fire-pad',result.firePad+'px');
  el.style.setProperty('--stone-fire-mask',`url("${result.flame}")`);
  el.style.setProperty('--stone-width',result.width+'px');el.style.setProperty('--stone-height',result.height+'px');
 }
 let frame=0;const refresh=()=>{if(frame)return;frame=requestAnimationFrame(()=>{frame=0;document.querySelectorAll(selector).forEach(paint);ensureSelection()});};
 let fireFrame=0;
 const animateFire=now=>{
  document.querySelectorAll('.stone-selected').forEach(el=>{
   const data=el._stoneFrames,layer=el.querySelector('.letter-fire');if(!data||!layer||!el.getClientRects().length)return;
   if(layer.width!==data.fw||layer.height!==data.fh){layer.width=data.fw;layer.height=data.fh;}
   const g=layer.getContext('2d'),at=window.matchMedia('(prefers-reduced-motion: reduce)').matches?16:(now/2600*64)%64;
   const first=Math.floor(at),fraction=at-first;g.clearRect(0,0,data.fw,data.fh);
   g.globalCompositeOperation='lighter';
   for(const [idx,opacity] of [[first,1-fraction],[(first+1)%64,fraction]]){g.globalAlpha=opacity;g.drawImage(data.sheet,idx%8*data.fw,Math.floor(idx/8)*data.fh,data.fw,data.fh,0,0,data.fw,data.fh);}
   g.globalAlpha=1;g.globalCompositeOperation='source-over';
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
