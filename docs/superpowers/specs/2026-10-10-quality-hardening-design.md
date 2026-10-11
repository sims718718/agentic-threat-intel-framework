# Quality Hardening: Design

Sub-project B of three (A: post-hunt stages, on the pushed branch `feature/post-hunt-stages`; C: tooling and agents). This work is stacked on A's branch because it edits skills A changed. C gets its own spec.

## Purpose

Raise the quality of the existing skills without changing what they produce. Every change names the Unified Threat Hunting Process (UTH) step it comes from. The nine-gap review that started this work found these gaps in B's scope: a contradiction in `gather`, duplicated Step 0 content, a thin Initial Assessment, optional hypothesis rigor, intel with no timeliness or relevance test, and a planner that can overwrite a plan whose results are recorded. B also folds in the ten minors deferred from A's final review.

**Success criteria**

1. The six existing artifacts keep their paths, slug rule, top-level section order, and fields. No new field appears in any of them.
2. Each new check follows the framework's existing pattern: ask once in standalone use, annotate in pipeline mode, lower an existing rating where a gate exists, never block `/run-hunt-pipeline`. (Decided by the user.)
3. A `hunt-planner` run can no longer destroy the link between a plan and recorded hunt results.
4. A first-time hunter with no prior hunts, and a user with an all-`Unknown` environment profile, still get a complete plan.

## Constraints

- **Outputs unchanged.** Improvements land in instructions, references, and inside existing sections (`Initial Research`, `Exclusions`, `Operational Implications`, `Open Questions and Gaps`, the Quality Gate text).
- **Exception: A's new artifacts.** The hunt log and hunt report are new in A's unmerged PR, so B may change their content. Their section order stays fixed.
- **Check behavior** is the existing ask/annotate/downgrade pattern; no hard gates.
- **Grounded in UTH.** See the Grounding table.
- Conventions as in `CLAUDE.md`: files are the interface; annotate gaps with `Unknown` / `[FILL IN: ...]` / `Not provided` / `[PENDING EXECUTION]`; never fabricate.

## Changes

### B1, B2: `gather` and a shared Step 0 reference (UTH: Step 0 Environment Context)

- New `skills/_shared/references/environment-context.md` is the single home for the six-context table (SIEM / data platform, EDR platform, environment type, industry vertical, log retention, hunt maturity) with its "why it matters" column, the Express path (SIEM and environment type), and the `Unknown` rule.
- `gather` Step 2 and `hunt-planner` Step 0 link to it instead of copying the table. The `## Environment Profile` output template stays in `gather`.
- Both skills keep a one-line inline fallback ("capture at least SIEM and environment type") so `hunt-planner` stays usable if the reference cannot be read.
- Rewrite `skills/gather/SKILL.md:68`: pipeline mode never asks, infers what it can from context, marks the rest `Unknown`, and never pauses. Remove the contradictory "ask first" wording and the typos.

### B3: Initial Assessment (UTH: Initial Assessment)

New `skills/hunt-planner/references/initial-assessment.md`, referenced from `hunt-planner` Step 3. Findings go in the Epic's existing `Initial Research` and the Scope `Exclusions` line.

- **Prior-hunt check.** Scan `./threat-hunting/hunt-logs/` and `hunt-reports/` for the same ATT&CK techniques and data sources. Record hunt, date, verdict, and coverage. A prior `Refuted` hunt on the same technique within 90 days with no stack change is flagged as a likely duplicate. A prior hunt that was `Inconclusive` for coverage reasons is recorded with the telemetry fix it needed. No prior hunts: record "None found (no prior hunts in ./threat-hunting)".
- **Known-good seeding.** Pull entries from prior logs' `Known-Good / Exclusion List` into `Initial Research` and `Exclusions` as candidates, each marked "from <slug>, reconfirm".
- **RFIs.** When open-source research cannot answer a question and a trusted external organisation exists, list the RFI (recipient and ask).
- **Standalone use** asks once whether prior hunts live outside `./threat-hunting/` (for example Jira or Confluence). Pipeline mode annotates and continues.
- **Express mode** keeps only a one-line prior-hunt check.

### B4: Hypothesis rigor (UTH: Hypothesis Development; Stories)

In `hunt-planner` Step 2, supported by `hypothesis-templates.md`:

- **Competing hypotheses.** Heuer's method (already in `hypothesis-templates.md`) is required when the trigger admits two or more plausible explanations for the same observable, or when the assessment finds a benign explanation that is not excluded. Its result goes in `Initial Research`. Otherwise record "ACH not needed: single explanation".
- **Assumed breach.** State the AIMOD2 premise (an adversary has already bypassed preventive controls) in `Initial Research`.
- **Story diversity.** A non-Express plan with two or more Stories uses different methods (for example direct test versus baseline or anomaly), or records a single-method justification in `Initial Research`.
- Express mode still skips ACH and Story diversity, with the existing Express warning.

### B5: Intel timeliness, actionability and relevance (UTH: Intelligence-Led Hunting)

In `intel-analysis` and `intel-report`, within existing sections:

- **Timeliness statement** in *Scope and Intelligence Question*: intelligence type (strategic, operational, tactical), most recent activity date, and a shelf-life judgment of Current, Aging, or Historical. Aging or Historical tactical intelligence lowers the quality-gate status to LIMITED unless the question is strategic (rule added to `analysis-rubric.md`). IOCs outside the stated shelf life carry "Stale" in the existing notes text.
- **Actionability test.** A handoff seed must name the behavior, an ATT&CK ID, a data source, and a field-level observable. A seed that fails is labelled "information, not yet actionable" and listed under *Open Questions and Gaps* with the analysis it still needs. `intel-report` carries only actionable seeds into `Recommended Actions > Hunt`.
- **Relevance to us** in *Operational Implications*: compare the actor's targeting criteria (vertical, geography, tech stack, size) with the environment profile and rate it Matches, Partial, Not shown, or Unknown. Unknown stays Unknown when the profile is `Unknown`. Hunt seeds are ordered by relevance and timeliness with the reason in one clause; active exploitation of a product in use goes first.
- **Collection suggestions** in *Open Questions and Gaps*: the internal sources the framework cannot query (own incident history, ISAC reporting, exposure and credential-leak monitoring, internal telemetry).

### B6: Plan lock (UTH: Formalize Hunt Plan)

Before writing `<slug>-hunt-plan.md`, `hunt-planner` checks whether `./threat-hunting/hunt-logs/<slug>-hunt-log.md` holds results, using `hunt-execution`'s definition (`Results status` of `RECORDED` or `PARTIAL`, or any Per-Story result field changed from `[PENDING EXECUTION]`). If it does, `hunt-planner` writes nothing and says the plan is locked because the results reference its Story IDs. `commands/run-hunt-pipeline.md` step 5 notes this behavior.

### B7: Follow-ups from A's final review

1. `hunt-execution` template: *Hunt-Level Verdict and Coverage* gains a small table (Verdict, Coverage, Window planned versus achieved) that the reporter and validator read.
2. The verdict table distinguishes Story scope from hunt scope.
3. Detection Opportunity requires an executed query with `Confirmed` coverage for that Story.
4. If no Story executed, `Results status` stays `PENDING EXECUTION`, unmapped text is recorded, and the `/run-post-hunt` gate trips.
5. RECORD mode without a detection writes `Source detection: None (detection-engineer skipped: <reason>)`.
6. The PLAN-mode telemetry-proof line goes in the validation record's existing `Follow-up:` field.
7. `hunt-reporter` carries a recorded validation forward when it regenerates a report.
8. The `hunt-reporter` and `hunt-validator` trigger descriptions are reworded so they do not overlap.
9. "Standalone (not via `/run-hunt-pipeline`)" in `detection-engineer` Step 1 and `hunt-validator` Step 1 becomes "not via a pipeline command".
10. README: redraw the mermaid diagram to show the two-command split, the PLAN edge, conditional detection, and the validator write-back to the hunt report; add a quality-gates row for `hunt-execution`; fix the "Whole pipeline, one input" heading.

## Files

- **New:** `skills/_shared/references/environment-context.md`, `skills/hunt-planner/references/initial-assessment.md`.
- **Edited:** `skills/gather/SKILL.md`, `skills/hunt-planner/SKILL.md` (Steps 0, 2, 3, 6 and the output checklist), `skills/hunt-planner/references/hypothesis-templates.md`, `skills/intel-analysis/SKILL.md`, `skills/intel-analysis/references/analysis-rubric.md`, `skills/intel-report/SKILL.md`, `skills/hunt-execution/SKILL.md`, `skills/hunt-validator/SKILL.md`, `skills/hunt-reporter/SKILL.md`, `skills/detection-engineer/SKILL.md` (wording only), `commands/run-hunt-pipeline.md` (step 5), `README.md`, `CLAUDE.md`.
- **Untouched:** `agents/intel-researcher.md` (C), `hunt-planner`'s Jira templates and other references.

## Edge cases

- First-ever hunt: the prior-hunt check records "None found" and continues.
- Environment profile all `Unknown`: relevance reads Unknown; no claim is made.
- Express mode: one-line prior-hunt check only.
- Shared reference unreadable: the inline fallback applies.

## Grounding

| Change | UTH step |
|---|---|
| B1, B2 | Step 0: Environment Context |
| B3 | Initial Assessment (prior hunts, known-good list, RFIs) |
| B4 | Hypothesis Development (ACH, assumed breach); Stories (challenge assumptions, different methods) |
| B5 | Intelligence-Led Hunting: timeliness, actionability, relevance to the organisation |
| B6 | Formalize Hunt Plan |
| B7 | Document Outcomes; Report & Iterate (as in A) |

## Verification

1. **Template check.** The fenced templates of the existing artifacts (`gather`, `intel-analysis`, `intel-report`, `hunt-planner`, `detection-engineer`, `hunt-validator`) are byte-identical to the head of `feature/post-hunt-stages`. The `hunt-execution` template is the one deliberate exception and has its own assertions.
2. **Rule checks.** Each new rule has a grep assertion that fails before the edit and passes after.
3. **Dry runs** on a scratch copy of the PAN-OS example:
   - a `hunt-planner` run with a prior hunt report and log on disk records the prior hunt, seeds known-good entries marked "reconfirm", and adds no fields;
   - a `hunt-planner` run with a recorded hunt log writes nothing and says the plan is locked;
   - `gather` in pipeline mode asks nothing and writes `Unknown` for what it cannot infer.
4. **Intel-side changes are verified statically only.** Exercising `intel-analysis` end to end needs live web research; the plan flags this gap instead of claiming coverage.

## Out of scope

Sub-project C: the artifact-contract linter, Sigma and ATT&CK checks, and the `intel-challenger`, plan-reviewer and detection-reviewer agents.
