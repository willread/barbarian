import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve('E:/Cairn-build-tools/itch-artwork');
http.createServer((req,res)=>{
 const name=decodeURIComponent(new URL(req.url,'http://localhost').pathname).replace(/^\/+/, '')||'index.html';
 const file=path.resolve(root,name);
 if(!file.startsWith(root+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile()){res.writeHead(404);res.end();return;}
 const type={'.html':'text/html; charset=utf-8','.png':'image/png','.jpg':'image/jpeg','.gif':'image/gif','.zip':'application/zip','.md':'text/plain; charset=utf-8'}[path.extname(file)]||'application/octet-stream';
 res.writeHead(200,{'Content-Type':type,'Cache-Control':'no-store'});fs.createReadStream(file).pipe(res);
}).listen(3018,'127.0.0.1',()=>console.log('http://127.0.0.1:3018/'));
