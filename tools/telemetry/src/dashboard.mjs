const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export function dashboard(rows, range) {
  const count = metric => rows.filter(r => r.metric === metric).reduce((n, r) => n + r.value, 0);
  const attempts = count('attempts'), completed = count('outcome:completed');
  const days = new Map();
  for (const row of rows) {
    if (!days.has(row.day)) days.set(row.day, { attempts: 0, completed: 0, died: 0, quit: 0 });
    const item = days.get(row.day);
    if (row.metric === 'attempts') item.attempts += row.value;
    for (const outcome of ['completed','died','quit']) if (row.metric === 'outcome:'+outcome) item[outcome] += row.value;
  }
  const percent = (n, total) => total ? Math.round(n / total * 100) + '%' : '—';
  return `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cairn · Gameplay statistics</title>
  <style>body{background:#171719;color:#eee9de;font:16px system-ui;max-width:1100px;margin:48px auto;padding:0 24px}h1{font-size:36px}p,small{color:#bdb7ab}a{color:#eec06e}nav,form{display:flex;flex-wrap:wrap;gap:20px;align-items:center;margin:24px 0}input,button{font:inherit;padding:8px;background:#242326;color:#eee9de;border:1px solid #827052}.cards{display:flex;flex-wrap:wrap;gap:16px}.card{background:#242326;padding:24px;flex:1;border-top:3px solid #c39048}.card strong{display:block;font-size:32px}table{width:100%;border-collapse:collapse;margin-top:20px}th,td{text-align:left;padding:12px;border-bottom:1px solid #393637}th{color:#eec06e}.scroll{overflow:auto}h2{margin-top:36px}</style>
  <header><small>CAIRN / PRIVATE DASHBOARD</small><h1>How the battles unfold</h1><p>${escape(range.label)}. Aggregate attempts, not unique players.</p></header>
  <nav><a href="?days=1">Today</a><a href="?days=7">7 days</a><a href="?days=30">30 days</a><a href="?days=90">90 days</a><a href="?days=all">All time</a><a href="/admin/data?${escape(range.query)}">Download JSON</a><a href="/cdn-cgi/access/logout">Sign out</a></nav>
  <form method="get" action="/admin"><label>View a UTC day <input type="date" name="day" value="${escape(range.day)}" required></label><button type="submit">View day</button></form>
  <section class="cards"><div class="card">Attempts<strong>${attempts.toLocaleString('en')}</strong></div><div class="card">Completed<strong>${completed.toLocaleString('en')}</strong></div><div class="card">Completion rate<strong>${percent(completed,attempts)}</strong></div></section>
  <h2>By day</h2><div class="scroll"><table><thead><tr><th>UTC day</th><th>Attempts</th><th>Completed</th><th>Died</th><th>Quit</th><th>Completion rate</th></tr></thead><tbody>${[...days].sort(([a],[b])=>b.localeCompare(a)).map(([day,v])=>`<tr><td><a href="?day=${escape(day)}">${escape(day)}</a></td><td>${v.attempts}</td><td>${v.completed}</td><td>${v.died}</td><td>${v.quit}</td><td>${percent(v.completed,v.attempts)}</td></tr>`).join('') || '<tr><td colspan="6">No statistics received in this period.</td></tr>'}</tbody></table></div>
  <h2>Daily metric detail</h2><div class="scroll"><table><thead><tr><th>UTC day</th><th>Episode</th><th>Level</th><th>Difficulty</th><th>Metric</th><th>Total</th></tr></thead><tbody>${rows.map(r=>`<tr><td>${escape(r.day)}</td><td>${escape(r.episode)}</td><td>${escape(r.level)}</td><td>${escape(r.difficulty)}</td><td>${escape(r.metric)}</td><td>${escape(r.value)}</td></tr>`).join('') || '<tr><td colspan="6">No statistics received in this period.</td></tr>'}</tbody></table></div><p>Daily aggregates are retained indefinitely. Days with no reports are omitted. Dates reflect when reports reached the service. Time and score are ranges. No player or session drill-down is stored.</p></html>`;
}
