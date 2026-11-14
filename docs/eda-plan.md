# EDA plan: unified MODIS + VIIRS hotspot table

Input: `NASA_Data_Sources/processed/hotspots/` built by `scripts/build_hotspots.py`.
Scope: Chile and Argentina, November 2000 to November 2026.

## Why this EDA

The EDA has to answer three questions before we build anything:

1. **Is the merged table trustworthy?** Gaps, duplicates, provisional data, non-fire sources.
2. **How different are MODIS and VIIRS, and where?** This decides the harmonisation method.
3. **What do seasonality and anomalies look like per region?** This decides how the burn calendar
   and the risk model (our added value) are built.

## The unified table

One row per hotspot. Columns that matter for the EDA:

| Column | Meaning | Note |
|---|---|---|
| `acq_datetime`, `acq_date`, `acq_time`, `year`, `month` | Acquisition time (UTC) | `acq_time` is HHMM |
| `daynight` | `D` / `N` | |
| `latitude`, `longitude` | Position | |
| `country`, `admin1` | Country and region/province from boundary polygons | `country_firms` keeps FIRMS' label (yearly rows) |
| `instrument`, `satellite` | `MODIS` (Terra, Aqua) / `VIIRS` (Suomi-NPP, NOAA-20, NOAA-21) | |
| `processing`, `version` | `SP` (final) or `NRT` (provisional) | NRT only from late 2026 |
| `confidence_level` | `low` / `nominal` / `high` | MODIS mapped from 0-100 (<30, 30-79, >=80) |
| `confidence_pct`, `confidence_raw` | Original values | `confidence_pct` is MODIS only |
| `bright_mir_k`, `bright_tir_k` | Brightness temperature, mid and thermal IR (K) | MODIS T21/T31, VIIRS I4/I5: similar bands, not identical |
| `frp_mw` | Fire radiative power (MW) | Not burned area |
| `scan_km`, `track_km`, `pixel_area_km2` | Real pixel size | Grows towards the swath edge |
| `fire_type` | 0 vegetation, 1 volcano, 2 other static land source, 3 offshore | Empty in NRT rows |
| `source`, `source_file` | `country_yearly` or `api_bbox` | For traceability |

Sensor coverage: MODIS 2000-11 →, Suomi-NPP 2012-01 → 2026-11-02, NOAA-20 2018-04 →, NOAA-21 2023-03 →.
**MODIS and VIIRS overlap from 2012 to 2026: that window is where the harmonisation is calibrated.**

## What the merge already shows

First numbers from the merged table (8,042,380 rows after dropping 3 exact duplicates and
1,149,423 API points outside Chile and Argentina):

- **Country and region labels are consistent.** Our polygons agree with FIRMS' country label on
  99.98% of yearly rows (1,205 disagree, all near the Chile-Argentina border). 10,476 yearly rows
  (0.15%, mostly coastal) fall outside the simplified polygons and keep FIRMS' label without `admin1`.
- After clipping, NOAA-21 is in line with NOAA-20 (2024: 176,590 vs 179,307 points). Before clipping
  the bounding box made it look three times larger.
- Most points are in northern Argentina (Formosa, Santa Fe, Corrientes, Santiago del Estero, Chaco,
  Salta: about 1 million to 550 thousand each). La Araucanía is the Chilean region with most points.
- **VIIRS detects about 4-6 times more points than MODIS per satellite** in yearly files
  (for example 2013: Suomi-NPP 261k, Aqua 46k). Section 2 checks how this ratio varies.
- **MODIS mixes collection versions** (`6.03`, `6.2`, `61.03`, `6.1NRT`). Check which years use which,
  and whether counts jump when the version changes.
- `fire_type` is empty only in NRT rows (298,972). In SP rows, static land sources (type 2) are
  about 4% of VIIRS and MODIS points.
- 2020 is the peak year for every satellite in the record.

## 1. Data quality

- Row counts per satellite and month: find gaps and outages. Plot a satellite × month availability grid.
- `acq_time` histogram per satellite and year. Check whether Terra and Aqua overpass times drift in
  recent years, which would change what MODIS can see.
- Share of each `fire_type`. Decide to drop volcanoes (1), static sources such as gas flares (2) and
  offshore (3). Map type 2 points to confirm where they are.
- NRT rows have no `fire_type`. Check how many fall on known static sources (flag them by location,
  using the SP years).
- `confidence_level` share per sensor. Test how counts change with and without `low`.
- Points near the Chile-Argentina border and on the coast (rows without `admin1`).

## 2. MODIS vs VIIRS in the overlap (2012-2026)

The core of the challenge. All on a common grid (start with 0.25°, also test 0.1°) and time step (month, then week).

- Monthly counts per sensor, national and per region. Ratio VIIRS / MODIS over time.
- The ratio by season, region, land cover and fire size (FRP). Is it stable, or does it depend on these?
  A stable ratio supports a simple scaling; a variable one needs a model per region or month.
- **Near-simultaneous pairs:** Aqua and Suomi-NPP pass at about 13:30 local time. Match their detections
  in the same place and hour to see what VIIRS detects that MODIS misses (by FRP, size, day/night).
- FRP distributions per sensor. Estimate the FRP below which MODIS rarely detects a fire. Dropping
  VIIRS detections under that threshold is one harmonisation candidate.
- Detections per fire: cluster points into events (space and time) and compare points per event per sensor.
  Counting events instead of points may reduce the resolution effect.
- Day/night split per sensor: VIIRS detects more at night.
- Effect of the number of satellites: compare Terra+Aqua vs Aqua only, and Suomi-NPP vs Suomi-NPP+NOAA-20.

## 3. Temporal patterns (burn calendar)

- Year × month heatmap of counts per region: this is the first draft of the burn calendar.
- Seasonality per region: central and southern Chile (Nov-Mar), Córdoba (Aug-Oct), Chaco, Patagonia.
- Monthly median and percentiles over the years per region, and anomaly of each month against them.
- Top years and months per region. Check against known events (Chile 2016-17 and 2022-23, Córdoba 2024,
  Corrientes 2022, Patagonia 2026).

## 4. Spatial patterns

- Density maps per sensor and period on the grid.
- Persistent hotspots: agricultural burning, industrial sources not flagged as static.
- Regions with very few detections: low activity, or poor observation (clouds in the south)?

## 5. Inputs for the risk model (added value)

- Target candidates: hotspots or events per cell and week, and probability of at least one event.
- How skewed the target is (many zeros, few large events). This decides the model and the metric.
- Baseline to beat: the historical median per cell and week.
- External data the model would need (weather, land cover, population) is listed in
  `docs/research-and-plan.md`. It is not part of this EDA.

## Outputs of the EDA

- Notebook(s) in `notebooks/`, one per section.
- A short summary in `docs/` with the chosen grid, time step, filters (`fire_type`, `confidence`)
  and the harmonisation method to try first.

## Open decisions

- Grid resolution and time step.
- Whether to filter `low` confidence.
- Satellites per sensor: all, or one per sensor for a cleaner comparison.
- Whether to group regions into fire regimes (for example Chaco, Pampas, central Chile, Patagonia)
  instead of using administrative regions.
