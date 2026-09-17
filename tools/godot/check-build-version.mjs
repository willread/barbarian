import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {incrementBuild} from './build-version.mjs';
const parent=fs.realpathSync(os.tmpdir()),root=fs.mkdtempSync(path.join(parent,'cairn-version-test-'));
try{
 fs.mkdirSync(path.join(root,'godot/scripts'),{recursive:true});
 fs.writeFileSync(path.join(root,'version.json'),JSON.stringify({version:'2.3.0',build:8}));
 assert.equal(incrementBuild(root).build,9);
 assert.equal(incrementBuild(root).build,10);
 fs.writeFileSync(path.join(root,'version.json'),JSON.stringify({version:'2.4.0',build:10}));
 assert.deepEqual(incrementBuild(root),{version:'2.4.0',build:11});
 assert.match(fs.readFileSync(path.join(root,'godot/scripts/build_info.gd'),'utf8'),/const BUILD=11/);
 fs.writeFileSync(path.join(root,'version.json'),JSON.stringify({version:'bad',build:11}));
 assert.throws(()=>incrementBuild(root));
 console.log('BUILD_VERSION_OK: monotonic increments, release changes, embedded identity and validation');
}finally{
 if(path.dirname(fs.realpathSync(root))!==parent)throw Error('Unexpected test cleanup path');
 fs.rmSync(root,{recursive:true});
}
