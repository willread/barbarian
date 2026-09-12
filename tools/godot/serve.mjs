import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(process.env.CAIRN_BUILD_DIR||(fs.existsSync('E:/Cairn-build-tools')?'E:/Cairn-build-tools/build':'godot/build'),'web');
const port=Number(process.env.PORT||3001);
const types={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml'};
const server=http.createServer((req,res)=>{
 let url;try{url=decodeURIComponent(new URL(req.url,'http://localhost').pathname)}catch{res.writeHead(400).end();return;}
 const file=path.resolve(root,'.'+(url==='/'?'/index.html':url));
 if(!file.startsWith(root+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile()){res.writeHead(404).end('Not found');return;}
 res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Content-Length':fs.statSync(file).size,'Cache-Control':'no-store'});
 fs.createReadStream(file).pipe(res);
});
server.listen(port,'127.0.0.1',()=>console.log(`Cairn Godot preview: http://localhost:${port}/`));
