-- CREATE expansion_picks tables --
CREATE TABLE expansion_picks (
  draft_year      INTEGER,
  expansion_team  TEXT,
  pick_number     INTEGER,
  player_name     TEXT,
  former_team     TEXT
);

-- Create player_totals table --
CREATE TABLE player_totals (
  Season	INTEGER,
  Player	TEXT,
  Team		TEXT,
  Pos		TEXT,
  G			INTEGER,
  MP		INTEGER,
  GS		INTEGER,
  FG		INTEGER,
  FGA		INTEGER,
  'FG%'		NUMERIC,
  '3P'		INTEGER,
  '3PA'		INTEGER,
  '3P%'		NUMERIC,
  '2P'		INTEGER,
  '2PA'		INTEGER,
  '2P%'		NUMERIC,
  FT		INTEGER,
  FTA		INTEGER,
  'FT%'		NUMERIC,
  ORB		INTEGER,
  TRB		INTEGER,
  AST		INTEGER,
  STL		INTEGER,
  BLK		INTEGER,
  TOV		INTEGER,
  PF		INTEGER,
  PTS		INTEGER
);

-- Create player_advanced table --
CREATE TABLE player_advanced (
  Season	INTEGER,
  Player	TEXT,
  Team		TEXT,
  Pos		TEXT,
  G			INTEGER,
  MP		INTEGER,
  PER		NUMERIC,
  'TS%'		NUMERIC,
  'eFG%'	NUMERIC,
  '3PAr'	NUMERIC,
  FTr		NUMERIC,
  'ORB%'	NUMERIC,
  'TRB%'	NUMERIC,
  'AST%'	NUMERIC,
  'STL%'	NUMERIC,
  'BLK%'	NUMERIC,
  'TOV%'	NUMERIC,
  'USG%'	NUMERIC,
  ORtg		INTEGER,
  DRtg		INTEGER,
  OWS		NUMERIC,
  DWS		NUMERIC,
  WS		NUMERIC,
  'WS/40'	NUMERIC
);

-- Create before and after view --
CREATE VIEW pick_outcomes AS
SELECT p.draft_year,
       p.expansion_team,
       p.pick_number,
       p.player_name,
       p.former_team,
       DATE_PART('year', AGE(MAKE_DATE(p.draft_year, 5, 15), p.birth_date)) AS age_at_draft,
	   COALESCE(b.pos, a.pos) AS position,
       b.mp     AS minutes_before,
       a.mp     AS minutes_after,
       ab.ws         AS ws_before,
       aa.ws         AS ws_after
FROM expansion_picks p
LEFT JOIN player_totals    b  ON b.player  = p.player_name AND b.season  = p.draft_year - 1
LEFT JOIN player_totals    a  ON a.player  = p.player_name AND a.season  = p.draft_year
LEFT JOIN player_advanced  ab ON ab.player = p.player_name AND ab.season = p.draft_year - 1
LEFT JOIN player_advanced  aa ON aa.player = p.player_name AND aa.season = p.draft_year;