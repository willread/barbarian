import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd(),port=3003;
http.createServer((req,res)=>{
 let pathname;try{pathname=decodeURIComponent(new URL(req.url,'http://localhost').pathname)}catch{res.writeHead(400).end();return}
 if(pathname==='/')pathname='/studies/backgrounds/mire-v2/index.html';
 const file=path.resolve(root,'.'+pathname);
 const allowed=['studies/backgrounds/mire-v2/','studies/backgrounds/swamp-v1/','asset-sources/art/episodes/mire-effect-v1.png','godot/shaders/mire_sequence.gdshader','godot/assets/enemy-witch-','godot/assets/mire-oil-v2.png','godot/audio/mire_loop.ogg'];
 if(!file.startsWith(root+path.sep)||!allowed.some(prefix=>pathname.slice(1).startsWith(prefix))||!fs.existsSync(file)||!fs.statSync(file).isFile()){res.writeHead(404).end();return}
 res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.png':'image/png','.gdshader':'text/plain'})[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});fs.createReadStream(file).pipe(res);
}).listen(port,'127.0.0.1',()=>console.log(`Mire animation review: http://localhost:${port}/`));
