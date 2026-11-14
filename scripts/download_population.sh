#!/usr/bin/env bash
# Download WorldPop constrained population rasters (people per ~100 m cell) for Chile and Argentina.
# Source: WorldPop Global 2015-2030, release R2025A, v1 (GeoTIFF, WGS84). No account or key needed.
# Output: External_Data_Sources/WorldPop/<Country>/<original file name>.tif
# Re-running skips files that already exist.
#
# Usage: ./scripts/download_population.sh            # default year 2024
#        YEAR=2020 ./scripts/download_population.sh  # any year from 2015 to 2030
set -euo pipefail

BASE="https://data.worldpop.org/GIS/Population/Global_2015_2030/R2025A"
OUT="$(cd "$(dirname "$0")/.." && pwd)/External_Data_Sources/WorldPop"
YEAR="${YEAR:-2024}"
RELEASE="R2025A"

# folder  iso3
COUNTRIES="Chile:CHL Argentina:ARG"

fail=0
for c in $COUNTRIES; do
  IFS=: read -r country iso <<<"$c"
  iso_lc="$(echo "$iso" | tr '[:upper:]' '[:lower:]')"
  name="${iso_lc}_pop_${YEAR}_CN_100m_${RELEASE}_v1.tif"
  dest_dir="$OUT/$country"
  dest="$dest_dir/$name"
  mkdir -p "$dest_dir"
  [ -s "$dest" ] && { echo "skip $country/$name"; continue; }

  # A valid GeoTIFF starts with "II*" (little-endian) or "MM" (big-endian).
  if curl -fsS --retry 3 -m 1800 -o "$dest.part" "$BASE/$YEAR/$iso/v1/100m/constrained/$name" &&
    head -c 2 "$dest.part" | grep -qE '^(II|MM)'; then
    mv "$dest.part" "$dest"
    echo "ok   $country/$name"
  else
    rm -f "$dest.part"
    echo "FAIL $country/$name" >&2
    fail=1
  fi
done
exit $fail
