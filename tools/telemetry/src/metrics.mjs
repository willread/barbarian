export const moves = ['normal', 'charge', 'spin', 'slam', 'throw'];
export const features = ['controls', 'intro_watched', 'intro_skipped', 'music_player', 'weapon_menu'];
const duration = ['under_1m', '1_3m', '3_5m', '5_10m', '10_20m', '20m_plus'];
const scores = ['0_999', '1000_4999', '5000_9999', '10000_24999', '25000_49999', '50000_plus'];
function keys(value, allowed) {
  if (!value || typeof value !== 'object' || Array.isArray(value) || Object.keys(value).some(k => !allowed.includes(k))) throw Error('Invalid fields');
}
function member(value, allowed) { if (!allowed.includes(value)) throw Error('Invalid value'); }
export function aggregate(payload) {
  keys(payload, ['schema', 'episode', 'level', 'difficulty', 'outcome', 'duration', 'score', 'moves', 'features']);
  if (payload.schema !== 1) throw Error('Invalid schema');
  member(payload.episode, [1, 2, 3]);
  member(payload.level, [1, 2, 3, 4]);
  member(payload.difficulty, ['easy', 'normal', 'hard']);
  member(payload.outcome, ['completed', 'died', 'quit']);
  member(payload.duration, duration);
  member(payload.score, scores);
  keys(payload.moves, moves);
  keys(payload.features, features);
  const result = [['attempts', 1], [`outcome:${payload.outcome}`, 1], [`duration:${payload.duration}`, 1], [`score:${payload.score}`, 1]];
  for (const [move, count] of Object.entries(payload.moves)) {
    if (!Number.isSafeInteger(count) || count < 0 || count > 10000) throw Error('Invalid counter');
    if (count) result.push([`move:${move}`, count]);
  }
  for (const [feature, used] of Object.entries(payload.features)) {
    if (typeof used !== 'boolean') throw Error('Invalid feature');
    if (used) result.push([`feature:${feature}`, 1]);
  }
  return result;
}
export const UPSERT = `INSERT INTO totals(day, episode, level, difficulty, metric, value)
VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(day, episode, level, difficulty, metric)
DO UPDATE SET value = value + excluded.value`;
