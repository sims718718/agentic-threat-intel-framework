---
name: intel-analysis
description: "Analyze a threat actor, campaign, CVE, ATT&CK technique, advisory, or supplied CTI material into evidence-backed judgments, TTPs, and indicators. Use for intelligence assessment and enrichment before reporting or hunting. Stage 1 of the threat-intel-hunt-framework pipeline; feeds intel-report."
---

# Intel Analysis

Answer a decision-relevant intelligence question with traceable evidence and explicit uncertainty. Produce analysis, not a hunt execution result or a production detection.

## Step 0: Frame the question and slug

Identify the subject and reuse the pipeline slug, or derive one in kebab-case, at most 6 words. Ask only if no subject is identifiable. Otherwise proceed with documented assumptions.

State the intelligence question, intended decision/audience, scope, and collection cutoff. Convert relative periods into explicit start/end dates; distinguish event dates from publication dates. Older material may supply labeled background, not proof of activity within the requested window. Reuse `./threat-hunting/environment-profile.md` if available; missing environment details remain `Unknown`.

## Step 1: Collect and evaluate evidence

Read supplied material before research. For a bare subject, collect original reporting; for supplied material, corroborate and fill gaps. Consult [source guidance](references/high-reputation-sources.md). Curated membership is a discovery aid, not proof of a claim.

Give sources IDs and record URL/file locator, publisher, publication date, event period, original evidence origin, and access limitations. Link each material claim to a source and passage/section. Distinguish direct observations reported by a source, source assessments, and your inferences. Judge source access/reliability separately from the credibility of each claim. Reposts of one report count as one evidence origin.

Do not treat search snippets, inaccessible pages, or absent reporting as verified evidence. Preserve supplied sharing restrictions; do not submit sensitive source text to public searches.

## Step 2: Research four angles

Dispatch four `intel-researcher` agents in parallel, one per angle below. Supply the same question, dates, source material, and evidence requirements. If delegation is unavailable, research the four angles directly and disclose that limitation.

1. **Actor Profile:** attribution, alias scope, targeting, motivation, and campaign timeline. Distinguish publisher tracking clusters from established equivalence.
2. **ATT&CK / TTP Mapping:** procedure-level behavior and evidence; verify current IDs/names against MITRE. Use sub-techniques only where supported. Separate observed procedures from inferred mappings and historical actor capabilities.
3. **IOC Extraction:** exact source-backed values, type, provenance, context, first/last seen if reported, and operational limitations. Deduplicate without losing sources; separate artifacts such as generic paths from discriminating indicators. Never invent missing values.
4. **Related CVE / Advisory Correlation:** affected products, exploitation evidence, and explicit relationship to the subject. Separate exploitation by this actor/campaign from exploitation elsewhere and mere product overlap. KEV presence alone does not establish actor attribution.

Keep `Confirmed / Reported / Inferred` IOC labels for downstream compatibility: Confirmed requires direct technical evidence in an original source; Reported is a sourced assertion without that evidence; Inferred is an analytical association. These labels do not prove present maliciousness or authorize blocking.

## Step 3: Assess and challenge

Build a short event timeline and reconcile the four angles. Keep attribution disagreements explicit. For each material judgment, state the supporting evidence, reasoning, assumptions, counterevidence, confidence, and what would change it.

Test the strongest plausible alternative to each central explanation (including benign activity when applicable). Seek discriminating evidence; do not decide by counting citations. If evidence cannot distinguish alternatives, say so.

Use **High / Moderate / Low** confidence for judgments, justified by evidence quality, independence, and gaps; keep confidence distinct from likelihood. High requires strong direct or independently corroborated evidence with no material unresolved contradiction. Moderate has credible support with material limits. Low rests on sparse, indirect, or conflicting evidence. Do not assign numeric probabilities without a defensible basis.

Explain relevance to the known environment conditionally. Offer behavior + observable + likely telemetry as handoff seeds; never claim local compromise, visibility, or detection validation from external reporting alone.

## Step 4: Apply the quality gate

Score the draft with [analysis rubric](references/analysis-rubric.md). Revise analytical defects before delivery. Evidence that remains unavailable must lower confidence or narrow the judgment, not be fabricated to pass.

Record scores with evidence and one status: **READY** (all criteria met), **LIMITED** (usable but explicit collection gaps remain), or **INSUFFICIENT** (the central question cannot be answered). Always write the artifact and return its status to the pipeline; a completed analysis stage is not proof of a supported conclusion.

## Step 5: Write and hand off

Write `./threat-hunting/intel-analysis/<slug>-analysis.md` in the invoking project. Preserve these top-level sections and order for downstream compatibility; use subsections for the new analytical content:

```markdown
# Intel Analysis: <slug>

## Source Material
### Scope and Intelligence Question
[Decision, audience, date window, cutoff, assumptions, environment relevance.]
### Evidence Register
| Source ID | URL/file and locator | Publisher | Published | Event period | Evidence origin and limitations |
|---|---|---|---|---|---|

## Actor Profile
[Profile and timeline; actor-agnostic where appropriate.]
### Key Judgments
| Judgment | Evidence IDs and reasoning | Confidence and basis | Alternative/counterevidence | What would change it |
|---|---|---|---|---|
### Operational Implications
[Conditional relevance and prioritized behavior/observable/telemetry seeds.]

## ATT&CK / TTP Mapping
| Technique ID | Technique Name | Tactic | Evidence |
|---|---|---|---|
[Evidence includes source locator, procedure, event period, and observed/inferred status.]

## Indicators of Compromise (IOCs)
| Type | Value | Confidence | Source |
|---|---|---|---|
[For each row, include source ID, context, reported first/last seen or Unknown, and shared-infrastructure/staleness limitations. No findings is valid.]

## Related CVEs / Advisories
| CVE/Advisory | Summary | Relevance |
|---|---|---|
[Include source IDs, exploitation status, and strength of subject linkage.]

## Source Reputation Notes
[Source reliability versus claim credibility; dependent reporting and unverified findings.]

## Open Questions and Gaps
[Unresolved contradictions and unanswered questions; prioritize collection needed to resolve them.]
### Quality Gate
[Dimension scores with reasons, total, READY/LIMITED/INSUFFICIENT, and remaining limitations.]
```

Return the path, gate status, and material gaps. Hand off to `intel-report`; preserve uncertainty and provenance.