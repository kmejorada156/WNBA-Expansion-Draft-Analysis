-- =====================================================================
-- Export for Tableau
-- One row per expansion pick, with every calculated field the
-- dashboard needs, so Tableau only has to display, not calculate.
-- =====================================================================

SELECT o.draft_year,
       o.expansion_team,
       o.pick_number,
       o.player_name,
       o.former_team,
       o.age_at_draft,
       o.minutes_before,
       o.minutes_after,
       o.ws_before,
       o.ws_after,

       -- Change in win shares (NULL if she didn't play both seasons)
       o.ws_after - o.ws_before                                  AS ws_change,

       -- 1 = played for new team, 0 = didn't. Average it in Tableau for "% played"
       CASE WHEN o.minutes_after IS NOT NULL THEN 1 ELSE 0 END   AS played_after,

       -- 1 = improved, 0 = declined, NULL = can't compare
       CASE WHEN o.ws_before IS NULL OR o.ws_after IS NULL THEN NULL
            WHEN o.ws_after > o.ws_before THEN 1 ELSE 0 END      AS improved,

       CASE WHEN o.age_at_draft IS NULL THEN 'Unknown'
            WHEN o.age_at_draft < 25    THEN 'Under 25'
            WHEN o.age_at_draft < 30    THEN '25-29'
            ELSE '30+' END                                       AS age_group,

       CASE COALESCE(split_part(o.position, '-', 1), 'Unknown')
            WHEN 'G' THEN 'Guard'
            WHEN 'F' THEN 'Forward'
            WHEN 'C' THEN 'Center'
            ELSE 'Unknown' END                                   AS primary_position,

       CASE WHEN o.draft_year <= 2008 THEN 'Early (1998-2008)'
            ELSE 'Modern (2025-26)' END                          AS era,

       -- Rankings for the best/worst picks table (1 = best / worst)
       RANK() OVER (ORDER BY o.ws_after - o.ws_before DESC NULLS LAST) AS rank_best,
       RANK() OVER (ORDER BY o.ws_after - o.ws_before ASC  NULLS LAST) AS rank_worst,

       -- Season two years before the draft, for the down-year analysis
       t2.ws                                                     AS ws_two_before,
       CASE WHEN t2.ws IS NULL OR o.ws_before IS NULL OR o.ws_after IS NULL THEN NULL
            WHEN o.ws_before - t2.ws <= -0.5 THEN 'Down year'
            WHEN o.ws_before - t2.ws >=  0.5 THEN 'Up year'
            ELSE 'Steady' END                                    AS year_before_draft

FROM pick_outcomes o
LEFT JOIN player_advanced t2
  ON t2.player = o.player_name
 AND t2.season = o.draft_year - 2
ORDER BY o.draft_year, o.pick_number;