---
description: Run the planning half of the intel-to-hunt pipeline end-to-end — environment gather, intel analysis, intel report, hunt plan, hunt worksheet, and validation plan — without pausing between stages. After you execute the hunt, run /run-post-hunt.
argument-hint: "[CTI report path, URL, CVE ID, actor name, or technique]"
allowed-tools: Bash(bash *check-contracts.sh*)
---

Run the planning stages of the threat-intel-hunt-framework pipeline against `$ARGUMENTS` (a CTI report file, a URL, pasted text, a CVE ID, an actor name, a MITRE technique, or a rough idea). Do not pause for user confirmation between stages — run straight through. The user reviews the output files afterward, at their own pace. This command stops at a plan: the hunt itself is run by a human, and detection, hunt report, and recorded validation are produced by `/run-post-hunt` once results exist.

## Sequence

1. **Invoke the `gather` skill in pipeline mode.** Tell it explicitly that it is running as Step 1 of `/run-hunt-pipeline`. If `./threat-hunting/environment-profile.md` already exists, it will reuse it as-is. If not, it must infer what it can from `$ARGUMENTS` and the conversation so far, write `Unknown` for anything else, and never pause to ask the user anything. Wait for it to confirm `./threat-hunting/environment-profile.md` is in place before continuing.
2. **Derive the slug.** kebab-case, ≤6 words, from the input's primary subject (see intel-analysis's Step 0 for the exact rule). Use this same slug for every file below.
3. **Invoke the `intel-analysis` skill** with the user's input. Wait for it to write `./threat-hunting/intel-analysis/<slug>-analysis.md`.
4. **Invoke the `intel-report` skill.** It will find and read the file from step 3 automatically. Wait for `./threat-hunting/intel-reports/<slug>-report.md`.
5. **Invoke the `hunt-planner` skill.** It will find and read the environment profile from step 1 and the report from step 4 automatically. Wait for `./threat-hunting/hunt-plans/<slug>-hunt-plan.md`. If the hunt log already holds results, `hunt-planner` writes nothing and reports that the plan is locked; carry on to step 6.
6. **Invoke the `hunt-execution` skill in WORKSHEET mode.** It reads the plan and writes the blank hunt log `./threat-hunting/hunt-logs/<slug>-hunt-log.md`. If the log already holds results (recorded, or filled in by hand), it leaves it untouched; that is expected on a re-run.
7. **Invoke the `hunt-validator` skill.** With no recorded hunt results it runs in PLAN mode and writes `./threat-hunting/validations/<slug>-validation.md` with the test selection and `[PENDING EXECUTION]` fields. **Skip step 7** (write nothing, and say so) when the hunt log already holds results: a planning re-run must never touch a recorded validation.

8. **Quality checks (advisory).** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-contracts.sh" <slug> plan ./threat-hunting` and keep its output verbatim. Then dispatch the `intel-challenger` and `plan-reviewer` agents in parallel, giving each the slug and the project directory; each returns a findings table or `No findings`. If an agent type is not registered in the session, read its file under `${CLAUDE_PLUGIN_ROOT}/agents/` and run a `general-purpose` agent with that file's instructions, read-only, and mark the heading `[general-purpose fallback]`. Write `./threat-hunting/quality/<slug>-quality.md`: create it with a `# Quality Checks: <slug>` title if absent, then add or replace only the `## Plan stage` section, laid out as `Run: <date>`, `### Contract checks` (the linter output), `### intel-challenger`, and `### plan-reviewer`. Leave a `## Post stage` section untouched. If the script cannot run or an agent cannot be run at all, write `SKIP <reason>` under that heading and continue. Agents advise; the skills' own gates decide. A quality-check failure never fails the command, never edits another artifact, and adds no confirmation gate. If an agent returns free text instead of a table, paste it under its heading marked `[unstructured]`.

## If a stage can't produce a clean result

Every skill in this pipeline is designed to proceed and annotate gaps (`[FILL IN: ...]`, `Unknown`, `[PENDING EXECUTION]`) rather than block. Let that behavior carry through here too — do not stop the pipeline because one stage's output has caveats. This includes `gather`'s pipeline mode, which marks uninferrable environment fields `Unknown` rather than asking.

## Step 9: Final summary

After all stages complete, print a summary listing every file path (even any that only partially completed) so the user can review them. If `gather` left any environment fields as `Unknown`, call that out explicitly and remind the user they can run `gather` standalone at any time to fill them in. If `hunt-planner` reported the plan locked, or the hunt log already holds results, say so in the summary: label the hunt log as holding results instead of "(blank)", and note that the refreshed analysis and report are not reflected in the locked plan. Otherwise, tell the user that the hunt must now be run manually and that `/run-post-hunt` produces the detection, hunt report, and recorded validation:

```
Planning complete for <slug>:
0. Environment Profile: ./threat-hunting/environment-profile.md
1. Intel Analysis:   ./threat-hunting/intel-analysis/<slug>-analysis.md
2. Intel Report:     ./threat-hunting/intel-reports/<slug>-report.md
3. Hunt Plan:        ./threat-hunting/hunt-plans/<slug>-hunt-plan.md
4. Hunt Log (blank): ./threat-hunting/hunt-logs/<slug>-hunt-log.md
5. Validation Plan:  ./threat-hunting/validations/<slug>-validation.md
Quality:      <pass> pass, <warn> warn, <fail> fail, <skip> skip; High findings: intel-challenger <n>, plan-reviewer <n>; details ./threat-hunting/quality/<slug>-quality.md

Next: run the hunt in your own tools, record the results in the hunt log (or keep notes),
then run /run-post-hunt <slug> [path to results, or paste them].
```
