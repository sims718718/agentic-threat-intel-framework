---
name: intel-report
description: "Turn structured intel-analysis findings (or, if none exist yet, raw threat intel supplied directly) into a decision-ready actionable intel report: executive summary, key judgments, ATT&CK coverage, IOCs, and recommended hunt/detect/mitigate actions. Always trigger when a user asks for an intel report, a threat brief, an executive summary of a threat, or asks 'what should we do about X' after intel has been gathered. This is Stage 2 of the threat-intel-hunt-framework pipeline — it reads intel-analysis's output and its own output feeds the hunt-planner skill."
---

# Intel Report

Turn analysis findings into a report a decision-maker can act on without reading the raw research.

## Step 1: Locate or gather the analysis

If invoked standalone (not via `/run-hunt-pipeline`) and the slug isn't already established from context, look for the most recent matching file under `./threat-hunting/intel-analysis/*.md` and use its slug; if more than one candidate exists, ask the user which one.

Look for `./threat-hunting/intel-analysis/<slug>-analysis.md` in the invoking project. If it exists, read it — this is your primary input. If it doesn't exist (the user jumped straight to this skill), either run the `intel-analysis` skill's process yourself first, or, if the user has already supplied enough raw material directly, work from that — note in **Confidence and Sourcing** that the formal analysis stage was skipped.

## Step 2: Write the report

Write to `./threat-hunting/intel-reports/<slug>-report.md` (same slug as the analysis file) with **exactly** these top-level sections, in this order:

```markdown
# Actionable Intel Report: <Title>

## Executive Summary
[3-5 sentences. What is this, why does it matter to us, what should happen next. No jargon — this section should be readable by someone who never sees the raw analysis.]

## Key Judgments
[The 3-6 highest-confidence conclusions, each one sentence, each labeled with a confidence level: High / Moderate / Low.]

## Actor / Campaign Overview
[From the analysis's Actor Profile section, condensed to what's decision-relevant.]

## MITRE ATT&CK Coverage
| Technique ID | Technique Name | Tactic | Do we have visibility? |
|---|---|---|---|
[Carry the technique table from the analysis forward. The "visibility" column is new here — answer it if the user has stated their environment/data sources anywhere in the conversation, otherwise mark `Unknown — see hunt-planner Step 0`.]

## Indicators of Compromise
[Carry the IOC table forward, Confirmed/Reported only — drop Inferred-confidence IOCs from the report unless the user asks for full detail, since low-confidence IOCs in a decision document tend to get actioned uncritically.]

## Recommended Actions

### Hunt
[1-3 SMART-shaped hypothesis seeds — not full hypotheses, that's hunt-planner's job, but concrete enough that hunt-planner doesn't have to re-derive them from scratch. One sentence each: "Hunt for [behavior] evidenced by [observable] in [likely data source]."]

### Detect
[Which of the mapped techniques are strong candidates for a standing detection vs. which need a hunt first because they're too broad/noisy as stated.]

### Mitigate
[Any patch, config, or control changes implied directly by the intel — e.g. a specific CVE with a patch available. Pull from the analysis's `## Related CVEs / Advisories` table when relevant — a CVE with a patch is usually a Mitigate item, not just a Detect one. Leave empty with "None identified" if the intel is purely behavioral.]

## Confidence and Sourcing
[Overall confidence in this report and why. Explicitly note if the intel-analysis stage was skipped (see Step 1). Carry forward the analysis's `## Open Questions and Gaps` explicitly here — a decision-maker reading only this report still needs to know what's unresolved.]

## Appendix: Full Source List
[Every source cited in the analysis, carried forward verbatim.]
```

## Step 3: Render the HTML twin

After writing the Markdown file, also render a styled, self-contained HTML sibling at `./threat-hunting/intel-reports/<slug>-report.html`, following `../_shared/references/html-report-shell.md`'s shell and translation rules exactly. The Markdown file stays the source of truth; the HTML is a rendering of the same content, produced in the same turn.

## When to ask vs. proceed

- **Ask first** when the analysis file is missing AND the user hasn't supplied enough raw material to write a report without fabricating findings.
- **Proceed and annotate** otherwise — mark unknowns explicitly (`Unknown`, `Not assessed`) rather than blocking.
