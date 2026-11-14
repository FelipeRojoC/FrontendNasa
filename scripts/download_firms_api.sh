#!/usr/bin/env bash
# Download FIRMS hotspots through the Area API for what the yearly country files do not cover:
# 2026 (MODIS, VIIRS S-NPP, VIIRS NOAA-20) and VIIRS NOAA-21 (March 2023 onward).
#
# Needs a FIRMS MAP_KEY (free): https://firms.modaps.eosdis.nasa.gov/api/map_key/
# Put it in a git-ignored `.env` at the repo root:  FIRMS_MAP_KEY=your_key
# (or export FIRMS_MAP_KEY in your shell).
#
# Output: NASA_Data_Sources/<SENSOR>/API_bbox/<SOURCE>_<YYYY-MM>.csv  (one file per month)
# - Uses standard processing (SP) while it is available and near-real-time (NRT) after that.
# - The query is a bounding box around Chile and Argentina, so it also contains points from
#   neighbouring countries. Clip to the country borders when processing.
# - Months that are not fully covered by SP are re-downloaded on every run (NRT gets revised).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/NASA_Data_Sources"
API="https://firms.modaps.eosdis.nasa.gov/api"
BBOX="-76,-56,-53,-17" # west,south,east,north
CHUNK_DAYS=5           # the Area API accepts at most 5 days per request

# folder  sp-source  nrt-source  start-date
TARGETS="MODIS:MODIS_SP:MODIS_NRT:2026-01-01
VIIRS_SNPP:VIIRS_SNPP_SP:VIIRS_SNPP_NRT:2026-01-01
VIIRS_NOAA20:VIIRS_NOAA20_SP:VIIRS_NOAA20_NRT:2026-01-01
VIIRS_NOAA21:VIIRS_NOAA21_SP:VIIRS_NOAA21_NRT:2023-03-01"

if [ -z "${FIRMS_MAP_KEY:-}" ] && [ -f "$ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$ROOT/.env"
  set +a
fi
if [ -z "${FIRMS_MAP_KEY:-}" ]; then
  echo "FIRMS_MAP_KEY is not set. Add it to $ROOT/.env or export it." >&2
  exit 2
fi

d2e() { date -u -d "$1" +%s; }
e2d() { date -u -d "@$1" +%F; }
DAY=86400

# Echo "<min_date> <max_date>" for a source, from the data availability endpoint.
availability() {
  curl -fsS --retry 3 -m 60 "$API/data_availability/csv/$FIRMS_MAP_KEY/$1" |
    awk -F, -v s="$1" '$1 == s { print $2, $3 }'
}

# Download one chunk of days into a file; fail if the response is not a CSV.
fetch_chunk() { # source start-date days dest
  curl -fsS --retry 3 -m 300 -o "$4" "$API/area/csv/$FIRMS_MAP_KEY/$1/$BBOX/$3/$2"
  head -c 8 "$4" | grep -q '^latitude'
}

fail=0
while IFS=: read -r folder sp nrt start; do
  dest_dir="$OUT/$folder/API_bbox"
  mkdir -p "$dest_dir"

  read -r sp_min sp_max <<<"$(availability "$sp")"
  read -r _ nrt_max <<<"$(availability "$nrt")"
  if [ -z "${sp_max:-}" ] || [ -z "${nrt_max:-}" ]; then
    echo "FAIL $folder: could not read data availability (check the MAP_KEY)" >&2
    fail=1
    continue
  fi
  [ "$(d2e "$start")" -lt "$(d2e "$sp_min")" ] && start="$sp_min"
  end="$nrt_max"
  [ "$(d2e "$sp_max")" -gt "$(d2e "$end")" ] && end="$sp_max"
  echo "== $folder: $start .. $end (SP until $sp_max, NRT after)"

  month_start="${start:0:7}-01"
  while [ "$(d2e "$month_start")" -le "$(d2e "$end")" ]; do
    month="${month_start:0:7}"
    month_end="$(date -u -d "$month_start +1 month -1 day" +%F)"
    from="$start"
    [ "$(d2e "$month_start")" -gt "$(d2e "$from")" ] && from="$month_start"
    to="$month_end"
    [ "$(d2e "$to")" -gt "$(d2e "$end")" ] && to="$end"
    final_sp=0
    [ "$(d2e "$month_end")" -le "$(d2e "$sp_max")" ] && final_sp=1

    file="$dest_dir/${folder}_${month}.csv"
    if [ "$final_sp" = 1 ] && [ -s "$file" ]; then
      month_start="$(date -u -d "$month_start +1 month" +%F)"
      continue
    fi

    tmp="$(mktemp)"
    chunk="$(mktemp)"
    : >"$tmp"
    ok=1
    d="$(d2e "$from")"
    last="$(d2e "$to")"
    while [ "$d" -le "$last" ]; do
      if [ "$d" -le "$(d2e "$sp_max")" ]; then
        source="$sp"
        limit="$(d2e "$sp_max")"
      else
        source="$nrt"
        limit="$last"
      fi
      [ "$limit" -gt "$last" ] && limit="$last"
      days=$(((limit - d) / DAY + 1))
      [ "$days" -gt "$CHUNK_DAYS" ] && days="$CHUNK_DAYS"
      if fetch_chunk "$source" "$(e2d "$d")" "$days" "$chunk"; then
        if [ -s "$tmp" ]; then tail -n +2 "$chunk" >>"$tmp"; else cat "$chunk" >"$tmp"; fi
      else
        ok=0
        break
      fi
      d=$((d + days * DAY))
    done

    if [ "$ok" = 1 ]; then
      mv "$tmp" "$file"
      echo "ok   $folder/API_bbox/$(basename "$file")"
    else
      rm -f "$tmp"
      echo "FAIL $folder/API_bbox/$(basename "$file")" >&2
      fail=1
    fi
    rm -f "$chunk"
    month_start="$(date -u -d "$month_start +1 month" +%F)"
  done
done <<<"$TARGETS"
exit $fail
