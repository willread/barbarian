const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export function dashboard(rows, days) {
  const count = metric => rows.filter(r => r.metric === metric).reduce((n, r) => n + r.value, 0);
  const attempts = count('attempts');
  const completed = count('outcome:completed');
  return `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cairn · Gameplay statistics</title>
  <style>body{background:#171719;color:#eee9de;font:16px system-ui;max-width:1100px;margin:48px auto;padding:0 24px}h1{font-size:36px}p,small{color:#bdb7ab}a{color:#eec06e}nav{display:flex;gap:20px;margin:28px 0}.cards{display:flex;flex-wrap:wrap;gap:16px}.card{background:#242326;padding:24px;flex:1;border-top:3px solid #c39048}.card strong{display:block;font-size:32px}table{width:100%;border-collapse:collapse;margin-top:28px}th,td{text-align:left;padding:12px;border-bottom:1px solid #393637}th{color:#eec06e} .scroll{overflow:auto}</style>
  <header><small>CAIRN / PRIVATE DASHBOARD</small><h1>How the battles unfold</h1><p>Last ${days} UTC calendar days, including today. Aggregate attempts, not unique players.</p></header>
  <nav><a href="?days=7">7 days</a><a href="?days=30">30 days</a><a href="?days=90">90 days</a><a href="/admin/data?days=${days}">Download JSON</a><a href="/cdn-cgi/access/logout">Sign out</a></nav>
  <section class="cards"><div class="card">Attempts<strong>${attempts.toLocaleString('en')}</strong></div><div class="card">Completed<strong>${completed.toLocaleString('en')}</strong></div><div class="card">Completion rate<strong>${attempts ? Math.round(completed / attempts * 100) : 0}%</strong></div></section>
  <div class="scroll"><table><thead><tr><th>Episode</th><th>Level</th><th>Difficulty</th><th>Metric</th><th>Total</th></tr></thead><tbody>${rows.map(r => `<tr><td>${escape(r.episode)}</td><td>${escape(r.level)}</td><td>${escape(r.difficulty)}</td><td>${escape(r.metric)}</td><td>${escape(r.value)}</td></tr>`).join('') || '<tr><td colspan="5">No statistics received in this period.</td></tr>'}</tbody></table></div><p>Time and score are ranges. Move counts are totals; feature counts represent attempts where used. No player or session drill-down is stored.</p></html>`;
}
