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
      const excess = data[i + 1] - Math.max(data[i], data[i + 2]);
      if (excess > 20 && data[i + 1] > 90) {
        const key = clamp((excess - 20) / 80);
        data[i + 3] = Math.round(data[i + 3] * (1 - key));
        data[i + 1] = Math.min(data[i + 1], Math.max(data[i], data[i + 2]) + 12);
      }
    }
    ctx.putImageData(pixels, 0, 0);
    return canvas;
  }

  // Solve the knee from hip and planted ankle rather than rotating both legs
  // with a sine wave. The foot's world velocity is zero through the stance phase.
  function solveLeg(hip, ankle, upperLength, lowerLength, forward) {
    const dx = ankle[0] - hip[0], dy = ankle[1] - hip[1];
    const distance = clamp(Math.hypot(dx, dy), .001, upperLength + lowerLength - .01);
    const along = (upperLength * upperLength - lowerLength * lowerLength + distance * distance) / (2 * distance);
    const height = Math.sqrt(Math.max(0, upperLength * upperLength - along * along));
    return [hip[0] + dx / distance * along + forward * dy / distance * height,
      hip[1] + dy / distance * along - forward * dx / distance * height];
  }

  function footPath(phase, stride, lift) {
    phase = ((phase % 1) + 1) % 1;
    if (phase < .62) return { x: stride * (.31 - phase), y: 0, angle: 0, planted: true };
    const p = (phase - .62) / .38;
    return { x: stride * (-.31 + .62 * smooth(p)), y: -lift * Math.sin(Math.PI * p),
      angle: -.18 * Math.sin(Math.PI * p), planted: false };
  }

  class PaintedRig {
    constructor(image, isHero) {
      this.hero = isHero; this.forward = isHero ? 1 : -1;
      this.source = document.createElement('canvas'); this.source.width = 444; this.source.height = 444;
      this.source.getContext('2d').drawImage(image, 0, 0, image.width / 4, image.height / 2, 0, 0, 444, 444);
      const configs = isHero ? [
        { hip: [201,259], knee: [179,330], ankle: [176,405],
          upper: [[166,245],[211,245],[219,283],[201,339],[161,347],[151,306]],
          lower: [[159,320],[203,320],[202,374],[197,414],[158,421],[141,392]],
          foot: [[151,393],[198,394],[211,425],[190,435],[142,435],[144,414]] },
        { hip: [243,257], knee: [245,329], ankle: [257,410],
          upper: [[221,246],[266,242],[272,287],[265,338],[225,346],[214,292]],
          lower: [[223,319],[269,319],[282,403],[271,422],[234,422],[223,375]],
          foot: [[234,395],[275,395],[304,419],[293,435],[235,435],[229,419]] },
      ] : [
        { hip: [268,284], knee: [250,343], ankle: [232,414],
          upper: [[240,276],[287,278],[288,308],[273,354],[231,358],[222,332]],
          lower: [[233,333],[275,332],[267,386],[252,422],[214,424],[215,390]],
          foot: [[215,402],[253,401],[261,427],[240,440],[183,440],[190,422]] },
        { hip: [337,285], knee: [346,350], ankle: [352,421],
          upper: [[308,278],[352,277],[370,312],[372,356],[328,364],[313,319]],
          lower: [[329,343],[373,341],[376,405],[369,433],[334,437],[329,398]],
          foot: [[334,407],[372,407],[378,437],[361,446],[326,446],[331,425]] },
      ];
      this.legs = configs.map(config => ({ ...config,
        upperImage: this.part(config.upper), lowerImage: this.part(config.lower), footImage: this.part(config.foot),
        upperLength: Math.hypot(config.knee[0] - config.hip[0], config.knee[1] - config.hip[1]),
        lowerLength: Math.hypot(config.ankle[0] - config.knee[0], config.ankle[1] - config.knee[1]),
      }));
      this.body = this.part([[0,0],[444,0],[444,444],[0,444]]);
      const body = this.body.getContext('2d'); body.globalCompositeOperation = 'destination-out';
      for (const leg of this.legs) for (const points of [leg.upper, leg.lower, leg.foot]) {
        body.beginPath(); points.forEach(([x,y], i) => i ? body.lineTo(x,y) : body.moveTo(x,y)); body.closePath(); body.fill();
      }
      // Eliminate residual boot/skirt pixels outside the limb masks. Keep the
      // long cape behind the enemy, but never leave a stationary foot behind.
      body.globalCompositeOperation = 'source-over';
      if (isHero) body.clearRect(0, 285, 280, 159);
      else { body.clearRect(0, 375, 390, 69); body.clearRect(180, 295, 99, 149); body.clearRect(309, 298, 76, 146); }
      body.globalCompositeOperation = 'source-over';
      if (isHero) {
        this.axeHead = this.part([[284,253],[311,254],[338,269],[348,295],[321,294],
          [341,310],[325,337],[312,352],[284,356],[262,345],[250,329],[255,312],[273,299]]);
        const weapon = [[143,224],[192,226],[284,268],[284,254],[311,255],[337,269],
          [348,294],[320,294],[340,310],[324,337],[312,352],[284,356],
          [262,345],[250,328],[255,311],[265,306],[185,251],[142,241]];
        this.weapon = this.part(weapon);
        // Hands and weapon travel with the shoulders, never with a leg.
        for (const leg of this.legs) for (const image of [leg.upperImage, leg.lowerImage, leg.footImage]) {
          const c = image.getContext('2d'); c.globalCompositeOperation = 'destination-out';
          c.beginPath(); weapon.forEach(([x,y],i) => i ? c.lineTo(x,y) : c.moveTo(x,y)); c.closePath(); c.fill();
          c.globalCompositeOperation = 'source-over';
        }
      }
    }

    part(points) {
      const canvas = document.createElement('canvas'); canvas.width = 444; canvas.height = 444;
      const c = canvas.getContext('2d'); c.beginPath();
      points.forEach(([x,y], i) => i ? c.lineTo(x,y) : c.moveTo(x,y)); c.closePath(); c.clip();
      c.drawImage(this.source, 0, 0); return canvas;
    }

    segment(ctx, image, from, to, targetFrom, targetTo) {
      const angle = Math.atan2(targetTo[1] - targetFrom[1], targetTo[0] - targetFrom[0]) -
        Math.atan2(to[1] - from[1], to[0] - from[0]);
      ctx.save(); ctx.translate(targetFrom[0], targetFrom[1]); ctx.rotate(angle);
      ctx.translate(-from[0], -from[1]); ctx.drawImage(image, 0, 0); ctx.restore();
    }

    draw(ctx, stride, size, time, walking = true) {
      const scale = size / 444;
      const rootX = this.hero ? 222 : 297;
      ctx.save(); ctx.scale(scale * this.forward, scale); ctx.translate(-rootX, -432);
      if (!walking) {
        // Continuous 4.8-second inhalation: upper ribs expand under a stationary
        // pelvis; head, hands and axe follow by less than two display pixels.
        const breath = .5 - .5 * Math.cos(time / 4.8 * TAU);
        const slices = 40, step = 444 / slices;
        for (let row = 0; row < slices; row++) {
          const y = row * step;
          const weight = clamp((270 - y) / 120);
          const rib = Math.exp(-Math.pow((y - 156) / 61, 2));
          const sx = 1 + rib * breath * .009;
          ctx.drawImage(this.source, 0, y, 444, step + .2,
            rootX * (1 - sx), y - weight * breath * 2.2, 444 * sx, step + .45);
        }
        ctx.restore(); return;
      }
      const bob = (this.hero ? 12 : 4) + 1.3 * Math.cos(stride * TAU * 2);
      const drawLeg = (leg, index) => {
        const path = footPath(stride + index * .5, (this.hero ? 155 : 103) / scale, this.hero ? 27 : 23);
        const hip = [leg.hip[0], leg.hip[1] + bob];
        // Keep a little flexion available at maximum extension.
        const ankle = [leg.hip[0] + path.x * this.forward, leg.ankle[1] - 6 + path.y];
        const knee = solveLeg(hip, ankle, leg.upperLength, leg.lowerLength, this.forward);
        this.segment(ctx, leg.upperImage, leg.hip, leg.knee, hip, knee);
        this.segment(ctx, leg.lowerImage, leg.knee, leg.ankle, knee, ankle);
        ctx.save(); ctx.translate(ankle[0], ankle[1]); ctx.rotate(path.angle * this.forward);
        ctx.translate(-leg.ankle[0], -leg.ankle[1]); ctx.drawImage(leg.footImage, 0, 0); ctx.restore();
      };
      drawLeg(this.legs[0], 0);
      ctx.save(); ctx.translate(0, bob); ctx.drawImage(this.body, 0, 0); ctx.restore();
      drawLeg(this.legs[1], 1);
      if (this.weapon) { ctx.save(); ctx.translate(0, bob); ctx.drawImage(this.weapon, 0, 0); ctx.restore(); }
      ctx.restore();
    }
  }

  class Atlas {
    constructor(image, options = {}) {
      this.image = image;
      this.columns = options.columns || 4;
      this.rows = options.rows || 2;
      this.frames = options.frames || 8;
      this.cellWidth = image.width / this.columns;
      this.cellHeight = image.height / this.rows;
      this.pivots = options.pivots || Array.from({ length: this.frames }, () => [.5, .94]);
      this.scale = options.scale || 1;
      this.remap = options.remap;
      this.extensions = options.extensions || {};
    }

    paint(ctx, frame, size, alpha = 1) {
      frame = Math.max(0, Math.min(this.frames - 1, frame));
      if (this.remap) frame = this.remap[frame];
      const [px, py] = this.pivots[frame] || [.5, .94];
      const w = size * this.scale;
      const h = w * this.cellHeight / this.cellWidth;
      ctx.globalAlpha = alpha;
      ctx.drawImage(this.image, (frame % this.columns) * this.cellWidth,
        Math.floor(frame / this.columns) * this.cellHeight, this.cellWidth, this.cellHeight,
        -px * w, -py * h, w, h);
      // A weapon may cross the nominal cell boundary without its fighter doing
      // so. Include only its narrow, explicitly registered continuation region.
      for (const [x,y,width,height] of this.extensions[frame] || []) {
        ctx.drawImage(this.image, x * this.cellWidth, y * this.cellHeight,
          width * this.cellWidth, height * this.cellHeight,
          (x - frame % this.columns - px) * w,
          (y - Math.floor(frame / this.columns) - py) * h, width * w, height * h);
      }
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

  const clips = {
    heroAttack: { duration: .76, contact: .38 },
    enemyAttack: { duration: 1.0, contact: .50 },
    jump: { duration: .96, launch: .14, land: .78 },
    heroDeath: { duration: 1.2 },
    enemyDeath: { duration: 1.3 },
  };

  function jumpHeight(elapsed) {
    const { launch, land } = clips.jump;
    if (elapsed < launch || elapsed > land) return 0;
    return 118 * Math.sin(Math.PI * (elapsed - launch) / (land - launch));
  }

  function pose(f, hero) {
    if (f.hp <= 0) {
      const duration = hero ? clips.heroDeath.duration : clips.enemyDeath.duration;
      const frame = Math.min(hero ? 3 : 7, Math.floor(f.death / duration * (hero ? 4 : 8)));
      return { atlas: hero ? 'hero-reactions' : 'enemy-reactions', frame: hero ? frame + 4 : frame };
    }
    if (f.recoil > 0) return { atlas: hero ? 'hero-reactions' : 'enemy-reactions', frame: hero ? 4 : 0 };
    if (f.attack) {
      const duration = hero ? clips.heroAttack.duration : clips.enemyAttack.duration;
      return { atlas: hero ? 'hero-attack' : 'enemy-attack', frame: Math.min(7, Math.floor(f.attack.elapsed / duration * 8)) };
    }
    if (f.jump !== null) {
      const frame = f.jump < .14 ? 0 : f.jump < .31 ? 1 : f.jump < .76 ? 2 : 3;
      return { atlas: 'hero-reactions', frame };
    }
    if (f.moving) return { atlas: hero ? 'hero-walk' : 'enemy-walk', frame: Math.floor(f.stride * 8) % 8 };
    if (hero) {
      const position = ((f.clock % 4.8) / 4.8) * 8;
      return { atlas: 'hero-idle', frame: Math.floor(position), next: (Math.floor(position) + 1) % 8, blend: smooth(position % 1) };
    }
    return { atlas: 'enemy-attack', frame: 0 };
  }

  window.AshenAnimation = { Atlas, PaintedRig, LivingBackground, clips, pose, jumpHeight, flowPhase, footPath, solveLeg, decodeChroma, clamp, smooth };
})();

