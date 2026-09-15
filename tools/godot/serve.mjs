import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import {musicLibrary} from '../audio/music-library.mjs';
const root=path.resolve(process.env.CAIRN_BUILD_DIR||(fs.existsSync('E:/Cairn-build-tools')?'E:/Cairn-build-tools/build':'godot/build'),'web');
const port=Number(process.env.PORT||3001);
const types={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml'};
const server=http.createServer((req,res)=>{
 let url;try{url=decodeURIComponent(new URL(req.url,'http://localhost').pathname)}catch{res.writeHead(400).end();return;}
 if(url==='/music/api/library'){
  const tracks=musicLibrary();res.writeHead(200,{'Content-Type':'application/json','Cache-Control':'no-store'}).end(JSON.stringify({tracks:tracks.map(({path:localPath,...track})=>track)}));return;
 }
 if(url==='/ep2-music/'||url==='/ep2-music/index.html'){res.writeHead(302,{Location:'/music/'}).end();return;}
 if(url==='/music'||url==='/music/'||url==='/music/index.html'){
  res.writeHead(200,{'Content-Type':'text/html','Cache-Control':'no-store'});fs.createReadStream(path.resolve('soundboard/music-player/index.html')).pipe(res);return;
 }
 if(url.startsWith('/music/audio/')){
  const track=musicLibrary().find(t=>t.id===url.slice('/music/audio/'.length));
  if(!track){res.writeHead(404).end('Track not found');return;}
  const size=fs.statSync(track.path).size,type={'.ogg':'audio/ogg','.mp3':'audio/mpeg','.wav':'audio/wav','.flac':'audio/flac','.m4a':'audio/mp4'}[path.extname(track.path)]||'application/octet-stream';
  const match=/^bytes=(\d+)-(\d*)$/.exec(req.headers.range||'');
  if(match){const start=Number(match[1]),end=match[2]?Math.min(size-1,Number(match[2])):size-1;
   if(start>end||start>=size){res.writeHead(416,{'Content-Range':`bytes */${size}`}).end();return;}
   res.writeHead(206,{'Content-Type':type,'Content-Length':end-start+1,'Content-Range':`bytes ${start}-${end}/${size}`,'Accept-Ranges':'bytes'});fs.createReadStream(track.path,{start,end}).pipe(res);return;
  }
  res.writeHead(200,{'Content-Type':type,'Content-Length':size,'Accept-Ranges':'bytes','Cache-Control':'no-store'});fs.createReadStream(track.path).pipe(res);return;
 }
 const file=path.resolve(root,'.'+(url==='/'?'/index.html':url));
 if(!file.startsWith(root+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile()){res.writeHead(404).end('Not found');return;}
 res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Content-Length':fs.statSync(file).size,'Cache-Control':'no-store'});
 fs.createReadStream(file).pipe(res);
});
server.listen(port,'127.0.0.1',()=>console.log(`Cairn Godot preview: http://localhost:${port}/`));
