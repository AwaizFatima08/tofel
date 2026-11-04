#!/usr/bin/env bash
# Fails if the release ad configuration would ship Google's sample ids or ids that differ from config/admob.json.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/config/admob.json"
DART="$ROOT/lib/ads/ad_ids.dart"
MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"
fail=0
app_id=$(python3 -c "import json;print(json.load(open('$CFG'))['app']['app_id'])")
grep -q "$app_id" "$MANIFEST" || { echo "FAIL: manifest app id is not $app_id"; fail=1; }
for key in home_banner:_liveBanner results_interstitial:_liveInterstitial; do
  unit=${key%%:*}; const=${key##*:}
  want=$(python3 -c "import json;print(json.load(open('$CFG'))['ad_units']['$unit']['id'])")
  grep -q "$const = '$want'" "$DART" || { echo "FAIL: $const is not $want"; fail=1; }
done
[ $fail = 0 ] && echo "OK: release ad ids match config/admob.json"
exit $fail
