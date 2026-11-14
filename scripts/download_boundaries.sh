#!/usr/bin/env bash
# Download first-level region boundaries used by scripts/build_hotspots.py.
# Output: NASA_Data_Sources/boundaries/<Country>.geojson (one feature per region)
#   Chile:     geoBoundaries gbOpen CHL ADM1, simplified (16 regions, CC BY 3.0 IGO, source BCN / OCHA)
#   Argentina: Instituto Geográfico Nacional (IGN) provinces WFS (24 provinces, about 110 MB).
#              geoBoundaries ARG ADM1 is not used: it is missing Entre Ríos.
set -euo pipefail

OUT="$(cd "$(dirname "$0")/.." && pwd)/NASA_Data_Sources/boundaries"
mkdir -p "$OUT"

get() { # url dest
  [ -s "$2" ] && { echo "skip $(basename "$2")"; return; }
  curl -fsSL --retry 3 -m 600 -o "$2.part" "$1"
  head -c 200 "$2.part" | grep -q '"FeatureCollection"' || { rm -f "$2.part"; echo "FAIL $(basename "$2")" >&2; exit 1; }
  mv "$2.part" "$2"
  echo "ok   $(basename "$2")"
}

get "https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/CHL/ADM1/geoBoundaries-CHL-ADM1_simplified.geojson" \
  "$OUT/Chile.geojson"
get "https://wms.ign.gob.ar/geoserver/ows?service=WFS&version=2.0.0&request=GetFeature&typeNames=ign:provincia&outputFormat=application/json&srsName=EPSG:4326" \
  "$OUT/Argentina.geojson"
