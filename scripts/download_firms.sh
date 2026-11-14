#!/usr/bin/env bash
# Download FIRMS "Country Yearly Summary" CSVs (standard processing, no login needed).
# Output: NASA_Data_Sources/<SENSOR>/<Country>/<original file name>.csv
# Files are yearly at the source; month is derived from the acq_date column, not from folders.
# Re-running skips files that already exist.
set -euo pipefail

BASE="https://firms.modaps.eosdis.nasa.gov/data/country"
OUT="$(cd "$(dirname "$0")/.." && pwd)/NASA_Data_Sources"
COUNTRIES="Chile Argentina"
LAST_YEAR=2025 # shortcut: latest full standard-processing year, bump when FIRMS publishes the next one

# folder  firms-id  first-year
SENSORS="MODIS:modis:2000 VIIRS_SNPP:viirs-snpp:2012 VIIRS_NOAA20:viirs-jpss1:2018"

fail=0
for s in $SENSORS; do
  IFS=: read -r folder id first <<<"$s"
  for country in $COUNTRIES; do
    mkdir -p "$OUT/$folder/$country"
    for year in $(seq "$first" "$LAST_YEAR"); do
      name="${id}_${year}_${country}.csv"
      dest="$OUT/$folder/$country/$name"
      [ -s "$dest" ] && continue
      if curl -fsS --retry 3 -m 600 -o "$dest.part" "$BASE/$id/$year/$name" &&
        head -c 8 "$dest.part" | grep -q '^latitude'; then
        mv "$dest.part" "$dest"
        echo "ok   $folder/$country/$name"
      else
        rm -f "$dest.part"
        echo "FAIL $folder/$country/$name" >&2
        fail=1
      fi
    done
  done
done
exit $fail
