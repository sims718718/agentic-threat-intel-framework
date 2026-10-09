---
name: hunt-validator
description: "Prove a detection actually fires before it ships, and document the hunt's final typed outcome (visibility gap, security control issue, detection opportunity, hunt opportunity, suspicious security event, or threat intelligence observable). Always trigger when a user asks to validate a detection, test whether telemetry generates for a technique, run an atomic test against a hunt finding, or close out and document a completed hunt. It runs in two modes: PLAN at the end of /run-hunt-pipeline (before the hunt, nothing to record yet) and RECORD at the end of /run-post-hunt (after a human has executed the hunt); it reads the hunt-execution log and the detection-engineer output."
---

# Hunt Validator

A hunt that finds nothing is only meaningful if you've demonstrated you *would* have seen it. This skill proves the telemetry and logic fire, then documents the hunt's outcome by category so it's trackable and reportable.

## Step 0: Choose the mode

If invoked standalone and the slug is not established from context, use the same most-recent-file rule as Step 1. Read `./threat-hunting/hunt-logs/<slug>-hunt-log.md` if it exists and check its `Results status`:

| `Results status` | Mode |
|---|---|
| `RECORDED` or `PARTIAL` | **RECORD mode**: the full procedure below, using the hunt log's results |
| `PENDING EXECUTION`, or no hunt log | **PLAN mode**: prepare the validation plan before the hunt; no results exist to document |

**PLAN mode** (end of `/run-hunt-pipeline`): apply Step 1's table to the plan's feasibility to state whether validation will be required; in Step 2 select the test and mark every result field `[PENDING EXECUTION]`; skip Steps 3 and 4; Step 5 writes the validation file as described there. If `./threat-hunting/validations/<slug>-validation.md` already exists with a Validation Record whose Outcome is not `[PENDING EXECUTION]`, leave it untouched and say so.

**RECORD mode** (end of `/run-post-hunt`): everything below, with the additions marked RECORD.

## Step 1: Determine if validation is required

If invoked standalone (not via `/run-hunt-pipeline`) and the slug isn't already established from context, look for the most recent matching file under `./threat-hunting/detections/*.md` and use its slug; if more than one candidate exists, ask the user which one.

Read `./threat-hunting/detections/<slug>-detection.md` if it exists. Check `references/validation-hook.md`'s "When to run" table:

| Situation | Validation required? |
|---|---|
| Hunt produced a candidate detection | Yes — blocks handoff |
| Hunt returned clean, feasibility was CONDITIONAL | Yes |
| Hunt returned clean, feasibility GO, technique never previously validated | Yes |
| Technique validated within the last 90 days, no stack change | No — cite the prior test |

To check the "feasibility was CONDITIONAL" row, also read `./threat-hunting/hunt-plans/<slug>-hunt-plan.md`'s Feasibility Assessment section (in the Epic) — the detection artifact alone doesn't carry that information.

**RECORD mode:** decide the two clean-hunt rows from the hunt log instead of asking. A hunt-level verdict of Refuted with coverage Confirmed is a clean hunt. A verdict of Inconclusive means the negative result is unsupported, so validation is required.

## Step 2: Run the validation procedure

**PLAN mode:** do not ask the user for results. Select the test (Atomic Red Team preferred), leave operator and approval fields as `[FILL IN: ...]`, mark every result field `[PENDING EXECUTION]`, and add one line naming the data source that must be shown to generate events for this technique before a clean hunt result can be trusted. Then go to Step 5. **RECORD mode:** the validation test is a human step separate from the hunt itself; record test results if the user supplied them, otherwise leave the test fields `[PENDING EXECUTION]`.

Follow `references/validation-hook.md`'s 7-step procedure (select test → coordinate → set a marker → execute → query blind → record result → clean up). You cannot execute an actual attack simulation yourself — walk the user through each step and record what they report back, or, if this is a planning/documentation pass rather than a live exercise, produce the record with clearly marked `[PENDING EXECUTION]` fields rather than fabricating a result.

Fill the validation record template from `references/validation-hook.md` exactly:

```
Test ID:        [ART Txxxx.xxx test #N | CALDERA ability | MANUAL-XX]
ATT&CK:         [from the detection artifact's section 2]
Date/Time UTC:  [start] - [stop]
Host / Account: [target]     Operator: [name]     Approval ref: [ticket]

Telemetry generated:  [Y / N]  — which source, which fields
Detection fired:      [Y / N / Delayed — Xm]
Hunt query matched:   [Y / N]
Time to visibility:   [ingest lag observed]

Outcome:  [Validated | False negative | Partial — describe]
Follow-up: [gap ticket / tuning / none]
```

Interpret the result using `references/validation-hook.md`'s failure table — a **false negative is the most valuable output of this step**; if telemetry didn't generate at all, that is a Visibility Gap outcome (Step 3 below), not a clean pass.

## Step 3: Document the typed outcome

**PLAN mode:** skip this step. **RECORD mode:** start from the hunt log's `Outcome Candidates` table, confirm each against the log's evidence, and add any the log missed.

Using `references/hunt-outcome-documenter.md`, pick the outcome category (or categories — a hunt can produce more than one) that matches what was found, and fill that category's documentation template exactly:

1. **Visibility Gap** — telemetry didn't generate or wasn't queryable
2. **Security Control Issue** — a control gap was discovered, independent of detection coverage
3. **Detection Opportunity** — the validated rule itself (attach the artifact from `detection-engineer`)
4. **Hunt Opportunity** — a new hypothesis surfaced during this hunt
5. **Suspicious Security Event** — something was actually found; this needs immediate escalation, not just documentation — say so explicitly and first
6. **Threat Intelligence Observable** — a new IOC/TTP worth feeding back into `intel-analysis`

**Mapping from hunt-planner's Task outcome categories**, if you're closing out placeholders created during planning:

| hunt-planner Task category | hunt-validator outcome category |
|---|---|
| Analytics/Detection | Detection Opportunity |
| New Hunt Idea | Hunt Opportunity |
| Security Incident | Suspicious Security Event — escalate immediately, see the category above |
| Visibility Gap | Visibility Gap (same name, no change) |
| Security Control Issue | Security Control Issue (same name, no change) |
| Written Report | No outcome category: the written report is the `hunt-reporter` artifact (`<slug>-hunt-report.md`) |

`Threat Intelligence Observable` has no hunt-planner equivalent — it's a new-during-validation finding, not a planning-time placeholder.

## Step 4: Write back to the detection artifact

**PLAN mode:** skip this step. **RECORD mode:** if `./threat-hunting/detections/<slug>-detection.md` does not exist (`detection-engineer` was skipped because the hunt produced no hit or candidate), skip the detection write-back and say so; do not create the detection file.

Read `./threat-hunting/detections/<slug>-detection.md` and update its section 9 (Validation) in place, replacing the `Not yet validated — see hunt-validator` placeholder with the actual Method/Result/Evidence from this run (the test procedure from Step 2, the Outcome line from the filled record, and a one-line summary of what it proved), plus a `Validation record: ./threat-hunting/validations/<slug>-validation.md` line so the reference points back the other direction too. This closes the loop detection-handoff-spec.md's Acceptance Gate requires — the detection artifact must never permanently read "not yet validated" once a validation has actually run.

**RECORD mode, hunt report:** also read `./threat-hunting/hunt-reports/<slug>-hunt-report.md` if it exists and replace the line `Pending hunt-validator` under its `## Validation` heading with the Method/Result/Evidence summary and a `Validation record: ./threat-hunting/validations/<slug>-validation.md` line. If the report does not exist, skip this write-back and say so.

## Step 5: Write the output

Write to `./threat-hunting/validations/<slug>-validation.md`:

```markdown
## Validation Record
Source detection: [DET-XXX from the detection artifact]
[The filled record template from Step 2.]

## Outcome Documentation
[One block per applicable category from Step 3, using that category's exact template from references/hunt-outcome-documenter.md.]
```

The `Source detection: DET-XXX` field and the section 9 update from Step 4 above mean the two files reference each other by ID in both directions.

**PLAN mode:** write the same file with `Source detection: None yet (PLAN mode)` when no detection exists (otherwise the DET-XXX ID), the Step 2 record with its `[PENDING EXECUTION]` result fields, and, under `## Outcome Documentation`, the single line `Not documented — hunt not yet executed (PLAN mode)`.

If Step 3 produced a **Suspicious Security Event**, do not wait for this file write to raise it — flag it to the user immediately, before finishing the rest of the write-up.
