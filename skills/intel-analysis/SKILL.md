---
name: intel-analysis
description: "Analyze cyber threat intelligence — a CTI report, CISA/vendor advisory, CVE, MITRE ATT&CK technique, threat actor, or pasted/uploaded material (PDF, Markdown, plain text) — and produce structured findings: actor profile, ATT&CK/TTP mapping, IOC extraction, and related-CVE correlation. Always trigger when a user shares a threat intel document, asks to analyze an APT group or campaign, references a CVE or advisory for intelligence purposes, asks what is known about a threat actor or technique, or wants intel enriched from web sources before hunting or reporting. This is Stage 1 of the threat-intel-hunt-framework pipeline — its output feeds the intel-report skill."
---

# Intel Analysis

Turn raw cyber threat intelligence — supplied or web-researched — into structured, sourced findings that downstream skills (`intel-report`, then `hunt-planner`) can build on.

## Step 0: Establish the subject and the slug

Identify the subject: an actor name, a CVE, a technique, an advisory, or the content of a supplied document. Derive a slug — kebab-case, ≤6 words, e.g. `volt-typhoon-living-off-the-land` or `cve-2026-41205`. If nothing supplied makes the subject obvious, ask the user for a one-line description rather than guessing.

## Step 1: Determine input mode

- **Supplied material** (pasted text, an uploaded PDF/Markdown file, a URL the user gave you): read it fully before dispatching research — every research angle needs this as shared context.
- **No material supplied, only a name/ID/technique**: research angles will need to find the material themselves via WebSearch/WebFetch against `references/high-reputation-sources.md`.
- **Both**: supplied material is the anchor; web research fills gaps and corroborates.

## Step 2: Dispatch parallel research

Dispatch exactly 4 `intel-researcher` subagents in parallel (one Task/Agent call per angle, sent together so they run concurrently, not sequentially). Give every subagent the same subject material/context plus exactly one angle:

1. Actor Profile
2. ATT&CK / TTP Mapping
3. IOC Extraction
4. Related CVE / Advisory Correlation

Each returns a Markdown fragment under its own `##` heading (see `agents/intel-researcher.md` for the exact format each returns).

## Step 3: Synthesize

Merge the four fragments into one document. Do not simply concatenate — resolve contradictions (if two angles disagree on attribution, say so explicitly under **Open Questions and Gaps** rather than picking one silently), and cross-check that IOCs found in Step 2 line up with the ATT&CK techniques found (an IOC with no technique it supports is still worth keeping, but flag it).

## Step 4: Write the output

Write to `./threat-hunting/intel-analysis/<slug>-analysis.md` in the invoking project (create the directory if it doesn't exist) with **exactly** these top-level sections, in this order:

```markdown
# Intel Analysis: <slug>

## Source Material
[What was supplied vs. what was researched. List URLs/files consulted.]

## Actor Profile
[From the Actor Profile research angle. If actor-agnostic, say so explicitly.]

## ATT&CK / TTP Mapping
| Technique ID | Technique Name | Tactic | Evidence |
|---|---|---|---|

## Indicators of Compromise (IOCs)
| Type | Value | Confidence | Source |
|---|---|---|---|

## Related CVEs / Advisories
| CVE/Advisory | Summary | Relevance |
|---|---|---|

## Source Reputation Notes
[Any `[UNVERIFIED SOURCE]`-flagged findings from the subagents, listed explicitly.]

## Open Questions and Gaps
[Contradictions between angles, unattributable claims, anything a human should sanity-check before this becomes a report.]
```

Report the file path back to the user (or, if invoked from `/run-hunt-pipeline`, to the orchestrating command) when done.

## When to ask vs. proceed

- **Ask first** when no subject is identifiable at all (empty/ambiguous request).
- **Proceed and annotate** whenever a subject exists, even a thin one (a bare CVE ID, a single sentence) — run the process, and let **Open Questions and Gaps** carry what's missing rather than blocking on it.
