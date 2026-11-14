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
