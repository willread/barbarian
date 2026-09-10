/* Full-body enemy paintings with rigid, independent equipment. */
(() => {
  const names={bone:'bone-soldier',shield:'shield-revenant',marauder:'axe-marauder',champion:'cairn-champion'};
  const heights={bone:270,shield:260,marauder:250,champion:310};
  const angles=[125,125,115,125,115,-35,95,135,-20,135,85,110,100,85,80,-40];
  class EnemyRig {
    constructor(atlases,equipment,heroWeapons){this.atlases=atlases;this.equipment=equipment;this.heroWeapons=heroWeapons}
    paint(ctx,f,p,opacity){
      const atlas=this.atlases[p.atlas],cel=atlas?.cels?.[p.frame];if(!cel){atlas?.paint(ctx,p.frame,292,opacity);return}
      const meta=window.AshenEnemyArt.bodySheets[names[f.kind]];
      const scale=heights[f.kind]/atlas.cels[0].image.height;
      const point=xy=>[(xy[0]-.5)*atlas.cellWidth*scale,(xy[1]*atlas.cellHeight-cel.top-cel.image.height)*scale];
      let right=meta.rightGrip[p.frame],left=meta.leftGrip?.[p.frame];
      if(f.kind==='shield'&&p.frame===6&&!f.attack?.bash)[right,left]=[left,right];
      const hand=point(right),shieldHand=left&&point(left),size=scale*atlas.cellWidth/atlas.scale;
      const blade=(back=false)=>{
        ctx.save();ctx.translate(...hand);ctx.rotate(angles[p.frame]*Math.PI/180);
        if(f.kind==='champion'){
          const w=this.heroWeapons.cels?.[0];if(w){const h=182;ctx.drawImage(w.image,-h*w.image.width/w.image.height*.5,-h*.76,h*w.image.width/w.image.height,h)}
        }else{
          const frame=f.kind==='bone'?0:f.kind==='shield'?1:2;
          const w=this.equipment.cels?.[frame];if(w){const grip=window.AshenEnemyArt.equipment.grips[frame],h=f.kind==='bone'?135:f.kind==='shield'?108:145,s=h/w.image.height;
            ctx.drawImage(w.image,(w.left-grip[0]*this.equipment.cellWidth)*s,(w.top-grip[1]*this.equipment.cellHeight)*s,w.image.width*s,h)}
        }
        ctx.restore();
      };
      const shield=()=>{
        const w=this.equipment.cels?.[3];if(!w||!shieldHand)return;
        const down=!!f.down;const angle=down?1.2:f.brace?-.23:f.attack?.bash&&p.frame===6?-.3:0;
        ctx.save();ctx.translate(...shieldHand);ctx.rotate(angle);
        const h=158,s=h/w.image.height,grip=window.AshenEnemyArt.equipment.grips[3];
        ctx.drawImage(w.image,(w.left-grip[0]*this.equipment.cellWidth)*s,(w.top-grip[1]*this.equipment.cellHeight)*s,w.image.width*s,h);ctx.restore();
      };
      ctx.save();ctx.globalAlpha=opacity;
      const shieldBehind=f.kind==='shield'&&(f.attack&&!f.attack.bash||[5,7,8,9,10,14].includes(p.frame));
      const bladeBehind=f.kind==='shield'&&f.attack?.bash;
      if(shieldBehind)shield();if(bladeBehind)blade();
      atlas.paint(ctx,p.frame,size,opacity);
      if(!bladeBehind){blade();ctx.save();ctx.beginPath();ctx.arc(...hand,6,0,Math.PI*2);ctx.clip();atlas.paint(ctx,p.frame,size,opacity);ctx.restore()}
      if(!shieldBehind)shield();ctx.restore();
    }
  }
  window.AshenEnemyRig=EnemyRig;
})();
