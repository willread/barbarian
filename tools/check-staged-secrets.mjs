import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
const git=(...args)=>execFileSync('git',args,{maxBuffer:64*1024*1024});
const secretFile=name=>/(^|\/)\.env[^/]*$/i.test(name);
if(process.argv.includes('--self-test')){
 if(!secretFile('.env.local')||!secretFile('nested/.env.production')||secretFile('docs/environment.md'))throw Error('Secret-file guard failed');
 console.log('Secret-file guard checks passed');
 process.exit(0);
}
// Compare locally configured values without printing or persisting them.
const secrets=[];
for(const file of ['.env.local','.env']){
 if(!fs.existsSync(file))continue;
 for(const line of fs.readFileSync(file,'utf8').split(/\r?\n/)){
  const match=line.match(/^\s*(?:export\s+)?[A-Z0-9_]*(?:KEY|TOKEN|SECRET|PASSWORD)\s*=\s*(.+?)\s*$/i);
  if(match){const value=match[1].replace(/^['"]|['"]$/g,'');if(value.length>=12)secrets.push(value);}
 }
}
const files=git('diff','--cached','--name-only','--diff-filter=ACMR','-z').toString().split('\0').filter(Boolean);
for(const file of files){
 if(secretFile(file)){console.error('Commit blocked: an environment file is staged. Unstage it first.');process.exit(1);}
 const data=git('show',`:${file}`);
 if(secrets.some(value=>data.includes(Buffer.from(value)))){
  console.error('Commit blocked: a staged file contains a locally configured secret.');process.exit(1);
 }
}
