/* Full-body cels plus independent rigid weapons. Coordinates are authored hand sockets. */
(() => {
  const { clamp } = window.AshenAnimation;
  const weapons = {
    axe: { label: 'Axe', frame: 0, length: 154, grip: .76 },
    sword: { label: 'Sword', frame: 1, length: 176, grip: .78 },
  };
  // Coordinates use the source cell's pixel dimensions, not the figure bounds.
  // Head length calibrates uniform body scale without stretching crouched poses.
  const key = (head, grip, angle = 0, hand2 = null, behind = false) => ({ head, grip, angle, hand2, behind });
  const sheets = {
    'hero-cast-unarmed-v1': { cell:[384,512], frames:[
      key(53,[199,201]),key(53,[239,182]),key(53,[170,129]),key(53,[176,53]),
      key(53,[145,29]),key(53,[155,29]),key(53,[163,74]),key(53,[199,188]),
    ] },
    'hero-actions-unarmed-v8': { cell: [384,512], frames: [
      key(50,[138,194],0,[157,219]), key(50,[138,194],0,[157,219]),
      key(50,[138,194],0,[157,219]), key(50,[138,194],0,[157,219]),
      key(50,[144,147],0,[164,170]), key(50,[263,224],0,[235,229]),
      key(50,[281,257],0,[256,248]), key(50,[139,158],0,[158,185]),
    ] },
    'hero-walk-unarmed-v8': { cell: [512,768], frames: [
      key(84,[317,404],135), key(84,[326,404],135), key(84,[315,404],135), key(84,[333,404],135),
    ] },
    'hero-extra-unarmed-v8': { cell: [313.5,418], frames: [
      key(43,[237,258],40), key(43,[201,278],65), key(43,[237,256],50), key(43,[190,301],100),
      key(43,[190,292],40), key(43,[170,270],-45,null,true), key(43,[157,273],-45,null,true), key(43,[160,272],-45,null,true),
      key(43,[142,106],0,[153,131]), key(43,[225,134],0,[232,163]),
      key(43,[211,287],0,[183,278]), key(43,[204,288],0,[174,282]),
    ] },
    'hero-close-unarmed-v8': { cell: [313.5,418], frames: [
      key(50,[155,109],0,[180,111]), key(50,[194,123],0,[220,138]),
      key(50,[223,227],0,[219,248]), key(50,[206,123],0,[229,137]),
      key(50,[121,107],0,[146,134]), key(50,[157,88],0,[178,90]),
      key(50,[244,213],90), key(50,[201,252],45),
      key(50,[209,209],45), key(50,[150,73],0,[168,93]), key(50,[123,51],-85), key(50,[209,213],45),
    ] },
    'hero-reactions-unarmed-v8': { cell: [313.5,418], frames: [
      key(50,[102,292],120), key(50,[118,282],125), key(50,[116,308],120), key(50,[99,293],112),
      key(50,[102,254],120), key(50,[133,319],93), key(50,[119,324],0,[92,332]), key(50,[162,340],0,[132,340]),
      key(50,[234,251],105), key(50,[96,168],-30), key(50,[149,3],0,[107,16]), key(50,[221,261],105),
    ] },
  };

  function skin(r, g, b) {
    if (r <= g || g <= b || r < 65) return null;
    const saturation = (r - b) / r, hue = 60 * (g - b) / (r - b);
    const amount = clamp((hue - 5) / 7) * clamp((44 - hue) / 9) * clamp((r - 65) / 45) * clamp(saturation / .3);
    return amount ? { saturation, hue, amount, light: .2126 * r + .7152 * g + .0722 * b } : null;
  }
  function normalizeSkin(cel) {
    const ctx = cel.image.getContext('2d'), pixels = ctx.getImageData(0, 0, cel.image.width, cel.image.height), d = pixels.data;
    const saturation = [], luminance = [];
    for (let i = 0; i < d.length; i += 4) {
      const s = d[i + 3] > 200 && skin(d[i], d[i + 1], d[i + 2]);
      if (s && s.amount > .85) { saturation.push(s.saturation); luminance.push(s.light); }
    }
    if (saturation.length < 32) return;
    const median = values => values.sort((a, b) => a - b)[Math.floor(values.length / 2)];
    const satGain = clamp(.48 / median(saturation), .72, 1.15);
    const lightGain = clamp(145 / median(luminance), .88, 1.12);
    for (let i = 0; i < d.length; i += 4) {
      if (!d[i + 3]) continue;
      const s = skin(d[i], d[i + 1], d[i + 2]); if (!s) continue;
      // Match warm skin to a shared tan hue while retaining painted luminance.
      // Hue-space correction cannot create green patches in gold/highlights.
      const sat = clamp(s.saturation * satGain, 0, .78);
      const rgb = [1, 1 - sat * .55, 1 - sat];
      const light = s.light * lightGain / (.2126 * rgb[0] + .7152 * rgb[1] + .0722 * rgb[2]);
      for (let c = 0; c < 3; c++) d[i + c] += (rgb[c] * light - d[i + c]) * s.amount;
    }
    ctx.putImageData(pixels, 0, 0);
  }
  class HeroRig {
    constructor(atlases, weaponAtlas) {
      this.atlases = atlases; this.weaponAtlas = weaponAtlas;
      for (const name of Object.keys(sheets)) for (const cel of atlases[name]?.cels || []) normalizeSkin(cel);
    }

    layout(pose) {
      const atlas = this.atlases[pose.atlas], spec = sheets[pose.atlas], cel = atlas?.cels?.[pose.frame];
      if (!atlas || !spec || !cel) return null;
      const key = spec.frames[pose.frame];
      const sx = atlas.cellWidth / spec.cell[0], sy = atlas.cellHeight / spec.cell[1];
      const scale = 42 / (key.head * sy);
      const origin = [-atlas.cellWidth * .5 * scale, -(cel.top + cel.image.height) * scale];
      const point = p => [origin[0] + p[0] * sx * scale, origin[1] + p[1] * sy * scale];
      const grip = point(key.grip), hand2 = key.hand2 && point(key.hand2);
      const angle = hand2 ? Math.atan2(grip[0] - hand2[0], hand2[1] - grip[1]) : key.angle * Math.PI / 180;
      return { atlas, key, scale, grip, hand2, angle, size: scale * atlas.cellWidth / atlas.scale };
    }

    paintWeapon(ctx, layout, id, opacity) {
      const spec = weapons[id] || weapons.axe, cel = this.weaponAtlas?.cels?.[spec.frame];
      if (!cel) return;
      const h = spec.length, w = h * cel.image.width / cel.image.height;
      ctx.save(); ctx.globalAlpha = opacity;
      ctx.translate(...layout.grip); ctx.rotate(layout.angle);
      ctx.drawImage(cel.image, -w * .5, -h * spec.grip, w, h);
      ctx.restore();
    }

    paint(ctx, pose, size, opacity, time, id) {
      const layout = this.layout(pose), atlas = this.atlases[pose.atlas];
      if (!layout) { atlas?.paint(ctx, pose.frame, size, opacity, pose.breathing ? time : null); return; }
      const breath = pose.breathing ? time : null;
      if (layout.key.behind) this.paintWeapon(ctx, layout, id, opacity);
      atlas.paint(ctx, pose.frame, layout.size, opacity, breath);
      if (!layout.key.behind) {
        this.paintWeapon(ctx, layout, id, opacity);
        // The original whole-body painting supplies finger occlusion. Hands are
        // never moved, rotated or rendered as independent animated body parts.
        ctx.save(); ctx.beginPath();
        for (const p of [layout.grip, layout.hand2].filter(Boolean)) {
          ctx.moveTo(p[0] + 8, p[1]); ctx.arc(p[0], p[1], 8, 0, Math.PI * 2);
        }
        ctx.clip(); atlas.paint(ctx, pose.frame, layout.size, opacity, breath); ctx.restore();
      }
    }
  }
  window.AshenHeroRig = { HeroRig, sheets, weapons, normalizeSkin };
})();
