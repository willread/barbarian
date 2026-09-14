const $=id=>document.getElementById(id),canvas=$('effect');
const mud=$('mud').getContext('2d');
const gl=canvas.getContext('webgl2',{alpha:true,premultipliedAlpha:false});
let playing=true,t=0,last=performance.now();const duration=6.8;
function shader(type,source){const s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s}
try{
 if(!gl)throw Error('This preview requires WebGL 2.');
 const native=await(await fetch('/godot/shaders/mire_sequence.gdshader')).text();
 const fragment='#version 300 es\nprecision highp float;\nuniform sampler2D TEXTURE;uniform vec2 TEXTURE_PIXEL_SIZE;in vec2 UV;out vec4 COLOR;\n'+native.replace('shader_type canvas_item;','').replace(/uniform float (\w+)=[^;]+;/g,'uniform float $1;').replace(/uniform int (\w+)=[^;]+;/g,'uniform int $1;').replace('void fragment()','void main()');
 const vertex='#version 300 es\nlayout(location=0) in vec2 position;out vec2 UV;void main(){gl_Position=vec4(position,0,1);UV=vec2(position.x*.5+.5,.5-position.y*.5);}';
 const program=gl.createProgram();gl.attachShader(program,shader(gl.VERTEX_SHADER,vertex));gl.attachShader(program,shader(gl.FRAGMENT_SHADER,fragment));gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(program));gl.useProgram(program);
 const buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,1,-1,-1,1,-1,1,1,-1,1,1]),gl.STATIC_DRAW);gl.enableVertexAttribArray(0);gl.vertexAttribPointer(0,2,gl.FLOAT,false,0,0);
 const image=new Image();image.src='/godot/assets/mire-oil-v2.png';await image.decode();const tex=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,tex);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,image);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);gl.uniform2f(gl.getUniformLocation(program,'TEXTURE_PIXEL_SIZE'),1/image.width,1/image.height);
 const formation=gl.getUniformLocation(program,'formation'),pose=gl.getUniformLocation(program,'pose');
 function render(){
  let phase,label;
  if(t<1.4){phase=t/1.4;label='Buildup';}
  else if(t<1.85){phase=1+(t-1.4)/.15;label='Hands emerge';}
  else if(t<4.25){phase=3.5+.5*Math.cos((t-1.85)*Math.PI*2/1.2);label='Grasp';}
  else if(t<4.7){phase=4-(t-4.25)/.15;label='Reverse · hands withdraw';}
  else if(t<6.1){phase=1-(t-4.7)/1.4;label='Reverse · mire recedes';}
  else{phase=0;label='Gone';}
  gl.uniform1f(gl.getUniformLocation(program,"clock"),t);gl.uniform1f(formation,Math.max(0,Math.min(1,phase)));gl.uniform1f(pose,Math.max(0,Math.min(3,phase-1)));gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT);gl.enable(gl.BLEND);gl.blendFuncSeparate(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA,gl.ONE,gl.ONE_MINUS_SRC_ALPHA);gl.uniform1i(gl.getUniformLocation(program,'part'),0);gl.drawArrays(gl.TRIANGLES,0,6);mud.clearRect(0,0,960,480);mud.drawImage(canvas,0,0);gl.clear(gl.COLOR_BUFFER_BIT);for(const part of [2,1,4,3]){gl.uniform1i(gl.getUniformLocation(program,'part'),part);gl.drawArrays(gl.TRIANGLES,0,6);}
  $('phase').textContent=label+' · '+t.toFixed(2)+'s';$('timeline').value=t;
  const file=t<1.4?3:t<6.1?4:0;if($('hag').dataset.frame!==String(file)){$('hag').src='/godot/assets/enemy-witch-'+file+'.png';$('hag').dataset.frame=file;}
 }
 $('play').onclick=()=>{playing=!playing;$('play').textContent=playing?'Pause':'Play'};
 $('restart').onclick=()=>{t=0;render()};
 $('timeline').oninput=()=>{playing=false;$('play').textContent='Play';t=Number($('timeline').value);render()};
 $('floor').onchange=()=>$('stage').classList.toggle('checker',!$('floor').checked);
 $('actor').onchange=()=>$('hag').hidden=!$('actor').checked;
 function tick(now){if(playing)t=(t+Math.min(.05,(now-last)/1000)*Number($('speed').value))%duration;last=now;render();requestAnimationFrame(tick)}
 requestAnimationFrame(tick);
}catch(error){$('error').textContent=String(error);$('phase').textContent='Preview error';}
