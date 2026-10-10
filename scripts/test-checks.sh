#!/usr/bin/env bash
# Tests for the quality checks. Never reads examples/.
# Usage: test-checks.sh [drift|baseline|lint|agents|wiring|all]
#   drift    compare data/section-order.tsv with the skills' fenced templates (offline)
#   baseline build a real ./threat-hunting/ by running the commands in a scratch project
#            (needs the claude CLI and network; set TIH_BASELINE to choose where)
#   lint     run the linter on the baseline and on mutated copies
#   agents   dry-run the review agents on the baseline
#   wiring   dry-run the commands' quality step on copies of the baseline
REPO=$(cd "$(dirname "$0")/.." && pwd)
BASE=${TIH_BASELINE:-${TMPDIR:-/tmp}/tih-baseline}
PASSN=0; FAILN=0

ok()  { PASSN=$((PASSN+1)); echo "ok   $1"; }
bad() { FAILN=$((FAILN+1)); echo "FAIL $1${2:+ - $2}"; }
has() { # name output pattern
  if printf '%s\n' "$2" | grep -Eq "$3"; then ok "$1"; else bad "$1" "no line matching /$3/"; fi
}
fail_ids() { awk '$1=="FAIL"{print $2}' | sort -u | tr '\n' ' '; }
only_new_fail() { # name baseline_output mutated_output id : mutated FAIL ids == baseline FAIL ids + id
  local b m want
  b=$(printf '%s\n' "$2" | fail_ids); m=$(printf '%s\n' "$3" | fail_ids)
  want=$(printf '%s\n' "$b$4" | tr ' ' '\n' | grep . | sort -u | tr '\n' ' ')
  if [ "$m" = "$want" ]; then ok "$1"; else bad "$1" "FAIL ids [$m], expected [$want]"; fi
}
run_group() { local f; for f in $(declare -F | awk '{print $3}' | grep "^$1_"); do "$f"; done; }

# ---------- drift ----------
fence_h2() { # skill...: "## " headings inside fenced blocks, without the "## "
  local s
  for s in "$@"; do
    awk '/^```/{f=!f; next} f && /^## /{sub(/^## /,""); print}' "$REPO/skills/$s/SKILL.md"
  done
}
drift_section_order() {
  local spec art rest strict skills want got a pos prefix w g i found mismatch
  for spec in "analysis:1:intel-analysis" "report:1:intel-report" "hunt-log:1:hunt-execution" \
              "hunt-report:1:hunt-reporter" "plan:0:hunt-planner gather" \
              "detection:0:detection-engineer" "validation:0:hunt-validator"; do
    art=${spec%%:*}; rest=${spec#*:}; strict=${rest%%:*}; skills=${rest#*:}
    want=(); got=()
    while IFS=$'\t' read -r a pos prefix; do
      [ "$a" = "$art" ] && want+=("$prefix")
    done < <(grep -v '^#' "$REPO/data/section-order.tsv" 2>/dev/null)
    while IFS= read -r g; do got+=("$g"); done < <(fence_h2 $skills)
    if [ "${#want[@]}" = 0 ]; then bad "drift $art" "no rows in data/section-order.tsv"; continue; fi
    mismatch=""
    if [ "$strict" = 1 ]; then
      [ "${#got[@]}" = "${#want[@]}" ] || mismatch="skill has ${#got[@]} sections, data has ${#want[@]}"
      for i in "${!want[@]}"; do
        case "${got[$i]}" in "${want[$i]}"*) ;; *) mismatch="$mismatch [pos $((i+1)): data '${want[$i]}' vs skill '${got[$i]}']";; esac
      done
    else
      for w in "${want[@]}"; do
        found=0
        for g in "${got[@]}"; do case "$g" in "$w"*) found=1;; esac; done
        [ "$found" = 1 ] || mismatch="$mismatch ['$w' not in the skill's templates]"
      done
    fi
    if [ -z "$mismatch" ]; then ok "drift $art"; else bad "drift $art" "$mismatch"; fi
  done
}

# ---------- baseline ----------
SUBJECT=${TIH_SUBJECT:-"Scattered Spider help-desk social engineering used to reset MFA and take over accounts (CISA advisory AA23-320A)"}

claude_run() { # prompt outfile : run claude headless in the current directory
  MSYS_NO_PATHCONV=1 claude --plugin-dir "$REPO" --add-dir "$REPO" --permission-mode acceptEdits -p "$1" < /dev/null > "$2" 2>&1
}
mk_baseline() {
  if [ -f "$BASE/slug" ]; then echo "baseline exists: $BASE"; return 0; fi
  mkdir -p "$BASE/work" || return 1
  cd "$BASE/work" || return 1
  echo "running the planning half (live research; this can take 15-30 minutes)..."
  claude_run "Run the /run-hunt-pipeline command defined in $REPO/commands/run-hunt-pipeline.md for this input: $SUBJECT. Follow it exactly. It has no confirmation gates." "$BASE/pipeline.out"
  local s
  s=$(ls threat-hunting/hunt-plans/*-hunt-plan.md 2>/dev/null | head -1 | sed 's#.*/##; s#-hunt-plan\.md$##')
  [ -n "$s" ] || { echo "pipeline produced no hunt plan; see $BASE/pipeline.out" >&2; return 1; }
  local id first=1
  {
    echo "# TEST DATA: synthetic hunt results for $s. Not real findings."
    echo "Hunter: test-harness. Platform: test SIEM. Dates executed: 2026-10-01."
    for id in $(sed -n 's/^## Story: \[\(HUNT-[A-Za-z0-9-]*-S[0-9][0-9]*\)\].*/\1/p' "threat-hunting/hunt-plans/$s-hunt-plan.md"); do
      echo; echo "## $id"
      echo "Executed the planned query in full over the planned window. Queried the data sources named in the plan; coverage was confirmed for each."
      if [ "$first" = 1 ]; then
        echo "Result: 1 hit. Hit H1: help-desk ticket 4471, an MFA reset for a service-desk user. Reviewed with the ticket owner and confirmed as a legitimate change. Disposition: False positive."
        first=0
      else
        echo "Result: 0 hits."
      fi
    done
  } > "$BASE/results.md"
  echo "running the post-hunt half..."
  claude_run "Run the /run-post-hunt command defined in $REPO/commands/run-post-hunt.md with these arguments: $s $BASE/results.md . Follow it exactly." "$BASE/post.out"
  [ -f "threat-hunting/hunt-reports/$s-hunt-report.md" ] || { echo "post-hunt produced no hunt report; see $BASE/post.out" >&2; return 1; }
  echo "$s" > "$BASE/slug"
  echo "baseline ready: $BASE (slug $s)"
}
need_baseline() {
  [ -f "$BASE/slug" ] || { echo "no baseline at $BASE; run: scripts/test-checks.sh baseline" >&2; exit 2; }
  SLUG=$(cat "$BASE/slug")
}
mut() { local d; d=$(mktemp -d "$BASE/mut.XXXXXX") && cp -r "$BASE/work/threat-hunting" "$d/" && echo "$d"; }
sedi() { local f=$1; shift; sed "$@" "$f" > "$f.new" && mv "$f.new" "$f"; }
lint() { bash "$REPO/scripts/check-contracts.sh" "$SLUG" "$1" "$2/threat-hunting"; }

# --- tests end ---

main() {
  case "${1:-all}" in
    drift)    run_group drift;;
    baseline) mk_baseline;;
    lint)     need_baseline; run_group lint;;
    agents)   need_baseline; run_group agents;;
    wiring)   need_baseline; run_group wiring;;
    all)      run_group drift; need_baseline; run_group lint; run_group agents; run_group wiring;;
    *) echo "usage: test-checks.sh [drift|baseline|lint|agents|wiring|all]" >&2; exit 2;;
  esac
  echo "---- $PASSN passed, $FAILN failed"
  [ "$FAILN" = 0 ]
}
main "$@"
