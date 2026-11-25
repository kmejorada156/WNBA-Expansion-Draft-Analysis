# What Do WNBA Expansion Teams Get From Their Picks?

**An analysis of every WNBA expansion draft (1998–2026) using PostgreSQL and Tableau**

🔗 **Interactive dashboard:** [[Tableau Public link here](https://public.tableau.com:9443/views/wnba_expansion/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)]

![Dashboard preview](<img width="1501" height="1046" alt="dashboard" src="https://github.com/user-attachments/assets/672f97d4-c7cf-481e-a479-bd0af78f363e" />)

---

## The Question

The WNBA is in the middle of its largest expansion ever. Golden State joined in 2025, Toronto and Portland in 2026, and Cleveland, Detroit and Philadelphia have been approved to join in the coming years. Each new team builds its first roster largely through an **expansion draft**, choosing from players that existing teams leave unprotected.

This project asks the question an incoming general manager would face:

> **What did expansion teams actually get from their picks, and what kinds of players held up best?**

## Data

| Source | What it provided |
|---|---|
| Wikipedia | Expansion draft picks for 1998, 1999, 2000, 2006, 2008, 2025 and 2026 (entered manually) |
| Basketball Reference | Player season totals and advanced stats (win shares, offensive/defensive rating, usage) |
| Basketball Reference / Wikipedia | Player birth dates (entered manually for each pick) |

**Seasons used:** 1997–2001, 2005–2009, and 2024–2026. These are the seasons before and after each expansion draft.

**Final dataset:** 99 expansion picks across 7 drafts and 11 expansion teams.

### Database tables
- `expansion_picks`: one row per pick (year, expansion team, pick number, player, former team, birth date, notes)
- `player_totals`: season totals for every player
- `player_advanced`: advanced stats for every player
- `pick_outcomes` (view): each pick joined to her stats for the season **before** the draft and the season **after** it

## Data Cleaning

- **Skipped picks removed.** Some drafts had picks where no selection was made (e.g. the 12th and 22nd picks in 2026). Those rows were removed and the original pick numbers kept.
- **Picks who never played kept, not deleted.** 21 of 99 picks never played for their new team. They were labeled in a `notes` column and counted as misses, since leaving them out would make expansion picks look more successful than they were.
- **Traded players.** Players traded mid-season appear on several rows in Basketball Reference. Only the season-total (`TOT`) row was kept.
- **Name matching.** Names from Wikipedia were matched to Basketball Reference using:
  - `unaccent()` so accented and unaccented spellings match
  - `pg_trgm` fuzzy matching to catch spelling differences
  - a first-name + season check to catch married-name changes
  - Every remaining mismatch was checked by hand on Basketball Reference.
- **Age.** Calculated in SQL from birth date as of May 15 of the draft year (roughly the start of the season).

## Findings

### 1. On average, expansion picks played about as well as before. But about 1 in 5 never played for their new team.
Among the 71 picks who played both before and after the draft, average win shares barely changed (0.76 → 0.78) and minutes held steady (515 → 511). However, **21 of 99 picks (21%) never played a game for their new team**, including productive players such as Sandy Brondello (2.6 win shares the season before).

### 2. Young players improved most; veterans were the most likely to actually play.
| Age group | Picks | % who played after | Avg. change in win shares |
|---|---|---|---|
| Under 25 | 34 | 79.4% | **+0.43** |
| 25–29 | 46 | 73.9% | −0.28 |
| 30+ | 19 | **89.5%** | −0.03 |

Under-25 picks were the only group that improved. Players in their prime (25–29) declined the most and were the least likely to play for their new team.

### 3. Guards were the most likely to play for their new team.
| Position | Picks | % who played after | Avg. change in win shares |
|---|---|---|---|
| Guard | 42 | **90.5%** | +0.08 |
| Center | 16 | 75.0% | +0.10 |
| Forward | 36 | 77.8% | −0.11 |

Guards and centers held their value. Guards were also much more likely to play for their new team.

### 4. Modern expansion picks have done better than early ones.
| Era | Picks | % who played after | Avg. change in win shares |
|---|---|---|---|
| Early (1998–2008) | 66 | 75.8% | −0.23 |
| Modern (2025–26) | 33 | **84.8%** | **+0.53** |

Modern picks played for their new teams more often and improved more. With only 33 picks, though, the modern average is heavily influenced by a few standout seasons (see below).

### 5. Breakout picks took two different paths.
| Player | Draft | Win shares before → after | Change |
|---|---|---|---|
| Veronica Burton | 2025 Golden State | 1.7 → 6.4 | +4.7 |
| Tari Phillips | 2000 Portland | −0.6 → 3.8 | +4.4 |
| Marina Mabrey | 2026 Toronto | −1.1 → 1.5 | +2.6 |
| Kara Wolters | 2000 Indiana | 0.2 → 2.7 | +2.5 |
| Carla Leite | 2026 Portland | 0.8 → 3.0 | +2.2 |

Most of the top 10 improvers had elite defensive ratings. The exceptions were three guards whose offensive ratings jumped, and they got there in two different ways:
- **Opportunity:** Carla Leite and Sarah Ashlee Barker had higher usage after the draft. The expansion team gave them a bigger role than their previous team had.
- **Efficiency:** Marina Mabrey's usage stayed the same, but she became much more efficient, bouncing back from an unusually weak season.

### 6. A player's most recent season is a misleading guide.
For the 25 picks with two seasons of history before the draft:

| Season before the draft | Players | Avg. change after draft | % who improved |
|---|---|---|---|
| Down year (dropped 0.5+ win shares) | 11 | **+0.61** | **81.8%** |
| Steady | 4 | −0.25 | 25.0% |
| Up year (gained 0.5+ win shares) | 10 | **−0.85** | 20.0% |

Players coming off a down year usually bounced back, but only partially: they still finished 0.84 win shares below their level two seasons earlier. Players coming off a career year usually fell back. Both groups moved back toward their normal level, a statistical effect called regression to the mean.

## Recommendations for Future Expansion Teams

1. **Judge players on several seasons, not the most recent one.** Players coming off a career year tend to decline, and players coming off a down year tend to partly recover.
2. **Use young players for upside and veterans for reliability.** Under-25 picks improved most; 30+ picks were the most likely to actually play.
3. **Look for young players without a role on deep rosters.** Leite and Barker improved when an expansion team gave them a bigger role.
4. **Confirm a player will report before picking her.** About 1 in 5 picks never played for their new team. Overseas commitments, injuries and retirement plans should be checked before the draft.
5. **Guards are the safest picks.** Guards played for their new team 90.5% of the time, compared with 75–78% for forwards and centers.

## Limitations

- **Small sample.** 99 picks in total, and some groups are much smaller (e.g. 25 players in the down-year analysis, 4 "steady" players). These findings are patterns in this data, not rules.
- **Limited time after the draft.** 2026 picks have only one season of results.
- **The league has changed.** Season length, roster rules and pay are very different in 2026 than in 1998.
- **Season totals depend on season length.** Early seasons had fewer games, so comparisons across eras focus on changes and percentages rather than raw totals.
- **Win shares partly reflect team context.** Defensive rating and defensive win shares depend heavily on teammates, so moving to a weaker team can lower a player's numbers.
- **Draft picks only.** This analysis covers players who were selected, not the full pool of unprotected players teams could have chosen.

## Tools

- **Excel:** manual data entry and cleaning
- **PostgreSQL / pgAdmin:** database, cleaning queries, and analysis (views, CTEs, window functions, `unaccent`, `pg_trgm`)
- **Tableau Public:** interactive dashboard

## Repository Structure

```
├── data/
│   ├── expansion_picks.csv
│   ├── player_totals.csv
│   └── player_advanced.csv
├── sql/
│   ├── create_tables.sql
│   ├── data_checks.sql
│   ├── analysis_queries.sql
│   └── export_for_tableau.sql
├── exports/
│   └── tableau_data.csv
├── images/
│   └── dashboard.png
└── README.md
```
