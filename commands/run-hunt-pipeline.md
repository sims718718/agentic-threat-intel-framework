---
description: Run the full intel-to-detection threat hunting pipeline end-to-end — intel analysis, intel report, hunt plan, detection, and validation — without pausing between stages.
---

Run all five stages of the threat-intel-hunt-framework pipeline against the input the user provided with this command (a CTI report file, a URL, pasted text, a CVE ID, an actor name, a MITRE technique, or a rough idea). Do not pause for user confirmation between stages — run straight through. The user reviews the output files afterward, at their own pace.

## Sequence

1. **Derive the slug.** kebab-case, ≤6 words, from the input's primary subject (see any skill's Step 0 for the exact rule). Use this same slug for every file below.
2. **Invoke the `intel-analysis` skill** with the user's input. Wait for it to write `./threat-hunting/intel-analysis/<slug>-analysis.md`.
3. **Invoke the `intel-report` skill.** It will find and read the file from step 2 automatically. Wait for `./threat-hunting/intel-reports/<slug>-report.md`.
4. **Invoke the `hunt-planner` skill.** It will find and read the file from step 3 automatically. Wait for `./threat-hunting/hunt-plans/<slug>-hunt-plan.md`.
5. **Invoke the `detection-engineer` skill.** It will find and read the file from step 4 automatically. Wait for `./threat-hunting/detections/<slug>-detection.md`.
6. **Invoke the `hunt-validator` skill.** It will find and read the file from step 5 automatically. Wait for `./threat-hunting/validations/<slug>-validation.md`.

## If a stage can't produce a clean result

Every skill in this pipeline is designed to proceed and annotate gaps (`[FILL IN: ...]`, `Unknown`, `[PENDING EXECUTION]`) rather than block. Let that behavior carry through here too — do not stop the pipeline because one stage's output has caveats. The one exception is `hunt-validator` surfacing a **Suspicious Security Event**: if that happens, interrupt the summary in step 7 below and flag it first.

## Step 7: Final summary

After all five stages complete, print a summary listing all five file paths (even any that only partially completed) so the user can review them:

```
Pipeline complete for <slug>:
1. Intel Analysis:   ./threat-hunting/intel-analysis/<slug>-analysis.md
2. Intel Report:     ./threat-hunting/intel-reports/<slug>-report.md
3. Hunt Plan:        ./threat-hunting/hunt-plans/<slug>-hunt-plan.md
4. Detection:        ./threat-hunting/detections/<slug>-detection.md
5. Validation:       ./threat-hunting/validations/<slug>-validation.md
```
