#!/usr/bin/env bash
# Advisory contract checks for one hunt run. Never edits a file.
# Usage: check-contracts.sh <slug> <plan|post> [threat-hunting-dir]
# Output: "PASS|WARN|FAIL|SKIP <check-id> <message>" per finding, then a SUMMARY line.
# Exit: 0 no FAIL, 1 any FAIL, 2 usage error or no artifacts for the slug.

SLUG=${1:-}; STAGE=${2:-}; TH=${3:-./threat-hunting}
if [ -z "$SLUG" ] || { [ "$STAGE" != plan ] && [ "$STAGE" != post ]; }; then
  echo "usage: check-contracts.sh <slug> <plan|post> [threat-hunting-dir]" >&2
  exit 2
fi
HERE=$(cd "$(dirname "$0")" && pwd)
DATA="$HERE/../data"
ANALYSIS="$TH/intel-analysis/$SLUG-analysis.md"
REPORT="$TH/intel-reports/$SLUG-report.md"
PLAN="$TH/hunt-plans/$SLUG-hunt-plan.md"
LOG="$TH/hunt-logs/$SLUG-hunt-log.md"
DET="$TH/detections/$SLUG-detection.md"
HREPORT="$TH/hunt-reports/$SLUG-hunt-report.md"
VAL="$TH/validations/$SLUG-validation.md"
if [ ! -f "$ANALYSIS" ] && [ ! -f "$PLAN" ] && [ ! -f "$LOG" ]; then
  echo "no artifacts for slug '$SLUG' under $TH" >&2
  exit 2
fi

NP=0; NW=0; NF=0; NS=0
emit() { # level id message
  case $1 in PASS) NP=$((NP+1));; WARN) NW=$((NW+1));; FAIL) NF=$((NF+1));; SKIP) NS=$((NS+1));; esac
  printf '%s %s %s\n' "$1" "$2" "$3"
}
rd() { tr -d '\r' < "$1"; }

LSTATUS=""; HAS_RESULTS=0
if [ -f "$LOG" ]; then
  LSTATUS=$(rd "$LOG" | awk -F'|' '/^\|[[:space:]]*Results status[[:space:]]*\|/{v=$3; gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); print v; exit}')
  case "$LSTATUS" in RECORDED*|PARTIAL*) HAS_RESULTS=1;; esac
fi

need() { # file label required(1|0)
  if [ -f "$1" ]; then emit PASS presence "$2 present"
  elif [ "$3" = 1 ]; then emit FAIL presence "$2 missing ($1)"
  else emit SKIP presence "$2 not present ($1)"; fi
}
check_presence() {
  need "$ANALYSIS" "intel analysis" 1
  need "$REPORT" "intel report" 1
  need "${REPORT%.md}.html" "intel report HTML twin" 1
  need "$PLAN" "hunt plan" 1
  need "${PLAN%.md}.html" "hunt plan HTML twin" 1
  need "$LOG" "hunt log" 0
  need "$VAL" "validation" 1
  if [ "$STAGE" = post ]; then
    if [ "$HAS_RESULTS" = 1 ]; then
      need "$HREPORT" "hunt report" 1
      need "${HREPORT%.md}.html" "hunt report HTML twin" 1
    else
      emit SKIP presence "hunt report not expected: the hunt log holds no results"
    fi
    if [ -f "$DET" ]; then emit PASS presence "detection present"
    elif [ -f "$HREPORT" ] && rd "$HREPORT" | grep -qi 'No detection produced'; then emit PASS presence "no detection produced (stated in the hunt report)"
    elif det_expected; then emit FAIL presence "detection missing ($DET) although the hunt log lists a Detection Opportunity or a hit, and the hunt report does not say why none was produced"
    else emit SKIP presence "detection not present ($DET)"; fi
  fi
}

check_status() {
  if [ ! -f "$LOG" ]; then emit SKIP results-status "no hunt log"; return; fi
  case "$LSTATUS" in
    "PENDING EXECUTION"*|RECORDED*|PARTIAL*) emit PASS results-status "Results status: $LSTATUS";;
    *) emit FAIL results-status "Results status '${LSTATUS:-not found}' is not PENDING EXECUTION, RECORDED, or PARTIAL";;
  esac
}

headings() { rd "$1" | awk '/^```/{f=!f; next} !f && /^## /{sub(/^## /,""); print}'; }
check_order() { # artifact label file
  local art=$1 label=$2 file=$3 H=() l a pos prefix i last=0 idx any missing="" moved=""
  [ -f "$file" ] || return 0
  if [ ! -f "$DATA/section-order.tsv" ]; then emit SKIP section-order "data/section-order.tsv missing"; return; fi
  while IFS= read -r l; do H+=("$l"); done < <(headings "$file")
  while IFS=$'\t' read -r a pos prefix; do
    [ "$a" = "$art" ] || continue
    idx=0; any=0
    for i in "${!H[@]}"; do
      case "${H[$i]}" in
        "$prefix"*)
          any=1
          if [ $((i+1)) -gt "$last" ]; then idx=$((i+1)); break; fi
          ;;
      esac
    done
    if [ "$any" = 0 ]; then missing="$missing '$prefix'"
    elif [ "$idx" = 0 ]; then moved="$moved '$prefix'"
    else last=$idx; fi
  done < <(rd "$DATA/section-order.tsv" | grep -v '^#')
  if [ -n "$missing" ]; then emit FAIL section-order "$label: missing section(s):$missing"; fi
  if [ -n "$moved" ]; then emit FAIL section-order "$label: reordered section(s):$moved"; fi
  if [ -z "$missing$moved" ]; then emit PASS section-order "$label: required sections present and in order"; fi
}

check_det_sections() {
  [ -f "$DET" ] || return 0
  local bad
  bad=$(rd "$DET" | awk '
    function close_blk() { if (blk && n != 10) bad = bad " " id "(" n "/10)"; blk = 0 }
    /^```/ { f = !f; next }
    f { next }
    /^## DET-/ { close_blk(); blk = 1; id = $2; n = 0; next }
    /^## / { close_blk(); next }
    blk && /^### [0-9]+\./ { m = $2; sub(/\./, "", m); if (m + 0 == n + 1) n++; else bad = bad " " id "(### " m " out of order)" }
    END { close_blk(); print bad }')
  if [ -n "$bad" ]; then emit FAIL section-order "detection: DET block(s) without ### 1. to ### 10. in order:$bad"
  else emit PASS section-order "detection: every DET block has sections 1-10 in order"; fi
}

check_placeholders() {
  local f
  for f in "$ANALYSIS" "$REPORT" "$PLAN" "$LOG" "$DET" "$HREPORT" "$VAL"; do
    [ -f "$f" ] || continue
    emit PASS placeholders "$(basename "$f"): fill-in=$(rd "$f" | grep -o '\[FILL IN' | wc -l | tr -d ' ') unknown=$(rd "$f" | grep -ow 'Unknown' | wc -l | tr -d ' ') pending=$(rd "$f" | grep -o '\[PENDING EXECUTION\]' | wc -l | tr -d ' ')"
  done
}

nlog() { rd "$LOG" | tr -d '*`_'; }   # hunt log without emphasis markers
log_has_open_hit() { # a true-positive or Undetermined disposition in any cell (annotations and case allowed)
  nlog | grep -vi 'true positive / false positive' | grep -Eiq '\|[[:space:]]*(true positive|undetermined)'
}
log_has_any_hit() { # any disposition in the hit table's third cell
  nlog | grep -vi 'true positive / false positive' | grep -Eiq '^\|[^|]*\|[^|]*\|[[:space:]]*(true positive|false positive|benign|undetermined)'
}
det_expected() { # the hunt log lists a Detection Opportunity or a hit
  [ "$HAS_RESULTS" = 1 ] || return 1
  nlog | awk '/^## Outcome Candidates/{s=1; next} /^## /{s=0} s' | grep -qi 'detection opportunity' && return 0
  log_has_any_hit
}

check_story_ids() {
  [ "$STAGE" = post ] || return 0
  if [ "$HAS_RESULTS" != 1 ] || [ ! -f "$PLAN" ]; then emit SKIP story-ids "the hunt log holds no results, or the plan is missing"; return; fi
  local planids logids id bad="" miss=""
  planids=$(rd "$PLAN" | sed -n 's/^## Story: \[\(HUNT-[A-Za-z0-9-]*-S[0-9][0-9]*\)\].*/\1/p' | sort -u)
  logids=$(rd "$LOG" | sed -n 's/^### \(HUNT-[A-Za-z0-9-]*-S[0-9][0-9]*\).*/\1/p' | sort -u)
  for id in $logids; do printf '%s\n' "$planids" | grep -qx "$id" || bad="$bad $id"; done
  for id in $planids; do printf '%s\n' "$logids" | grep -qx "$id" || miss="$miss $id"; done
  if [ -n "$bad" ]; then emit FAIL story-ids "the hunt log has Story IDs that are not in the plan:$bad"; fi
  if [ -n "$miss" ]; then emit WARN story-ids "plan Stories missing from the hunt log:$miss"; fi
  if [ -z "$bad$miss" ]; then emit PASS story-ids "Story IDs agree ($(printf '%s\n' "$planids" | grep -c .) Stories)"; fi
}

cell() { # row column(2|3) : trimmed cell without markdown emphasis
  printf '%s' "$1" | awk -F'|' -v c="$2" '{v=$c; gsub(/\*/,"",v); gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); print v}'
}
check_verdict() {
  [ "$STAGE" = post ] || return 0
  if [ "$HAS_RESULTS" != 1 ]; then emit SKIP verdict-bound "the hunt log holds no results"; return; fi
  local row verdict cov problems=""
  row=$(rd "$LOG" | awk '/^## Hunt-Level Verdict and Coverage/{s=1; next} /^## /{s=0} s && /^\|/{n++; if(n==3){print; exit}}')
  verdict=$(cell "$row" 2); cov=$(cell "$row" 3)
  local vl cl
  vl=$(printf '%s' "$verdict" | tr 'A-Z' 'a-z'); cl=$(printf '%s' "$cov" | tr 'A-Z' 'a-z')
  case "$vl" in
    refuted*)
      case "$cl" in
        confirmed*) case "$cl" in *unconfirmed*) problems="$problems coverage is only partly confirmed ('$cov');";; esac;;
        *) problems="$problems coverage is '${cov:-missing}', not Confirmed;";;
      esac
      if nlog | grep -Eiq '^\|[[:space:]]*execution status[[:space:]]*\|[[:space:]]*(not executed|partial)'; then problems="$problems a Story is Not executed or Partial;"; fi
      if log_has_open_hit; then problems="$problems a true-positive or Undetermined hit is recorded;"; fi
      if [ -n "$problems" ]; then emit FAIL verdict-bound "Refuted is not allowed:$problems"
      else emit PASS verdict-bound "Refuted with coverage Confirmed, every Story executed, no open hit"; fi
      ;;
    "") emit WARN verdict-bound "could not read the hunt-level verdict";;
    *pending*) emit SKIP verdict-bound "the hunt-level verdict is still pending";;
    *) emit PASS verdict-bound "hunt-level verdict '$verdict'; no Refuted bound to check";;
  esac
}

check_escalation() {
  [ "$STAGE" = post ] || return 0
  if [ "$HAS_RESULTS" != 1 ]; then emit SKIP escalation "the hunt log holds no results"; return; fi
  if log_has_open_hit; then
    if nlog | awk '/^## Outcome Candidates/{s=1; next} /^## /{s=0} s' | grep -qi 'Suspicious Security Event'; then
      emit PASS escalation "a true-positive or Undetermined hit has a Suspicious Security Event candidate"
    else
      emit WARN escalation "a true-positive or Undetermined hit has no Suspicious Security Event outcome candidate"
    fi
  else
    emit PASS escalation "no true-positive or Undetermined hit recorded"
  fi
}

check_attack() {
  local data="$DATA/attack-enterprise-ids.tsv" ver f ids id status warned
  if [ ! -f "$data" ]; then emit SKIP attack-ids "data/attack-enterprise-ids.tsv missing"; return; fi
  ver=$(sed -n '1s/.*\(v[0-9][0-9.]*\).*/\1/p' "$data")
  for f in "$ANALYSIS" "$PLAN" "$DET"; do
    [ -f "$f" ] || continue
    if [ "$f" = "$DET" ] && [ "$STAGE" != post ]; then continue; fi
    ids=$(rd "$f" | grep -oiwE 'T[0-9]{4}(\.[0-9]{3})?' | tr 'a-z' 'A-Z' | sort -u)
    warned=0
    for id in $ids; do
      status=$(rd "$data" | awk -F'\t' -v id="$id" '!/^#/ && $1==id {print $3; exit}')
      case "$status" in
        current) ;;
        deprecated|revoked) emit WARN attack-ids "$(basename "$f"): $id is $status in ATT&CK $ver"; warned=1;;
        *) emit WARN attack-ids "$(basename "$f"): $id not in ATT&CK $ver (the bundled data is a snapshot)"; warned=1;;
      esac
    done
    if [ "$warned" = 0 ]; then emit PASS attack-ids "$(basename "$f"): $(printf '%s\n' "$ids" | grep -c .) technique ID(s), all current in ATT&CK $ver"; fi
  done
}

IFS= read -r -d '' SIGMA_AWK <<'AWK'
function lbl() { return (doc == 1) ? blk : blk "." doc }
function finish(   i, n, mind, ind, line, key, names, cond, incond, tokens, t, w, k, ok, pre, undefd, missing, field, base, allind, nfields, v, req) {
  if ("correlation" in top) {
    if ("title" in top) print "PASS	block " lbl() " is a correlation rule (detection keys not applicable)"
    else print "FAIL	block " lbl() " missing: title"
    return
  }
  missing = ""
  n = split("title logsource detection level", req, " ")
  for (i = 1; i <= n; i++) if (!(req[i] in top)) missing = missing " " req[i]
  mind = 1000
  for (i = 1; i <= nd; i++) if (detind[i] < mind) mind = detind[i]
  cond = ""; incond = 0; nfields = 0; allind = 1
  for (i = 1; i <= nd; i++) {
    line = detl[i]; ind = detind[i]
    if (ind == mind && line ~ /^[[:space:]]*[A-Za-z0-9_*-]+:/) {
      key = line; sub(/^[[:space:]]*/, "", key); sub(/:.*/, "", key)
      incond = 0
      if (key == "condition") {
        incond = 1; v = line; sub(/^[[:space:]]*condition:[[:space:]]*/, "", v)
        if (v != "|" && v != ">") cond = cond " " v
        continue
      }
      if (key != "timeframe") names[key] = 1
      continue
    }
    if (incond) { cond = cond " " line; continue }
    field = line; sub(/^[[:space:]]*(-[[:space:]]*)?/, "", field)
    if (field ~ /^[A-Za-z0-9_.|-]+:/) {
      sub(/:.*/, "", field); base = tolower(field); sub(/\|.*/, "", base)
      nfields++
      if (base !~ /^(hashes?|md5|sha1|sha256|sha512|imphash|ip|destinationip|sourceip|c-ip|cs-ip|queryname|destinationhostname|.*_ip|.*ipaddress|.*domain)$/) allind = 0
    }
  }
  if (cond == "") missing = missing " condition"
  if (missing != "") { print "FAIL\tblock " lbl() " missing:" missing; return }
  gsub(/[^A-Za-z0-9_*]/, " ", cond)
  n = split(cond, tokens, " ")
  undefd = ""
  for (i = 1; i <= n; i++) {
    t = tokens[i]; w = tolower(t)
    if (w ~ /^(and|or|not|of|all|them|count|by|near)$/ || t ~ /^[0-9]+$/) continue
    if (t ~ /\*/) {
      pre = t; sub(/\*.*/, "", pre); ok = 0
      for (k in names) if (index(k, pre) == 1) ok = 1
      if (!ok) undefd = undefd " " t
    } else if (!(t in names)) undefd = undefd " " t
  }
  if (undefd != "") { print "FAIL\tblock " lbl() " has a condition that uses an undefined selection:" undefd; return }
  if (nfields > 0 && allind) { print "WARN\tblock " lbl() " matches only hash, IP, or domain indicators"; return }
  print "PASS\tblock " lbl() " has the required keys and a defined condition"
}
function reset() { delete top; delete detl; delete detind; nd = 0; indet = 0; hascontent = 0 }
{ sub(/\r$/, "") }
/^```/ {
  if (inblk) { if (hascontent || doc == 1) finish(); inblk = 0; next }
  if ($0 ~ /^```(yaml|yml)[[:space:]]*$/) { inblk = 1; blk++; doc = 1; reset() }
  next
}
inblk && /^---[[:space:]]*$/ { if (hascontent) finish(); reset(); doc++; next }
inblk {
  if ($0 ~ /^[A-Za-z_]+:/) { k = $0; sub(/:.*/, "", k); top[k] = 1; hascontent = 1; indet = (k == "detection"); next }
  if (indet && $0 !~ /^[[:space:]]*(#.*)?$/) { match($0, /^[[:space:]]*/); nd++; detl[nd] = $0; detind[nd] = RLENGTH }
}
END { if (blk == 0) print "WARN\tno yaml block found in the detection" }
AWK

check_sigma() {
  [ "$STAGE" = post ] || return 0
  if [ ! -f "$DET" ]; then emit SKIP sigma "no detection"; return; fi
  local lvl msg
  while IFS=$'\t' read -r lvl msg; do
    [ -n "$lvl" ] && emit "$lvl" sigma "$msg"
  done < <(rd "$DET" | awk "$SIGMA_AWK")
}

check_det_xref() {
  [ "$STAGE" = post ] || return 0
  if [ ! -f "$DET" ]; then emit SKIP det-xref "no detection"; return; fi
  local dids id f bad="" first
  dids=$(rd "$DET" | sed -n 's/^## \(DET-[A-Za-z0-9]*\).*/\1/p' | sort -u)
  for f in "$VAL" "$HREPORT"; do
    [ -f "$f" ] || continue
    for id in $(rd "$f" | grep -oE 'DET-[A-Za-z0-9]+' | sort -u); do
      printf '%s\n' "$dids" | grep -qx "$id" || bad="$bad $(basename "$f"):$id"
    done
  done
  if [ -n "$bad" ]; then emit FAIL det-xref "DET IDs not defined in the detection:$bad"
  else emit PASS det-xref "DET IDs agree across the detection, validation, and hunt report"; fi
  if [ -f "$HREPORT" ] && [ -f "$VAL" ]; then
    first=$(rd "$HREPORT" | awk '/^## Validation/{s=1; next} /^## /{s=0} s && NF{print; exit}')
    if [ "$first" = "Pending hunt-validator" ]; then
      emit WARN det-xref "the hunt report's Validation section is still 'Pending hunt-validator' although a validation file exists"
    fi
  fi
}

check_language() {
  [ "$STAGE" = post ] || return 0
  if [ ! -f "$HREPORT" ]; then emit SKIP language "no hunt report"; return; fi
  local hits
  hits=$(rd "$HREPORT" | grep -v 'A clean result is bounded' | grep -inwE 'clean|no threat|environment is secure' | head -3 | tr '\n' ';')
  if [ -n "$hits" ]; then emit WARN language "the hunt report uses a phrase the framework avoids (line: text): $hits"
  else emit PASS language "no banned phrasing in the hunt report"; fi
}

# --- checks run ---
check_presence
check_status
check_order analysis "intel analysis" "$ANALYSIS"
check_order report "intel report" "$REPORT"
check_order plan "hunt plan" "$PLAN"
check_order hunt-log "hunt log" "$LOG"
check_order validation "validation" "$VAL"
if [ "$STAGE" = post ]; then
  check_order hunt-report "hunt report" "$HREPORT"
  check_order detection "detection" "$DET"
  check_det_sections
  check_story_ids
  check_verdict
  check_escalation
  check_sigma
  check_det_xref
  check_language
fi
check_attack
check_placeholders

echo "SUMMARY pass=$NP warn=$NW fail=$NF skip=$NS"
[ "$NF" -eq 0 ] || exit 1
exit 0
