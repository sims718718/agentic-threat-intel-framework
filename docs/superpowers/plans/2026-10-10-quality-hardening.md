# Quality Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tighten the existing skills (shared Step 0 reference, richer Initial Assessment, required hypothesis rigor, intel timeliness/actionability/relevance, plan lock, and A's ten deferred minors) without changing any existing artifact's paths, sections, or fields.

**Architecture:** Prompt-content edits in place, plus two new reference files. Every edit is applied by a small Python helper that asserts each target string occurs exactly once, so a drifted anchor fails loudly instead of silently mis-editing. "Tests" are grep assertions that fail before and pass after each task, a fenced-template diff proving existing artifact templates did not change, and `claude -p` dry runs on a scratch copy of the PAN-OS example.

**Tech Stack:** Markdown skills/references/commands, bash (`grep`, `awk`, `diff`), Python 3 (`edit.py` helper), `claude --plugin-dir` for dry runs.

**Spec:** `docs/superpowers/specs/2026-10-10-quality-hardening-design.md` (read it first; this plan argues from it).

## Global Constraints

Copied from the spec:

- **Outputs unchanged.** Improvements land in instructions, references, and inside existing sections (`Initial Research`, `Exclusions`, `Operational Implications`, `Open Questions and Gaps`, the Quality Gate text).
- **Exception: A's new artifacts.** The hunt log and hunt report may change content; their section order stays fixed.
- **Check behavior** is the existing ask/annotate/downgrade pattern: ask once in standalone use, annotate in pipeline mode, lower an existing rating where a gate exists, never block `/run-hunt-pipeline`. No hard gates.
- Conventions as in `CLAUDE.md`: files are the interface; annotate gaps with `Unknown` / `[FILL IN: ...]` / `Not provided` / `[PENDING EXECUTION]`; never fabricate.
- No new field in any existing artifact. Edits to `gather`, `intel-analysis`, `intel-report`, `hunt-planner`, `detection-engineer`, and `hunt-validator` must not add or alter any fenced code block (Task 8 diffs fenced content against the baseline taken in Task 1). Use prose and tables outside fences.
- The `hunt-execution` skill's own template is the one fence that may change (Task 5).
- Shared Step 0 reference path: `skills/_shared/references/environment-context.md`. Initial Assessment reference path: `skills/hunt-planner/references/initial-assessment.md`.
- Untouched: `agents/intel-researcher.md`, `hunt-planner`'s Jira templates and other references (except `hypothesis-templates.md`).
- In edit instructions, text between triple-quoted Python strings is exact; write it as shown.

## Review Focus

Failure modes the spec implies but a casual implementation would miss. Each is pinned by a check or dry run in the task that owns it.

1. **Plan lock misfires on a blank worksheet.** The lock must trip only when the hunt log *holds results*; a blank worksheet from a previous planning run must not stop a re-plan. (Task 3, dry run in Task 8)
2. **Seeded known-good entries act as approved exclusions.** They must be marked "from <slug>, reconfirm" and must not silently narrow the hunt. (Task 3, dry run in Task 8)
3. **"Likely duplicate" flag suppresses a needed hunt.** It is an annotation only; the plan is still produced. (Task 3)
4. **Shared reference unreadable.** `gather` and `hunt-planner` still capture at least SIEM and environment type. (Tasks 2, 3)
5. **Intel downgrades misapplied.** Strategic questions must not be capped at LIMITED by shelf-life; relevance must stay `Unknown` when the environment profile is `Unknown` rather than being inferred. (Task 4)
6. **Dangling slug rule.** Removing `hunt-validator` Step 1's duplicate slug paragraph must not leave other text pointing at it. (Task 6)

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `skills/_shared/references/environment-context.md` | Create | Single definition of the six Step 0 contexts, Express path, `Unknown` rule |
| `skills/hunt-planner/references/initial-assessment.md` | Create | Prior-hunt check, known-good seeding, RFIs, mode behavior |
| `skills/gather/SKILL.md` | Modify | Link shared reference; fix pipeline-mode contradiction |
| `skills/hunt-planner/SKILL.md` | Modify | Step 0 link; Step 2 ACH + assumed breach; Step 3 checklist; Story diversity; plan lock; checklist |
| `skills/hunt-planner/references/hypothesis-templates.md` | Modify | ACH trigger rule |
| `commands/run-hunt-pipeline.md` | Modify | Step 5 notes plan lock |
| `skills/intel-analysis/SKILL.md` | Modify | Timeliness, relevance, actionability, collection suggestions |
| `skills/intel-analysis/references/analysis-rubric.md` | Modify | Shelf-life status cap |
| `skills/intel-report/SKILL.md` | Modify | Carry only actionable, ordered hunt seeds |
| `skills/hunt-execution/SKILL.md` | Modify | Hunt-level table, verdict scope, Detection Opportunity rule, zero-executed rule |
| `skills/hunt-validator/SKILL.md` | Modify | Description, slug dedupe, Follow-up placement, no-detection source line |
| `skills/hunt-reporter/SKILL.md` | Modify | Description, validation carry-forward |
| `skills/detection-engineer/SKILL.md` | Modify | Caller wording |
| `README.md`, `CLAUDE.md` | Modify | Diagram, gates row, heading, new contracts |

Working directory for every command: `D:\agentic-threat-intel-framework` (Git Bash). Branch: `feature/quality-hardening` (already created, stacked on `feature/post-hunt-stages`). Scratch files live in `.superpowers/scratch-b/` (git-ignored).

---

### Task 1: Scratch tooling and baseline

**Files:**
- Create (git-ignored): `.superpowers/scratch-b/edit.py`, `.superpowers/scratch-b/lib.sh`, `.superpowers/scratch-b/base-<skill>.txt`
- Commit: this plan

**Interfaces:**
- Produces: `edit.py` module with `rep(path, old, new, count=1)`, `rep_line(path, startswith, new)` (replace the single line starting with `startswith`; `new=None` deletes the line and one following blank line), `rep_block(path, start_prefix, end_prefix, new)` (replace from the line starting with `start_prefix` through the line starting with `end_prefix`, inclusive). All assert exactly one match and preserve line endings. `lib.sh` with `must`, `mustnot`, `fences`. Baselines of fenced content for the six artifact-owning skills.

- [ ] **Step 1: Confirm the branch**

```bash
git branch --show-current
git status --short
```
Expected: `feature/quality-hardening`; clean tree except this plan if not yet committed.

- [ ] **Step 2: Create the helper module with the Write tool**

Write `.superpowers/scratch-b/edit.py`:

```python
import io

def _read(p):
    return io.open(p, encoding="utf-8", newline="").read()

def _write(p, s):
    io.open(p, "w", encoding="utf-8", newline="").write(s)

def rep(path, old, new, count=1):
    s = _read(path)
    n = s.count(old)
    assert n == count, "%s: expected %d match(es), found %d for: %r" % (path, count, n, old[:80])
    _write(path, s.replace(old, new))

def _lines(s):
    return s.split("\n")

def rep_line(path, startswith, new):
    s = _read(path)
    L = _lines(s)
    idx = [i for i, l in enumerate(L) if l.startswith(startswith)]
    assert len(idx) == 1, "%s: expected 1 line starting %r, found %d" % (path, startswith[:60], len(idx))
    i = idx[0]
    if new is None:
        del L[i]
        if i < len(L) and L[i] == "":
            del L[i]
    else:
        L[i] = new
    _write(path, "\n".join(L))

def rep_block(path, start_prefix, end_prefix, new):
    s = _read(path)
    L = _lines(s)
    a = [i for i, l in enumerate(L) if l.startswith(start_prefix)]
    assert len(a) == 1, "%s: expected 1 start line %r, found %d" % (path, start_prefix[:60], len(a))
    i = a[0]
    j = next((k for k in range(i, len(L)) if L[k].startswith(end_prefix)), None)
    assert j is not None, "%s: end line %r not found after start" % (path, end_prefix[:60])
    L[i:j + 1] = new.split("\n")
    _write(path, "\n".join(L))
```

- [ ] **Step 3: Create the check library and the baselines**

```bash
mkdir -p .superpowers/scratch-b
cat > .superpowers/scratch-b/lib.sh <<'EOF'
FAIL=0
must()   { grep -qF -- "$2" "$1" && echo "ok: $2" || { echo "MISSING in $1: $2"; FAIL=1; }; }
mustnot(){ grep -qF -- "$2" "$1" && { echo "UNEXPECTED in $1: $2"; FAIL=1; } || echo "ok (absent): $2"; }
fences() { awk '/^```/{s=!s; next} s' "$1"; }
EOF
source .superpowers/scratch-b/lib.sh
for s in gather intel-analysis intel-report hunt-planner detection-engineer hunt-validator; do
  fences skills/$s/SKILL.md > .superpowers/scratch-b/base-$s.txt
done
wc -l .superpowers/scratch-b/base-*.txt | tail -7
git check-ignore .superpowers/scratch-b/edit.py && echo "scratch is git-ignored"
python -c "import sys; sys.path.insert(0,'.superpowers/scratch-b'); import edit; print('edit.py imports ok')"
```
Expected: six non-empty baselines, `scratch is git-ignored`, `edit.py imports ok`.

- [ ] **Step 4: Commit the plan**

```bash
git add docs/superpowers/plans/2026-10-10-quality-hardening.md
git commit -m "Add implementation plan for quality hardening (sub-project B)" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```
(Append the harness-required session trailer to every commit in this plan.)

---

### Task 2: Shared Step 0 reference and `gather` (B1, B2)

**Files:**
- Create: `skills/_shared/references/environment-context.md`
- Modify: `skills/gather/SKILL.md`

**Interfaces:**
- Produces: `skills/_shared/references/environment-context.md` with the six-context table (rows keyed by bold context names), `## Express path`, `## Unknown`; consumed by `gather` Step 2 and `hunt-planner` Step 0 (Task 3) via the relative link `../_shared/references/environment-context.md`.

- [ ] **Step 1: Write the failing checks** (save as `.superpowers/scratch-b/check2.sh`)

```bash
cd /d/agentic-threat-intel-framework; source .superpowers/scratch-b/lib.sh
R=skills/_shared/references/environment-context.md; G=skills/gather/SKILL.md
must $R "## Express path"
must $R "## Unknown"
must $R "**SIEM / Data Platform**"
must $R "**Hunt Maturity Level**"
must $G "../_shared/references/environment-context.md"
must $G "at least **SIEM platform** and **environment type**"
mustnot $G "ask first, always proceed"
mustnot $G "additonal"
mustnot $G "procedding"
mustnot $G "intial"
[ "$(grep -c 'SIEM / Data Platform' $G)" -le 1 ] && echo "ok: gather table deduplicated" || { echo "gather still has the table copy"; FAIL=1; }
fences $G | diff - .superpowers/scratch-b/base-gather.txt >/dev/null && echo "ok: gather fences identical" || { echo "GATHER FENCES CHANGED"; FAIL=1; }
bash scripts/validate-frontmatter.sh $G name description >/dev/null || FAIL=1
echo "FAIL=$FAIL"; exit $FAIL
```
Run: `bash .superpowers/scratch-b/check2.sh`
Expected: `MISSING` lines (reference file absent, link absent, old wording present), `FAIL=1`.

- [ ] **Step 2: Create the shared reference**

Write `skills/_shared/references/environment-context.md`:

```markdown
# Environment Context

**Used by:** `gather` (Step 2) and `hunt-planner` (Step 0).
**Purpose:** The single definition of the six environment contexts, so queries, field names, time windows, and scaffolding are tailored to the user's real stack rather than written generically. This is Step 0 of the Unified Threat Hunting Process.

| Context | Why It Matters |
|---|---|
| **SIEM / Data Platform** | Splunk SPL vs. KQL vs. Elastic DSL vs. Chronicle affects every query example |
| **EDR Platform** | CrowdStrike, SentinelOne, Defender for Endpoint — affects telemetry field names |
| **Environment Type** | On-premises, cloud-native (AWS/Azure/GCP), or hybrid |
| **Industry Vertical** | Tailors threat actor relevance (finance, healthcare, energy, manufacturing, etc.) |
| **Approximate Log Retention** | Determines what time windows are actually feasible |
| **Hunt Maturity Level** | Score honestly using `../../hunt-planner/references/hunt-maturity-model.md` rather than a free-text guess — first-time hunters need more scaffolding; experienced teams may prefer a skeleton |

## Express path

If the user wants to move fast, capture only **SIEM platform** and **environment type**. These are the minimum required to produce useful, non-generic outputs; with less, queries will be generic.

## Unknown

A value that cannot be captured or inferred reads `Unknown`. Never guess a value, and never omit the row.

## Profile location

`./threat-hunting/environment-profile.md`, written by `gather` (its Step 3 holds the `## Environment Profile` table template).
```

- [ ] **Step 3: Edit `gather`** (Write `.superpowers/scratch-b/edit2.py`, then run it)

```python
import sys
sys.path.insert(0, ".superpowers/scratch-b")
from edit import rep_block, rep_line
P = "skills/gather/SKILL.md"

rep_block(P, "| Context | Why It Matters |", "| **Hunt Maturity Level** |",
 "The six contexts, why each matters, the Express path, and the `Unknown` rule are defined in `../_shared/references/environment-context.md`; capture or infer each one. If that file cannot be read, capture at least **SIEM platform** and **environment type**.")

rep_line(P, "**Express path**: If the user wants to move fast", None)

rep_line(P, "- **Pipeline mode: ask first, always proceed**",
 "- **Pipeline mode: never ask, always proceed** — infer what you can from context, mark everything else `Unknown`, and never pause after the first pass. This mirrors every other stage's \"proceed and annotate gaps rather than block\" philosophy.")
print("gather edited")
```
Run: `python .superpowers/scratch-b/edit2.py`
Expected: `gather edited`.

- [ ] **Step 4: Run the checks**

Run: `bash .superpowers/scratch-b/check2.sh`
Expected: all `ok:`, `FAIL=0`. If `mustnot ... ask first` fails, re-read the pipeline-mode bullet and fix the leftover wording by hand.

- [ ] **Step 5: Commit**

```bash
git add skills/_shared/references/environment-context.md skills/gather/SKILL.md
git commit -m "Add shared Step 0 reference; fix gather pipeline-mode contradiction" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 3: `hunt-planner` Initial Assessment, hypothesis rigor, plan lock (B2, B3, B4, B6)

**Files:**
- Create: `skills/hunt-planner/references/initial-assessment.md`
- Modify: `skills/hunt-planner/SKILL.md`, `skills/hunt-planner/references/hypothesis-templates.md`, `commands/run-hunt-pipeline.md`

**Interfaces:**
- Consumes: `../_shared/references/environment-context.md` (Task 2); hunt-log fields `Results status`, `Known-Good / Exclusion List`, `Dates executed`, hunt-level verdict (A, Task 5 reshapes the hunt-level section into a table with columns Verdict, Coverage, Window planned vs achieved — read either form).
- Produces: `references/initial-assessment.md` sections `## 1. Prior-hunt check`, `## 2. Known-good seeding`, `## 3. RFIs`, `## Mode behavior`; the plan-lock rule consumed by `commands/run-hunt-pipeline.md`.

- [ ] **Step 1: Write the failing checks** (`.superpowers/scratch-b/check3.sh`)

```bash
cd /d/agentic-threat-intel-framework; source .superpowers/scratch-b/lib.sh
I=skills/hunt-planner/references/initial-assessment.md; P=skills/hunt-planner/SKILL.md
must $I "## 1. Prior-hunt check"
must $I "## 2. Known-good seeding"
must $I "## 3. RFIs"
must $I "## Mode behavior"
must $I "from <slug>, reconfirm"
must $I "None found (no prior hunts in ./threat-hunting)"
must $I "likely duplicate"
must $I "annotation only"
must $P "../_shared/references/environment-context.md"
must $P "capture at least **SIEM platform** and **environment type**"
must $P "references/initial-assessment.md"
must $P "ACH not needed: single explanation"
must $P "Assumed breach."
must $P "single-method justification"
must $P "Plan lock (applies to Express Mode too)"
must $P "A blank worksheet"
must $P "prior-hunt check, known-good seeding"
must skills/hunt-planner/references/hypothesis-templates.md "Required (hunt-planner Step 2)"
must commands/run-hunt-pipeline.md "the plan is locked"
[ "$(grep -c 'SIEM / Data Platform' $P)" -eq 0 ] && echo "ok: planner table deduplicated" || { echo "planner still has the table"; FAIL=1; }
fences $P | diff - .superpowers/scratch-b/base-hunt-planner.txt >/dev/null && echo "ok: planner fences identical" || { echo "PLANNER FENCES CHANGED"; FAIL=1; }
bash scripts/validate-frontmatter.sh $P name description >/dev/null || FAIL=1
echo "FAIL=$FAIL"; exit $FAIL
```
Run it. Expected: `FAIL=1`.

- [ ] **Step 2: Create `references/initial-assessment.md`**

````markdown
# Initial Assessment Checklist

**Fits at:** `hunt-planner` Step 3 (Initial Assessment).
**UTH step:** Initial Assessment: previous hunts and lessons learned, known-good behavior (which becomes the exclusion list), and RFIs to trusted external organisations.
**Where findings go:** the Epic's existing `### Initial Research`; known-good candidates also go in the Scope `Exclusions` line. No new field is added to the hunt plan.

## 1. Prior-hunt check

Scan `./threat-hunting/hunt-logs/` and `./threat-hunting/hunt-reports/` for hunts that touched the same ATT&CK techniques or data sources. Reports and logs do not carry the technique list, so match through each prior slug's `./threat-hunting/hunt-plans/<prior-slug>-hunt-plan.md` Epic `### MITRE ATT&CK Mapping`.

For each match, record one line in `Initial Research`:

```
Prior hunt: <prior-slug> — executed <date, or Unknown> — verdict <Supported | Refuted | Inconclusive> — coverage <Confirmed | Unconfirmed> — <note>
```

| Prior hunt | Note to record |
|---|---|
| `Refuted`, same technique, within 90 days, no stack change | "likely duplicate: consider extending scope or window instead of repeating" |
| `Inconclusive` for coverage reasons | The telemetry fix it needed, so this plan does not repeat the gap |
| `Supported` or an `Undetermined` hit | Link to the follow-up; reuse its triage notes |

A "likely duplicate" is an annotation only. The plan is still produced; the hunter decides.

If nothing matches, record `None found (no prior hunts in ./threat-hunting)`.

## 2. Known-good seeding

Copy entries from matching prior logs' `## Known-Good / Exclusion List` into `Initial Research`, and list them on the Scope `Exclusions` line, each marked `from <slug>, reconfirm`. They are candidates, never approved exclusions: do not describe them as excluded from the hunt until the owner reconfirms, because an unconfirmed exclusion can hide a real finding.

## 3. RFIs

When open-source research cannot answer a question and a trusted external organisation is available (sector ISAC, peer, vendor), list the RFI in `Initial Research` as `RFI: <recipient> — <the question>`. Do not send anything; the framework only records it.

## Mode behavior

| Mode | Behavior |
|---|---|
| Standalone | Ask once whether prior hunts are kept outside `./threat-hunting/` (for example Jira or Confluence); record the answer. Then run checks 1-3 |
| Pipeline / non-interactive | Run checks 1-3 on what is on disk, annotate gaps, never ask |
| Express Mode | Run check 1 as a single line only |
````

- [ ] **Step 3: Edit `hunt-planner`, `hypothesis-templates.md`, and the pipeline command** (Write `.superpowers/scratch-b/edit3.py`, then run)

```python
import sys
sys.path.insert(0, ".superpowers/scratch-b")
from edit import rep, rep_block, rep_line
P = "skills/hunt-planner/SKILL.md"

# B2: Step 0 uses the shared reference
rep_block(P, "| Context | Why It Matters |", "| **Hunt Maturity Level** |",
 "The six contexts, why each matters, the Express path, and the `Unknown` rule are defined in `../_shared/references/environment-context.md`; capture or infer each one. If that file cannot be read, capture at least **SIEM platform** and **environment type**.")
rep_line(P, "**Express path**: If the user wants to move fast", None)

# B4: Step 2 rigor
rep(P, "most failures are Specificity, so push the hypothesis down to a field-level observable.",
 """most failures are Specificity, so push the hypothesis down to a field-level observable.

**Competing explanations (required when they exist).** Run the Competing Hypotheses Method in `references/hypothesis-templates.md` when the trigger admits two or more plausible explanations for the same observable (for example malicious use versus administrator tooling), or when the Initial Assessment (Step 3) finds a benign explanation that is not excluded; revisit this after Step 3. Record the matrix summary in the Epic's `Initial Research`. When there is a single explanation, record `ACH not needed: single explanation`. Express Mode skips this.

**Assumed breach.** State the AIMOD2 premise in `Initial Research`: assume an adversary has already bypassed preventive controls, so the hunt looks for post-compromise behavior rather than prevention failures.""")

# B3: Step 3 checklist
rep(P, "Gather supporting information:",
 "Gather supporting information, and run the prior-hunt check, known-good seeding, and RFI checks in `references/initial-assessment.md`; record the results in the Epic's `Initial Research` and `Exclusions`:")

# B4: Story diversity
rep(P, "Stories are discrete investigations under the Epic. Each Story tests a specific aspect of the hypothesis.",
 "Stories are discrete investigations under the Epic. Each Story tests a specific aspect of the hypothesis. A non-Express plan with two or more Stories must use different methods (for example a direct signature-style test and a baseline or anomaly test) so the hypothesis is challenged rather than only confirmed; if one method genuinely suffices, record a single-method justification in the Epic's `Initial Research`.")

# B6: plan lock
rep(P, "Use the templates in `references/jira-templates.md` for exact field structures.",
 """**Plan lock (applies to Express Mode too).** Before writing `<slug>-hunt-plan.md` or its HTML twin, check `./threat-hunting/hunt-logs/<slug>-hunt-log.md`. If it holds results (`Results status` is `RECORDED` or `PARTIAL`, or any Per-Story result field is no longer `[PENDING EXECUTION]`), write nothing and tell the user the plan is locked, because the recorded results reference its Story IDs; they may archive the log or choose a new slug to re-plan. A blank worksheet (`PENDING EXECUTION`, every result field still pending) does not lock the plan.

Use the templates in `references/jira-templates.md` for exact field structures.""")

# Express one-liner
rep(P, "1. Capture trigger and hypothesis in 2-3 sentences (use the Express Template in `references/hypothesis-templates.md`)",
 "1. Capture trigger and hypothesis in 2-3 sentences (use the Express Template in `references/hypothesis-templates.md`), plus a one-line prior-hunt check (`references/initial-assessment.md`, check 1)")

# Output checklist
rep(P, "- [ ] Initial assessment completed with internal/external sources",
 "- [ ] Initial assessment completed with internal/external sources, and the prior-hunt check, known-good seeding, ACH decision, and assumed-breach premise recorded in `Initial Research`")

# hypothesis-templates: ACH trigger
rep("skills/hunt-planner/references/hypothesis-templates.md", "### When to Use Competing Hypotheses\n",
 "### When to Use Competing Hypotheses\n\n**Required (hunt-planner Step 2)** when the trigger admits two or more plausible explanations for the same observable, or when the initial assessment finds a benign explanation that is not excluded. Optional otherwise.\n")

# pipeline command: step 5 note
rep("commands/run-hunt-pipeline.md", "Wait for `./threat-hunting/hunt-plans/<slug>-hunt-plan.md`.",
 "Wait for `./threat-hunting/hunt-plans/<slug>-hunt-plan.md`. If the hunt log already holds results, `hunt-planner` writes nothing and reports that the plan is locked; carry on to step 6.")
print("planner edited")
```
Run: `python .superpowers/scratch-b/edit3.py`
Expected: `planner edited`. If an assertion fails, the anchor drifted: re-read that line in the file and fix the anchor, not the helper.

- [ ] **Step 4: Run the checks**

Run: `bash .superpowers/scratch-b/check3.sh`
Expected: all `ok:`, `FAIL=0`.

- [ ] **Step 5: Commit**

```bash
git add skills/hunt-planner commands/run-hunt-pipeline.md
git commit -m "hunt-planner: Initial Assessment checklist, required ACH and Story diversity, plan lock" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Intel timeliness, actionability, relevance (B5)

**Files:**
- Modify: `skills/intel-analysis/SKILL.md`, `skills/intel-analysis/references/analysis-rubric.md`, `skills/intel-report/SKILL.md`

**Interfaces:**
- Produces: a shelf-life judgment (`Current` / `Aging` / `Historical`) in the analysis's *Scope and Intelligence Question*; relevance ratings (`Matches` / `Partial` / `Not shown` / `Unknown`); the literal label `information, not yet actionable`; consumed by `intel-report` (carry only actionable seeds) and indirectly `hunt-planner` (seeds).

- [ ] **Step 1: Write the failing checks** (`.superpowers/scratch-b/check4.sh`)

```bash
cd /d/agentic-threat-intel-framework; source .superpowers/scratch-b/lib.sh
A=skills/intel-analysis/SKILL.md; R=skills/intel-report/SKILL.md; B=skills/intel-analysis/references/analysis-rubric.md
must $A "shelf-life judgment"
must $A "**Current**, **Aging**, or **Historical**"
must $A "marked \`Stale\`"
must $A "**Matches**, **Partial**, **Not shown**, or **Unknown**"
must $A "relevance stays \`Unknown\` when the profile is \`Unknown\`"
must $A "information, not yet actionable"
must $A "incident history, sector ISAC reporting"
must $A "caps the status at LIMITED unless the question is strategic"
must $A "also give the timeliness statement"
must $B "caps the status at LIMITED unless the question is strategic"
must $R "**Hunt seeds.**"
must $R "information, not yet actionable"
for f in intel-analysis intel-report; do fences skills/$f/SKILL.md | diff - .superpowers/scratch-b/base-$f.txt >/dev/null && echo "ok: $f fences identical" || { echo "$f FENCES CHANGED"; FAIL=1; }; done
for f in $A $R; do bash scripts/validate-frontmatter.sh $f name description >/dev/null || FAIL=1; done
echo "FAIL=$FAIL"; exit $FAIL
```
Run it. Expected: `FAIL=1`.

- [ ] **Step 2: Edit the three files** (Write `.superpowers/scratch-b/edit4.py`, then run)

```python
import sys
sys.path.insert(0, ".superpowers/scratch-b")
from edit import rep, rep_line
A = "skills/intel-analysis/SKILL.md"

# Step 0: timeliness statement
rep(A, "Older material may supply labeled background, not proof of activity within the requested window.",
 "Older material may supply labeled background, not proof of activity within the requested window. State the intelligence type (strategic, operational, or tactical), the most recent reported activity date, and a shelf-life judgment: **Current**, **Aging**, or **Historical**. Operational and tactical intelligence has a shelf life: a technique that has since been patched or abandoned is Historical even if the report is recent. IOCs outside the shelf life are marked `Stale` in the existing notes text, not in a new column.")

# Step 3: relevance, actionability, ordering, collection suggestions
rep_line(A, "Explain relevance to the known environment conditionally.",
 """Explain relevance to the known environment conditionally. Rate relevance as **Matches**, **Partial**, **Not shown**, or **Unknown** by comparing the actor's or campaign's targeting criteria (vertical, geography, technology stack, size) and any exposed product or version with the environment profile; relevance stays `Unknown` when the profile is `Unknown`, and is never inferred from an actor's prominence. Offer behavior + observable + likely telemetry as handoff seeds; never claim local compromise, visibility, or detection validation from external reporting alone.

A seed is **actionable** only if it names the behavior, an ATT&CK technique ID, a data source, and a field-level observable. Label any seed that fails `information, not yet actionable` and list it under *Open Questions and Gaps* with the analysis it still needs. Order actionable seeds by relevance and timeliness, giving the reason in one clause; active exploitation of a product the organization runs comes first. Also list under *Open Questions and Gaps* the internal sources this framework cannot query that would sharpen relevance: the organization's incident history, sector ISAC reporting, exposure and credential-leak monitoring, and internal telemetry.""")

# Step 4: status cap
rep(A, "or **INSUFFICIENT** (the central question cannot be answered).",
 "or **INSUFFICIENT** (the central question cannot be answered). Aging or Historical tactical or operational intelligence caps the status at LIMITED unless the question is strategic.")

# Step 5: timeliness belongs in the existing Scope subsection (template fence is unchanged)
rep(A, "Return the path, gate status, and material gaps.",
 "In `### Scope and Intelligence Question`, also give the timeliness statement from Step 0 (intelligence type, most recent activity date, shelf-life judgment), and in `### Operational Implications` the relevance rating and ordered seeds from Step 3.\n\nReturn the path, gate status, and material gaps.")

# Rubric
rep("skills/intel-analysis/references/analysis-rubric.md",
 "**LIMITED:** usable findings remain, but collection gaps prevent READY; identify the affected judgments and next collection action.",
 "**LIMITED:** usable findings remain, but collection gaps prevent READY; identify the affected judgments and next collection action. Aging or Historical tactical or operational intelligence (the shelf-life judgment in the analysis's Scope section) also caps the status at LIMITED unless the question is strategic.")

# intel-report
rep("skills/intel-report/SKILL.md", "## Step 3: Render the HTML twin",
 """**Hunt seeds.** Under `### Hunt`, carry forward only seeds that `intel-analysis` marked actionable (behavior, observable, and data source named in the sentence, and an ATT&CK ID on the Coverage table row it refers to), in the analysis's order of relevance and timeliness. A seed marked `information, not yet actionable` goes in **Confidence and Sourcing** with the analysis it still needs. If the analysis stage was skipped (Step 1), apply the same test yourself.

## Step 3: Render the HTML twin""")
print("intel edited")
```
Run: `python .superpowers/scratch-b/edit4.py`
Expected: `intel edited`.

- [ ] **Step 3: Run the checks**

Run: `bash .superpowers/scratch-b/check4.sh`
Expected: all `ok:`, `FAIL=0`.

- [ ] **Step 4: Commit**

```bash
git add skills/intel-analysis skills/intel-report
git commit -m "Intel: timeliness statement, relevance rating, actionability test, collection suggestions" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 5: `hunt-execution` follow-ups (B7 items 1-4)

**Files:**
- Modify: `skills/hunt-execution/SKILL.md`

**Interfaces:**
- Produces: the hunt log's `## Hunt-Level Verdict and Coverage` section becomes a three-column table (`Verdict | Coverage | Window planned vs achieved`) followed by a per-source line; consumed by `hunt-planner` (Task 3 prior-hunt check), `hunt-reporter`, `hunt-validator`.

- [ ] **Step 1: Write the failing checks** (`.superpowers/scratch-b/check5.sh`)

```bash
cd /d/agentic-threat-intel-framework; source .superpowers/scratch-b/lib.sh
E=skills/hunt-execution/SKILL.md
must $E "| Verdict | Coverage | Window planned vs achieved |"
must $E "Judge each Story on its own fields."
must $E "Refuted only if every Story is Refuted"
must $E "does not bear on the hypothesis"
must $E "a plan's Analytics/Detection task alone is not enough"
must $E "leave \`Results status\` as \`PENDING EXECUTION\`"
mustnot $E "a validated query exists"
for h in "## Execution Header" "## Per-Story Results" "## Hunt-Level Verdict and Coverage" "## Outcome Candidates" "## Known-Good / Exclusion List" "## Deviations and New Questions"; do must $E "$h"; done
bash scripts/validate-frontmatter.sh $E name description >/dev/null || FAIL=1
echo "FAIL=$FAIL"; exit $FAIL
```
Run it. Expected: `FAIL=1`.

- [ ] **Step 2: Edit** (Write `.superpowers/scratch-b/edit5.py`, then run)

```python
import sys
sys.path.insert(0, ".superpowers/scratch-b")
from edit import rep, rep_line
E = "skills/hunt-execution/SKILL.md"

# 1: hunt-level table in the template
rep(E, '[Verdict; coverage per data source; window achieved vs planned; "No evidence found in ... over ..." when applicable.]',
 '''| Verdict | Coverage | Window planned vs achieved |
|---|---|---|
| [PENDING EXECUTION] (Supported / Refuted / Inconclusive) | [PENDING EXECUTION] (Confirmed / Unconfirmed) | [PENDING EXECUTION] |

[Per-source coverage and, when applicable, "No evidence found in ... over ...".]''')

# 2: verdict scope
rep(E, "7. **Verdicts**, per Story and for the hunt:",
 "7. **Verdicts.** Judge each Story on its own fields. The hunt-level verdict is Supported if any Story is Supported, Refuted only if every Story is Refuted, and Inconclusive otherwise:")
rep(E, "| **Refuted** | Every Story is `Executed`;", "| **Refuted** | The Story is `Executed`;")
rep(E, "| **Inconclusive** | Anything else: a Story `Not executed`, coverage `Unconfirmed`, a shorter window than planned, or an `Undetermined` hit. State which |",
 "| **Inconclusive** | Anything else: the Story is `Not executed`, coverage `Unconfirmed`, a shorter window than planned, an `Undetermined` hit, or a `True positive` that does not bear on the hypothesis. State which |")

# 3: Detection Opportunity
rep(E, "| Detection Opportunity | The query ran, hits were triaged, and the logic could stand as a rule; or the plan expects an Analytics/Detection task and a validated query exists |",
 "| Detection Opportunity | The Story's query was `Executed` with coverage `Confirmed`, any hits were triaged, and the logic could stand as a rule; a plan's Analytics/Detection task alone is not enough |")

# 4: no executed Story
rep(E, "8. **Set `Results status`:** `RECORDED` if every Story is `Executed`; `PARTIAL` if any Story is `Not executed` or `Partial`.",
 "8. **Set `Results status`:** `RECORDED` if every Story is `Executed`; `PARTIAL` if any Story is `Not executed` or `Partial`. If no Story is `Executed` or `Partial`, leave `Results status` as `PENDING EXECUTION`, record the unmapped text under *Deviations and New Questions*, and say that no results were recognised (standalone: ask the user to map them to Stories).")
print("hunt-execution edited")
```
Run: `python .superpowers/scratch-b/edit5.py`
Expected: `hunt-execution edited`.

- [ ] **Step 3: Run the checks**

Run: `bash .superpowers/scratch-b/check5.sh`
Expected: `FAIL=0`.

- [ ] **Step 4: Commit**

```bash
git add skills/hunt-execution/SKILL.md
git commit -m "hunt-execution: hunt-level table, verdict scope, Detection Opportunity and zero-result rules" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 6: `hunt-validator`, `hunt-reporter`, `detection-engineer` follow-ups (B7 items 5-9)

**Files:**
- Modify: `skills/hunt-validator/SKILL.md`, `skills/hunt-reporter/SKILL.md`, `skills/detection-engineer/SKILL.md`

**Interfaces:**
- Consumes: Step 0 slug rule in `hunt-validator` (already says it applies to every step).
- Produces: `Source detection: None (detection-engineer skipped: <reason>)` in RECORD mode without a detection; PLAN-mode telemetry-proof line inside the existing `Follow-up:` field.

- [ ] **Step 1: Write the failing checks** (`.superpowers/scratch-b/check6.sh`)

```bash
cd /d/agentic-threat-intel-framework; source .superpowers/scratch-b/lib.sh
V=skills/hunt-validator/SKILL.md; R=skills/hunt-reporter/SKILL.md; D=skills/detection-engineer/SKILL.md
must $V "The slug is resolved in Step 0."
must $V "in the record's \`Follow-up:\` field"
must $V "None (detection-engineer skipped: <reason>)"
must $V "Not for writing the narrative hunt report: that is hunt-reporter."
must $R "Not for proving a detection fires or documenting typed outcomes: that is hunt-validator."
must $R "carry its Method/Result/Evidence summary into"
must $D "not via a pipeline command"
mustnot $V "If invoked standalone (not via \`/run-hunt-pipeline\`)"
mustnot $D "(not via \`/run-hunt-pipeline\`)"
# Review Focus 6: nothing else points at a slug rule in Step 1
mustnot $V "slug rule as Step 1"
for f in detection-engineer hunt-validator; do fences skills/$f/SKILL.md | diff - .superpowers/scratch-b/base-$f.txt >/dev/null && echo "ok: $f fences identical" || { echo "$f FENCES CHANGED"; FAIL=1; }; done
for f in $V $R $D; do bash scripts/validate-frontmatter.sh $f name description >/dev/null || FAIL=1; done
echo "FAIL=$FAIL"; exit $FAIL
```
Run it. Expected: `FAIL=1`.

- [ ] **Step 2: Edit** (Write `.superpowers/scratch-b/edit6.py`, then run)

```python
import sys
sys.path.insert(0, ".superpowers/scratch-b")
from edit import rep, rep_line
V = "skills/hunt-validator/SKILL.md"
R = "skills/hunt-reporter/SKILL.md"
D = "skills/detection-engineer/SKILL.md"

# validator: description, slug dedupe, Follow-up placement, no-detection source line
rep(V, "or close out and document a completed hunt.",
 "or record the typed outcomes of a completed hunt. Not for writing the narrative hunt report: that is hunt-reporter.")
rep_line(V, "If invoked standalone (not via `/run-hunt-pipeline`) and the slug isn't already established",
 "The slug is resolved in Step 0.")
rep(V, "and add one line naming the data source that must be shown to generate events for this technique before a clean hunt result can be trusted. Then go to Step 5.",
 "and put one line in the record's `Follow-up:` field naming the data source that must be shown to generate events for this technique before a clean hunt result can be trusted. Then go to Step 5.")
rep(V, "under `## Outcome Documentation`, the single line `Not documented — hunt not yet executed (PLAN mode)`.",
 "under `## Outcome Documentation`, the single line `Not documented — hunt not yet executed (PLAN mode)`.\n\n**RECORD mode without a detection:** write `Source detection: None (detection-engineer skipped: <reason>)`; never invent a DET ID.")

# reporter: description, carry-forward
rep(R, "to report or close out an executed hunt, or what to do next after hunt results are in.",
 "to report on an executed hunt, or what to do next after hunt results are in. Not for proving a detection fires or documenting typed outcomes: that is hunt-validator.")
rep(R, "- Leave the `## Validation` placeholder as written; `hunt-validator` replaces it.",
 "- Leave the `## Validation` placeholder as written when no validation record exists; `hunt-validator` replaces it. If `./threat-hunting/validations/<slug>-validation.md` already holds a recorded test result, carry its Method/Result/Evidence summary into `## Validation` instead, in the same wording `hunt-validator` writes.")

# detection-engineer: caller wording
rep(D, "If invoked standalone (not via `/run-hunt-pipeline`)", "If invoked standalone (not via a pipeline command)")
print("validator/reporter/detection edited")
```
Run: `python .superpowers/scratch-b/edit6.py`
Expected: `validator/reporter/detection edited`.

- [ ] **Step 3: Run the checks**

Run: `bash .superpowers/scratch-b/check6.sh`
Expected: `FAIL=0`. Also confirm the old A-era assertions still hold:
```bash
grep -c "Pending hunt-validator" skills/hunt-validator/SKILL.md skills/hunt-reporter/SKILL.md
grep -c "leave it untouched and say so" skills/hunt-validator/SKILL.md
```
Expected: both files ≥1; the validator line ≥1.

- [ ] **Step 4: Commit**

```bash
git add skills/hunt-validator skills/hunt-reporter skills/detection-engineer
git commit -m "Validator/reporter/detection-engineer: description overlap, slug dedupe, Follow-up placement, no-detection source" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 7: README and CLAUDE.md (B7 item 10, new contracts)

**Files:**
- Modify: `README.md`, `CLAUDE.md`

- [ ] **Step 1: Write the failing checks** (`.superpowers/scratch-b/check7.sh`)

```bash
cd /d/agentic-threat-intel-framework; source .superpowers/scratch-b/lib.sh
must README.md "Stage 4 — detection-engineer (only if a hit or detection candidate exists)"
must README.md "Stage 5 — hunt-validator (PLAN before the hunt, RECORD after)"
must README.md 'S3 -->|"hunt-plan.md (PLAN mode, before the hunt)"| S5'
must README.md 'S5 -.->|"RECORD mode: writes result back into the report"| S4B'
must README.md "run-hunt-pipeline"  # still mentioned
must README.md "| \`hunt-execution\` | Coverage-bounded verdict |"
must README.md "**Planning half, one input:**"
mustnot README.md "**Whole pipeline, one input:**"
must README.md "stages 0–3"
must CLAUDE.md "A plan is locked once its hunt log holds results"
must CLAUDE.md "environment-context.md"
echo "FAIL=$FAIL"; exit $FAIL
```
Run it. Expected: `FAIL=1`.

- [ ] **Step 2: Edit** (Write `.superpowers/scratch-b/edit7.py`, then run)

```python
import sys
sys.path.insert(0, ".superpowers/scratch-b")
from edit import rep
RD = "README.md"
CL = "CLAUDE.md"

rep(RD, 'subgraph S4["Stage 4 — detection-engineer"]',
 'subgraph S4["Stage 4 — detection-engineer (only if a hit or detection candidate exists)"]')
rep(RD, 'subgraph S5["Stage 5 — hunt-validator"]',
 'subgraph S5["Stage 5 — hunt-validator (PLAN before the hunt, RECORD after)"]')
rep(RD, '    S4B -->|"hunt-report.md"| S5\n',
 '''    S4B -->|"hunt-report.md"| S5
    S3 -->|"hunt-plan.md (PLAN mode, before the hunt)"| S5
    S5 -.->|"RECORD mode: writes result back into the report"| S4B
''')
rep(RD, "The chain has four properties worth knowing before you read the stages:",
 "`/run-hunt-pipeline` runs stages 0–3, then `hunt-execution` (worksheet) and `hunt-validator` (PLAN). `/run-post-hunt` runs `hunt-execution` (intake), stages 4 and 4b, and `hunt-validator` (RECORD). The human hunt sits between them.\n\nThe chain has four properties worth knowing before you read the stages:")
rep(RD, "| `hunt-validator` | Validation record | A detection artifact should not permanently read \"not yet validated\" once a run has occurred |",
 "| `hunt-validator` | Validation record | A detection artifact should not permanently read \"not yet validated\" once a run has occurred |\n| `hunt-execution` | Coverage-bounded verdict | `Refuted` needs every planned source queried with confirmed coverage over the planned window and no true-positive or undetermined hit; anything else is `Inconclusive` |")
rep(RD, "**Whole pipeline, one input:**", "**Planning half, one input:**")

rep(CL, "- **Never fabricate, annotate instead.**",
 "- **A plan is locked once its hunt log holds results.** `hunt-planner` writes nothing if `hunt-logs/<slug>-hunt-log.md` holds results (the recorded results reference the plan's Story IDs). A blank worksheet does not lock it.\n- **Step 0 has one home.** The six environment contexts, the Express path, and the `Unknown` rule live in `skills/_shared/references/environment-context.md`; `gather` and `hunt-planner` link to it instead of copying the table.\n- **Never fabricate, annotate instead.**")
print("docs edited")
```
Run: `python .superpowers/scratch-b/edit7.py`
Expected: `docs edited`.

- [ ] **Step 3: Run the checks**

Run: `bash .superpowers/scratch-b/check7.sh`
Expected: `FAIL=0`.

- [ ] **Step 4: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "Docs: redraw pipeline diagram, add hunt-execution gate row, document plan lock and shared Step 0" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Verification and dry runs

**Files:**
- Scratch only (never committed): `.superpowers/scratch-b/projD`, `projE`, `projF`

**Interfaces:**
- Consumes: everything above. Needs the `claude` CLI; plugin loaded with `--plugin-dir`. Run prompts with `MSYS_NO_PATHCONV=1`, `< /dev/null`, `--permission-mode acceptEdits`, and keep any input file inside the scratch project directory.

- [ ] **Step 1: Static verification across the branch**

```bash
source .superpowers/scratch-b/lib.sh
for n in 2 3 4 5 6 7; do bash .superpowers/scratch-b/check$n.sh >/dev/null 2>&1 && echo "check$n ok" || { echo "check$n FAILED"; FAIL=1; }; done
for s in gather intel-analysis intel-report hunt-planner detection-engineer hunt-validator; do
  fences skills/$s/SKILL.md | diff -q - .superpowers/scratch-b/base-$s.txt >/dev/null && echo "fences identical: $s" || { echo "FENCES CHANGED: $s"; FAIL=1; }
done
git diff --stat feature/post-hunt-stages -- agents skills/hunt-planner/references/jira-templates.md skills/hunt-planner/references/feasibility-checklist.md
python -c "import json;d=json.load(open('.claude-plugin/plugin.json'));assert len(d['skills'])==8; print('manifest ok')"
echo "FAIL=$FAIL"
```
Expected: six `check ok`, six `fences identical`, an empty `git diff --stat`, `manifest ok`, `FAIL=0`.

- [ ] **Step 2: Build scratch projects**

```bash
EX=/d/agentic-threat-intel-framework/examples
for P in projD projE; do
  T=$PWD/.superpowers/scratch-b/$P/threat-hunting
  rm -rf $PWD/.superpowers/scratch-b/$P
  mkdir -p $T/{intel-analysis,intel-reports,hunt-plans,hunt-logs}
  cp $EX/intel-analysis/*.md $T/intel-analysis/
  cp $EX/intel-reports/*.md $T/intel-reports/
  printf '## Environment Profile\n\n| Context | Value |\n|---|---|\n| SIEM / Data Platform | Unknown |\n| EDR Platform | Unknown |\n| Environment Type | Unknown |\n| Industry Vertical | Unknown |\n| Approximate Log Retention | Unknown |\n| Hunt Maturity Level | Unknown |\n' > $T/environment-profile.md
done
# projD: a blank worksheet for the slug (must NOT lock) plus a synthetic prior hunt with overlapping techniques
T=$PWD/.superpowers/scratch-b/projD/threat-hunting
cp $EX/hunt-logs/pan-os-cve-2026-0257-hunt-log.md $T/hunt-logs/
cp $EX/hunt-plans/pan-os-cve-2026-0257-hunt-plan.md $T/hunt-plans/prior-gp-hunt-hunt-plan.md
sed -i 's/HUNT-2026-001/HUNT-2026-000/g' $T/hunt-plans/prior-gp-hunt-hunt-plan.md
cat > $T/hunt-logs/prior-gp-hunt-hunt-log.md <<'EOF'
# Hunt Log: prior-gp-hunt
SYNTHETIC TEST FIXTURE - not a real hunt.

## Execution Header
| Field | Value |
|---|---|
| Plan reference | ./threat-hunting/hunt-plans/prior-gp-hunt-hunt-plan.md (HUNT-2026-000) |
| Hunter | test-user |
| Dates executed | 2026-09-20 |
| Platform / tools used | Splunk (synthetic) |
| Results status | RECORDED |

## Per-Story Results
### HUNT-2026-000-S1: prior GlobalProtect hunt
| Field | Value |
|---|---|
| Execution status | Executed |

## Hunt-Level Verdict and Coverage
| Verdict | Coverage | Window planned vs achieved |
|---|---|---|
| Refuted | Confirmed | 121 days vs 121 days |

## Outcome Candidates
| Category | Evidence reference | Notes |
|---|---|---|

## Known-Good / Exclusion List
| Entry | Reason | Confirmed by |
|---|---|---|
| svc-backup from 198.51.100.20 | nightly backup | identity team |

## Deviations and New Questions
None.
EOF
# projE: a log that holds results for the slug (must lock) with an existing plan
T=$PWD/.superpowers/scratch-b/projE/threat-hunting
cp $EX/hunt-plans/pan-os-cve-2026-0257-hunt-plan.md $T/hunt-plans/
cp $EX/hunt-logs/pan-os-cve-2026-0257-hunt-log.md $T/hunt-logs/
sed -i 's/| Results status | PENDING EXECUTION |/| Results status | RECORDED |/' $T/hunt-logs/pan-os-cve-2026-0257-hunt-log.md
md5sum $T/hunt-plans/*.md > $PWD/.superpowers/scratch-b/e.md5
ls $T/hunt-plans $T/hunt-logs
```
Expected: projD has two logs and two plans; projE has one plan and a RECORDED log; `e.md5` written.

- [ ] **Step 3: Prior hunts and blank worksheet (Review Focus 1, 2, 3)**

```bash
cd .superpowers/scratch-b/projD
MSYS_NO_PATHCONV=1 claude --plugin-dir D:/agentic-threat-intel-framework --permission-mode acceptEdits -p "Use the hunt-planner skill for slug pan-os-cve-2026-0257 as step 5 of /run-hunt-pipeline (pipeline mode: do not ask questions). The intel report is already in threat-hunting/intel-reports." < /dev/null 2>&1 | tail -12
cd ../../..
source .superpowers/scratch-b/lib.sh
PL=.superpowers/scratch-b/projD/threat-hunting/hunt-plans/pan-os-cve-2026-0257-hunt-plan.md
test -f $PL && echo "ok: plan written (blank worksheet did not lock)" || { echo "PLAN NOT WRITTEN"; FAIL=1; }
must $PL "prior-gp-hunt"
must $PL "reconfirm"
must $PL "likely duplicate"
must $PL "ACH"
must $PL "ssumed breach"
for h in "## Environment Profile" "## Epic:" "## Story:" "## Task:"; do must $PL "$h"; done
echo "FAIL=$FAIL"
```
Expected: plan written; it names `prior-gp-hunt` with the "likely duplicate" annotation, lists the seeded known-good entry with "reconfirm" (and does not present it as an applied exclusion), records the ACH decision and assumed-breach premise, and keeps the standard Epic/Story/Task structure. Read the Epic's Initial Research and Exclusions to confirm the known-good entry is described as a candidate. The plan must still be a complete plan despite the duplicate flag.

- [ ] **Step 4: Plan lock (Review Focus 1)**

```bash
cd .superpowers/scratch-b/projE
MSYS_NO_PATHCONV=1 claude --plugin-dir D:/agentic-threat-intel-framework --permission-mode acceptEdits -p "Use the hunt-planner skill for slug pan-os-cve-2026-0257 as step 5 of /run-hunt-pipeline (pipeline mode: do not ask questions)." < /dev/null 2>&1 | tee ../e.out | tail -6
md5sum -c ../e.md5
grep -ci "locked" ../e.out
cd ../../..
```
Expected: `...hunt-plan.md: OK` (unchanged) and a non-zero count from `grep -ci locked`.

- [ ] **Step 5: `gather` in pipeline mode (B1)**

```bash
mkdir -p .superpowers/scratch-b/projF && cd .superpowers/scratch-b/projF && rm -rf threat-hunting
MSYS_NO_PATHCONV=1 claude --plugin-dir D:/agentic-threat-intel-framework --permission-mode acceptEdits -p "Use the gather skill in pipeline mode. This is step 1 of /run-hunt-pipeline for the input: CVE-2026-0257 in PAN-OS GlobalProtect, our org is a regional hospital using Splunk." < /dev/null 2>&1 | tee ../f.out | tail -6
cd ../../..
source .superpowers/scratch-b/lib.sh
G=.superpowers/scratch-b/projF/threat-hunting/environment-profile.md
must $G "Splunk"
must $G "Unknown"
grep -ci "which\|could you\|please tell\|?" .superpowers/scratch-b/f.out
echo "FAIL=$FAIL"
```
Expected: profile written with Splunk and Unknown values; the output contains no question to the user (a count of 0, or only question marks inside quoted text; read `f.out` if the count is non-zero).

- [ ] **Step 6: Final status**

```bash
git status --short
git log --oneline feature/post-hunt-stages..HEAD
```
Expected: clean tree; one commit per task (Tasks 1-7) after the spec commit. Report any step that failed, with its output, instead of claiming success. State that the intel-side changes (Task 4) were verified statically only.
