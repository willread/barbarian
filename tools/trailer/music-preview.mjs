import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const root='E:/Cairn-build-tools/trailer/music-options';
const ids=['iron-oath','ash-engine','war-crown','blood-rush'];
const allowed=new Set(['tracks.json',...ids.flatMap(id=>[id+'.mp3',id+'.wav',id+'-source.mp3'])]);
http.createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname.slice(1);
 const file=name===''||name==='index.html'?new URL('./music-preview.html',import.meta.url):allowed.has(name)?path.join(root,name):null;
 if(!file||!fs.existsSync(file)){res.writeHead(404);res.end('Not found');return;}
 const size=fs.statSync(file).size;
 const type=name.endsWith('.mp3')?'audio/mpeg':name.endsWith('.wav')?'audio/wav':name.endsWith('.json')?'application/json':'text/html; charset=utf-8';
 const headers={'Content-Type':type,'Cache-Control':'no-store','Accept-Ranges':'bytes'};
 const range=req.headers.range?.match(/^bytes=(\d+)-(\d*)$/);
 let start=range?Number(range[1]):0,end=range&&range[2]?Number(range[2]):size-1;
 end=Math.min(end,size-1);
 if(start>end||start>=size){res.writeHead(416,{'Content-Range':`bytes */${size}`});res.end();return;}
 if(range)headers['Content-Range']=`bytes ${start}-${end}/${size}`;
 headers['Content-Length']=end-start+1;
 res.writeHead(range?206:200,headers);
 if(req.method==='HEAD'){res.end();return;}
 fs.createReadStream(file,{start,end}).pipe(res);
}).listen(3016,'127.0.0.1',()=>console.log('Trailer music preview: http://127.0.0.1:3016'));
