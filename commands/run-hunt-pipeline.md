---
description: Run the full intel-to-detection threat hunting pipeline end-to-end — environment gather, intel analysis, intel report, hunt plan, detection, and validation — without pausing between stages.
argument-hint: "[CTI report path, URL, CVE ID, actor name, or technique]"
---

Run all six stages of the threat-intel-hunt-framework pipeline against `$ARGUMENTS` (a CTI report file, a URL, pasted text, a CVE ID, an actor name, a MITRE technique, or a rough idea). Do not pause for user confirmation between stages — run straight through. The user reviews the output files afterward, at their own pace.

## Sequence

1. **Invoke the `gather` skill in pipeline mode.** Tell it explicitly that it is running as Step 1 of `/run-hunt-pipeline`. If `./threat-hunting/environment-profile.md` already exists, it will reuse it as-is. If not, it must infer what it can from `$ARGUMENTS` and the conversation so far, write `Unknown` for anything else, and never pause to ask the user anything. Wait for it to confirm `./threat-hunting/environment-profile.md` is in place before continuing.
2. **Derive the slug.** kebab-case, ≤6 words, from the input's primary subject (see intel-analysis's Step 0 for the exact rule). Use this same slug for every file below.
3. **Invoke the `intel-analysis` skill** with the user's input. Wait for it to write `./threat-hunting/intel-analysis/<slug>-analysis.md`.
4. **Invoke the `intel-report` skill.** It will find and read the file from step 3 automatically. Wait for `./threat-hunting/intel-reports/<slug>-report.md`.
5. **Invoke the `hunt-planner` skill.** It will find and read the environment profile from step 1 and the report from step 4 automatically. Wait for `./threat-hunting/hunt-plans/<slug>-hunt-plan.md`.
6. **Invoke the `detection-engineer` skill.** It will find and read the file from step 5 automatically. Wait for `./threat-hunting/detections/<slug>-detection.md`.
7. **Invoke the `hunt-validator` skill.** It will find and read the file from step 6 automatically. Wait for `./threat-hunting/validations/<slug>-validation.md`.

## If a stage can't produce a clean result

Every skill in this pipeline is designed to proceed and annotate gaps (`[FILL IN: ...]`, `Unknown`, `[PENDING EXECUTION]`) rather than block. Let that behavior carry through here too — do not stop the pipeline because one stage's output has caveats. This includes `gather`'s pipeline mode, which marks uninferrable environment fields `Unknown` rather than asking. The one exception is `hunt-validator` surfacing a **Suspicious Security Event**: if that happens, interrupt the summary in step 8 below and flag it first.

## Step 8: Final summary

After all six stages complete, print a summary listing all six file paths (even any that only partially completed) so the user can review them. If `gather` left any environment fields as `Unknown`, call that out explicitly and remind the user they can run `gather` standalone at any time to fill them in:

```
Pipeline complete for <slug>:
0. Environment Profile: ./threat-hunting/environment-profile.md
1. Intel Analysis:   ./threat-hunting/intel-analysis/<slug>-analysis.md
2. Intel Report:     ./threat-hunting/intel-reports/<slug>-report.md
3. Hunt Plan:        ./threat-hunting/hunt-plans/<slug>-hunt-plan.md
4. Detection:        ./threat-hunting/detections/<slug>-detection.md
5. Validation:       ./threat-hunting/validations/<slug>-validation.md
```
