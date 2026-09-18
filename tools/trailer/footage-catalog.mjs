import fs from 'node:fs';
const out='E:/Cairn-build-tools/trailer/gameplay-cut';
// All four recordings, divided into contiguous review bins. Boundaries are approximate;
// tags describe observed elements, not a claim that every frame contains every element.
const bins=[
 [1,0,27,'Opening','black; story artwork','Exclude: not combat'],
 [1,27,72,'Aqueduct','skeleton melee; ranged skeleton; marauder; axe; sword; chicken running; roast pickup','Run 44.2; eating around 59; avoid eating repeat'],
 [1,72,81,'Transition','tip; black','Exclude'],
 [1,81,115,'Gate','marauder; ranged skeleton; armored melee; sword; blood; player damage','Combat alternatives'],
 [1,115,126.483,'Menu','pause; title','Exclude'],
 [2,0,27,'Opening','black; story artwork','Exclude'],
 [2,27,81,'Aqueduct','skeleton; marauder; axe; sword; combo; blood','Repeated location; use only for distinct action'],
 [2,81,192,'Gate','marauder; armored melee; ranged skeleton; slam; spin; magic; chicken; player damage','Opening slam 119.4; confirmed eating 151.5; magic around 127'],
 [2,192,200,'Transition','tip; secret text','Exclude all secret text'],
 [2,200,217,'Bell courtyard','armored melee; ranged skeleton; marauder; jump; crowd melee; low health','Distinct arena, use 202.4; death follows 217'],
 [2,217,233,'Restart','death wipe; restart; arena change','Exclude'],
 [2,233,338,'Warden arena','Iron Warden; axe tell; charge; knockdown; sword exchanges','Shareware boss: 241.1–245.1 readable tell/contact'],
 [2,338,345.4,'Menu','title; transition','Exclude'],
 [3,0,8,'Menu / entry','menu; transition','Exclude'],
 [3,8,54,'Swamp waterline','mire witch; pools; ranged skeleton; melee; chicken; sword; dash','Witch closing 16.5; pools 33.4; chicken around 26–30'],
 [3,54,117,'Hollow tree','witch; archer; marauder; spin; lightning; high combo; roast; player damage','Magic 69 and 106.5; pickup around 104.5; omit both duplicate casts'],
 [3,117,128,'Transition','tip; secret text','Exclude'],
 [3,128,190,'Drowned belltower','shield enemy; marauder; archer; lightning; launch; blood; chicken','Magic 163.6–166.6 selected; avoid neighboring roast shots'],
 [3,190,234,'Pause','menu','Exclude'],
 [3,234,278,'Drowned belltower','shield enemy; archer; sword; jumping; blood','Alternate shield combat'],
 [3,278,378,'Throne approach','shield enemy; archer; marauder; magic; combo; roast; knockdown','Dense fog; check silhouettes before selection'],
 [3,378,448.067,'Drowned King','root hazards; rolling charge; player hit; sword','382–385 readable rolling charge; no boss death'],
 [4,0,9,'Menu / entry','menu; transition','Exclude'],
 [4,9,70,'Ashen bridge','bomb thrower; archer; marauder; blast; aerial strike; chicken; player hit','29.5 mixed formation; 38.2 bomb pressure; 43.1 blast'],
 [4,70,100,'Results','scoreboard; menu','Not used in action montage'],
 [4,100,111,'Restart','entry; transition','Exclude'],
 [4,111,192,'Forge exterior','bomb thrower; green ranged enemy; marauder; chicken; roast; blast','Extra eating 150.5: exclude to prevent duplication'],
 [4,192,200,'Transition','tip; secret text','Exclude'],
 [4,200,289,'Forge interior','shield enemy; marauder; ranged skeleton; jump; sword; lightning; blood','212.4 under title; 276.6 shield launch; avoid lightning 216/271'],
 [4,289,296,'Transition','tip; black','Exclude'],
 [4,296,342,'Kiln approach','shield enemy; bomb thrower; ranged enemy; blast; player hit','Alternative late enemy lineup'],
 [4,342,357,'Restart','death wipe; transition','Exclude'],
 [4,357,390,'Kiln Saint','bomb volley; furnace jet; chain weapon; player damage','373 volley; 360.5 flame continues into title background'],
 [4,390,398.283,'Death / ending','wipe; defeat','Exclude'],
];
const edl=JSON.parse(fs.readFileSync(out+'/edit-decisions.json','utf8'));
const elements=[['slam','marauder'],['feature-title'],['armored-melee','ranged-skeleton','new-arena'],['witch','sword'],['bomb-thrower','archer','blast'],['warden','enemy-charge','player-hit'],['feature-title'],['combo','sword'],['chicken-running'],['chicken-eating','health-recovery'],['witch','mire-hazard'],['lightning','crowd-control'],['feature-title','jump'],['marauder','player-hit'],['king','enemy-charge','roots'],['saint','bomb-volley'],['bomb-thrower','archer','player-hit'],['shield-enemy','launch'],['skeleton-melee'],['witch','mire-hazard'],['bomb-blast','archer'],['saint','furnace-jet'],['logo','saint']];
const selected=edl.shots.map((s,i)=>({...s,elements:elements[i]}));
const counts={};for(const s of selected)for(const tag of s.elements)counts[tag]=(counts[tag]||0)+1;
const overlaps=[];for(let i=0;i<selected.length;i++)for(let j=i+1;j<selected.length;j++){
 const a=selected[i].background||selected[i],b=selected[j].background||selected[j];
 if(a.clip===b.clip&&Math.min(a.start+selected[i].duration,b.start+selected[j].duration)-Math.max(a.start,b.start)>.01)overlaps.push([i,j]);
}
if(counts.lightning!==1||counts['chicken-eating']!==1||overlaps.length)throw Error('Repetition audit failed '+JSON.stringify({counts,overlaps}));
const data={reviewMethod:'All files surveyed through overview contact sheets; selected actions checked with denser detail sheets. Bins are approximate scene ranges, not exhaustive frame-level detections.',bins:bins.map(([clip,start,end,scene,tags,notes])=>({clip,start,end,scene,elements:tags.split('; '),notes})),selected,counts,exactSourceOverlaps:overlaps};
fs.writeFileSync(out+'/footage-catalog.json',JSON.stringify(data,null,2));
const esc=x=>String(x).replaceAll('&','&amp;').replaceAll('<','&lt;');
const rows=bins.map(b=>`<tr><td>${b[0]}</td><td>${b[1]}–${b[2]}</td><td>${b[3]}</td><td>${b[4]}</td><td>${b[5]}</td></tr>`).join('');
const html=`<!doctype html><meta charset="utf-8"><title>Cairn footage catalogue</title><style>body{background:#121317;color:#ddd;font:15px system-ui;margin:32px}table{border-collapse:collapse;width:100%}td,th{border-bottom:1px solid #383838;padding:12px;text-align:left}input{padding:12px;width:450px}p{max-width:1000px;line-height:1.6}a{color:#e0b873}</style><h1>Cairn footage catalogue & repetition audit</h1><p>${esc(data.reviewMethod)}</p><p>Latest edit: <b>one lightning sequence, one chicken pickup, one running-chicken glimpse, no reused source intervals</b>. Enemy-charge shots retain wind-up and contact. Text frames are centered. Incidental ground roasts can remain in real gameplay; these are distinguished from eating actions.</p><h2>Selected shots</h2><table><tr><th>Trailer seconds</th><th>Source</th><th>Purpose</th><th>Elements</th></tr>${selected.map(s=>`<tr><td>${s.timeline}–${s.timeline+s.duration}</td><td>Clip ${(s.background||s).clip}, ${(s.background||s).start}s</td><td>${esc(s.note||s.card)}</td><td>${s.elements.join(', ')}</td></tr>`).join('')}</table><h2>All four recordings</h2><input placeholder="Filter: witch, charge, pickup, menu…" oninput="document.querySelectorAll('#bins tr').forEach(r=>r.hidden=!r.textContent.toLowerCase().includes(this.value.toLowerCase()))"><table><thead><tr><th>Clip</th><th>Source seconds</th><th>Scene</th><th>Observed elements</th><th>Editorial notes</th></tr></thead><tbody id="bins">${rows}</tbody></table>`;
fs.writeFileSync(out+'/footage-catalog.html',html);
fs.copyFileSync(out+'/footage-catalog.html','E:/Cairn-build-tools/itch-artwork/footage-catalog.html');
fs.copyFileSync(out+'/footage-catalog.json','E:/Cairn-build-tools/itch-artwork/footage-catalog.json');
console.log(JSON.stringify({lightning:counts.lightning,eating:counts['chicken-eating'],running:counts['chicken-running'],exactSourceOverlaps:overlaps.length,bins:bins.length}));
