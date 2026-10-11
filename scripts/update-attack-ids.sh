#!/usr/bin/env bash
# Maintainer-only: regenerates data/attack-enterprise-ids.tsv from MITRE's published
# Enterprise ATT&CK STIX bundle. Needs network and Python 3. Not used at hunt time.
# Usage: update-attack-ids.sh [output-file]
URL="https://raw.githubusercontent.com/mitre-attack/attack-stix-data/master/enterprise-attack/enterprise-attack.json"
OUT=${1:-"$(cd "$(dirname "$0")/.." && pwd)/data/attack-enterprise-ids.tsv"}
PY=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' 2>/dev/null; then PY=$c; break; fi
done
[ -n "$PY" ] || { echo "Python 3 is required for this maintainer script" >&2; exit 2; }
"$PY" - "$URL" "$OUT" <<'PY'
import datetime, json, sys, urllib.request
url, out = sys.argv[1], sys.argv[2]
with urllib.request.urlopen(url) as r:
    data = json.load(r)
objs = data["objects"]
ver = next((o.get("x_mitre_version") for o in objs if o.get("type") == "x-mitre-collection"), "unknown")
rank = {"current": 0, "deprecated": 1, "revoked": 2}
rows = {}
for o in objs:
    if o.get("type") != "attack-pattern":
        continue
    ext = next((e["external_id"] for e in o.get("external_references", []) if e.get("source_name") == "mitre-attack"), None)
    if not ext:
        continue
    status = "revoked" if o.get("revoked") else "deprecated" if o.get("x_mitre_deprecated") else "current"
    if ext not in rows or rank[status] < rank[rows[ext][1]]:
        rows[ext] = (o["name"], status)
with open(out, "w", encoding="utf-8", newline="\n") as f:
    f.write("# ATT&CK Enterprise v%s generated %s\n" % (ver, datetime.date.today().isoformat()))
    for k in sorted(rows):
        f.write("%s\t%s\t%s\n" % (k, rows[k][0].replace("\t", " "), rows[k][1]))
print("wrote %d techniques (ATT&CK v%s) to %s" % (len(rows), ver, out))
PY
