export function dateRange(params, now = Date.now()) {
  const episode=params.get('episode')||'all',difficulty=params.get('difficulty')||'all';
  if(!['all','1','2','3'].includes(episode)||!['all','easy','normal','hard'].includes(difficulty))throw Error('Invalid filter');
  const finish=range=>({...range,episode,difficulty,query:range.query+`&episode=${episode}&difficulty=${difficulty}`});
  const day = params.get('day');
  if (day) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(day) || !Number.isFinite(Date.parse(day)) || new Date(day).toISOString().slice(0, 10) !== day) throw Error('Invalid date');
    return finish({ start: day, end: day, label: `${day} (UTC)`, query: `day=${day}`, day, days:'30' });
  }
  const days = params.get('days') || '30';
  if (days === 'all') return finish({ start: '0000-01-01', end: '9999-12-31', label: 'All time · UTC calendar days', query: 'days=all', day: '',days });
  if (!['1', '7', '30', '90'].includes(days)) throw Error('Invalid date range');
  return finish({ start: new Date(now - (Number(days) - 1) * 86400000).toISOString().slice(0, 10), end: new Date(now).toISOString().slice(0, 10), label: `Last ${days} UTC calendar days, including today`, query: `days=${days}`, day: '',days });
}
export async function dailyRows(db, range) {
  const { results } = await db.prepare("SELECT day, episode, level, difficulty, metric, SUM(value) AS value FROM totals WHERE day >= ? AND day <= ? AND (? = 'all' OR episode = ?) AND (? = 'all' OR difficulty = ?) GROUP BY day, episode, level, difficulty, metric ORDER BY day DESC, episode, level, difficulty, metric").bind(range.start, range.end,range.episode,range.episode,range.difficulty,range.difficulty).all();
  return results;
}
