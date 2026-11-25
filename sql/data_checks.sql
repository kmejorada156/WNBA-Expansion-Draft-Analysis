-- Run checks on expansion_picks data --
-- Compare count to Wikipedia page where we received data from
SELECT draft_year, expansion_team, COUNT(*) AS picks
FROM expansion_picks
GROUP BY draft_year, expansion_team
ORDER BY draft_year, expansion_team;

-- Check team spellings
SELECT DISTINCT expansion_team FROM expansion_picks ORDER BY 1;
SELECT DISTINCT former_team    FROM expansion_picks ORDER BY 1;

-- Check for empty values
SELECT * FROM expansion_picks
WHERE player_name IS NULL OR draft_year IS NULL OR pick_number IS NULL;

-- Check for any duplicates
SELECT draft_year, pick_number, COUNT(*)
FROM expansion_picks
GROUP BY draft_year, pick_number
HAVING COUNT(*) > 1;

-- Run checks to see if players are missing in player_totals and player_advanced from expansion_picks
SELECT p.draft_year, p.player_name, p.former_team
FROM expansion_picks p
WHERE NOT EXISTS (
  SELECT 1 FROM player_totals t
  WHERE t.player = p.player_name
);

-- Running this to pull names from player_totals
SELECT season, player
FROM player_totals
WHERE player LIKE '%Conde' OR player LIKE 'Luisa%' OR player LIKE 'Nika%'

-- Fix accented names in expansion_picks
UPDATE expansion_picks
SET player_name = CASE player_name
	WHEN 'Nika Muhl' THEN 'Nika Mühl'
	WHEN 'Luisa Geiselsoder' THEN 'Luisa Geiselsöder'
	WHEN 'Maria Conde' THEN 'María Conde'
	ELSE player_name END;

-- Add text column to expansion_picks explaining drafted players who ended up not playing
ALTER TABLE expansion_picks ADD COLUMN notes TEXT;

UPDATE expansion_picks
SET notes = CASE player_name
	WHEN 'Adja Kane' THEN 'Never played in WNBA - rights only, went to NCAA'
	WHEN 'Molly Goodenbour' THEN 'Never played in WNBA - retired then started coaching'
	ELSE notes END;

-- Add column for birth_date to expansion_picks
ALTER TABLE expansion_picks ADD COLUMN birth_date DATE;
