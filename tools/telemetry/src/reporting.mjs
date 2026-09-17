export function dateRange(params, now = Date.now()) {
  const day = params.get('day');
  if (day !== null) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(day) || !Number.isFinite(Date.parse(day)) || new Date(day).toISOString().slice(0, 10) !== day) throw Error('Invalid date');
    return { start: day, end: day, label: `${day} (UTC)`, query: `day=${day}`, day };
  }
  const days = params.get('days') || '30';
  if (days === 'all') return { start: '0000-01-01', end: '9999-12-31', label: 'All time · UTC calendar days', query: 'days=all', day: '' };
  if (!['1', '7', '30', '90'].includes(days)) throw Error('Invalid date range');
  return { start: new Date(now - (Number(days) - 1) * 86400000).toISOString().slice(0, 10), end: new Date(now).toISOString().slice(0, 10), label: `Last ${days} UTC calendar days, including today`, query: `days=${days}`, day: '' };
}
export async function dailyRows(db, range) {
  const { results } = await db.prepare('SELECT day, episode, level, difficulty, metric, SUM(value) AS value FROM totals WHERE day >= ? AND day <= ? GROUP BY day, episode, level, difficulty, metric ORDER BY day DESC, episode, level, difficulty, metric').bind(range.start, range.end).all();
  return results;
}
