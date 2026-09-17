const outcomes=['completed','died','quit'];
const empty=()=>({attempts:0,completed:0,died:0,quit:0});
function add(item,row){
  if(row.metric==='attempts')item.attempts+=row.value;
  for(const outcome of outcomes)if(row.metric==='outcome:'+outcome)item[outcome]+=row.value;
}
export function levelSummary(rows){
  const levels=Array.from({length:12},(_,i)=>({episode:Math.floor(i/4)+1,level:i%4+1,...empty()}));
  for(const row of rows){const level=levels.find(v=>v.episode===row.episode&&v.level===row.level);if(level)add(level,row)}
  return levels;
}
export function insights(rows,range){
  const sum=metric=>rows.reduce((n,r)=>n+(r.metric===metric?r.value:0),0);
  const totals=empty(),days=new Map();
  for(const row of rows){add(totals,row);if(!days.has(row.day))days.set(row.day,empty());add(days.get(row.day),row)}
  const levels=levelSummary(rows).filter(v=>range.episode==='all'||v.episode===Number(range.episode));
  const difficulties=range.difficulty==='all'?['easy','normal','hard']:[range.difficulty];
  const heat=levels.map(level=>({...level,cells:difficulties.map(difficulty=>{
    const value=empty();for(const row of rows)if(row.episode===level.episode&&row.level===level.level&&row.difficulty===difficulty)add(value,row);
    return {difficulty,...value};
  })}));
  const combat=['normal','charge','spin','slam','throw'].map(move=>({move,total:sum('move:'+move),average:totals.attempts?sum('move:'+move)/totals.attempts:null,outcomes:Object.fromEntries(['completed','died'].map(outcome=>{
    const buckets=['none','1_5','6_20','21_plus'].map(bucket=>sum(`outcome:${outcome}:move:${move}:${bucket}`));
    return [outcome,{total:buckets.reduce((a,b)=>a+b,0),used:buckets.slice(1).reduce((a,b)=>a+b,0)}];
  }))}));
  const features=['controls','weapon_menu','music_player','intro_watched','intro_skipped'].map(feature=>({feature,count:sum('feature:'+feature)}));
  const sorted=[...days.keys()].sort(),timeline=[];
  let binDays=1;
  if(sorted.length){
    const start=Date.parse(range.days==='all'?sorted[0]:range.start),end=Date.parse(range.days==='all'?sorted.at(-1):range.end);
    const span=Math.round((end-start)/86400000)+1;
    binDays=Math.max(1,Math.ceil(span/90));
    for(let offset=0;offset<span;offset+=binDays)timeline.push({day:new Date(start+offset*86400000).toISOString().slice(0,10),end:new Date(Math.min(end,start+(offset+binDays-1)*86400000)).toISOString().slice(0,10),...empty()});
    for(const [day,value] of days){const bin=timeline[Math.floor((Date.parse(day)-start)/86400000/binDays)];if(bin)for(const key of Object.keys(empty()))bin[key]+=value[key]}
  }
  const hotspot=heat.flatMap(v=>v.cells.map(c=>({...c,episode:v.episode,level:v.level}))).filter(v=>v.attempts>=5).sort((a,b)=>b.died/b.attempts-a.died/a.attempts||b.attempts-a.attempts)[0]||null;
  return {totals,levels,difficulties,heat,combat,features,timeline,binDays,days:[...days].sort(([a],[b])=>b.localeCompare(a)),hotspot};
}
