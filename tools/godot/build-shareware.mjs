import {fileURLToPath} from 'node:url';

// Resolve build inputs from the repository even when invoked from another folder.
process.chdir(fileURLToPath(new URL('../../', import.meta.url)));
if (!process.argv.includes('--shareware')) process.argv.push('--shareware');
await import('./build.mjs');
