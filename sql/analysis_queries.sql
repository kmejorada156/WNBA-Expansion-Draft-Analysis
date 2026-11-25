--------------------------------------------------------------
-- Q1: How productive were expansion picks overall? 
--------------------------------------------------------------
-- Compare avg minutes and win shares before v. after
-- 1a. Players who played in BOTH seasons
SELECT COUNT(*)                                          AS players_compared,
       ROUND(AVG(minutes_before)::numeric, 1)            AS avg_minutes_before,
       ROUND(AVG(minutes_after)::numeric, 1)             AS avg_minutes_after,
       ROUND(AVG(ws_before)::numeric, 2)                 AS avg_ws_before,
       ROUND(AVG(ws_after)::numeric, 2)                  AS avg_ws_after,
       ROUND(AVG(ws_after - ws_before)::numeric, 2)      AS avg_ws_change
FROM pick_outcomes
WHERE ws_before IS NOT NULL
  AND ws_after  IS NOT NULL;

-- 1b. Every pick, counting "did not play after" as 0
--     (what the expansion team actually got from each pick)
SELECT COUNT(*)                                               AS total_picks,
       COUNT(minutes_after)                                   AS played_after,
       ROUND(100.0 * COUNT(minutes_after) / COUNT(*), 1)      AS pct_played_after,
       ROUND(AVG(COALESCE(minutes_after, 0))::numeric, 1)     AS avg_minutes_after,
       ROUND(AVG(COALESCE(ws_after, 0))::numeric, 2)          AS avg_ws_after
FROM pick_outcomes;

-- ---------------------------------------------------------------------
-- Q2. Which ages held up best?
-- ---------------------------------------------------------------------
SELECT CASE WHEN age_at_draft IS NULL THEN 'Unknown'
            WHEN age_at_draft < 25    THEN 'Under 25'
            WHEN age_at_draft < 30    THEN '25-29'
            ELSE '30+' END                                    AS age_group,
       COUNT(*)                                               AS picks,
       COUNT(ws_after)                                        AS played_after,
       ROUND(100.0 * COUNT(minutes_after) / COUNT(*), 1)      AS pct_played_after,
       ROUND(AVG(ws_after - ws_before)::numeric, 2)           AS avg_ws_change
FROM pick_outcomes
GROUP BY age_group
ORDER BY age_group;

-- ---------------------------------------------------------------------
-- Q3. Did position matter?
-- Basketball Reference uses combo positions like 'G-F' and 'F-C'.
-- split_part() keeps the first (primary) position so groups aren't tiny.
-- To see the raw combos instead, group by position directly.
-- ---------------------------------------------------------------------
SELECT COALESCE(split_part(position, '-', 1), 'Unknown')      AS primary_position,
       COUNT(*)                                               AS picks,
       COUNT(ws_after)                                        AS played_after,
       ROUND(100.0 * COUNT(minutes_after) / COUNT(*), 1)      AS pct_played_after,
       ROUND(AVG(ws_after - ws_before)::numeric, 2)           AS avg_ws_change
FROM pick_outcomes
GROUP BY primary_position
ORDER BY avg_ws_change DESC NULLS LAST;

-- ---------------------------------------------------------------------
-- Q4. Were early-era drafts (1998-2008) different from modern (2025-26)?
-- Caution: season lengths differ across eras (fewer games in early
-- years), so season TOTALS aren't directly comparable. The % columns
-- and the change in WS are fairer; WS/40 would be fairer still if
-- you add it to the view.
-- ---------------------------------------------------------------------
SELECT CASE WHEN draft_year <= 2008 THEN 'Early (1998-2008)'
            ELSE 'Modern (2025-26)' END                       AS era,
       COUNT(*)                                               AS picks,
       COUNT(ws_after)                                        AS played_after,
       ROUND(100.0 * COUNT(minutes_after) / COUNT(*), 1)      AS pct_played_after,
       ROUND(AVG(age_at_draft)::numeric, 1)                   AS avg_age_at_draft,
       ROUND(AVG(ws_after - ws_before)::numeric, 2)           AS avg_ws_change
FROM pick_outcomes
GROUP BY era
ORDER BY era;
-- ---------------------------------------------------------------------
-- Q5. Who were the best and worst picks?
-- Only players with both seasons can have a change in WS.
-- ---------------------------------------------------------------------

-- 5a. Best 5: biggest improvement after the draft
SELECT draft_year,
       expansion_team,
       player_name,
       ws_before,
       ws_after,
       ws_after - ws_before AS ws_change
FROM pick_outcomes
WHERE ws_before IS NOT NULL
  AND ws_after  IS NOT NULL
ORDER BY ws_change DESC
LIMIT 5;

-- 5b. Worst 5: biggest decline after the draft
SELECT draft_year,
       expansion_team,
       player_name,
       ws_before,
       ws_after,
       ws_after - ws_before AS ws_change
FROM pick_outcomes
WHERE ws_before IS NOT NULL
  AND ws_after  IS NOT NULL
ORDER BY ws_change ASC
LIMIT 5;

-- 5c. Productive players who never played for the new team
--     (these don't appear in 5b because their ws_after is NULL)
SELECT draft_year,
       expansion_team,
       player_name,
       ws_before
FROM pick_outcomes
WHERE ws_after IS NULL
  AND ws_before IS NOT NULL
ORDER BY ws_before DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- Want to check offensive and defensive ratings of the best picks
-- ---------------------------------------------------------------------
WITH best_picks AS (
  SELECT draft_year,
         expansion_team,
         player_name,
         ws_after - ws_before AS ws_change
  FROM pick_outcomes
  WHERE ws_before IS NOT NULL
    AND ws_after  IS NOT NULL
  ORDER BY ws_change DESC
  LIMIT 10
)
SELECT bp.draft_year,
       bp.expansion_team,
       bp.player_name,
       bp.ws_change,
       b.ortg            AS ortg_before,
       a.ortg            AS ortg_after,
       a.ortg - b.ortg   AS ortg_change,
       b.drtg            AS drtg_before,
       a.drtg            AS drtg_after,
       a.drtg - b.drtg   AS drtg_change
FROM best_picks bp
LEFT JOIN player_advanced b
  ON b.player = bp.player_name AND b.season = bp.draft_year - 1
LEFT JOIN player_advanced a
  ON a.player = bp.player_name AND a.season = bp.draft_year
ORDER BY bp.ws_change DESC;

---------------------------------------------------------------------
-- compare defensive patterns
---------------------------------------------------------------------
WITH league_avg AS (
  SELECT season, AVG(drtg) AS lg_drtg
  FROM player_advanced
  WHERE mp >= 200          -- skip players with very few minutes
  GROUP BY season
),
picks AS (
  SELECT o.player_name,
         o.ws_after - o.ws_before AS ws_change,
         b.drtg - l.lg_drtg       AS drtg_vs_league   -- negative = better than average
  FROM pick_outcomes o
  JOIN player_advanced b
    ON b.player = o.player_name AND b.season = o.draft_year - 1
  JOIN league_avg l ON l.season = o.draft_year - 1
  WHERE o.ws_before IS NOT NULL AND o.ws_after IS NOT NULL
)
SELECT CASE WHEN drtg_vs_league <= -3 THEN '1. Elite defender (3+ better)'
			WHEN drtg_vs_league <= -2 THEN '2. Strong defender (2+ better)'
            WHEN drtg_vs_league <   2 THEN '3. Average'
            ELSE                           '4. Weak defender (2+ worse)' END AS defense_tier,
       COUNT(*)                               AS players,
       ROUND(AVG(ws_change)::numeric, 2)      AS avg_ws_change
FROM picks
GROUP BY defense_tier
ORDER BY defense_tier

--------------------------------------------
-- check veteran players with down years
--------------------------------------------
WITH history AS (
  SELECT o.draft_year,
         o.expansion_team,
         o.player_name,
         t2.ws        AS ws_two_before,
         o.ws_before,
         o.ws_after
  FROM pick_outcomes o
  JOIN player_advanced t2
    ON t2.player = o.player_name
   AND t2.season = o.draft_year - 2
  WHERE o.ws_before IS NOT NULL
    AND o.ws_after  IS NOT NULL
),
grouped AS (
  SELECT *,
         CASE WHEN ws_before - ws_two_before <= -0.5 THEN '1. Down year (dropped 0.5+ WS)'
              WHEN ws_before - ws_two_before >=  0.5 THEN '3. Up year (gained 0.5+ WS)'
              ELSE                                        '2. Steady' END AS year_before_draft
  FROM history
)
SELECT year_before_draft,
       COUNT(*)                                                       AS players,
       ROUND(AVG(ws_after - ws_before)::numeric, 2)                   AS avg_ws_change_after_draft,
       ROUND(AVG(ws_after - ws_two_before)::numeric, 2)               AS vs_two_seasons_before,
       ROUND(100.0 * SUM(CASE WHEN ws_after > ws_before THEN 1 ELSE 0 END) / COUNT(*), 1)
                                                                      AS pct_improved
FROM grouped
GROUP BY year_before_draft
ORDER BY year_before_draft;
