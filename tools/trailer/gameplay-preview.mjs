import http from 'node:http';
import fs from 'node:fs';
const root='E:/Cairn-build-tools/trailer/gameplay-cut/';
http.createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname.slice(1);
 const file=name===''?new URL('./gameplay-preview.html',import.meta.url):['cairn-gameplay-trailer.mp4','logo.png','edit-decisions.json'].includes(name)?root+name:null;
 if(!file||!fs.existsSync(file)){res.writeHead(404);res.end();return;}
 const size=fs.statSync(file).size,range=req.headers.range?.match(/^bytes=(\d+)-(\d*)$/);
 const start=range?Number(range[1]):0,end=Math.min(range?.[2]?Number(range[2]):size-1,size-1);
 if(start>end||start>=size){res.writeHead(416,{'Content-Range':`bytes */${size}`});res.end();return;}
 const headers={'Content-Type':name.endsWith('.mp4')?'video/mp4':name.endsWith('.png')?'image/png':name.endsWith('.json')?'application/json':'text/html; charset=utf-8','Content-Length':end-start+1,'Accept-Ranges':'bytes','Cache-Control':'no-store'};
 if(range)headers['Content-Range']=`bytes ${start}-${end}/${size}`;
 res.writeHead(range?206:200,headers);if(req.method==='HEAD')res.end();else fs.createReadStream(file,{start,end}).pipe(res);
}).listen(3017,'127.0.0.1',()=>console.log('http://127.0.0.1:3017/'));
