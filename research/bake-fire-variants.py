import sys
import numpy as np
from PIL import Image
from pathlib import Path
W,H=128,192
Y,X=np.mgrid[:H,:W].astype(float)
u=np.zeros((H,W));v=u.copy();t=u.copy();sm=u.copy()
variant=int(sys.argv[1]) if len(sys.argv)>1 else 0
rng=np.random.default_rng(173+variant*719)
centres=[[48,77],[37,61,90],[56,71],[32,53,75,94]][variant]
buoyancy=[.15,.105,.19,.12][variant]
shear=[.045,-.038,.025,-.02][variant]
def sample(a,x,y):
 x=np.clip(x,0,W-1.001);y=np.clip(y,0,H-1.001);ix=x.astype(int);iy=y.astype(int);fx=x-ix;fy=y-iy
 return a[iy,ix]*(1-fx)*(1-fy)+a[iy,ix+1]*fx*(1-fy)+a[iy+1,ix]*(1-fx)*fy+a[iy+1,ix+1]*fx*fy
fire=Image.new('RGBA',(W*8,H*8));smoke=Image.new('RGBA',(W*8,H*8))
for step in range(224):
 for center in centres:
  source=np.exp(-((X-center-(4+variant)*np.sin(step*(.11+variant*.027)+center))**2/55+(Y-(170+variant*2))**2/(10+variant*3)))
  t+=source*(.22+.1*rng.random());sm+=source*.12
 v-=t*buoyancy;u+=(np.sin(Y*.11+step*.14)*.035+shear)*t
 curl=np.gradient(v,axis=1)-np.gradient(u,axis=0)
 gy,gx=np.gradient(np.abs(curl));length=np.sqrt(gx*gx+gy*gy)+1e-5
 u+=gy/length*curl*.17;v-=gx/length*curl*.17
 div=(np.gradient(u,axis=1)+np.gradient(v,axis=0))*.5;p=np.zeros_like(t)
 for _ in range(12):p=(np.roll(p,1,0)+np.roll(p,-1,0)+np.roll(p,1,1)+np.roll(p,-1,1)-div)*.25
 u-=np.gradient(p,axis=1);v-=np.gradient(p,axis=0)
 bx=X-u;by=Y-v
 u=sample(u,bx,by)*.993;v=sample(v,bx,by)*.993
 t=sample(t,bx,by)*.978;sm=sample(sm,bx,by)*.992
 u[:,[0,-1]]=0;v[[0,-1]]=0;t[:,[0,-1]]=0;t[[0,-1]]=0
 if step>=160:
  heat=np.clip(t/1.35,0,1);a=np.clip((heat-.045)*4,0,1)
  # Temperature-driven red/orange/ivory, emissive flame and independent smoke.
  r=np.interp(heat,[0,.15,.4,.75,1],[45,145,245,255,255]);g=np.interp(heat,[0,.15,.4,.75,1],[0,12,63,177,248]);b=np.interp(heat,[0,.15,.4,.75,1],[0,0,4,54,213])
  rgba=np.stack([r,g,b,a*255],axis=-1).astype('uint8');idx=step-160
  fire.paste(Image.fromarray(rgba),(idx%8*W,idx//8*H))
  alpha=np.clip(sm*.42,0,.45)*(1-a*.85)*255
  gray=np.clip(70+sm*18,70,95);rgba=np.stack([gray,gray*.95,gray*.9,alpha],axis=-1).astype('uint8')
  smoke.paste(Image.fromarray(rgba),(idx%8*W,idx//8*H))
fire.save(f'public/art/fluid-fire-v2-{variant}.png')
print('Baked 64 frames: incompressible 2D advection, buoyancy, vorticity confinement; separate temperature emission and smoke.')
