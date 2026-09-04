---
name: hunt-validator
description: "Prove a detection actually fires before it ships, and document the hunt's final typed outcome (visibility gap, security control issue, detection opportunity, hunt opportunity, suspicious security event, or threat intelligence observable). Always trigger when a user asks to validate a detection, test whether telemetry generates for a technique, run an atomic test against a hunt finding, or close out and document a completed hunt. This is Stage 5 (final) of the threat-intel-hunt-framework pipeline — it reads the detection-engineer skill's output."
---

# Hunt Validator

A hunt that finds nothing is only meaningful if you've demonstrated you *would* have seen it. This skill proves the telemetry and logic fire, then documents the hunt's outcome by category so it's trackable and reportable.

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

## Step 2: Run the validation procedure

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
| Written Report | No direct equivalent — the written report is this file plus the hunt plan; there's no separate outcome category for it here |

`Threat Intelligence Observable` has no hunt-planner equivalent — it's a new-during-validation finding, not a planning-time placeholder.

## Step 4: Write back to the detection artifact

Read `./threat-hunting/detections/<slug>-detection.md` and update its section 9 (Validation) in place, replacing the `Not yet validated — see hunt-validator` placeholder with the actual Method/Result/Evidence from this run (the test procedure from Step 2, the Outcome line from the filled record, and a one-line summary of what it proved), plus a `Validation record: ./threat-hunting/validations/<slug>-validation.md` line so the reference points back the other direction too. This closes the loop detection-handoff-spec.md's Acceptance Gate requires — the detection artifact must never permanently read "not yet validated" once a validation has actually run.

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

If Step 3 produced a **Suspicious Security Event**, do not wait for this file write to raise it — flag it to the user immediately, before finishing the rest of the write-up.
