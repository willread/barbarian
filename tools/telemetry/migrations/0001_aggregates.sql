-- Each metric is aggregated separately: no submission, session or player rows.
CREATE TABLE totals (
  day TEXT NOT NULL,
  episode INTEGER NOT NULL,
  level INTEGER NOT NULL,
  difficulty TEXT NOT NULL,
  metric TEXT NOT NULL,
  value INTEGER NOT NULL CHECK(value >= 0),
  PRIMARY KEY (day, episode, level, difficulty, metric)
) WITHOUT ROWID;
