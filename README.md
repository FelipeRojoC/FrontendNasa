# NASA Space Apps 2026: Harmonization of MODIS and VIIRS Hot Spots

## Getting the data

The hotspot data is not stored in this repository (about 585 MB). Download it with:

```bash
./scripts/download_firms.sh
```

- Needs `bash` and `curl` (on Windows, run it from Git Bash). No account or API key.
- Source: [FIRMS Country Yearly Summary](https://firms.modaps.eosdis.nasa.gov/country/), Chile and Argentina.
- Output: `NASA_Data_Sources/<SENSOR>/<Country>/<file>.csv`, one file per year (96 files).
- Sensors: `MODIS` (2000–2025), `VIIRS_SNPP` (2012–2025), `VIIRS_NOAA20` (2018–2025).
- Safe to re-run: files already downloaded are skipped.

### 2026 and VIIRS NOAA-21 (FIRMS API)

The yearly files stop at 2025 and do not include NOAA-21. To fill that gap:

1. Get a free MAP_KEY at <https://firms.modaps.eosdis.nasa.gov/api/map_key/>.
2. Copy `.env.example` to `.env` and set `FIRMS_MAP_KEY=` (`.env` is git-ignored, never commit the key).
3. Run:

```bash
./scripts/download_firms_api.sh
```

- Output: `NASA_Data_Sources/<SENSOR>/API_bbox/<SENSOR>_<YYYY-MM>.csv`, one file per month.
- Covers 2026 for `MODIS`, `VIIRS_SNPP` and `VIIRS_NOAA20`, and `VIIRS_NOAA21` from March 2023.
- Uses standard processing (SP) while available and near-real-time (NRT) after that. Months not fully covered by SP are re-downloaded on every run, because NRT data gets revised.
- The query is a bounding box around Chile and Argentina, so it includes points from neighbouring countries. Clip to the country borders when processing.
- NOAA-21 files are not in the yearly layout (`<SENSOR>/<Country>/`), they only exist under `API_bbox/`.

## Population data (WorldPop)

Used by the risk and impact extension to estimate the population near a fire. See `docs/population-and-past-fires.md`.

```bash
./scripts/download_population.sh            # 2024 by default
YEAR=2020 ./scripts/download_population.sh  # any year from 2015 to 2030
```

- Needs `bash` and `curl`. No account or API key.
- Source: [WorldPop R2025A](https://hub.worldpop.org/geodata/listing?id=135), constrained population counts, about 100 m per cell.
- Output: `External_Data_Sources/WorldPop/<Country>/<file>.tif` (git-ignored), one GeoTIFF per country.
- Safe to re-run: files already downloaded are skipped.

## Runpod MCP server

`.mcp.json` registers the official [Runpod MCP server](https://github.com/runpod/runpod-mcp) (pinned to 4.12.0) so Claude Code can manage pods, endpoints and volumes.

1. Create an API key in the Runpod console (Settings → API Keys).
2. Add `RUNPOD_API_KEY=` to your `.env` (see `.env.example`). The key never leaves your machine and is not committed.
3. Restart the session and approve the `runpod` server when asked.

`scripts/runpod_mcp.mjs` reads the key from `.env` and passes only that variable to the server.
