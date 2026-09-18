import {fileURLToPath} from 'node:url';

process.chdir(fileURLToPath(new URL('../../', import.meta.url)));
for (const flag of ['--shareware', '--steam-shareware']) {
 if (!process.argv.includes(flag)) process.argv.push(flag);
}
await import('./build.mjs');
