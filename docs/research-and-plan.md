# Research and Plan: Harmonization of MODIS and VIIRS Hot Spots

> Background research, data sources, harmonization approaches and a proposed plan for our solution.
> Scope: **Chile and Argentina only**. Read `challenge-brief.es.md` first for the challenge requirements.
> Compiled on 2026-11-14. All sources are listed at the end.

---

## 1. Key context

### MODIS is ending, and S-NPP has already stopped

- NASA plans to end data collection for **Terra MODIS in January 2027** and **Aqua MODIS around September 2027**.
- Both satellites are **drifting out of their orbits**. This has affected MODIS pixel size, scan gaps and diurnal sampling, with significant impacts since late 2024.
- **Important:** FIRMS **stopped producing new Suomi NPP (S-NPP) VIIRS data on 2026-11-02**. Historical S-NPP data stays available, but **recent data must come from NOAA-20 and NOAA-21**.

### Overpass times matter

- **Aqua MODIS and S-NPP VIIRS** cross the equator at about 13:30 and 01:30 local time. Their observations are nearly simultaneous, so they are the natural pair for calibration.
- **Terra MODIS** is the only morning overpass (about 3 hours before Aqua). It has no VIIRS counterpart.
- **NOAA-20 and NOAA-21** fly in the same orbital plane as S-NPP, about 50 minutes apart.

### The sensor gap is large and region-dependent

- MODIS pixel is **1 km**, VIIRS pixel is **375 m**. VIIRS detects many more and smaller fires.
- A study in Northeast Asia found that MODIS missed **65%** of VIIRS fire pixels in forests and **83%** in low-biomass lands.
- A study across South America found the S-NPP/Aqua detection ratio ranged from **6.81 (Venezuela)** down to **3.87 (Chile, the lowest)**, and it varied a lot even inside a country.
- **Conclusion:** a single global correction factor is not enough. Calibration must be **regional and seasonal**.

---

## 2. Data sources

| Product | Coverage | Role in our project |
|---|---|---|
| MODIS C6.1 (Terra + Aqua), 1 km | 2000-11-01 to present | Historical record 2000–2011 |
| VIIRS S-NPP, 375 m | 2012-01-20 to 2026-11-02 | Calibration reference |
| VIIRS NOAA-20, 375 m | 2018-04-01 to present | Continuity |
| VIIRS NOAA-21, 375 m | 2024-01-17 to present | Continuity |

### How to get the data

- **Historical (bulk):** FIRMS yearly summaries by country as CSV. Download `CHL` and `ARG` for every year and sensor.
- **Recent (near real time):** FIRMS API `/api/area/csv/[MAP_KEY]/[SOURCE]/[AREA]/[DAY_RANGE]/[DATE]`. Requires a free MAP_KEY.
- NRT data is replaced by standard science-quality data with a lag of about 5 months. We must label recent months as provisional.
- **CONAE Hot Spot Catalog** (Argentina): web catalog of MODIS/VIIRS hot spots. Useful for validation and relevant to the challenge author, who works at CONAE.

### Filters to apply

| Field | Values | Our rule |
|---|---|---|
| `type` (standard data only) | 0 vegetation fire, 1 active volcano, 2 other static land source, 3 offshore | Keep only `0`. Critical for Andean volcanoes and northern Chile mining smelters. |
| `confidence` MODIS | 0–100 | Keep nominal and high (drop low) |
| `confidence` VIIRS | low / nominal / high | Keep nominal and high |

FIRMS also offers a **Static Thermal Anomalies** layer to remove industrial heat sources (gas flares, smelters, etc.).

---

## 3. How the literature approaches harmonization

- **Regional statistical calibration.** The NASA VIIRS burned area paper (VNP64A1) states that regional-scale statistical calibration will likely be needed to build a single consistent MODIS/VIIRS record.
- **Region and biome lookup tables.** GFED5NRT converts VIIRS active fire counts into values consistent with the MODIS-era record using region- and biome-specific lookup tables.
- **Quantile mapping.** Widely used to remove cross-sensor bias (MODIS FRP swath bias in CAMS GFAS, the MRBA60 harmonized burned area dataset).

---

## 4. Proposed solution approaches

### A. Calibration ratio per grid cell and month (baseline)

1. Common grid over Chile and Argentina (0.25° cells or H3 hexagons).
2. On the overlap period (2012–2025), compute the VIIRS/MODIS count ratio per region and month.
3. Shrink each local ratio toward the regional mean when the cell has few detections.
4. Apply the ratio to MODIS 2000–2011 to express it in **VIIRS-equivalent counts**.

Simple, explainable and easy to validate.

### B. Quantile mapping

Same idea as A, but maps the whole distribution of daily counts instead of a single factor. Better for extreme months (for example February 2017 or February 2023 in Chile).

### C. Fire-days metric

Instead of counting hot spots, count **days with at least one detection per cell**. Being binary, it is much less sensitive to pixel size. Useful as a second metric and as a cross-check.

### Recommendation

- **A as the baseline, C as a complementary metric, B if time allows.**
- Harmonize everything to **VIIRS scale**, because VIIRS is the future of the record.
- Calibrate with **Aqua vs S-NPP** (same overpass time). Link NOAA-20/21 to S-NPP on their overlap years.
- Validate with **leave-one-year-out** on the overlap period and show a **before/after chart** where the 2012 step disappears. This is the strongest evidence for the judges.

---

## 5. Architecture

```
FIRMS CSV (CHL, ARG) + FIRMS NRT API
        │
  [1] ingest     → type/confidence filters, unified schema
        │
  [2] grid       → assign cell + local date + sensor
        │
  [3] harmonize  → per cell/month factors, validation
        │
  [4] export     → aggregated Parquet (cell × day)
        │
  [5] API        → FastAPI + DuckDB (query by polygon and date range)
        │
  [6] frontend   → map + calendar + comparison + CSV export
```

### Suggested stack

| Layer | Tools |
|---|---|
| Pipeline | Python, pandas, DuckDB, geopandas |
| API | FastAPI |
| Frontend | React + Vite, MapLibre or Leaflet with polygon drawing, ECharts for the calendar heatmap |
| Colors | Accessible palettes (viridis, cividis) |

The aggregated data for two countries is small, so everything can be precomputed.

### App views (covering all brief requirements)

1. Map with area drawing or lat/lon input.
2. Burning activity calendar (year × month) with harmonized counts.
3. Current month vs historical median, with anomaly in standard deviations.
4. Ranking of the months and years with the most fire.
5. Before/after harmonization chart.
6. CSV download of the hot spots in the search.

---

## 6. Suggested 48-hour plan

| Block | Saturday | Sunday |
|---|---|---|
| Data | Download, filters, grid | Recent NRT data |
| Harmonization | Factors and validation | Before/after chart |
| Backend | DuckDB API | CSV and statistics endpoints |
| Frontend | Map and calendar | Comparison, anomalies, polish |
| Pitch | Storyline | Video, slides, submission |

### Demo cases

- **Chile, 2016–2017 season:** the worst on record, more than 570,000 ha burned.
- **Chile, 2022–2023 season:** about 430,000 ha, megafires in Ñuble and Biobío.
- **Valparaíso, 2–3 February 2024:** Valparaíso, Viña del Mar, Quilpué and Villa Alemana.
- **Chilecito, La Rioja (Argentina), July 2026:** the example used by the challenge author in her audio briefing.

---

## 7. Sources

- [FIRMS Archive Download](https://firms.modaps.eosdis.nasa.gov/download/)
- [FIRMS API, area endpoint](https://firms.modaps.eosdis.nasa.gov/api/area/csv)
- [FIRMS active fire data attributes (MODIS and VIIRS)](https://earthdata.nasa.gov/data/tools/firms/active-fire-data-attributes-modis-viirs)
- [Transitioning from S-NPP VIIRS: what FIRMS users need to know (NASA Earthdata)](https://www.earthdata.nasa.gov/news/blog/transitioning-from-s-npp-viirs-omps-what-nasa-firms-users-need-know)
- [Drifting away from MODIS: CAMS Global Fire Assimilation System](https://atmosphere.copernicus.eu/drifting-away-modis-cams-global-fire-assimilation-system)
- [MODIS Terra/Aqua drift (NASA LDOPE)](https://landweb.modaps.eosdis.nasa.gov/displayissue?id=1254)
- [ARSET 2026 Advanced FIRMS Q&A (static thermal anomalies, confidence)](https://d3vpnmsr9g81nw.cloudfront.net/s3fs-public/2026-02/arset-2026-advfirms-part2-qa.pdf)
- [MODIS vs VIIRS fire detection in Northeast Asia (Remote Sensing, 2020)](https://mdpi.com/2072-4292/12/18/2870)
- [Quantitative differences between Aqua/MODIS and S-NPP/VIIRS fire pixels in South America](https://periodicos.ufpe.br/revistas/jhrs/article/download/256618/43434)
- [NASA VIIRS burned area product VNP64A1](https://geog.umd.edu/sites/geog.umd.edu/files/pubs/1-s2.0-S0034425725004109-main.pdf)
- [GFED5NRT (ESSD, 2026)](https://essd.copernicus.org/articles/18/7535/2026/)
- [Correcting swath-dependent bias of MODIS FRP with quantile mapping (Remote Sensing, 2019)](https://www.mdpi.com/2072-4292/11/10/1205)
- [MRBA60 harmonized burned area dataset](https://meetingorganizer.copernicus.org/Plinius19/Plinius19-103.html)
- [CONAE Hot Spot Catalog user manual](https://catalogos5.conae.gov.ar/catalogofocos/Docs/033_CONAE_AQUA-TERRA-NOAA20_MODIS-VIIRS_FC_VISOR_ManualUsuarios_e01.pdf)
- [Chile 2022–2023 fire season (Ex-Ante)](https://www.ex-ante.cl/?p=145180)
- [Chile fire seasons by region (24horas)](https://www.24horas.cl/data/incendios-forestales-quemado-39-mas-hectareas-promedio-temporadas)
- [Valparaíso 2024 fire and vulnerability (Revista Planeo UC)](https://ojs.uc.cl/index.php/RP/article/download/75685/65916/258460)
