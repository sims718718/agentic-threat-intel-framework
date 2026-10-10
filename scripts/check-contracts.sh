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

HIT_RE='\|[[:space:]]*(True positive|Undetermined)[[:space:]]*\|'

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
  case "$verdict" in
    Refuted*)
      case "$cov" in Confirmed*) ;; *) problems="$problems coverage is '${cov:-missing}', not Confirmed;";; esac
      if rd "$LOG" | grep -Eq '^\|[[:space:]]*Execution status[[:space:]]*\|[[:space:]]*(Not executed|Partial)'; then problems="$problems a Story is Not executed or Partial;"; fi
      if rd "$LOG" | grep -Eq "$HIT_RE"; then problems="$problems a true-positive or Undetermined hit is recorded;"; fi
      if [ -n "$problems" ]; then emit FAIL verdict-bound "Refuted is not allowed:$problems"
      else emit PASS verdict-bound "Refuted with coverage Confirmed, every Story executed, no open hit"; fi
      ;;
    "") emit WARN verdict-bound "could not read the hunt-level verdict";;
    *PENDING*) emit SKIP verdict-bound "the hunt-level verdict is still pending";;
    *) emit PASS verdict-bound "hunt-level verdict '$verdict'; no Refuted bound to check";;
  esac
}

check_escalation() {
  [ "$STAGE" = post ] || return 0
  if [ "$HAS_RESULTS" != 1 ]; then emit SKIP escalation "the hunt log holds no results"; return; fi
  if rd "$LOG" | grep -Eq "$HIT_RE"; then
    if rd "$LOG" | awk '/^## Outcome Candidates/{s=1; next} /^## /{s=0} s' | grep -qi 'Suspicious Security Event'; then
      emit PASS escalation "a true-positive or Undetermined hit has a Suspicious Security Event candidate"
    else
      emit WARN escalation "a true-positive or Undetermined hit has no Suspicious Security Event outcome candidate"
    fi
  else
    emit PASS escalation "no true-positive or Undetermined hit recorded"
  fi
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
fi
check_placeholders

echo "SUMMARY pass=$NP warn=$NW fail=$NF skip=$NS"
[ "$NF" -eq 0 ] || exit 1
exit 0
