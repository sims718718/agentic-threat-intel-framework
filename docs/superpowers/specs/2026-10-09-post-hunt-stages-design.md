# Post-Hunt Stages: Design

Sub-project A of three (A: command split and post-hunt stages; B: quality hardening of existing skills; C: tooling and agents). B and C get their own specs.

## Purpose

The pipeline currently builds a detection and a validation record from an **unexecuted** hunt plan. `detection-engineer` is described as taking a "validated hunt finding" but reads only the plan's query pseudocode. The Unified Threat Hunting (UTH) steps **Execute Hunt**, **Document Outcomes** and **Report & Iterate** have no stage. This design adds them without changing any existing artifact.

**Success criteria**

1. A human executes the hunt manually. Their results enter the framework through a structured, auditable record, and the framework never fabricates a result.
2. `detection-engineer` and `hunt-reporter` consume real results.
3. The six existing artifacts keep their paths, slug rule, top-level section order, and fields.
4. A "clean" result is never reported as "environment clean." It is bounded by confirmed telemetry coverage.

## Constraints

- **Additive only.** New skills may write new files. Existing artifacts may not gain, lose, rename or reorder sections or fields. (Decided by the user.)
- **Execution is manual.** No skill runs queries or attack simulations.
- **Grounded in UTH.** Each new element names its UTH step (see Grounding).
- Conventions as in `CLAUDE.md`: files are the interface; one slug per run; annotate gaps with `Unknown` / `[FILL IN: ...]` / `Not provided` / `[PENDING EXECUTION]` instead of inventing content.

## Flow

```
/run-hunt-pipeline   (planning, automated)
  gather → intel-analysis → intel-report → hunt-planner
        → hunt-execution [WORKSHEET] → hunt-validator [PLAN]

        ── human executes the hunt and records results ──

/run-post-hunt   (requires results)
  hunt-execution [INTAKE] → detection-engineer ┐
                          → hunt-reporter      ┴→ hunt-validator [RECORD]
```

`detection-engineer` is conditional (see `/run-post-hunt`). `hunt-reporter` runs before `hunt-validator` so the validator can write back into the report, mirroring its existing write-back into detection §9.

## New artifacts

| Artifact | Path | Written by |
|---|---|---|
| Hunt log | `./threat-hunting/hunt-logs/<slug>-hunt-log.md` | `hunt-execution` (blank in WORKSHEET mode, filled in INTAKE mode) |
| Hunt report | `./threat-hunting/hunt-reports/<slug>-hunt-report.md` and `.html` twin | `hunt-reporter` |

The hunt log is one progressively-filled file, like the validation file. The HTML twin follows `skills/_shared/references/html-report-shell.md` exactly; Markdown stays the source of truth.

## `hunt-execution` skill (UTH: Hunt Execution Steps; Initial Assessment)

Records the hunt. It has no execution tools and never produces results.

**WORKSHEET mode** (end of `/run-hunt-pipeline`, or standalone). Reads `<slug>-hunt-plan.md` and `./threat-hunting/environment-profile.md`. Writes `<slug>-hunt-log.md` with a header block and one block per Story, pre-filled from the plan: planned query pseudocode (the Story's `Detection Logic`), planned window, data sources and fields, and expected malicious/benign outcomes. Result fields are blank, marked `[PENDING EXECUTION]`.

**INTAKE mode** (after the human hunts; standalone or via `/run-post-hunt`). Input is the filled worksheet, a file path, or pasted free-form notes.

1. Locate the log. If standalone and the slug is not established, take the most recent file under `./threat-hunting/hunt-logs/` or, if none, the most recent plan; ask if several candidates exist (same rule as other skills).
2. Map results to Stories. Stories with no results are marked `Not executed`.
3. Check required fields per Story: queries run (verbatim), window actually searched vs planned, data sources actually queried, result counts, hit list, triage dispositions, known-good exclusions applied, deviations from plan. Standalone: ask only for what is missing. Via `/run-post-hunt`: mark `Not provided`.
4. **Coverage check.** For each data source, did it return events across the full window searched? If not confirmed, the Story verdict is Inconclusive (coverage unproven), never Refuted.
5. Record each hit's triage disposition: true positive, false positive, benign, or undetermined.
6. **Escalation.** A true-positive or undetermined hit is a potential Suspicious Security Event and is flagged to the user first, before the rest of the write-up (same rule as `hunt-validator`).
7. Verdict per Story and overall: **Supported**, **Refuted**, or **Inconclusive**. Refuted requires confirmed coverage and a clean result against the plan's disproof criterion (the hypothesis rubric's Falsifiability dimension).
8. List **outcome candidates** drawn from the six outcome categories (Visibility Gap, Security Control Issue, Detection Opportunity, Hunt Opportunity, Suspicious Security Event, Threat Intelligence Observable).
9. Save new known-good entries in the log as the exclusion list for the next hunt.

Intake updates the log in place on re-run.

**Hunt log structure** (fixed order, a downstream contract): Execution Header (hunter, dates executed, platform, plan reference) → Per-Story Results → Hunt-Level Verdict and Coverage → Outcome Candidates → Known-Good / Exclusion List → Deviations and New Questions.

## `hunt-reporter` skill (UTH: Report & Iterate; Maturity & Metrics)

Reads `<slug>-report.md` (intel), `<slug>-hunt-plan.md`, `<slug>-hunt-log.md`, and `<slug>-detection.md` if present. Writes `<slug>-hunt-report.md` + `.html`.

**Fixed section order:** Executive Summary → Hypothesis and Verdict → Scope and Coverage Achieved (planned vs actual) → Findings → Typed Outcomes → Detections → Visibility Gaps → Next Iteration → Metrics → Caveats → Validation → Sources.

- **Wording.** "No evidence of X found in <sources> over <window>," never "environment is clean."
- **Validation** contains `Pending hunt-validator`; `hunt-validator` RECORD mode overwrites it.
- **Next Iteration** routes `Threat Intelligence Observable` outcomes back to `intel-analysis` and `Hunt Opportunity` outcomes back to `hunt-planner` as hypothesis seeds.
- **Metrics** are the per-hunt outcome metrics from UTH Maturity & Metrics: net-new detections for this hunt, visibility gaps raised, techniques with a passing validation, robustness level of any detection shipped, and time from epic open to report. It does **not** report hours spent, queries run, or records searched.
- **Caveats** always state the UTH reporting caveats: clean results are bounded by telemetry coverage, and coverage scores are visibility-scored, not proof of detection.
- Missing inputs are annotated, not invented. If the log is absent the skill stops and asks for results (it does not write a report from the plan alone).

## `hunt-validator` skill changes (UTH: Document Outcomes; Validation Hook)

Two modes, **inferred, not stored**, so no field is added to the existing validation or detection artifacts.

- **PLAN mode.** Used when `<slug>-hunt-log.md` has no recorded results (including at the end of `/run-hunt-pipeline`). Writes `<slug>-validation.md` with test selection, approval placeholders and the telemetry-proof question, all `[PENDING EXECUTION]`. No outcome documentation. No write-back to the detection or the report. No detection exists yet, so the existing `Source detection:` field reads `None yet (PLAN mode)`.
- **RECORD mode.** Used when the log has recorded results. Existing behavior, plus:
  - The validation-required table's "clean hunt" rows are decided from the log's verdict and coverage fields.
  - Typed outcomes are documented from the log's outcome candidates.
  - It writes back into detection §9 as today, and now also into the hunt report's `Validation` section.
  - Validation test fields stay `[PENDING EXECUTION]` unless the user supplies test results, because an attack simulation is a separate human step.

## `detection-engineer` skill changes

Adds `<slug>-hunt-log.md` as an input. Where it exists it supplies observed false-positive data and sample sizes for §7 (so "None observed" can state a real sample size), triage evidence, and the queries that actually ran. When absent, behavior is unchanged: it reads the plan, or asks for the finding directly. Output format and the 10-section template are unchanged.

## Commands

### `/run-hunt-pipeline` (edited)

Stages: `gather` → `intel-analysis` → `intel-report` → `hunt-planner` → `hunt-execution` (WORKSHEET) → `hunt-validator` (PLAN). Remains non-pausing. The final summary lists the artifact paths, including the blank hunt log, states that detection and hunt report are produced after the hunt, and points to `/run-post-hunt`. It no longer runs `detection-engineer`.

### `/run-post-hunt [slug] [results path or pasted results]` (new)

1. Resolve the slug from the argument, or from the most recent hunt plan; ask only if several candidates exist.
2. **Results gate.** If no results are supplied and the hunt log holds none, stop and say what to provide. This is the one deliberate stop in either command.
3. `hunt-execution` INTAKE. Surface any escalation immediately.
4. `detection-engineer`, only if the outcome candidates include Analytics/Detection or any hit exists; otherwise skip and state the reason.
5. `hunt-reporter`.
6. `hunt-validator` RECORD.
7. Summary: file paths, overall verdict and coverage status, escalations, and what remains pending.

**Edge cases.** Partial results: unrun Stories are `Not executed`, the overall verdict is Inconclusive, later stages still run. Re-runs: the log updates in place and the report is regenerated.

## Files

- **New:** `skills/hunt-execution/SKILL.md`, `skills/hunt-reporter/SKILL.md`, `commands/run-post-hunt.md`, a blank worksheet in `examples/hunt-logs/`.
- **Edited:** `skills/hunt-validator/SKILL.md`, `skills/detection-engineer/SKILL.md`, `commands/run-hunt-pipeline.md`, `.claude-plugin/plugin.json` (add the two skills), `README.md` (diagram, stage walkthrough, output convention, layout, and the "no confirmation gates" limitation), `CLAUDE.md`.
- **Untouched:** `gather`, `intel-analysis`, `intel-report`, `hunt-planner`, `agents/intel-researcher.md`.

No filled example is added, because it would require invented hunt results.

## Grounding

| Element | UTH step |
|---|---|
| `hunt-execution` | Hunt Execution Steps (Gather and Analyze, Investigate and Validate, Document Observations); Initial Assessment (known-good list) |
| Coverage check, verdicts | Feasibility (data quality); Hypothesis rubric Falsifiability; Validation Hook |
| Outcome candidates, `hunt-validator` RECORD | Tasks (Outcomes); Document Outcomes |
| `hunt-reporter` | Report & Iterate; Maturity & Metrics (outcome metrics, reporting caveats) |
| Next Iteration routing | The cycle back to the Triggering Event |

## Verification

1. `plugin.json` parses and lists eight skills; both new skills pass `scripts/validate-frontmatter.sh <file> name description`.
2. The headings of the six existing artifact templates are identical before and after (checked by grep over the `SKILL.md` templates).
3. Dry run on the `pan-os-cve-2026-0257` slug using a small synthetic results file kept in scratch space and not committed. It must show: the log and report have every required section; unproven coverage yields Inconclusive; missing fields read `Not provided`; no result is invented; the results gate stops when no results exist.
4. `README.md` and `CLAUDE.md` describe the two-command flow and no longer claim the pipeline emits detection and validation as finished artifacts.

## Out of scope

Sub-projects B (ACH, assumed breach, prior-hunt and known-good checks in planning, intel timeliness, the `gather` pipeline-mode contradiction, Step 0 de-duplication) and C (artifact-contract linter, Sigma and ATT&CK checks, `intel-challenger` and reviewer agents).
