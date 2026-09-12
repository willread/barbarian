export async function createWaterfall(image,polygon,width,height){
 const canvas=document.createElement('canvas');canvas.width=width;canvas.height=height;
 const gl=canvas.getContext('webgl',{alpha:false,antialias:false,preserveDrawingBuffer:true});if(!gl)throw Error('WebGL required for the waterfall study');
 const vertex=`attribute vec2 p;varying vec2 uv;void main(){uv=(p+1.)*.5;gl_Position=vec4(p.x,-p.y,0.,1.);}`;
 const fragment=`precision highp float;varying vec2 uv;uniform sampler2D base,mask;uniform float time,enabled,showMask;
 float coverage(vec2 p){return texture2D(mask,p).r;}
 void main(){
 vec3 original=texture2D(base,uv).rgb;
 float m=coverage(uv);
 // Confine motion to neutral bright water and mist; preserve dark rocks inside the outline.
 float water=smoothstep(.13,.44,dot(original,vec3(.2126,.7152,.0722)));
 m*=water;
 float phase=fract(time/2.);
 float a=phase,b=fract(phase+.5);
 float wa=1.-abs(a*2.-1.),wb=1.-abs(b*2.-1.);
 float splash=smoothstep(.52,.58,uv.y);
 vec2 direction=mix(vec2(.003,.06),vec2((uv.x-.16)*.7,.008),splash);
 vec2 pa=uv-direction*(a-.5),pb=uv-direction*(b-.5);
 // Never drag adjacent masonry into the moving water.
 vec3 ca=mix(original,texture2D(base,pa).rgb,coverage(pa));
 vec3 cb=mix(original,texture2D(base,pb).rgb,coverage(pb));
 vec3 moving=(ca*wa+cb*wb)/max(.001,wa+wb);
 vec3 result=mix(original,moving,m*enabled*.88);
 if(showMask>.5)result=mix(result,vec3(.15,.95,.72),m*.6);
 gl_FragColor=vec4(result,1.);
 }`;
 function shader(type,source){const s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s}
 const program=gl.createProgram();gl.attachShader(program,shader(gl.VERTEX_SHADER,vertex));gl.attachShader(program,shader(gl.FRAGMENT_SHADER,fragment));gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(program));gl.useProgram(program);
 const buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,1,-1,-1,1,-1,1,1,-1,1,1]),gl.STATIC_DRAW);const loc=gl.getAttribLocation(program,'p');gl.enableVertexAttribArray(loc);gl.vertexAttribPointer(loc,2,gl.FLOAT,false,0,0);
 const mask=document.createElement('canvas');mask.width=width;mask.height=height;const ctx=mask.getContext('2d');ctx.fillStyle='black';ctx.fillRect(0,0,width,height);ctx.filter='blur(3px)';ctx.fillStyle='white';ctx.beginPath();polygon.forEach(([x,y],i)=>i?ctx.lineTo(x*width,y*height):ctx.moveTo(x*width,y*height));ctx.closePath();ctx.fill();
 function texture(source,unit,name){gl.activeTexture(gl.TEXTURE0+unit);gl.bindTexture(gl.TEXTURE_2D,gl.createTexture());gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,source);gl.uniform1i(gl.getUniformLocation(program,name),unit)}texture(image,0,'base');texture(mask,1,'mask');
 return {canvas,render(time,enabled=true,showMask=false){gl.uniform1f(gl.getUniformLocation(program,'time'),time);gl.uniform1f(gl.getUniformLocation(program,'enabled'),+enabled);gl.uniform1f(gl.getUniformLocation(program,'showMask'),+showMask);gl.drawArrays(gl.TRIANGLES,0,6);return canvas},checkLoop(){this.render(0);let a=new Uint8Array(width*height*4);gl.readPixels(0,0,width,height,gl.RGBA,gl.UNSIGNED_BYTE,a);this.render(2);let b=new Uint8Array(a.length);gl.readPixels(0,0,width,height,gl.RGBA,gl.UNSIGNED_BYTE,b);let max=0;for(let i=0;i<a.length;i++)max=Math.max(max,Math.abs(a[i]-b[i]));return max;}};
}
