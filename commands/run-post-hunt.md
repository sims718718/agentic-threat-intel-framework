---
description: Run the post-execution half of the pipeline after a human has run the hunt — record the results, build the detection, write the hunt report, and record validation. Requires hunt results.
argument-hint: "[slug] [path to filled hunt log or results file, or pasted results]"
---

Run the post-hunt stages of the threat-intel-hunt-framework against the hunt results in `$ARGUMENTS` (a slug, plus a path to the filled hunt log or a results file, or pasted results). The hunt itself is manual: this command never runs queries or attack simulations, and it never invents results.

## Sequence

1. **Resolve the slug.** Use the slug in `$ARGUMENTS` if given; otherwise use the most recent plan under `./threat-hunting/hunt-plans/`. Ask only if more than one candidate exists.
2. **Results gate.** If `$ARGUMENTS` supplies no results and the hunt log does not hold results (as defined in `hunt-execution` Step 0: `Results status` is `RECORDED` or `PARTIAL`, or the worksheet was filled in place), stop and write nothing. If the log itself holds results and `$ARGUMENTS` supplies none, the log is the input. Tell the user to run the hunt, record the results in the hunt log or provide them here, and re-run. This is the one deliberate stop in the framework's commands.
3. **Invoke the `hunt-execution` skill in INTAKE mode.** Tell it explicitly that it is running from `/run-post-hunt`, so it must not ask follow-up questions (it marks missing fields `Not provided`). Wait for the updated hunt log. If it reports a true-positive or `Undetermined` hit, tell the user immediately, before continuing, that this is a potential Suspicious Security Event to escalate to SOC / IR. If it leaves `Results status` as `PENDING EXECUTION` (no results were recognised), stop and write nothing further: tell the user to map the results to Story IDs and re-run.
4. **Invoke the `detection-engineer` skill only if** the hunt log's Outcome Candidates include Detection Opportunity or any hit exists. Otherwise skip it and state the reason in the summary. Wait for `./threat-hunting/detections/<slug>-detection.md`.
5. **Invoke the `hunt-reporter` skill.** Wait for `./threat-hunting/hunt-reports/<slug>-hunt-report.md` and its `.html` twin.
6. **Invoke the `hunt-validator` skill.** With recorded results it runs in RECORD mode: it documents typed outcomes, and writes its result back into the detection (if one exists) and the hunt report. Validation test fields stay `[PENDING EXECUTION]` unless the user also supplied test results.

7. **Quality checks (advisory).** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-contracts.sh" <slug> post ./threat-hunting` and keep its output verbatim. The linter exits with status 1 when any check FAILed; that is a normal result, not a script failure, so record its output rather than `SKIP`. If `./threat-hunting/detections/<slug>-detection.md` exists, dispatch the `detection-reviewer` agent with the slug and the project directory; otherwise record `SKIP no detection` under its heading and say so in the summary. If the agent type is not registered in the session, do not dispatch a substitute agent: read its file under `${CLAUDE_PLUGIN_ROOT}/agents/` and perform that review yourself, inline, reading only (the quality file is the only file you write), mark the heading `[inline fallback]`, and say in the summary that the review was not independent. Write `./threat-hunting/quality/<slug>-quality.md`: create it with a `# Quality Checks: <slug>` title if absent, then add or replace only the `## Post stage` section, laid out as `Run: <date>`, `### Contract checks` (the linter output), and `### detection-reviewer`. Leave a `## Plan stage` section untouched. If the script cannot run or the agent cannot be run at all, write `SKIP <reason>` under that heading and continue. A quality-check failure never fails the command, never edits another artifact, and adds no confirmation gate. If the agent returns free text instead of a table, paste it under its heading marked `[unstructured]`.

## Partial results and re-runs

If only some Stories were run, the unrun Stories are `Not executed`, the hunt-level verdict is Inconclusive, and the later stages still run. Re-running updates the hunt log in place and regenerates the report.

## Final summary

Print the file paths, the hunt-level verdict and coverage status, any escalation, whether `detection-engineer` ran (and why not if skipped), and what remains pending (for example, the validation test):

```
Post-hunt complete for <slug>:
Hunt Log:     ./threat-hunting/hunt-logs/<slug>-hunt-log.md        (verdict: <verdict>; coverage: <status>)
Detection:    ./threat-hunting/detections/<slug>-detection.md      (or: skipped — <reason>)
Hunt Report:  ./threat-hunting/hunt-reports/<slug>-hunt-report.md
Validation:   ./threat-hunting/validations/<slug>-validation.md
Quality:      <pass> pass, <warn> warn, <fail> fail, <skip> skip; High findings: detection-reviewer <n or skipped>; details ./threat-hunting/quality/<slug>-quality.md
Pending:      <for example, the validation test has not been run>
```
