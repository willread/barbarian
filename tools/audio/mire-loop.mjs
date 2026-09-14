import fs from 'node:fs';
// User-selected ElevenLabs take; volume and pitch are applied at runtime.
fs.copyFileSync('studies/backgrounds/mire-v2/eleven-sticky-slurp.ogg','godot/audio/mire_loop.ogg');
console.log('Installed ElevenLabs Sticky slurp');
