import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root = path.dirname(fileURLToPath(import.meta.url));
const trailer = 'E:/Cairn-build-tools/trailer/cairn-first-cut.mp4';
const types = {'.html':'text/html; charset=utf-8','.css':'text/css','.png':'image/png','.jpg':'image/jpeg','.ttf':'font/ttf','.json':'application/json','.mp4':'video/mp4','.txt':'text/plain','.md':'text/plain'};
const server = http.createServer((req,res) => {
 let pathname;
 try { pathname = decodeURIComponent(new URL(req.url,'http://localhost').pathname); }
 catch { res.writeHead(400).end(); return; }
 const file = pathname === '/trailer.mp4' ? trailer : path.resolve(root,'.'+(pathname === '/' ? '/index.html' : pathname));
 if ((file !== trailer && !file.startsWith(root+path.sep)) || !fs.existsSync(file) || !fs.statSync(file).isFile()) { res.writeHead(404).end('Not found'); return; }
 const size = fs.statSync(file).size;
 const headers = {'Content-Type':types[path.extname(file)] || 'application/octet-stream','Cache-Control':'no-store','Accept-Ranges':'bytes'};
 const range = /^bytes=(\d+)-(\d*)$/.exec(req.headers.range || '');
 let start=0,end=size-1,status=200;
 if(range){start=Number(range[1]);end=range[2]?Math.min(Number(range[2]),size-1):size-1;status=206;
  if(start>end || start>=size){res.writeHead(416,{'Content-Range':`bytes */${size}`}).end();return;}
  headers['Content-Range']=`bytes ${start}-${end}/${size}`;
 }
 headers['Content-Length']=end-start+1;
 res.writeHead(status,headers);
 if(req.method==='HEAD'){res.end();return;}
 fs.createReadStream(file,{start,end}).on('error',()=>res.destroy()).pipe(res);
});
server.listen(3014,'127.0.0.1',()=>console.log('Cairn itch.io theme: http://localhost:3014/'));
