/* Painted animation playback and region-masked, seamless background motion. */
(() => {
  const TAU = Math.PI * 2;
  const clamp = (n, a = 0, b = 1) => Math.max(a, Math.min(b, n));
  const smooth = n => { n = clamp(n); return n * n * (3 - 2 * n); };

  // Runtime chroma-key decoding for intentionally green-backed animation exports.
  // Original files remain intact; this is the renderer's texture-upload stage.
  function decodeChroma(image) {
    const canvas = document.createElement('canvas'); canvas.width = image.width; canvas.height = image.height;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(image, 0, 0);
    const pixels = ctx.getImageData(0, 0, image.width, image.height), data = pixels.data;
    for (let i = 0; i < data.length; i += 4) {
      if (!data[i + 3]) continue;
      const neutral = Math.max(data[i], data[i + 2]);
      const excess = data[i + 1] - neutral;
      // Key saturation as well as brightness: dark green in hair, fingers and
      // blade cutouts otherwise survives as opaque background fragments.
      if (excess > 8) {
        const saturation = excess / Math.max(1, data[i + 1]);
        const key = Math.max(clamp((excess - 8) / 64), clamp((saturation - .35) / .25));
        data[i + 3] = Math.round(data[i + 3] * (1 - key));
        // Remove spill entirely, including partially transparent edge pixels.
        data[i + 1] = neutral;
      }
    }
    ctx.putImageData(pixels, 0, 0);
    return canvas;
  }

  class Atlas {
    constructor(image, options = {}) {
      this.image = image;
      this.columns = options.columns || 4;
      this.rows = options.rows || 4;
      this.frames = options.frames || 16;
      this.cellWidth = image.width / this.columns;
      this.cellHeight = image.height / this.rows;
      this.pivots = options.pivots || Array.from({ length: this.frames }, () => [.5, .92]);
      // Register each complete painted cel to the ground at texture load time.
      // This changes the anchor only; no body part is cropped, scaled, or moved.
      if (!options.pivots && image.getContext) {
        const data = image.getContext('2d').getImageData(0, 0, image.width, image.height).data;
        for (let frame = 0; frame < this.frames; frame++) {
          const left = Math.round((frame % this.columns) * this.cellWidth);
          const top = Math.round(Math.floor(frame / this.columns) * this.cellHeight);
          const right = Math.round(left + this.cellWidth);
          for (let y = Math.min(image.height - 1, Math.floor(top + this.cellHeight - 1)); y >= top; y--) {
            let solid = 0;
            for (let x = left; x < right; x++) if (data[(y * image.width + x) * 4 + 3] > 160) solid++;
            if (solid >= 3) { this.pivots[frame][1] = (y + 1 - top) / this.cellHeight; break; }
          }
        }
      }
      this.scale = options.scale || 1;
      this.remap = options.remap;
      this.facing = options.facing || 1;
      this.breathRegion = options.breathRegion || [.61, .415, .30, .135];
      this.cels = this.extractWholeCels(image);
    }

    extractWholeCels(image) {
      if (!image.getContext) return null;
      const width = image.width, height = image.height;
      const pixels = image.getContext('2d').getImageData(0, 0, width, height).data;
      if (pixels.length !== width * height * 4) return null;
      const labels = new Int32Array(width * height), stack = new Int32Array(width * height);
      const components = [null];
      // Follow each connected, complete figure across nominal grid boundaries.
      // A long sword can overhang its cell without being amputated or appearing
      // in the neighboring frame. This is texture unpacking, never a limb rig.
      for (let seed = 0; seed < labels.length; seed++) {
        if (labels[seed] || pixels[seed * 4 + 3] < 40) continue;
        const id = components.length;
        let count = 0, sumX = 0, sumY = 0, left = width, right = 0, top = height, bottom = 0, tail = 1;
        stack[0] = seed; labels[seed] = id;
        while (tail) {
          const p = stack[--tail], x = p % width, y = Math.floor(p / width);
          count++; sumX += x; sumY += y;
          left = Math.min(left, x); right = Math.max(right, x); top = Math.min(top, y); bottom = Math.max(bottom, y);
          for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
            const nx = x + dx, ny = y + dy, n = ny * width + nx;
            if (nx < 0 || nx >= width || ny < 0 || ny >= height || labels[n] || pixels[n * 4 + 3] < 40) continue;
            labels[n] = id; stack[tail++] = n;
          }
        }
        components.push({ count, left, right, top, bottom,
          frame: Math.min(this.rows - 1, Math.floor(sumY / count / this.cellHeight)) * this.columns +
            Math.min(this.columns - 1, Math.floor(sumX / count / this.cellWidth)) });
      }
      const boxes = Array.from({ length: this.frames }, () => ({ left: width, right: 0, top: height, bottom: 0 }));
      for (const c of components.slice(1)) if (c.count >= 8 && boxes[c.frame]) {
        const b = boxes[c.frame];
        b.left = Math.min(b.left, c.left); b.right = Math.max(b.right, c.right);
        b.top = Math.min(b.top, c.top); b.bottom = Math.max(b.bottom, c.bottom);
      }
      if (boxes.some(b => b.right <= b.left || b.bottom <= b.top)) return null;
      return boxes.map((b, frame) => {
        const canvas = document.createElement('canvas');
        canvas.width = b.right - b.left + 1; canvas.height = b.bottom - b.top + 1;
        const ctx = canvas.getContext('2d'), cel = ctx.createImageData(canvas.width, canvas.height);
        for (let y = b.top; y <= b.bottom; y++) for (let x = b.left; x <= b.right; x++) {
          const p = y * width + x, component = components[labels[p]];
          if (!component || component.count < 8 || component.frame !== frame) continue;
          const dst = ((y - b.top) * canvas.width + x - b.left) * 4;
          for (let c = 0; c < 4; c++) cel.data[dst + c] = pixels[p * 4 + c];
        }
        ctx.putImageData(cel, 0, 0);
        return { image: canvas, left: b.left - (frame % this.columns) * this.cellWidth,
          top: b.top - Math.floor(frame / this.columns) * this.cellHeight };
      });
    }

    breathingCel(cel, time) {
      // One stable painting, continuously deformed around the chest. The face,
      // axe head and lower body stay pinned; no redrawn poses or detached parts.
      const phase = Math.floor((((time % 4.8) + 4.8) % 4.8) / 4.8 * 48);
      this.breathFrames ??= [];
      if (this.breathFrames[phase]) return this.breathFrames[phase];
      const source = cel.image, w = source.width, h = source.height;
      const pixels = source.getContext('2d').getImageData(0, 0, w, h).data;
      const canvas = document.createElement('canvas'); canvas.width = w; canvas.height = h;
      const context = canvas.getContext('2d'), out = context.createImageData(w, h);
      out.data.set(pixels);
      const inhale = (1 - Math.cos(phase / 48 * TAU)) / 2;
      const [cx, cy, rx, ry] = this.breathRegion;
      for (let y = Math.floor(h * (cy - ry)); y < Math.ceil(h * (cy + ry)); y++) for (let x = Math.floor(w * (cx - rx)); x < Math.ceil(w * (cx + rx)); x++) {
        const dx = (x / w - cx) / rx, dy = (y / h - cy) / ry;
        const weight = Math.max(0, 1 - dx * dx - dy * dy) ** 2 * inhale;
        if (!weight) continue;
        const sx = clamp(x - dx * w * .007 * weight, 0, w - 1);
        const sy = clamp(y + h * .004 * weight, 0, h - 1);
        const ix = Math.floor(sx), iy = Math.floor(sy), fx = sx - ix, fy = sy - iy;
        const dst = (y * w + x) * 4;
        let a = 0, r = 0, g = 0, b = 0;
        for (let j = 0; j < 2; j++) for (let i = 0; i < 2; i++) {
          const src = (Math.min(h - 1, iy + j) * w + Math.min(w - 1, ix + i)) * 4;
          const coverage = (i ? fx : 1 - fx) * (j ? fy : 1 - fy) * pixels[src + 3];
          a += coverage; r += pixels[src] * coverage; g += pixels[src + 1] * coverage; b += pixels[src + 2] * coverage;
        }
        if (a) { out.data[dst] = r / a; out.data[dst + 1] = g / a; out.data[dst + 2] = b / a; out.data[dst + 3] = a; }
        else out.data[dst + 3] = 0;
      }
      context.putImageData(out, 0, 0); this.breathFrames[phase] = canvas; return canvas;
    }

    paint(ctx, frame, size, alpha = 1, breathTime = null) {
      frame = Math.max(0, Math.min(this.frames - 1, frame));
      if (this.remap) frame = this.remap[frame];
      const [px, py] = this.pivots[frame] || [.5, .92];
      const w = size * this.scale;
      const h = w * this.cellHeight / this.cellWidth;
      ctx.globalAlpha = alpha;
      if (this.facing < 0) { ctx.save(); ctx.scale(-1, 1); }
      const cel = this.cels?.[frame];
      if (cel) {
        const scale = w / this.cellWidth;
        const texture = breathTime === null ? cel.image : this.breathingCel(cel, breathTime);
        ctx.drawImage(texture, (cel.left - px * this.cellWidth) * scale, -cel.image.height * scale,
          cel.image.width * scale, cel.image.height * scale);
      } else ctx.drawImage(this.image, (frame % this.columns) * this.cellWidth,
          Math.floor(frame / this.columns) * this.cellHeight, this.cellWidth, this.cellHeight,
          -px * w, -py * h, w, h);
      if (this.facing < 0) ctx.restore();
    }
  }

  // All channels repeat exactly after 48 seconds. The two offset phases avoid
  // a visible reset when an advected texture sample wraps back to its origin.
  const flowPhase = (time, duration) => {
    const p = ((time % duration) + duration) % duration / duration;
    return { a: p, b: (p + .5) % 1, blend: Math.abs(p * 2 - 1) };
  };

  class LivingBackground {
    constructor(image, width, height) {
      this.image = image;
      this.width = width;
      this.height = height;
      this.canvas = document.createElement('canvas');
      this.canvas.width = width;
      this.canvas.height = height;
      this.masks = this.createMasks();
      this.gl = this.canvas.getContext('webgl', { alpha: false, antialias: false, preserveDrawingBuffer: true });
      if (this.gl) {
        try { this.initGL(); } catch (error) { console.warn('Using canvas scenery animation', error); this.gl = null; }
      }
      if (!this.gl) {
        this.layer = document.createElement('canvas');
        this.layer.width = width;
        this.layer.height = height;
        this.layerCtx = this.layer.getContext('2d');
      }
    }

    createMasks() {
      const make = () => {
        const c = document.createElement('canvas');
        c.width = this.width; c.height = this.height;
        return c;
      };
      const masks = [make(), make(), make(), make()];
      const polygon = (index, points, blur = 3) => {
        const c = masks[index].getContext('2d');
        c.fillStyle = '#fff'; c.filter = `blur(${blur}px)`;
        c.beginPath();
        points.forEach(([x, y], i) => i ? c.lineTo(x * this.width, y * this.height) : c.moveTo(x * this.width, y * this.height));
        c.closePath(); c.fill(); c.filter = 'none';
      };
      // Sky follows mountain and statue silhouettes; eclipse and citadel are excluded.
      polygon(0, [[.169,0],[.854,0],[.846,.152],[.814,.182],[.799,.20],[.78,.25],
        [.765,.235],[.748,.055],[.731,.075],[.704,.095],[.684,.17],[.659,.251],
        [.636,.272],[.612,.267],[.579,.271],[.552,.239],[.512,.28],
        [.471,.184],[.448,.085],[.422,.102],[.396,.191],[.363,.179],
        [.308,.185],[.271,.112],[.259,.045],[.237,.054],[.192,.129],[.176,.104]], 5);
      const sky = masks[0].getContext('2d');
      sky.globalCompositeOperation = 'destination-out';
      sky.filter = 'blur(4px)'; sky.beginPath();
      sky.ellipse(this.width * .611, this.height * .123, this.width * .061, this.height * .091, 0, 0, TAU);
      sky.fill(); sky.globalCompositeOperation = 'source-over'; sky.filter = 'none';

      // Waterfalls: each narrow mask stays inside its painted channel.
      polygon(1, [[.292,.389],[.305,.39],[.313,.492],[.31,.511],[.291,.505]], 2);
      polygon(1, [[.501,.459],[.516,.46],[.515,.522],[.504,.534]], 2);
      polygon(1, [[.528,.46],[.543,.459],[.541,.527],[.531,.534]], 2);
      polygon(1, [[.248,.542],[.26,.545],[.27,.6],[.256,.599]], 2);
      polygon(1, [[.326,.543],[.341,.544],[.35,.602],[.335,.602]], 2);
      // Lake above the parapet, without including the foreground paving.
      polygon(2, [[.493,.556],[.565,.549],[.643,.567],[.638,.595],[.449,.599],[.441,.586]], 3);
      // Existing mist between rock shelves, kept away from columns and statues.
      polygon(3, [[.32,.489],[.37,.485],[.405,.515],[.45,.519],[.469,.556],
        [.456,.574],[.4,.553],[.375,.541],[.343,.546]], 12);
      polygon(3, [[.477,.515],[.513,.524],[.556,.525],[.589,.508],[.623,.515],
        [.637,.532],[.619,.551],[.569,.551],[.526,.548],[.486,.55]], 10);
      polygon(3, [[.592,.371],[.625,.365],[.655,.382],[.683,.377],[.686,.401],
        [.649,.418],[.616,.409],[.58,.419]], 10);
      return masks;
    }

    initGL() {
      const gl = this.gl;
      const compile = (type, source) => {
        const shader = gl.createShader(type); gl.shaderSource(shader, source); gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(shader));
        return shader;
      };
      const vertex = compile(gl.VERTEX_SHADER, `attribute vec2 position;
        varying vec2 uv; void main(){uv=vec2((position.x+1.0)*0.5,(1.0-position.y)*0.5);gl_Position=vec4(position,0.0,1.0);}`);
      const fragment = compile(gl.FRAGMENT_SHADER, `precision highp float;
        varying vec2 uv; uniform sampler2D painting; uniform sampler2D cloudMask;
        uniform sampler2D fallMask; uniform sampler2D lakeMask; uniform sampler2D fogMask;
        uniform float time;
        vec3 advect(vec2 at,vec2 travel,float period,float mask){
          float a=fract(time/period);float b=fract(a+0.5);float blend=abs(a*2.0-1.0);
          vec3 ca=texture2D(painting,at-travel*(a-0.5)*mask).rgb;
          vec3 cb=texture2D(painting,at-travel*(b-0.5)*mask).rgb;
          return mix(ca,cb,blend);
        }
        void main(){
          vec3 base=texture2D(painting,uv).rgb;
          float cloud=texture2D(cloudMask,uv).a;
          float fall=texture2D(fallMask,uv).a;
          float lake=texture2D(lakeMask,uv).a;
          float fog=texture2D(fogMask,uv).a;
          vec3 color=mix(base,advect(uv,vec2(0.018,-0.002),48.0,cloud),cloud*0.95);
          color=mix(color,advect(uv,vec2(0.0005,0.045),3.0,fall),fall*0.72);
          float theta=time*6.28318530718/8.0;
          vec2 ripple=vec2(sin(uv.y*920.0+theta)*0.00085+sin(uv.y*460.0-theta*2.0)*0.0004,
            sin(uv.x*290.0+theta)*0.00032)*lake;
          vec3 water=texture2D(painting,uv+ripple).rgb;
          water*=1.0+0.018*sin(uv.y*1100.0-theta*2.0)*lake;
          color=mix(color,water,lake*0.8);
          vec3 mist=advect(uv,vec2(0.016,0.002),24.0,fog);
          color=mix(color,mist,fog*0.58);
          gl_FragColor=vec4(color,1.0);
        }`);
      this.program = gl.createProgram();
      gl.attachShader(this.program, vertex); gl.attachShader(this.program, fragment); gl.linkProgram(this.program);
      if (!gl.getProgramParameter(this.program, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(this.program));
      gl.deleteShader(vertex); gl.deleteShader(fragment); gl.useProgram(this.program);
      this.buffer = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer);
      gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1, 1,-1, -1,1, -1,1, 1,-1, 1,1]), gl.STATIC_DRAW);
      const position = gl.getAttribLocation(this.program, 'position');
      gl.enableVertexAttribArray(position); gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);
      const names = ['painting','cloudMask','fallMask','lakeMask','fogMask'];
      this.textures = [this.image, ...this.masks].map((image, i) => {
        const texture = gl.createTexture(); gl.activeTexture(gl.TEXTURE0 + i); gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
        gl.uniform1i(gl.getUniformLocation(this.program, names[i]), i);
        return texture;
      });
      this.timeUniform = gl.getUniformLocation(this.program, 'time');
      gl.viewport(0, 0, this.width, this.height);
    }

    draw(ctx, time, reducedMotion = false) {
      if (reducedMotion) time = 0;
      if (this.gl && !this.gl.isContextLost()) {
        this.gl.uniform1f(this.timeUniform, time % 48);
        this.gl.drawArrays(this.gl.TRIANGLES, 0, 6);
        ctx.drawImage(this.canvas, 0, 0);
        return;
      }
      ctx.drawImage(this.image, 0, 0, this.width, this.height);
      if (!this.layerCtx || reducedMotion) return;
      const configs = [[48,22,-2,.65],[3,0,30,.55],[8,1.8,.3,.6],[24,17,2,.4]];
      configs.forEach(([duration, dx, dy, opacity], i) => {
        const { a, b, blend } = flowPhase(time, duration);
        const c = this.layerCtx;
        c.clearRect(0, 0, this.width, this.height);
        c.globalCompositeOperation = 'source-over'; c.globalAlpha = 1 - blend;
        c.drawImage(this.image, (a - .5) * dx, (a - .5) * dy, this.width, this.height);
        c.globalCompositeOperation = 'lighter'; c.globalAlpha = blend;
        c.drawImage(this.image, (b - .5) * dx, (b - .5) * dy, this.width, this.height);
        c.globalCompositeOperation = 'destination-in'; c.globalAlpha = 1;
        c.drawImage(this.masks[i], 0, 0);
        ctx.globalAlpha = opacity; ctx.drawImage(this.layer, 0, 0); ctx.globalAlpha = 1;
      });
    }

    dispose() {
      if (!this.gl) return;
      this.textures?.forEach(texture => this.gl.deleteTexture(texture));
      this.gl.deleteBuffer(this.buffer); this.gl.deleteProgram(this.program);
    }
  }

  // Gameplay timing comes from mechanics.js. These envelopes remain available
  // for standalone artwork previews; painted poses follow each live action.
  const clips = {
    heroAttack: { duration: 18 / 59.92274340431231, contact: 8 / 59.92274340431231 },
    enemyAttack: { duration: 51 / 59.92274340431231, contact: 29 / 59.92274340431231 },
    jump: { duration: 49 / 60, launch: 2 / 60, land: 47 / 60 },
    heroDeath: { duration: 1.2 },
    enemyDeath: { duration: 1.3 },
  };

  function jumpHeight(elapsed) {
    const { launch, land } = clips.jump;
    if (elapsed <= launch || elapsed >= land) return 0;
    const t = (elapsed - launch) * 60;
    // Sum the ROM's -5.5 launch velocity and +0.25 gravity, scaled for our scene.
    return Math.max(0, (5.5 * t - .125 * t * (t - 1)) * 1.87);
  }

  function pose(f, hero) {
    const motion = hero ? 'hero-reactions-unarmed-v8' : 'enemy-motion-v3';
    const combat = hero ? 'hero-reactions-unarmed-v8' : 'enemy-combat-v3';
    const reaction = frame => ({ atlas: combat, frame: hero ? frame - 8 : frame });
    if (f.down) {
      const d = f.down;
      const frame = d.ground ? (f.hp > 0 && d.ground <= 20 ? (d.ground > 10 ? 14 : 13) : 15) : d.vz < 0 ? 13 : 14;
      return reaction(frame);
    }
    if (f.hp <= 0) {
      const duration = hero ? clips.heroDeath.duration : clips.enemyDeath.duration;
      return reaction(12 + Math.min(3, Math.floor(f.death / duration * 4)));
    }
    if (f.recoil > 0) {
      const progress = clamp((f.hurtAge || 0) / (hero ? 11 : 25));
      return reaction(8 + Math.min(3, Math.floor(progress * 4)));
    }
    if (f.recovering > 0) return reaction(11);
    if (f.attack) {
      const a = f.attack, age = (a.age || 0) * (['air','back'].includes(a.type)?(a.animationRate||1):1);
      if (a.type === 'charge' || a.type === 'enemyCharge')
        return hero ? { atlas: 'hero-extra-unarmed-v8', frame: age < 3 ? 4 : 5 + Math.min(2, Math.floor((age - 3) / 10)) } : { atlas: 'enemy-charge-v5', frame: Math.min(3, Math.floor(age / 9)) };
      if (a.type === 'air') return { atlas: 'hero-extra-unarmed-v8', frame: age < 4 ? 8 : age < 7 ? 9 : age < 9 ? 10 : 11 };
      if (a.type === 'pommel') return { atlas: 'hero-close-unarmed-v8', frame: age < 7 ? 0 : age < 13 ? 1 : age <= 17 ? 2 : 3 };
      if (a.type === 'back') return { atlas: 'hero-close-unarmed-v8', frame: age < 14 ? 4 : age < 27 ? 5 : age <= 32 ? 6 : 7 };
      if (a.type === 'kick') return { atlas: 'hero-close-unarmed-v8', frame: age < 8 ? 8 : age < 15 ? 9 : age <= 20 ? 10 : 11 };
      if (hero) {
        // Keep the contact silhouette visible throughout the active window.
        const frame = a.type === 'whiff' ? Math.min(3, Math.floor(Math.max(0, age - 2) / 5)) :
          age < a.from ? 0 : age <= a.to ? 1 : age < a.ticks - 2 ? 2 : 3;
        return { atlas: 'hero-actions-unarmed-v8', frame: 4 + frame };
      }
      return { atlas: 'enemy-attack-v4', frame: age < a.from - 8 ? 0 : age < a.from ? 1 : age <= a.to ? 2 : 3 };
    }
    if (f.jump !== null) {
      const frame = f.air ? (f.air.age <= 2 ? 12 : f.air.land ? 15 : f.air.vz < 0 ? 13 : 14) :
        f.jump < clips.jump.launch ? 12 : f.jump < .18 ? 13 : f.jump < clips.jump.land ? 14 : 15;
      return { atlas: motion, frame: hero ? frame - 4 : frame };
    }
    if (f.moving) {
      if (hero && f.running) return { atlas: 'hero-extra-unarmed-v8', frame: Math.floor(f.stride * 4) % 4 };
      return { atlas: hero ? 'hero-walk-unarmed-v8' : 'enemy-walk-v4', frame: Math.floor(f.stride * 4) % 4 };
    }
    // Complete painted poses. No limb segmentation, mesh warping, or ghosted crossfade.
    return hero ? { atlas: 'hero-actions-unarmed-v8', frame: 0, breathing: true } :
      { atlas: 'enemy-walk-v4', frame: 0 };
  }

  window.AshenAnimation = { Atlas, LivingBackground, clips, pose, jumpHeight, flowPhase, decodeChroma, clamp, smooth };
})();

