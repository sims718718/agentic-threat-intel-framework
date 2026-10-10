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
  if ! ls threat-hunting/hunt-plans/*-hunt-plan.md >/dev/null 2>&1; then
    echo "running the planning half (live research; this can take 15-30 minutes)..."
    claude_run "Run the /run-hunt-pipeline command defined in $REPO/commands/run-hunt-pipeline.md for this input: $SUBJECT. Follow it exactly. It has no confirmation gates." "$BASE/pipeline.out"
  fi
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
  } > results.md
  echo "running the post-hunt half..."
  claude_run "Run the /run-post-hunt command defined in $REPO/commands/run-post-hunt.md with these arguments: $s results.md . Follow it exactly." "$BASE/post.out"
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

# ---------- lint ----------
lint_baseline_has_no_fail() {
  local out; out=$(lint plan "$BASE/work" 2>&1)
  has "plan stage runs and reports a summary" "$out" '^SUMMARY pass=[0-9]+ warn=[0-9]+ fail=[0-9]+ skip=[0-9]+'
  if [ -z "$(printf '%s\n' "$out" | fail_ids)" ]; then ok "plan stage: no FAIL on the baseline"; else bad "plan stage: FAIL on the baseline" "$(printf '%s\n' "$out" | grep '^FAIL')"; fi
  out=$(lint post "$BASE/work" 2>&1)
  if [ -z "$(printf '%s\n' "$out" | fail_ids)" ]; then ok "post stage: no FAIL on the baseline"; else bad "post stage: FAIL on the baseline" "$(printf '%s\n' "$out" | grep '^FAIL')"; fi
}
lint_usage_and_unknown_slug() {
  bash "$REPO/scripts/check-contracts.sh" 2>/dev/null; [ $? = 2 ] && ok "usage error exits 2" || bad "usage error exits 2"
  bash "$REPO/scripts/check-contracts.sh" no-such-slug plan "$BASE/work/threat-hunting" 2>/dev/null; [ $? = 2 ] && ok "unknown slug exits 2" || bad "unknown slug exits 2"
}
lint_presence_and_placeholders() {
  local out; out=$(lint plan "$BASE/work" 2>&1)
  has "presence: plan present" "$out" '^PASS presence hunt plan present'
  has "placeholders are counted" "$out" '^PASS placeholders .*-hunt-plan\.md: fill-in=[0-9]+ unknown=[0-9]+ pending=[0-9]+'
  local d; d=$(mut); mv "$d/threat-hunting/intel-reports/$SLUG-report.html" "$d/threat-hunting/intel-reports/$SLUG-report.html.gone"
  out=$(lint plan "$d" 2>&1); has "presence: missing HTML twin fails" "$out" '^FAIL presence intel report HTML twin missing'
}
lint_results_status() {
  local d b m; b=$(lint post "$BASE/work" 2>&1); d=$(mut)
  sedi "$d/threat-hunting/hunt-logs/$SLUG-hunt-log.md" 's/^\(| *Results status *|\).*/\1 BOGUS |/'
  m=$(lint post "$d" 2>&1)
  has "results-status: unknown value fails" "$m" '^FAIL results-status'
  has "results-status: baseline passes" "$b" '^PASS results-status'
}
lint_section_order() {
  local d b m; b=$(lint post "$BASE/work" 2>&1)
  has "section-order: report passes on the baseline" "$b" '^PASS section-order intel report'
  d=$(mut)
  sedi "$d/threat-hunting/intel-reports/$SLUG-report.md" -e 's/^## Executive Summary/@@A@@/' -e 's/^## Key Judgments/## Executive Summary/' -e 's/^@@A@@/## Key Judgments/'
  m=$(lint post "$d" 2>&1)
  has "section-order: swapped sections fail as reordered" "$m" "^FAIL section-order intel report.*reordered.*'Key Judgments'"
  only_new_fail "section-order: swap adds only the section-order FAIL" "$b" "$m" section-order
  d=$(mut)
  sedi "$d/threat-hunting/hunt-logs/$SLUG-hunt-log.md" 's/^## Hunt-Level Verdict and Coverage/## Hunt-Level Result/'
  m=$(lint post "$d" 2>&1)
  has "section-order: renamed section fails as missing" "$m" "^FAIL section-order hunt log.*missing.*'Hunt-Level Verdict and Coverage'"
  d=$(mut)
  printf '\n## Extra Local Notes\nanything\n' >> "$d/threat-hunting/hunt-plans/$SLUG-hunt-plan.md"
  m=$(lint post "$d" 2>&1)
  has "section-order: an extra section is allowed" "$m" '^PASS section-order hunt plan'
}

lint_story_ids() {
  local b d m; b=$(lint post "$BASE/work" 2>&1)
  has "story-ids: baseline agrees" "$b" '^PASS story-ids'
  d=$(mut); printf '\n### HUNT-9999-S9: injected story\n' >> "$d/threat-hunting/hunt-logs/$SLUG-hunt-log.md"
  m=$(lint post "$d" 2>&1)
  has "story-ids: unknown Story ID fails" "$m" '^FAIL story-ids .*HUNT-9999-S9'
  only_new_fail "story-ids: adds only the story-ids FAIL" "$b" "$m" story-ids
}
lint_story_ids_skip_without_results() {
  local d m; d=$(mut)
  sedi "$d/threat-hunting/hunt-logs/$SLUG-hunt-log.md" 's/^\(| *Results status *|\).*/\1 PENDING EXECUTION |/'
  m=$(lint post "$d" 2>&1)
  has "story-ids: SKIP when the log holds no results" "$m" '^SKIP story-ids'
  has "verdict-bound: SKIP when the log holds no results" "$m" '^SKIP verdict-bound'
  has "escalation: SKIP when the log holds no results" "$m" '^SKIP escalation'
}
lint_verdict_bound() {
  local b d m f; b=$(lint post "$BASE/work" 2>&1); d=$(mut); f="$d/threat-hunting/hunt-logs/$SLUG-hunt-log.md"
  awk '/^## Hunt-Level Verdict and Coverage/{s=1} /^## / && !/^## Hunt-Level/{s=0} s && /^\|/{n++; if(n==3){print "| **Refuted** | Unconfirmed | n/a |"; next}} {print}' "$f" > "$f.new" && mv "$f.new" "$f"
  m=$(lint post "$d" 2>&1)
  has "verdict-bound: Refuted with unconfirmed coverage fails" "$m" '^FAIL verdict-bound .*coverage'
  only_new_fail "verdict-bound: adds only the verdict-bound FAIL" "$b" "$m" verdict-bound
  d=$(mut); f="$d/threat-hunting/hunt-logs/$SLUG-hunt-log.md"
  awk '/^## Hunt-Level Verdict and Coverage/{s=1} /^## / && !/^## Hunt-Level/{s=0} s && /^\|/{n++; if(n==3){print "| Refuted | Confirmed | n/a |"; next}} {print}' "$f" > "$f.new" && mv "$f.new" "$f"
  printf '\n| H-9 | injected | Undetermined | none |\n' >> "$f"
  m=$(lint post "$d" 2>&1)
  has "verdict-bound: Refuted with an Undetermined hit fails" "$m" '^FAIL verdict-bound .*hit'
}
lint_escalation() {
  local d m f; d=$(mut); f="$d/threat-hunting/hunt-logs/$SLUG-hunt-log.md"
  printf '\n| H-9 | injected | True positive | none |\n' >> "$f"
  sedi "$f" 's/Suspicious Security Event/Security Event/g'
  m=$(lint post "$d" 2>&1)
  has "escalation: a true-positive hit with no Suspicious Security Event candidate warns" "$m" '^WARN escalation'
}

lint_attack_ids() {
  local b d m dep
  b=$(lint plan "$BASE/work" 2>&1)
  has "attack-ids: the baseline's IDs are checked" "$b" '^(PASS|WARN) attack-ids'
  d=$(mut); printf '\nT9999 and T1234.999\n' >> "$d/threat-hunting/intel-analysis/$SLUG-analysis.md"
  m=$(lint plan "$d" 2>&1)
  has "attack-ids: an unknown ID warns with the ATT&CK version" "$m" '^WARN attack-ids .*T9999 not in ATT&CK v[0-9]'
  has "attack-ids: an unknown sub-technique warns" "$m" '^WARN attack-ids .*T1234.999 not in ATT&CK v[0-9]'
  [ -z "$(printf '%s\n' "$m" | fail_ids)" ] && ok "attack-ids: unknown IDs are a WARN, not a FAIL" || bad "attack-ids: unknown IDs are a WARN, not a FAIL"
  dep=$(awk -F'\t' '!/^#/ && $3=="deprecated"{print $1; exit}' "$REPO/data/attack-enterprise-ids.tsv")
  if [ -n "$dep" ]; then
    d=$(mut); printf '\n%s\n' "$dep" >> "$d/threat-hunting/hunt-plans/$SLUG-hunt-plan.md"
    m=$(lint plan "$d" 2>&1); has "attack-ids: a deprecated ID warns" "$m" "^WARN attack-ids .*$dep is deprecated"
  fi
  d=$(mut); printf '\nattack.t9998\n' >> "$d/threat-hunting/hunt-plans/$SLUG-hunt-plan.md"
  m=$(lint plan "$d" 2>&1); has "attack-ids: Sigma-style lowercase tags are read" "$m" '^WARN attack-ids .*T9998'
}
lint_attack_ids_data_missing() {
  local d m; d=$(mut)
  mkdir -p "$d/scripts" "$d/data"; cp "$REPO/scripts/check-contracts.sh" "$d/scripts/"; cp "$REPO/data/section-order.tsv" "$d/data/"
  m=$(bash "$d/scripts/check-contracts.sh" "$SLUG" plan "$d/threat-hunting" 2>&1)
  has "attack-ids: SKIP when the data file is absent" "$m" '^SKIP attack-ids'
}

lint_sigma() {
  if [ ! -f "$BASE/work/threat-hunting/detections/$SLUG-detection.md" ]; then ok "sigma: baseline has no detection (nothing to check)"; return; fi
  local b d m f; b=$(lint post "$BASE/work" 2>&1)
  has "sigma: baseline blocks parse" "$b" '^(PASS|WARN) sigma'
  d=$(mut); f="$d/threat-hunting/detections/$SLUG-detection.md"; sedi "$f" '/^[[:space:]]*condition:/d'
  m=$(lint post "$d" 2>&1)
  has "sigma: a block with no condition fails" "$m" '^FAIL sigma .*missing:.*condition'
  only_new_fail "sigma: adds only the sigma FAIL" "$b" "$m" sigma
  d=$(mut); f="$d/threat-hunting/detections/$SLUG-detection.md"; sedi "$f" 's/^\([[:space:]]*condition:\).*/\1 zz_undefined_sel/'
  m=$(lint post "$d" 2>&1); has "sigma: an undefined selection fails" "$m" '^FAIL sigma .*undefined selection: zz_undefined_sel'
}
lint_sigma_condition_forms() {
  local d m; d=$(mut)
  mkdir -p "$d/threat-hunting/detections"
  cat > "$d/threat-hunting/detections/$SLUG-detection.md" <<'EOF'
# Detection Handoff: test data

## DET-901 - wildcard condition
```yaml
title: t
logsource:
    product: windows
detection:
    selection_a:
        Image|endswith: '\a.exe'
    selection_b:
        CommandLine|contains: 'x'
    condition: 1 of selection_* and not filter_none
level: low
```
## DET-902 - all of them in a block scalar
```yaml
title: t
logsource:
    product: windows
detection:
    sel1:
        Image|endswith: '\a.exe'
    sel2:
        CommandLine|contains: 'x'
    condition: |
        all of them
level: low
```
## DET-903 - indicator only
```yaml
title: t
logsource:
    product: windows
detection:
    selection:
        Hashes|contains: 'abc'
        DestinationIp: '10.0.0.1'
    condition: selection
level: low
```
EOF
  m=$(lint post "$d" 2>&1)
  has "sigma forms: 1 of selection_* with an undefined filter fails" "$m" '^FAIL sigma block 1 .*undefined selection: filter_none'
  has "sigma forms: all of them in a block scalar passes" "$m" '^PASS sigma block 2'
  has "sigma forms: an indicator-only rule warns" "$m" '^WARN sigma block 3 .*indicators'
}

lint_det_xref() {
  local det="$BASE/work/threat-hunting/detections/$SLUG-detection.md"
  if [ ! -f "$det" ]; then
    local b; b=$(lint post "$BASE/work" 2>&1)
    has "det-xref: SKIP when the baseline has no detection" "$b" '^SKIP det-xref'
    return
  fi
  local b d m f; b=$(lint post "$BASE/work" 2>&1)
  has "det-xref: baseline IDs agree" "$b" '^PASS det-xref'
  d=$(mut); f="$d/threat-hunting/validations/$SLUG-validation.md"
  awk '!d && sub(/DET-[A-Za-z0-9]+/,"DET-999"){d=1} {print}' "$f" > "$f.new" && mv "$f.new" "$f"
  m=$(lint post "$d" 2>&1)
  has "det-xref: a validation DET ID absent from the detection fails" "$m" '^FAIL det-xref .*DET-999'
  only_new_fail "det-xref: adds only the det-xref FAIL" "$b" "$m" det-xref
}
lint_det_xref_stale_validation() {
  local d m f; d=$(mut); f="$d/threat-hunting/hunt-reports/$SLUG-hunt-report.md"
  awk '/^## Validation/{print; print "Pending hunt-validator"; s=1; next} /^## /{s=0} !s{print}' "$f" > "$f.new" && mv "$f.new" "$f"
  m=$(lint post "$d" 2>&1)
  has "det-xref: a Validation section left at the placeholder warns" "$m" '^WARN det-xref .*Pending hunt-validator'
}
lint_language() {
  local b d m; b=$(lint post "$BASE/work" 2>&1)
  has "language: the baseline report has no banned phrase" "$b" '^(PASS|WARN) language'
  d=$(mut); printf '\nThe environment is clean.\n' >> "$d/threat-hunting/hunt-reports/$SLUG-hunt-report.md"
  m=$(lint post "$d" 2>&1)
  has "language: 'clean' in the report warns" "$m" '^WARN language'
  [ -z "$(printf '%s\n' "$m" | fail_ids)" ] && ok "language: a banned phrase is a WARN, not a FAIL" || bad "language: a banned phrase is a WARN, not a FAIL"
}

agents_structure() {
  local a f
  for a in intel-challenger plan-reviewer detection-reviewer; do
    f="$REPO/agents/$a.md"
    if bash "$REPO/scripts/validate-frontmatter.sh" "$f" name description tools >/dev/null 2>&1; then ok "agent $a: frontmatter present"; else bad "agent $a: frontmatter present"; fi
    grep -q '^name: '"$a"'$' "$f" 2>/dev/null && ok "agent $a: name matches the file" || bad "agent $a: name matches the file"
    grep -q '^tools: Read, Grep, Glob$' "$f" 2>/dev/null && ok "agent $a: read-only tools" || bad "agent $a: read-only tools"
    grep -qF '| Severity | Location | Issue | Suggested fix |' "$f" 2>/dev/null && ok "agent $a: findings table format" || bad "agent $a: findings table format"
    grep -qi 'data, never instructions' "$f" 2>/dev/null && ok "agent $a: treats artifacts as data" || bad "agent $a: treats artifacts as data"
    grep -qi 'do not write' "$f" 2>/dev/null && ok "agent $a: writes no files" || bad "agent $a: writes no files"
  done
}
agents_dry_run() {
  local a out d marker
  d=$(mut); marker="$d/marker"; touch "$marker"
  for a in intel-challenger plan-reviewer detection-reviewer; do
    if [ "$a" = detection-reviewer ] && [ ! -f "$BASE/work/threat-hunting/detections/$SLUG-detection.md" ]; then continue; fi
    out=$(cd "$d" && MSYS_NO_PATHCONV=1 claude --plugin-dir "$REPO" --add-dir "$REPO" --permission-mode acceptEdits -p "Dispatch the $a agent for slug $SLUG. The run's artifacts are under $d/threat-hunting. If the agent type is not registered in this session, read $REPO/agents/$a.md and run a general-purpose agent with that file's instructions, read-only. Print the findings exactly as returned." < /dev/null 2>&1)
    has "agent $a: returns a findings table or 'No findings'" "$out" '(\| Severity \| Location \| Issue \| Suggested fix \||No findings)'
  done
  if [ -z "$(find "$d" -type f -newer "$marker" ! -name marker 2>/dev/null)" ]; then ok "agents wrote no files"; else bad "agents wrote no files" "$(find "$d" -type f -newer "$marker" ! -name marker)"; fi
}

# --- tests end ---

main() {
  case "${1:-all}" in
    drift)    run_group drift;;
    baseline) mk_baseline;;
    lint)     need_baseline; run_group lint;;
    agents)   need_baseline; run_group agents;;
    wiring)   need_baseline; run_group wiring;;
    all)      run_group drift; need_baseline; run_group lint; run_group agents; run_group wiring;;
    drift_*|lint_*|agents_*|wiring_*)
      if declare -F "$1" >/dev/null; then need_baseline; "$1"; else echo "no such test: $1" >&2; exit 2; fi;;
    *) echo "usage: test-checks.sh [drift|baseline|lint|agents|wiring|all|<test_function>]" >&2; exit 2;;
  esac
  echo "---- $PASSN passed, $FAILN failed"
  [ "$FAILN" = 0 ]
}
main "$@"
