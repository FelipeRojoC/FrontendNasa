# EDA plan: unified MODIS + VIIRS hotspot table

Input: `NASA_Data_Sources/processed/hotspots/` built by `scripts/build_hotspots.py` (8,042,380 rows).
Scope: Chile and Argentina, November 2000 to 13 November 2026.
This version replaces the first plan. It adds strict time handling, the population data
(`scripts/download_population.sh`) and the past fire cases (`docs/population-and-past-fires.md`).

## Why this EDA

The EDA has to answer four questions before we build anything:

1. **Which day does a hotspot belong to?** The table stores UTC. Chile and Argentina are 3 to 5 hours
   behind, and the satellites pass at fixed local solar times. A wrong day key splits a satellite pass
   in two and creates artefacts that affect one sensor and not the other.
2. **Is the merged table trustworthy?** Gaps, duplicates, provisional data, collection versions,
   non-fire sources, rows without region.
3. **How different are MODIS and VIIRS, and where?** This decides the harmonisation method.
4. **What do seasonality, anomalies and exposure look like per region?** This decides how the burn
   calendar, the risk model and the population layer are built.

Columns of the table are described in `README.md` and `CLAUDE.md`. Earlier facts (row counts, country
labels, peak year) are in `CLAUDE.md`.

## Facts measured on the table

Read-only checks made on 2026-11-14. Notebook 00 must reproduce them.
"Local solar time" means UTC hour + longitude / 15. It is the clock the orbits follow, and it does
not depend on time zones or daylight saving time.

| Topic | Result |
|---|---|
| `acq_time` | It is UTC, with 1-minute resolution and no missing values. API files come without leading zeros (`48` means 00:48); the build already pads them. |
| Civil date vs UTC date | They differ only for Terra: 14.15% of its rows (the night pass, about 22:30 local). For Aqua and VIIRS, 0%. |
| Civil midnight | It splits the Terra night pass. Argentina: 86,043 rows at 23 h and 63,529 at 00 h. Chile depends on daylight saving time: with UTC-4 most rows fall before midnight (4,523 vs 682 after), with UTC-3 most fall after it (19,493 vs 3,031 before). This artefact affects MODIS only. |
| Solar midnight | It splits the VIIRS night pass: about 2.4% of VIIRS night rows fall before solar midnight. |
| UTC midnight | Almost clean: only about 1,265 Terra rows sit within an hour of it (drift years). But the "UTC day" runs from about 20:00 to 20:00 local time. |
| 06:00 local solar time | 0 rows between 04:30 and 07:00, for every satellite and year. It is the only cut that splits no pass. |
| Month and year | Against UTC, the civil date moves 3,755 rows to another month and 386 to another year. The 06:00 cut moves 67,658 (0.84%) and 6,257. The effect is below 1% for monthly totals. It is not small for daily series. |
| Orbit drift | Median local solar time of the Terra day pass: about 10.2 h through 2021, then 10.0, 9.8, 9.5, 9.1 and 8.6 h in 2022-2026. Aqua: about 13.9 h through 2022, then 14.2, 14.5, 15.0 and 15.8 h in 2023-2026. VIIRS is stable (13.8 to 14.0 h). MODIS in 2023-2026 does not observe at the same hour as MODIS in 2003-2021. |
| `daynight` | It follows the sun angle, not the pass: 47 rows are flagged `N` in the afternoon pass (May to July, latitudes -35 to -54). |
| MODIS versions | One version per year: `6.2` in 2000-2017, `6.03` in 2018-2022, `61.03` from 2023 to August 2026, `6.1NRT` from September 2026. The change to `61.03` happens in the same year the drift starts, so MODIS alone cannot separate the two. |
| SP / NRT in 2026 | MODIS is SP through August. VIIRS is SP through July. August 2026 mixes final MODIS with provisional VIIRS. September 2026 (NRT) has roughly 2.5 to 4 times more rows than August and October. |
| End of data | Last complete UTC day: 2026-11-13. The 14th is partial. Suomi-NPP ends on 2026-11-02 at 04:23 UTC (3 rows that day). November 2026 has 13 days. |
| Aqua vs Suomi-NPP | Day pass, 2012-2022, per UTC date and 2° longitude bin: median time difference -6 minutes, but only 22.7% of cases are within 10 minutes and 88.7% within 60. "Near-simultaneous" holds for a subset. |
| Fire-days | Days with at least one detection per 0.25° cell, 2019-2021: VIIRS / MODIS is about 2.8 and Suomi-NPP / Aqua about 3.0, against 4-6 for point counts. It narrows the gap but does not close it. |
| Rows without `admin1` | 10,476, all from yearly files: Argentina 9,736, Chile 740. |
| Source asymmetries | Easter Island: 467 rows, yearly files only (the API bounding box stops at -76°). Malvinas/Falklands: 130 rows, API only (the IGN polygon includes the islands, the FIRMS yearly files do not). |
| Terra-only period | 51,236 rows before 2002-07-04 (no Aqua). |
| Civil time | 16 IANA zones in the data. Chile changes clocks at local midnight. Magallanes has stayed on UTC-3 since 2016-08-14 and Aysén since 2024-09-08. Argentina used UTC-2 in the summers of 2007-08 (all zones) and 2008-09 (some provinces), and UTC-4 in mid-2004 (western provinces) and in 2008-2009 (San Luis). |
| Environment | `tzdata` 2025b is installed and has `America/Coyhaique`. Team laptops run on Chile time, so any tool that uses the session time zone gives different results from a server on UTC. `duckdb`, `rasterio`, `geopandas` and `pytest` are not installed. WorldPop is not downloaded yet. |

## Time rules

These rules apply to the EDA, the pipeline and the web app.

1. **Store one instant: UTC with an explicit zone.** No naive datetimes, no `datetime.now()` without a zone.
2. **Three clocks, one per kind of question.**
   - UTC: storage, time differences, joins, reconciliation with FIRMS.
   - Local solar time: everything about the sensor (passes, drift, day cut).
   - Civil time (IANA zone per region): everything about people (displayed hour, day of week, reported
     dates of past fires).
3. **The day key is `burn_date`**: the day from 06:00 to 06:00 local solar time, computed as
   `date(UTC + longitude / 15 h - 6 h)`. The afternoon and the following night stay in the same day.
   Daily weather for the risk model is aligned the same way. This decision is taken.
4. **Week, month, year and season derive from `burn_date`**, never from the UTC `acq_date` or the civil
   date. Season means July to June (the CONAF convention); the calendar year is also reported.
5. **Time differences use UTC instants only** (Aqua / Suomi-NPP pairs, event clustering, duration).
6. **Civil conversion always goes from UTC to local.** Date ranges chosen by the user filter the
   `burn_date` column. No local time is converted to UTC, so repeated or missing hours at clock changes
   cannot cause errors.
7. **Never compare a partial period with a complete one.** The current month is compared with the median
   of the same days (1 to N) of every year. The "data through" date comes from the data, per satellite,
   not from the clock.
8. **Tools.**
   - DuckDB: `SET TimeZone='UTC'` and group by the `burn_date` column.
   - pandas: do not drop the zone before deriving fields.
   - API: instants in ISO 8601 with `Z`, dates as `YYYY-MM-DD` text.
   - Frontend: never `new Date('2024-02-02')` (it displays as 1 February in Chile).
   - CSV export: FIRMS' UTC columns untouched, plus the local columns.
9. **Guards in the build**: fail if a detection is closer than 30 minutes to the 06:00 cut, if an instant
   is missing, or if an IANA zone is not available.

## Step before the EDA: time fields in the table

- New module `scripts/timefields.py`, used by `scripts/build_hotspots.py` (in `normalise()` and after
  `label_regions()`) and by the notebooks.
- New columns: `solar_time_h`, `pass_slot` (`day_pass` from 06 to 18 h local solar time, otherwise
  `night_pass`), `burn_date`, `burn_year`, `burn_month`, `season_year`, `tz_name`, `utc_offset_min`,
  `local_wall_time`, `local_date`.
- `acq_date`, `year`, `month` and the `year=` partition stay in UTC (compatible with FIRMS) and are
  documented as UTC.
- Civil zone from `country` + `admin1` (40 regions mapped to 15 zones). Easter Island is set by longitude.
  Rows without `admin1` take the zone of the nearest region.
- `tests/test_timefields.py` with the edge cases:
  - Terra night pass in summer and in winter.
  - VIIRS night pass (Valparaíso, 2024-02-03 05:30 UTC belongs to `burn_date` 2024-02-02).
  - New Year's night (year and season change).
  - Both Chilean clock changes (repeated hour and missing hour at midnight).
  - Magallanes and Aysén against Santiago.
  - Argentina in the summer of 2008-09 (provinces with and without daylight saving time), San Luis on UTC-4.
  - Easter Island, 29 February, drifted passes of 2026, `N` flag in the afternoon in austral winter.
  - `acq_time` values `0`, `48` and `2359`.
- `requirements.txt`: pin `tzdata>=2025.2`, add `pytest`. Add `duckdb`, `rasterio` and `pyproj` when the
  blocks that need them start.

## Periods of the record

Every analysis is reported per period or controls for it.

| Period | Dates | Satellites |
|---|---|---|
| E1 | 2000-11 to 2002-07 | Terra only |
| E2 | 2002-07 to 2012-01 | Terra + Aqua |
| E3 | 2012-01 to 2018-04 | + Suomi-NPP |
| E4 | 2018-04 to 2023-03 | + NOAA-20 (MODIS orbits stable through 2021) |
| E5 | 2023-03 to 2026-11-02 | + NOAA-21, MODIS drifting, collection `61.03` |
| E6 | from 2026-11-02 | No Suomi-NPP, NRT data |

## EDA blocks

Priority: **P0** blocks the calendar. **P1** improves it and covers the population and past fire data.
**P2** is the risk layer. Block 0 and the time fields come first; after that, blocks can be split among
the team. One notebook per block in `notebooks/`.

### Block 0. Time audit (P0): `00_time_audit.ipynb`

- 0.1 Confirm the source is UTC from the local solar time peaks per satellite. Check format and range of `acq_time`.
- 0.2 Rows that change day, month, year and season under each convention (UTC, civil, solar, `burn_date`),
  per satellite, region and year.
- 0.3 Rows per half hour of local solar time, per satellite and year. Confirm the 06:00 cut is always
  empty, also per latitude band (passes spread more in Patagonia).
- 0.4 `pass_slot` against `daynight` and against computed sun elevation: summer and winter twilight at
  high latitudes.
- 0.5 Terra and Aqua drift per year and latitude band. Fix the stable-orbit period.
- 0.6 Civil time: assigned zones, observed offsets, rows inside clock-change hours.
- 0.7 End of coverage per satellite. Partial days and months at the start and end of each satellite.
- 0.8 Calendars: calendar year against the July-June season. ISO week (with week 53) against 52 fixed
  7-day bins with 29 February merged into 28 February.
- 0.9 Sensitivity of the final metrics (monthly count, fire-days, ranking of years) to the day
  convention. Write the decision record.

### Block 1. Integrity and quality (P0): `01_quality.ipynb`

- 1.1 Availability per satellite and day: outages, partial months, days with zero detections over the whole domain.
- 1.2 Near duplicates (same satellite and minute, closer than about 100 m). Re-observations by consecutive
  orbits in the south. The seam between yearly and API files (December 2025 / January 2026) and the
  seams between the 5-day API chunks.
- 1.3 Ranges: missing, zero or extreme FRP, saturated or abnormal brightness temperatures, `scan_km` and
  `track_km` per instrument.
- 1.4 SP against NRT per satellite and month. August 2026 is mixed. Is September 2026 a real peak or an
  NRT effect? Compare per region and with earlier years. Keep a dated copy of the NRT files to measure
  the revision when SP replaces them.
- 1.5 MODIS versions: MODIS / VIIRS and Terra / Aqua ratios, and the distributions of confidence, FRP and
  brightness, on both sides of 2017-2018 and 2022-2023. Direct test: download one month of an old year
  through the API and match it row by row with the yearly file.
- 1.6 `fire_type`: share per type, sensor, year and region. Map types 1 to 3. Build a static-source mask
  from the SP years (fine cells with persistent detections and no seasonality) to flag NRT rows and
  unlabelled sources (smelters, gas flares, volcanoes, false positives in northern Chile).
- 1.7 Confidence: distribution per sensor, day/night and scan angle. Effect of dropping `low` on counts
  and on the ratio between sensors. The two scales are not equivalent, so the filter is evaluated per sensor.
- 1.8 Geography: map the 10,476 rows without region and their distance to the nearest polygon. Assign
  them to the nearest region within a tolerance. Count the API points that were dropped inside the same
  tolerance (source asymmetry). Review the 1,205 border disagreements. Flag Easter Island and
  Malvinas/Falklands as outside the analysis.
- 1.9 Scan geometry: pixel size and counts per scan angle. Duplicated detections at the edge of the MODIS swath.

### Block 2. Observation effort (P1): `02_observation_effort.ipynb`

The table has detections only, with no cloud or overpass information. This block builds indirect measures.

- 2.1 Satellites operating per day. Passes per day by latitude (more overlap in the south).
- 2.2 Static sources as witnesses: monthly detection rate per satellite at persistent gas flares and
  smelters, as an indirect indicator of clouds, outages and sensitivity.
- 2.3 Regions with few detections: little fire, or poor observation? Optional: external monthly cloud cover.
- 2.4 How the app words "no detections" (it does not mean "no fire").

### Block 3. MODIS against VIIRS in the overlap 2012-2026 (P0, core): `03_modis_vs_viirs.ipynb`

- 3.1 Counts and VIIRS / MODIS ratio over time: national, per regime, region and cell. With bootstrap
  intervals and a minimum number of detections.
- 3.2 Like-for-like comparison: Aqua against Suomi-NPP per `pass_slot` (afternoon and night separately).
  Terra has no VIIRS counterpart: decide how it enters. The Terra-only period (E1) is treated separately.
- 3.3 What the ratio depends on: season, regime, FRP, day/night, scan angle, latitude, year, confidence
  and `fire_type` filters.
- 3.4 Drift: do the Aqua / Suomi-NPP and Terra / Aqua ratios change in 2023-2026? Proposed calibration
  window: 2012-2021, with 2022-2026 as a test.
- 3.5 Near-simultaneous pairs on UTC instants, stratified by time difference (10, 30 and 60 minutes).
  Spatial tolerance from the real pixel size. MODIS omission curve against the FRP of the VIIRS cluster.
  MODIS detections with no VIIRS match.
- 3.6 FRP: distribution per sensor, minimum detectable FRP against scan angle, FRP summed per cell and `burn_date`.
- 3.7 Events: cluster points in space and time. Points per event and events per cell-month, per sensor.
- 3.8 Fire-days (cell × `burn_date`) at 0.25° and 0.1°, for all passes and for the afternoon pass only.
- 3.9 Number of VIIRS satellites (1, 2, 3, then back to 2): calibrate NOAA-20 and NOAA-21 against
  Suomi-NPP in their overlaps.
- 3.10 Harmonisation candidates: ratio per regime and month with shrinkage, quantile mapping, fire-days,
  FRP threshold, events. Evaluate with leave-one-year-out: error of the equivalent monthly count,
  removal of the 2012 step, and whether the ranking of years and months is kept.
- 3.11 Risk of extrapolating to 2000-2011: stability of the ratio between the first and second half of the overlap.

### Block 4. Temporal patterns and burn calendar (P0): `04_calendar.ipynb`

- 4.1 Year × month heatmap per region and regime, per sensor and with each harmonised candidate. Ordered
  by calendar year and by season.
- 4.2 Seasonality per regime: peak month, season length, daily climatology.
- 4.3 Monthly median, quartiles and percentiles. Anomalies (ratio to the median, percentile, score on a
  log scale) that stay robust with low counts and zeros.
- 4.4 Current month against the median with the same day cut (1 to 13 November), with Suomi-NPP ended
  and NRT data.
- 4.5 Years and months with most fire, and how stable the ranking is across sensor, method, day
  convention, calendar year or season, and filters.
- 4.6 Afternoon / night share per regime and sensor. Weekly cycle by civil date (human-caused burning).
- 4.7 Trends: only with control for the periods (E1 without Aqua, number of satellites, drift).

### Block 5. Spatial patterns (P1): `05_spatial.ipynb`

- 5.1 Density maps per sensor and period. A 0.25° cell loses about 40% of its area between 20°S and 55°S:
  use detections per km² or compare with an equal-area grid.
- 5.2 Fire regimes: group cells by seasonality and compare them with administrative regions.
- 5.3 Persistent points, and evaluation of the static-source mask.
- 5.4 Cells with very few detections: minimum aggregation level for the calendar and the model.
  Consistency along the Andean border.

### Block 6. Past fire cases (P1): `06_case_studies.ipynb`

- 6.1 Case register (place, reported local dates, time zone, source) from
  `docs/population-and-past-fires.md`: Valparaíso February 2024, Ñuble / Biobío / La Araucanía February
  2023, Chile 2017, Puerto Patriada January-February 2026, Córdoba September 2024, Corrientes
  January-February 2022, Chilecito July 2026.
- 6.2 For each case: `burn_date` window, timeline per satellite and pass (UTC and civil hour), first
  detection against the reported start, MODIS against VIIRS points for the same event, processing level.
- 6.3 Do the month and region of the case show up as a high anomaly in the calendar?
- 6.4 Correction needed in `docs/population-and-past-fires.md`: it says the 2017 season falls in the
  MODIS-only period, but Suomi-NPP has data since January 2012. A MODIS-only case must be earlier than
  2012. Candidates to verify with a source: Paraná Delta in April 2008, Torres del Paine in December 2011.

### Block 7. Population and exposure, WorldPop (P1): `07_population.ipynb`

- 7.1 Download (`scripts/download_population.sh`) and check the rasters: coordinate system, no-data
  value, country totals against the censuses (Chile 2024, Argentina 2022).
- 7.2 Aggregate to the grid by summing, never by averaging or interpolating. Table `population_grid`
  per cell and year.
- 7.3 WorldPop covers 2015-2030: decide which population to use for 2000-2014 (hold 2015, or use GHSL
  or GPW) and state it as a limit.
- 7.4 Population within 1, 5 and 10 km of each event, with distances in metres (one degree of longitude
  is 96 km at 30°S and 64 km at 55°S).
- 7.5 Detections per population density class and per sensor: does VIIRS add small fires near populated
  areas? Apply the static-source mask first (industry next to cities).
- 7.6 Validation with the cases: Valparaíso 2024 (small area, high exposure) against February 2023
  (large area, lower exposure).
- 7.7 Limits: exposure is not damage. Residential population only, no tourists. The population year and
  the fire year can differ.

### Block 8. Inputs for the risk model (P2): `08_risk_inputs.ipynb`

- 8.1 Target per cell and week on `burn_date`. Share of zeros. Definition of a large fire.
- 8.2 Baseline: historical median per cell and week. Temporal validation (train on the past, test on the future).
- 8.3 Persistence, and temporal and spatial autocorrelation.
- 8.4 Information leaks: NRT months, climatology built with future data, harmonisation factors fitted on test years.
- 8.5 Weather alignment: aggregate hourly UTC data to the same 06:00-06:00 day. Do not use daily
  aggregates from an API without setting its time zone.

## Outputs of the EDA

- One notebook per block in `notebooks/`, all reading the table with the time fields.
- Derived tables in `NASA_Data_Sources/processed/`: daily counts per cell, satellite and pass; static-source
  mask; events; population per cell.
- `docs/eda-findings.md`: decision record (day convention, grid, week, filters, calibration window,
  harmonisation method to try first).

## Decisions

Taken: the day key is `burn_date` (06:00 to 06:00 local solar time). Block 0 documents it with numbers
and the build keeps the guard.

Open, with the proposed value:

| Decision | Proposal |
|---|---|
| Week | 52 fixed 7-day bins, 29 February merged into 28 February |
| Year | Show both the calendar year and the July-June season |
| Grid | 0.25° to explore, with density per km²; also test 0.1° |
| Filters | Drop `fire_type` 1-3 in SP rows, static-source mask in NRT rows; `low` confidence is decided in 1.7 |
| Calibration window | 2012-2021 (stable orbits); 2022-2026 as a test |
| Reference pair | Aqua against Suomi-NPP, per pass |
| Easter Island and Malvinas/Falklands | Outside the analysis, flagged |
| Population before 2015 | Hold 2015 and state it |

## How to verify the EDA work

- `pytest tests/test_timefields.py` passes every edge case.
- The rebuilt table keeps 8,042,380 rows and the totals per satellite. The build guards do not fire.
- Notebook 00 reproduces the numbers in "Facts measured on the table".
- Reconciliation with FIRMS: the count per UTC `acq_date` of a raw file equals the count in the table.
- Counts per `burn_date` add up to the number of rows after filters.
- Valparaíso appears on `burn_date` 2 and 3 February 2024, with civil hours consistent with the reports.
