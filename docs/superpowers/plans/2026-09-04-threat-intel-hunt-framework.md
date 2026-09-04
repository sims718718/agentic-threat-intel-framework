# Threat Intel Hunt Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `threat-intel-hunt-framework`, a self-contained Claude Code plugin that runs a five-stage agentic pipeline — intel analysis → actionable intel report → hunt plan → detection engineering → validation — grounded in the Unified Threat Hunting Process.

**Architecture:** A Claude Code plugin (`.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` for local install) with five independently-triggerable skills, one subagent type for parallel intel research, and one master slash command that chains all five skills end-to-end without pausing. Every skill writes Markdown artifacts to a fixed `./threat-hunting/<stage>/` convention in whatever project the plugin is invoked from. No hooks, no custom MCP tools — built-in tools only (Read/Write/WebSearch/WebFetch/Task).

**Tech Stack:** Markdown (SKILL.md / command / agent files with YAML frontmatter), JSON (plugin manifests), Bash (one shared frontmatter validator script). No compiled code.

**Spec:** Captured inline below in **Spec Summary** — synthesized from an interactive grilling session on 2026-09-04 (16 questions, all answered). No separate spec file exists; this plan is the spec's only recorded form.

## Spec Summary

- **Deliverable:** Proper Claude Code plugin (skills + commands + agents; no hooks).
- **Location:** New, separate repo at `D:\threat-intel-hunt-framework` (already created, empty, not yet git-initialized).
- **Relationship to `UnifiedThreatHunting`:** Fully self-contained — methodology ported/adapted from that repo (`D:\UnifiedThreatHunting`) into this plugin's own reference docs; no runtime dependency on the source repo.
- **Relationship to the existing `Threat_Hunt_Planner_Skill`:** Absorbed and refactored into the `hunt-planner` skill below; not left standalone.
- **Scope:** Full five-stage pipeline built in one pass (not phased).
- **Intel input:** Hybrid — user-supplied material (PDF, Markdown, pasted text) plus agent-driven WebSearch/WebFetch against a static curated source list when material isn't supplied.
- **Subagents:** Used only in the `intel-analysis` stage (parallel fan-out across 4 research angles via the `intel-researcher` agent type). All other stages are single sequential skills.
- **Orchestration:** One master command (`/run-hunt-pipeline`) runs all five stages straight through — no pause/confirmation gates. Output files are reviewed by a human afterward, whenever they choose.
- **Hooks:** None in v1.
- **Tools:** No custom MCP integrations in v1 — WebSearch/WebFetch only.
- **Output convention:** Fixed `./threat-hunting/<stage>/<slug>-<stage>.md` in the calling project, Markdown throughout.
- **Distribution:** Local-dev-only — a minimal single-plugin `marketplace.json` is still required for the `claude plugin marketplace add` / `claude plugin install` local-install mechanism (confirmed by inspecting this machine's installed plugins — every plugin, even single-author ones like `andrej-karpathy-skills`, is registered through a marketplace.json), but no public-distribution polish (no changelog, no CI, no versioning strategy beyond `0.1.0`).

## Global Constraints

- Every skill/command/agent frontmatter file must pass `scripts/validate-frontmatter.sh` before its task is considered done.
- Skill `description` frontmatter is a single physical line (however long), written to maximize trigger-matching accuracy — matches the convention observed in every installed plugin on this machine.
- All five pipeline output docs live under `./threat-hunting/` in the *invoking* project, never inside this plugin repo.
- No hooks, no `.mcp.json`, no live SIEM/API integrations in v1.
- Repo must have zero runtime dependency on `D:\UnifiedThreatHunting` — every ported reference file is a physical copy adapted in place.
- `git commit` at the end of every task.

---

## File Structure

```
threat-intel-hunt-framework/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── scripts/
│   └── validate-frontmatter.sh
├── skills/
│   ├── intel-analysis/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── high-reputation-sources.md
│   ├── intel-report/
│   │   └── SKILL.md
│   ├── hunt-planner/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── hypothesis-templates.md
│   │       ├── hypothesis-rubric.md
│   │       ├── feasibility-checklist.md
│   │       ├── telemetry-gap-assessment.md
│   │       ├── jira-templates.md
│   │       ├── data-source-explorer.md
│   │       ├── domain-telemetry-matrix.md
│   │       └── hunt-maturity-model.md
│   ├── detection-engineer/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── sigma-rule-builder.md
│   │       └── detection-handoff-spec.md
│   └── hunt-validator/
│       ├── SKILL.md
│       └── references/
│           ├── validation-hook.md
│           └── hunt-outcome-documenter.md
├── agents/
│   └── intel-researcher.md
├── commands/
│   └── run-hunt-pipeline.md
└── README.md
```

**Responsibility per file:**
- `plugin.json` / `marketplace.json` — plugin manifest and local-install registration.
- `scripts/validate-frontmatter.sh` — shared verification tool used by every task below.
- `skills/intel-analysis` — Stage 1: turns raw CTI (supplied or web-researched) into structured findings.
- `skills/intel-report` — Stage 2: turns those findings into a decision-ready report.
- `skills/hunt-planner` — Stage 3: turns the report (or any trigger) into a SMART hypothesis, feasibility gate, and Jira-structured hunt plan. Absorbs the existing `Threat_Hunt_Planner_Skill`.
- `skills/detection-engineer` — Stage 4: turns a hunt finding into an ADS-lite detection handoff artifact (Sigma + platform translation).
- `skills/hunt-validator` — Stage 5: proves the detection fires, documents the typed outcome.
- `agents/intel-researcher.md` — subagent type dispatched (4x, in parallel) by `intel-analysis`.
- `commands/run-hunt-pipeline.md` — chains all five stages end-to-end.

---

## Pipeline Output Interfaces (canonical — every task below must match these exactly)

All paths are relative to the project the plugin is invoked from, not this repo.

| Stage | Writes to | Required top-level sections (exact headings) |
|---|---|---|
| intel-analysis | `./threat-hunting/intel-analysis/<slug>-analysis.md` | `# Intel Analysis: <slug>`, `## Source Material`, `## Actor Profile`, `## ATT&CK / TTP Mapping`, `## Indicators of Compromise (IOCs)`, `## Related CVEs / Advisories`, `## Source Reputation Notes`, `## Open Questions and Gaps` |
| intel-report | `./threat-hunting/intel-reports/<slug>-report.md` | `# Actionable Intel Report: <Title>`, `## Executive Summary`, `## Key Judgments`, `## Actor / Campaign Overview`, `## MITRE ATT&CK Coverage`, `## Indicators of Compromise`, `## Recommended Actions` (with `### Hunt`, `### Detect`, `### Mitigate`), `## Confidence and Sourcing`, `## Appendix: Full Source List` |
| hunt-planner | `./threat-hunting/hunt-plans/<slug>-hunt-plan.md` | `## Environment Profile`, `## Epic: [HUNT-XXX] ...` (with the Epic/Story/Task sub-structure defined in Task 4 below) |
| detection-engineer | `./threat-hunting/detections/<slug>-detection.md` | `## DET-XXX — [Title]` with the 10 numbered sections from `detection-handoff-spec.md` |
| hunt-validator | `./threat-hunting/validations/<slug>-validation.md` | `## Validation Record`, `## Outcome Documentation` (category block per `hunt-outcome-documenter.md`) |

**Slug rule** (defined once here; every skill and the master command restates it briefly): kebab-case, ≤6 words, derived from the input's primary subject — a named actor + technique (`volt-typhoon-living-off-the-land`), a lowercased CVE ID (`cve-2026-41205`), or the first few significant words of a technique/behavior description. If a skill is invoked standalone with no obvious subject, ask the user for a one-line label instead of guessing.

---

### Task 1: Repo scaffold, manifests, and the shared validator

**Files:**
- Create: `D:\threat-intel-hunt-framework\.claude-plugin\plugin.json`
- Create: `D:\threat-intel-hunt-framework\.claude-plugin\marketplace.json`
- Create: `D:\threat-intel-hunt-framework\scripts\validate-frontmatter.sh`
- Create: `D:\threat-intel-hunt-framework\.gitignore` (empty placeholder not needed — skip; no build artifacts exist in this repo)

**Interfaces:**
- Produces: `scripts/validate-frontmatter.sh <file> <field1> [field2 ...]` — exits 0 and prints `OK: <field>=<value>` per field if every named frontmatter field is present and non-empty; exits 1 and prints `FAIL: <file> missing '<field>:' in frontmatter` (or `FAIL: <file> does not exist`) otherwise. Every later task's "verify" steps call this exact script with this exact argument order.
- Produces: `plugin.json`'s `skills` array — the list every later skill-creation task must append itself to.

- [ ] **Step 1: Initialize the repo**

```bash
cd "D:/threat-intel-hunt-framework"
git init
mkdir -p .claude-plugin scripts skills agents commands
```

- [ ] **Step 2: Write the shared frontmatter validator**

Create `scripts/validate-frontmatter.sh`:

```bash
#!/usr/bin/env bash
# Validates that a Markdown file's YAML frontmatter contains the given
# fields, non-empty. Usage: validate-frontmatter.sh <file> <field1> [field2 ...]
set -euo pipefail

FILE="$1"
shift

if [ ! -f "$FILE" ]; then
  echo "FAIL: $FILE does not exist"
  exit 1
fi

STATUS=0
for FIELD in "$@"; do
  VALUE=$(sed -n "s/^${FIELD}: *//p" "$FILE" | head -1)
  if [ -z "$VALUE" ]; then
    echo "FAIL: $FILE missing '${FIELD}:' in frontmatter"
    STATUS=1
  else
    echo "OK: ${FIELD}=${VALUE}"
  fi
done
exit $STATUS
```

- [ ] **Step 3: Prove the validator fails on a missing file**

Run: `bash scripts/validate-frontmatter.sh does-not-exist.md name description`
Expected: `FAIL: does-not-exist.md does not exist`, exit code 1

- [ ] **Step 4: Prove the validator fails on missing fields, then passes**

```bash
mkdir -p /tmp/fmtest
printf -- '---\nname: sample\n---\nbody\n' > /tmp/fmtest/sample.md
bash scripts/validate-frontmatter.sh /tmp/fmtest/sample.md name description
```

Expected: `OK: name=sample` then `FAIL: /tmp/fmtest/sample.md missing 'description:' in frontmatter`, exit code 1.

```bash
printf -- '---\nname: sample\ndescription: a test file\n---\nbody\n' > /tmp/fmtest/sample.md
bash scripts/validate-frontmatter.sh /tmp/fmtest/sample.md name description
rm -rf /tmp/fmtest
```

Expected: `OK: name=sample`, `OK: description=a test file`, exit code 0.

- [ ] **Step 5: Write the plugin manifest**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "threat-intel-hunt-framework",
  "version": "0.1.0",
  "description": "Agentic pipeline for intel-driven threat hunting and detection engineering: analyze CTI, produce an actionable intel report, build a hunt plan, author a detection, and validate it — grounded in the Unified Threat Hunting Process.",
  "author": {
    "name": "sims718718"
  },
  "license": "MIT",
  "keywords": [
    "threat-hunting",
    "threat-intelligence",
    "detection-engineering",
    "mitre-attack",
    "security"
  ],
  "skills": [
    "./skills/intel-analysis",
    "./skills/intel-report",
    "./skills/hunt-planner",
    "./skills/detection-engineer",
    "./skills/hunt-validator"
  ]
}
```

- [ ] **Step 6: Write the local marketplace manifest**

Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "threat-intel-hunt-framework",
  "id": "threat-intel-hunt-framework",
  "owner": {
    "name": "sims718718"
  },
  "metadata": {
    "description": "Local marketplace for the threat-intel-hunt-framework plugin — intel analysis, hunt planning, and detection engineering as a Claude Code plugin.",
    "version": "0.1.0"
  },
  "plugins": [
    {
      "name": "threat-intel-hunt-framework",
      "source": "./",
      "description": "Agentic pipeline for intel-driven threat hunting and detection engineering, grounded in the Unified Threat Hunting Process.",
      "version": "0.1.0",
      "author": {
        "name": "sims718718"
      },
      "keywords": ["threat-hunting", "threat-intelligence", "detection-engineering"],
      "category": "workflow"
    }
  ]
}
```

- [ ] **Step 7: Validate both manifests are well-formed JSON**

Run: `python -c "import json; json.load(open('.claude-plugin/plugin.json')); json.load(open('.claude-plugin/marketplace.json')); print('OK')"`
Expected: `OK`

- [ ] **Step 8: Commit**

```bash
git add .claude-plugin scripts
git commit -m "chore: scaffold plugin manifests and shared frontmatter validator"
```

---

### Task 2: `intel-analysis` skill + `intel-researcher` subagent

**Files:**
- Create: `skills/intel-analysis/SKILL.md`
- Create: `skills/intel-analysis/references/high-reputation-sources.md`
- Create: `agents/intel-researcher.md`

**Interfaces:**
- Consumes: nothing from earlier tasks (this is Stage 1).
- Produces: `./threat-hunting/intel-analysis/<slug>-analysis.md` matching the exact section headings in the **Pipeline Output Interfaces** table above. This is what Task 3 (`intel-report`) reads.
- Produces: the `intel-researcher` agent type, invoked by name via the Task/Agent tool with exactly 4 distinct prompts (one per research angle) — Task 3+ do not use this agent.

- [ ] **Step 1: Verify the skill directory doesn't validate yet**

```bash
mkdir -p skills/intel-analysis/references
bash scripts/validate-frontmatter.sh skills/intel-analysis/SKILL.md name description
```

Expected: `FAIL: skills/intel-analysis/SKILL.md does not exist`

- [ ] **Step 2: Write the curated source list**

Create `skills/intel-analysis/references/high-reputation-sources.md`:

```markdown
# High-Reputation Intelligence Sources

**Used by:** the intel-analysis skill and the intel-researcher subagent it dispatches.
**Purpose:** Ground web-sourced findings in primary and vendor-authoritative sources rather than aggregators, forums, or unverified blogs — keeps intel-analysis output consistent and reviewable.

## Guiding principle

Prefer, in order: (1) primary/government sources, (2) the vendor or researcher who originally published the finding, (3) MITRE/community-maintained technical references. Treat aggregator sites, unattributed blog reposts, and forum threads as leads to verify against a source below — never cite them directly as the source of a claim.

## Curated source list (v1 — static, extend as needed)

| Source | Type | Best for |
|---|---|---|
| [MITRE ATT&CK](https://attack.mitre.org/) | Technique reference | TTP definitions, technique/sub-technique IDs, data sources |
| [CISA Known Exploited Vulnerabilities (KEV)](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) | Government advisory | Confirmed in-the-wild exploitation, patch urgency |
| [NVD (National Vulnerability Database)](https://nvd.nist.gov/) | Government advisory | CVE scoring, affected products, CWE mapping |
| [Mandiant (Google Cloud)](https://cloud.google.com/blog/topics/threat-intelligence) | Vendor threat intel | APT/actor tracking, campaign analysis |
| [CrowdStrike Intelligence](https://www.crowdstrike.com/en-us/blog/category/threat-intel-research/) | Vendor threat intel | Adversary profiles, eCrime and targeted intrusion |
| [Unit 42 (Palo Alto Networks)](https://unit42.paloaltonetworks.com/) | Vendor threat intel | Malware analysis, campaign TTPs |
| [Recorded Future](https://www.recordedfuture.com/blog) | Vendor threat intel | Actor infrastructure, predictive intelligence |
| [GTIG (Google Threat Intelligence Group)](https://cloud.google.com/blog/topics/threat-intelligence) | Vendor threat intel | Merged Mandiant/TAG reporting, nation-state activity |

## When a claim has no source on this list

Say so explicitly rather than silently citing a lower-quality source: `Source not on the curated list — verify independently: [URL]`. Do not omit the finding; flag it.

## Extending this list

This list is intentionally static for v1. To add a source, append a row with the same three columns — no other file needs to change.
```

- [ ] **Step 3: Write the intel-researcher subagent**

Create `agents/intel-researcher.md`:

```markdown
---
name: intel-researcher
description: Researches one specific angle of a cyber threat intelligence subject (actor profile, MITRE ATT&CK/TTP mapping, IOC extraction, or related CVE/advisory correlation) and returns structured findings as plain text. Dispatched by the intel-analysis skill to run several research angles in parallel — do not invoke directly for unrelated tasks.
tools: WebSearch, WebFetch, Read, Grep, Glob
---

You are a threat intelligence research specialist. You will be given: (1) the subject material (a pasted report, file contents, a CVE ID, an actor name, or a technique ID), and (2) exactly one research angle to pursue. Research only that angle — the other angles are being researched in parallel by separate copies of you, and a synthesis step will merge all of them afterward.

## The four research angles

Whichever one you are assigned, follow its process exactly:

**Actor Profile** — Identify the threat actor(s) or group(s) associated with the subject material, if any. For each: known aliases, suspected origin/motivation, typical targeting (sector/geography), and 2-4 sentences on their general tradecraft. If no specific actor is attributable, say so explicitly rather than guessing — most hunts are actor-agnostic and that is a valid, common finding.

**ATT&CK / TTP Mapping** — Map every technique implied by the subject material to MITRE ATT&CK technique IDs (sub-technique level where possible, e.g. `T1558.004` not just `T1558`). For each: technique ID, technique name, tactic, and one sentence of evidence from the source material or research tying it to that technique.

**IOC Extraction** — Extract every indicator of compromise present in the subject material or found during research: hashes, IPs, domains, file paths, registry keys, mutexes, command lines. For each: the IOC value, its type, and a confidence label (`Confirmed` if directly stated by a primary source, `Reported` if from a single vendor source, `Inferred` if you derived it from pattern context).

**Related CVE / Advisory Correlation** — Identify CVEs, CISA advisories, or vendor advisories directly related to the subject material (the same vulnerability, the same campaign, or the same exploited software). For each: identifier, one-sentence summary, and why it's relevant to this subject.

## Sourcing rules

Consult `skills/intel-analysis/references/high-reputation-sources.md` (read it first) and prefer those sources. When you cite a claim from the web, name the source and, if it is not on that curated list, prefix the finding with `[UNVERIFIED SOURCE]`.

## Output format

Return plain text only — no file writes. Structure your response as a Markdown fragment with one `##` heading naming your angle (e.g. `## ATT&CK / TTP Mapping`) followed by the findings in the format described above (a table where one is implied, prose where it reads better). If you found nothing for your angle, say so explicitly under the heading rather than omitting it — an empty angle is itself a finding.
```

- [ ] **Step 4: Write the intel-analysis skill**

Create `skills/intel-analysis/SKILL.md`:

```markdown
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
```

- [ ] **Step 5: Verify all frontmatter**

```bash
bash scripts/validate-frontmatter.sh skills/intel-analysis/SKILL.md name description
bash scripts/validate-frontmatter.sh agents/intel-researcher.md name description
```

Expected: both print `OK: name=...` and `OK: description=...`, exit code 0.

- [ ] **Step 6: Verify the reference file is non-empty**

Run: `test -s skills/intel-analysis/references/high-reputation-sources.md && echo OK`
Expected: `OK`

- [ ] **Step 7: Commit**

```bash
git add skills/intel-analysis agents/intel-researcher.md
git commit -m "feat: add intel-analysis skill and intel-researcher subagent"
```

---

### Task 3: `intel-report` skill

**Files:**
- Create: `skills/intel-report/SKILL.md`

**Interfaces:**
- Consumes: `./threat-hunting/intel-analysis/<slug>-analysis.md` (exact section headings from Task 2, Step 4).
- Produces: `./threat-hunting/intel-reports/<slug>-report.md` matching the exact section headings in the **Pipeline Output Interfaces** table. This is what Task 4 (`hunt-planner`) reads as its trigger input.

- [ ] **Step 1: Verify the skill doesn't validate yet**

```bash
mkdir -p skills/intel-report
bash scripts/validate-frontmatter.sh skills/intel-report/SKILL.md name description
```

Expected: `FAIL: skills/intel-report/SKILL.md does not exist`

- [ ] **Step 2: Write the intel-report skill**

Create `skills/intel-report/SKILL.md`:

```markdown
---
name: intel-report
description: "Turn structured intel-analysis findings (or, if none exist yet, raw threat intel supplied directly) into a decision-ready actionable intel report: executive summary, key judgments, ATT&CK coverage, IOCs, and recommended hunt/detect/mitigate actions. Always trigger when a user asks for an intel report, a threat brief, an executive summary of a threat, or asks 'what should we do about X' after intel has been gathered. This is Stage 2 of the threat-intel-hunt-framework pipeline — it reads intel-analysis's output and its own output feeds the hunt-planner skill."
---

# Intel Report

Turn analysis findings into a report a decision-maker can act on without reading the raw research.

## Step 1: Locate or gather the analysis

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
[Any patch, config, or control changes implied directly by the intel — e.g. a specific CVE with a patch available. Leave empty with "None identified" if the intel is purely behavioral.]

## Confidence and Sourcing
[Overall confidence in this report and why. Explicitly note if the intel-analysis stage was skipped (see Step 1).]

## Appendix: Full Source List
[Every source cited in the analysis, carried forward verbatim.]
```

## When to ask vs. proceed

- **Ask first** when the analysis file is missing AND the user hasn't supplied enough raw material to write a report without fabricating findings.
- **Proceed and annotate** otherwise — mark unknowns explicitly (`Unknown`, `Not assessed`) rather than blocking.
```

- [ ] **Step 3: Verify frontmatter**

Run: `bash scripts/validate-frontmatter.sh skills/intel-report/SKILL.md name description`
Expected: `OK: name=intel-report`, `OK: description=...`, exit code 0.

- [ ] **Step 4: Commit**

```bash
git add skills/intel-report
git commit -m "feat: add intel-report skill"
```

---

### Task 4: `hunt-planner` skill (absorbs the existing Threat Hunt Planner skill)

**Files:**
- Create: `skills/hunt-planner/SKILL.md` (adapted from `D:\UnifiedThreatHunting\Threat_Hunt_Planner_Skill\threat-hunt-planner (2).skill` → extracted `threat-hunt-planner/SKILL.md`)
- Create: `skills/hunt-planner/references/hypothesis-templates.md` (ported from the same zip's `references/hypothesis-framework.md`)
- Create: `skills/hunt-planner/references/hypothesis-rubric.md` (ported from `D:\UnifiedThreatHunting\references\hypothesis_rubric.md`)
- Create: `skills/hunt-planner/references/feasibility-checklist.md` (ported from the zip's `references/feasibility-checklist.md`)
- Create: `skills/hunt-planner/references/telemetry-gap-assessment.md` (ported from `D:\UnifiedThreatHunting\references\telemetry_gap_assessment.md`)
- Create: `skills/hunt-planner/references/jira-templates.md` (ported from the zip's `references/jira-templates.md`)
- Create: `skills/hunt-planner/references/data-source-explorer.md` (ported from the zip's `references/data-source-explorer.md`)
- Create: `skills/hunt-planner/references/domain-telemetry-matrix.md` (ported from `D:\UnifiedThreatHunting\docs\modern_domain_matrix.md`)
- Create: `skills/hunt-planner/references/hunt-maturity-model.md` (ported from `D:\UnifiedThreatHunting\docs\maturity_metric.md`)

**Interfaces:**
- Consumes: `./threat-hunting/intel-reports/<slug>-report.md` (Task 3's exact headings) as an optional trigger — the skill must also work standalone with any other trigger (a bare CVE, a stakeholder request, a red-team finding), per the original skill's design.
- Produces: `./threat-hunting/hunt-plans/<slug>-hunt-plan.md` with the `## Environment Profile` block plus the Epic/Story/Task structure defined in Step 6 below. This is what Task 5 (`detection-engineer`) reads for its Environment Profile / SIEM dialect and expected-outcome content.

The zip is already extracted locally at `/tmp/skill_extract/threat-hunt-planner/` from earlier inspection in this session — use that extraction; do not re-unzip.

- [ ] **Step 1: Verify the skill doesn't validate yet**

```bash
mkdir -p skills/hunt-planner/references
bash scripts/validate-frontmatter.sh skills/hunt-planner/SKILL.md name description
```

Expected: `FAIL: skills/hunt-planner/SKILL.md does not exist`

- [ ] **Step 2: Port the six existing reference files verbatim, then apply targeted fixes**

Copy each file unchanged first:

```bash
cp "/tmp/skill_extract/threat-hunt-planner/references/hypothesis-framework.md" "skills/hunt-planner/references/hypothesis-templates.md"
cp "/tmp/skill_extract/threat-hunt-planner/references/feasibility-checklist.md" "skills/hunt-planner/references/feasibility-checklist.md"
cp "/tmp/skill_extract/threat-hunt-planner/references/jira-templates.md" "skills/hunt-planner/references/jira-templates.md"
cp "/tmp/skill_extract/threat-hunt-planner/references/data-source-explorer.md" "skills/hunt-planner/references/data-source-explorer.md"
```

Then check every copied file for relative references to other reference files, since some moved to a different skill (`sigma-rule-builder.md` is now under `skills/detection-engineer/references/`, `hunt-outcome-documenter.md` is now under `skills/hunt-validator/references/`):

```bash
grep -rn "references/" skills/hunt-planner/references/*.md
```

For every hit that points at `sigma-rule-builder.md` or `hunt-outcome-documenter.md`, edit that line to say `the detection-engineer skill's sigma-rule-builder.md reference` or `the hunt-validator skill's hunt-outcome-documenter.md reference` respectively, instead of a broken relative path. Leave hits that point at files still inside this skill (e.g. `hypothesis-framework.md` → rename the reference text to `hypothesis-templates.md` to match its new filename) unchanged in meaning, just updated to the new filename.

- [ ] **Step 3: Port the two UnifiedThreatHunting reference files verbatim**

```bash
cp "D:/UnifiedThreatHunting/references/hypothesis_rubric.md" "skills/hunt-planner/references/hypothesis-rubric.md"
cp "D:/UnifiedThreatHunting/references/telemetry_gap_assessment.md" "skills/hunt-planner/references/telemetry-gap-assessment.md"
cp "D:/UnifiedThreatHunting/docs/modern_domain_matrix.md" "skills/hunt-planner/references/domain-telemetry-matrix.md"
cp "D:/UnifiedThreatHunting/docs/maturity_metric.md" "skills/hunt-planner/references/hunt-maturity-model.md"
```

These four carry a `**Fits at:** Step N ...` line referencing the original Unified Threat Hunting Process step numbers (0/2/4/9) — leave those lines as-is; they're still accurate context for a reader, just cross-reference the source process rather than this plugin's own step numbering.

- [ ] **Step 4: Verify all eight reference files are non-empty**

```bash
for f in skills/hunt-planner/references/*.md; do test -s "$f" && echo "OK: $f" || echo "FAIL: $f empty"; done
```

Expected: 8 `OK:` lines, no `FAIL:` lines.

- [ ] **Step 5: Write the adapted hunt-planner SKILL.md**

Create `skills/hunt-planner/SKILL.md`. This is the existing `threat-hunt-planner/SKILL.md` (315 lines, already read in full during planning) ported with these specific changes from the original:

1. Frontmatter `description` updated to mention it's Stage 3 of this pipeline and that it optionally consumes an `intel-report` output.
2. A new "Step 1 (pipeline mode)" note before the original Step 1, pointing at `./threat-hunting/intel-reports/<slug>-report.md` as an optional trigger source.
3. `references/hypothesis-framework.md` → `references/hypothesis-templates.md` throughout, and add a new gate: after building the SMART hypothesis, score it with `references/hypothesis-rubric.md` before proceeding to feasibility (this rubric didn't exist in the original skill — it's ported from the source methodology repo per the spec's instruction to build on that repo's more rigorous artifacts).
4. `references/feasibility-checklist.md` stays, and Step 4 also references the new `references/telemetry-gap-assessment.md` for the Data Availability/Data Quality inputs specifically (the original skill's feasibility checklist covers team/timeline/tooling well but scores data availability/quality only loosely; the ported telemetry-gap-assessment.md gives that a DeTT&CT-based scoring method).
5. Step 0's Environment Context table gets one addition: a link to `references/domain-telemetry-matrix.md` (pick the domain — endpoint / on-prem AD / cloud IdP / cloud control plane — before writing the hypothesis, since it changes the telemetry model) and `references/hunt-maturity-model.md` (for scoring the "Hunt Maturity Level" field honestly rather than leaving it a free-text label).
6. Output path: the Epic-format document is now written to a file, not just presented in chat — add an explicit final step: write everything (Environment Profile + Epic + at least one Story + Task placeholders) to `./threat-hunting/hunt-plans/<slug>-hunt-plan.md`.
7. All other content — Steps 1-6, the Express Mode section, the Quick Reference table, the Output Checklist — carries forward unchanged.

Full file:

```markdown
---
name: hunt-planner
description: "Generate structured, Jira-ready threat hunt plans following the Unified Threat Hunting Process methodology. Always trigger when users mention threat hunting, hunt plans, hunting hypotheses, or ask how to detect a specific TTP, threat actor, or adversary behavior. Also trigger for structuring hunts in Jira format (Epics/Stories/Tasks), translating a CTI report or CISA advisory into an actionable hunt, formalizing ad-hoc hunt ideas, validating EDR or SIEM detection coverage, planning purple team exercises, or when someone shares a MITRE ATT&CK technique and wants to hunt for it. Produces SMART hypotheses, feasibility assessments, and Jira-ready planning artifacts. This is Stage 3 of the threat-intel-hunt-framework pipeline — it optionally consumes the intel-report skill's output as its trigger, and its output feeds the detection-engineer skill."
---

# Hunt Planner

Generate structured, actionable threat hunt plans using the Unified Threat Hunting Process methodology. Output follows Jira planning structure (Epics → Stories → Tasks).

## Process Overview

### Planning Phase (Steps 0-6)
0. **Gather environment context** — tailor all outputs to the user's actual stack
1. **Identify the triggering event** — why are we hunting? (check `./threat-hunting/intel-reports/<slug>-report.md` first — see Step 1 below)
2. **Develop hypothesis** — use `references/hypothesis-templates.md`, then score it with `references/hypothesis-rubric.md`
3. **Conduct initial assessment** — internal + external research
4. **Perform feasibility assessment** — use `references/feasibility-checklist.md` and `references/telemetry-gap-assessment.md`
5. **Define scope and objectives** — boundaries and success criteria
6. **Formalize hunt plan in Jira structure** — use `references/jira-templates.md`

### Pre-Execution Phase
- Explore unfamiliar data sources (`references/data-source-explorer.md`)

### Post-Execution Phase
- Detection rule authoring is handled by the `detection-engineer` skill (Stage 4 of this pipeline) — hand off expected-outcome content to it rather than duplicating rule-building here.

## When to Ask vs. When to Proceed

- **Ask first** when: the trigger or threat actor is ambiguous, the environment is unknown, or the user hasn't indicated what data sources they have.
- **Proceed and annotate** when: the user provides a specific CTI report, MITRE technique ID, or clear scenario — generate the plan immediately with `[FILL IN: <detail>]` placeholders where context is missing, then invite the user to fill them.
- **Never block on perfect information** — a plan with clearly marked placeholders is always more useful than no plan.

## Step 0: Gather Environment Context

Before building the hunt plan, capture the user's environment so that all outputs — queries, data source references, tool names — are tailored rather than generic. If any of this is already known from the conversation, skip those items.

**Capture (or infer) the following:**

| Context | Why It Matters |
|---------|----------------|
| **SIEM / Data Platform** | Splunk SPL vs. KQL vs. Elastic DSL vs. Chronicle affects every query example |
| **EDR Platform** | CrowdStrike, SentinelOne, Defender for Endpoint — affects telemetry field names |
| **Environment Type** | On-premises, cloud-native (AWS/Azure/GCP), or hybrid |
| **Industry Vertical** | Tailors threat actor relevance (finance, healthcare, energy, manufacturing, etc.) |
| **Approximate Log Retention** | Determines what time windows are actually feasible |
| **Hunt Maturity Level** | Score honestly using `references/hunt-maturity-model.md` rather than a free-text guess — first-time hunters need more scaffolding; experienced teams may prefer a skeleton |

Pick the relevant domain row from `references/domain-telemetry-matrix.md` (endpoint / on-prem AD / cloud IdP / cloud control plane) before writing the hypothesis in Step 2 — it changes which telemetry and identity model applies.

**Express path**: If the user wants to move fast, capture only **SIEM platform** and **environment type** — these are the minimum required to produce useful, non-generic outputs.

Document captured context at the top of the Epic under an `## Environment Profile` section.

---

## Step 1: Identify the Triggering Event

**Pipeline mode:** first check for `./threat-hunting/intel-reports/<slug>-report.md` in the invoking project. If it exists, read its `## Recommended Actions > ### Hunt` section — those are your candidate hypothesis seeds — and its `## MITRE ATT&CK Coverage` table for technique context. Use the same `<slug>` for this hunt plan's output file.

Every hunt begins with a trigger. Identify which type applies:

- **CTI (Cyber Threat Intelligence)**: Threat report, advisory, or intel feed — including this pipeline's own `intel-report` output
- **Incomplete Use Cases**: Gaps in existing detection coverage
- **Past Incidents**: Lessons learned from previous security events
- **Red Team/Purple Team Findings**: Offensive assessment results
- **MITRE ATT&CK TTPs**: Specific techniques requiring validation
- **Stakeholder Requirements**: Direct requests from leadership or business units
- **Vulnerability Disclosure**: New CVEs affecting the environment

Document the trigger source, date received, and relevance to the organization.

## Step 2: Develop Hypothesis

Construct a SMART hypothesis:

| Criterion | Requirement |
|-----------|-------------|
| **Specific** | Clear, unambiguous, no room for misinterpretation |
| **Measurable** | Quantifiable criteria to track progress |
| **Achievable** | Realistic given team capabilities and data access |
| **Relevant** | Aligned with organizational goals and risk priorities |
| **Time-bound** | Defined start/end dates, no open-ended hunts |

**Hypothesis Template:**
```
We hypothesize that [THREAT ACTOR/TECHNIQUE/BEHAVIOR] may be present in our
environment, evidenced by [OBSERVABLE INDICATORS] in [DATA SOURCES], which
we can validate by [TEST METHODOLOGY] within [TIMEFRAME].
```

For complex hunts requiring competing hypotheses, or for the five ready-made templates (threat-actor-focused, TTP-focused, behavioral, intelligence-driven, express), see `references/hypothesis-templates.md`.

**Then score it.** Run the hypothesis through `references/hypothesis-rubric.md`'s 5-dimension rubric (Specificity, Testability, Falsifiability, Relevance, Pyramid level). A score below 10, or any single dimension scoring 1, means rewrite before proceeding to Step 3 — most failures are Specificity, so push the hypothesis down to a field-level observable.

## Step 3: Initial Assessment

Gather supporting information:

**Internal Sources:**
- Previous hunt reports and lessons learned
- Network and application architecture diagrams
- Internal threat intelligence
- Existing detection rules and coverage maps
- Asset inventory and crown jewels analysis

**External Sources:**
- OSINT and vendor threat reports
- MITRE ATT&CK technique documentation
- Sigma rule repositories
- Threat actor profiles and campaign analysis

**SME Engagement:**
- Identify business/technical owners if the hunt involves specific systems
- Document any tribal knowledge that affects the hunt

## Step 4: Feasibility Assessment

Before planning, validate the hunt is executable. Use `references/feasibility-checklist.md` for team/timeline/tooling criteria, and `references/telemetry-gap-assessment.md` for a rigorous, DeTT&CT-scored Data Availability and Data Quality assessment.

**Core Questions:**
1. **Data Availability**: Do required log sources exist and are they accessible?
2. **Data Quality**: Is telemetry complete, parsed correctly, and retained long enough?
3. **Team Skillset**: Does the team have expertise for the analysis techniques required?
4. **Timeline**: Can this be completed within the sprint/allocated time?
5. **Tooling**: Are required tools (SIEM, EDR, notebooks) available?

**Decision:**
- **GO**: All criteria met → proceed to planning
- **NO-GO**: Critical blockers exist → backlog with remediation plan
- **CONDITIONAL**: Minor gaps → document assumptions and proceed with caveats

## Step 5: Define Scope and Objectives

Specify boundaries and success criteria:

**Scope Definition:**
- Target environment segments (production, DMZ, cloud, endpoints)
- Time window for analysis (e.g., last 30 days, specific incident window)
- Systems/assets in scope
- Exclusions (if any)

**Objectives:**
- Primary: What must be answered to validate/invalidate the hypothesis?
- Secondary: Additional findings that would add value
- Metrics: How will success be measured?

## Step 6: Formalize Hunt Plan (Jira Structure)

Use the templates in `references/jira-templates.md` for exact field structures.

### Epic Structure

The Epic represents the overarching hunt hypothesis and contains:

```markdown
## Epic: [HUNT-XXX] [Descriptive Title]

### Hypothesis
[SMART hypothesis statement]

### Triggering Event
- Type: [CTI | Incomplete Use Cases | Past Incidents | Red Team/Purple Team Findings | MITRE ATT&CK TTPs | Stakeholder Requirements | Vulnerability Disclosure]
- Source: [Source name/reference]
- Date Received: [YYYY-MM-DD]
- Relevance: [Why this matters to the organization]

### Initial Research
[Summary of initial assessment findings, key references, prior art]

### Feasibility Assessment
- Data Availability: [GO/NO-GO with notes]
- Data Quality: [GO/NO-GO with notes]
- Skillset: [GO/NO-GO with notes]
- Timeline: [Estimated duration]
- Tooling: [Required tools]
- **Overall Decision**: [GO | NO-GO | CONDITIONAL]

### Scope
- Environment: [Target segments]
- Time Window: [Analysis period]
- In-Scope Assets: [List]
- Exclusions: [List]

### Objectives
1. [Primary objective]
2. [Secondary objective]

### MITRE ATT&CK Mapping
| Technique ID | Technique Name | Tactic |
|--------------|----------------|--------|
| TXXXX.XXX    | Name           | Tactic |

### Data Sources Required
- [Log source 1]
- [Log source 2]

### References
- [Link/citation 1]
- [Link/citation 2]
```

### Story Structure

Stories are discrete investigations under the Epic. Each Story tests a specific aspect of the hypothesis.

```markdown
## Story: [HUNT-XXX-S1] [Investigation Title]

### Parent Epic
[HUNT-XXX]

### Objective
[What this specific investigation aims to determine]

### Hypothesis Component
[Which part of the Epic hypothesis this tests]

### Methodology
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Data Sources
| Source | Fields Required | Location |
|--------|-----------------|----------|
| Source | field1, field2  | SIEM/EDR |

### Detection Logic
[Query pseudocode. Hand off to the detection-engineer skill (Stage 4) once validated — see references/jira-templates.md for the Analytics/Detection task template that links the two.]

### Expected Outcomes
- If malicious: [What evidence would confirm threat presence]
- If benign: [What evidence would invalidate hypothesis]

### Acceptance Criteria
- [ ] Data sources validated
- [ ] Queries executed across full time window
- [ ] Findings documented
- [ ] False positives triaged
```

### Task Structure (Outcome Placeholders)

Tasks capture hunt outcomes. Create placeholder tasks during planning; populate after execution — see the `hunt-validator` skill (Stage 5) for outcome documentation once a detection has been built and validated.

**Outcome Categories** (from AIMOD2 framework):
1. **New Hunt Idea**: Future hypothesis to explore
2. **Analytics/Detection**: Rules, dashboards, or signatures created — hand off to `detection-engineer`
3. **Security Incident**: Escalation to IR
4. **Written Report**: Final hunt report
5. **Visibility Gap**: Missing telemetry identified
6. **Security Control Issue**: Gaps in defenses discovered

```markdown
## Task: [HUNT-XXX-T1] [Outcome Type]: [Brief Description]

### Parent Story
[HUNT-XXX-S1]

### Outcome Category
[New Hunt Idea | Analytics/Detection | Security Incident | Written Report | Visibility Gap | Security Control Issue]

### Description
[Details of the finding/outcome]

### Evidence
[Supporting data, screenshots, query results]

### Recommended Action
[Next steps based on this outcome]

### Assignee
[Team/individual responsible for action]
```

## Output Checklist

Before finalizing the hunt plan, verify:

- [ ] Triggering event documented with source and relevance
- [ ] Hypothesis is SMART-compliant and scored ≥10 on the hypothesis rubric with no dimension at 1
- [ ] Initial assessment completed with internal/external sources
- [ ] Feasibility assessment shows GO or CONDITIONAL with documented assumptions
- [ ] Scope clearly defines boundaries, time window, and in-scope assets
- [ ] Objectives are specific and measurable
- [ ] MITRE ATT&CK techniques mapped
- [ ] Data sources identified with field-level requirements
- [ ] Epic created with all required fields
- [ ] At least one Story created with methodology and detection logic
- [ ] Task placeholders created for expected outcome types
- [ ] Written to `./threat-hunting/hunt-plans/<slug>-hunt-plan.md` (Environment Profile + Epic + Stories + Tasks, in that order)

## Express Mode: Rapid Hunt Skeleton

Use Express Mode when the user has a rough idea and needs a skeleton quickly, or when time doesn't allow the full 6-step process. Express Mode produces a condensed, actionable plan in a single pass.

**Trigger signals**: User says "quick plan," "rough draft," "just give me a skeleton," shares a single CVE or advisory with urgency, or is clearly time-constrained.

**Express Mode process:**
1. Capture trigger and hypothesis in 2-3 sentences (use the Express Template in `references/hypothesis-templates.md`)
2. Note the top 2-3 data sources required
3. List the key MITRE ATT&CK techniques under investigation
4. Give a rough effort estimate: Low (1-2 days) / Medium (3-5 days) / High (1-2 weeks)
5. Output a single condensed Epic with one placeholder Story

**Always flag the trade-offs**: Express plans skip full feasibility assessment and competing hypotheses. Add this notice to the document:

> ⚠️ **EXPRESS PLAN** — Full feasibility assessment and competing hypotheses analysis not completed. Upgrade to the full 6-step process before hunt execution.

## Quick Reference: Hunt Types

| Hunt Type | Starting Point | Characteristics |
|-----------|---------------|-----------------|
| **Exploratory (EDA)** | Raw data | Baselining, understanding data shape, no prior hypothesis. See `references/data-source-explorer.md` |
| **Hypothesis-Based (HBO)** | Situational awareness | Testing credible attack scenarios |
| **Threat-Informed (TIO)** | Actionable CTI | Intelligence-driven, known actor/TTP focus |
| **Purple Operations (DPO)** | Red team insight | Joint offensive/defensive validation |

Select the hunt type that matches your starting position in the DAIKI chain (Data → Information → Knowledge → Insight).
```

- [ ] **Step 6: Verify frontmatter**

Run: `bash scripts/validate-frontmatter.sh skills/hunt-planner/SKILL.md name description`
Expected: `OK: name=hunt-planner`, `OK: description=...`, exit code 0.

- [ ] **Step 7: Commit**

```bash
git add skills/hunt-planner
git commit -m "feat: add hunt-planner skill, absorbing the existing Threat Hunt Planner skill"
```

---

### Task 5: `detection-engineer` skill

**Files:**
- Create: `skills/detection-engineer/SKILL.md`
- Create: `skills/detection-engineer/references/sigma-rule-builder.md` (ported from `/tmp/skill_extract/threat-hunt-planner/references/sigma-rule-builder.md`)
- Create: `skills/detection-engineer/references/detection-handoff-spec.md` (ported from `D:\UnifiedThreatHunting\references\detection_handoff_spec.md`)

**Interfaces:**
- Consumes: `./threat-hunting/hunt-plans/<slug>-hunt-plan.md` (Task 4's Environment Profile + Story-level Detection Logic/Expected Outcomes sections).
- Produces: `./threat-hunting/detections/<slug>-detection.md` with the exact `## DET-XXX — [Title]` / 10-numbered-section structure from `detection-handoff-spec.md`. This is what Task 6 (`hunt-validator`) reads.

- [ ] **Step 1: Verify the skill doesn't validate yet**

```bash
mkdir -p skills/detection-engineer/references
bash scripts/validate-frontmatter.sh skills/detection-engineer/SKILL.md name description
```

Expected: `FAIL: skills/detection-engineer/SKILL.md does not exist`

- [ ] **Step 2: Port the two reference files verbatim**

```bash
cp "/tmp/skill_extract/threat-hunt-planner/references/sigma-rule-builder.md" "skills/detection-engineer/references/sigma-rule-builder.md"
cp "D:/UnifiedThreatHunting/references/detection_handoff_spec.md" "skills/detection-engineer/references/detection-handoff-spec.md"
```

No cross-reference fixes needed — `sigma-rule-builder.md` doesn't reference other reference files by relative path, and `detection-handoff-spec.md` only links external URLs.

- [ ] **Step 3: Verify both are non-empty**

```bash
test -s skills/detection-engineer/references/sigma-rule-builder.md && echo "OK: sigma-rule-builder.md"
test -s skills/detection-engineer/references/detection-handoff-spec.md && echo "OK: detection-handoff-spec.md"
```

Expected: both `OK:` lines print.

- [ ] **Step 4: Write the detection-engineer skill**

Create `skills/detection-engineer/SKILL.md`:

```markdown
---
name: detection-engineer
description: "Turn a validated hunt finding into a production-ready detection handoff artifact: a Sigma rule (plus native SIEM translation if the platform is known), MITRE ATT&CK mapping, robustness scoring, blind spots, and response guidance. Always trigger when a user asks to build a detection from a hunt finding, convert a hunt query into a standing rule, write a Sigma rule, or asks how to hand a finding off to detection engineering. This is Stage 4 of the threat-intel-hunt-framework pipeline — it reads the hunt-planner skill's output and its own output feeds the hunt-validator skill."
---

# Detection Engineer

Turn a hunt finding into an artifact detection engineering can actually accept — not just "here's the query I ran." Uses an ADS-lite handoff spec (trimmed Palantir Alerting & Detection Strategy fields plus a Summiting the Pyramid robustness score).

## Step 1: Locate the hunt plan

Read `./threat-hunting/hunt-plans/<slug>-hunt-plan.md`. Pull: the `## Environment Profile` (for SIEM/EDR platform — determines whether you produce Sigma only or Sigma + a native translation), the Story's `### Detection Logic` and `### Expected Outcomes` (the raw material for the rule), and the Epic's `### MITRE ATT&CK Mapping`.

If no hunt plan exists yet, ask for the finding directly: what behavior fires the rule, on what data source, and what the false-positive picture looks like. Do not fabricate a finding to fill the template.

## Step 2: Build the rule

Use `references/sigma-rule-builder.md`'s 6-step process (define objective → select log source → build detection logic → map ATT&CK → assess detection level → document false positives) and its rule templates as starting points where the finding matches a covered use case (process execution, command-line pattern, encoded PowerShell, registry persistence, C2 network connection, LSASS credential access, webshell/dropper file creation).

Produce Sigma as the primary, portable logic. If the Environment Profile names a specific SIEM (Splunk/SPL, Microsoft Sentinel or Defender/KQL, Elastic DSL), also produce the native-dialect translation — but Sigma is never optional, since it's what makes the handoff portable and reviewable without trusting a translation.

## Step 3: Score robustness

For every rule, score both Summiting the Pyramid axes from `references/detection-handoff-spec.md`'s Robustness Guidance section:

- **Observable robustness** — ephemeral value the adversary sets freely, or core to how the technique must work?
- **Event robustness** — application-layer telemetry (spoofable) or lower in the stack (kernel/sensor-level)?

If both score low, do not ship the detection — recommend a Visibility Gap outcome instead (you're detecting the tool, not the technique, and it will die with the next build). Say this explicitly rather than producing a weak rule anyway.

## Step 4: Write the handoff artifact

Fill `references/detection-handoff-spec.md`'s exact 10-section template. Do not skip a section — if a section genuinely doesn't apply yet (e.g. validation hasn't run), write `Not yet validated — see hunt-validator` rather than leaving it blank; the spec's acceptance gate rejects a handoff with an empty validation or blind-spots section.

Write to `./threat-hunting/detections/<slug>-detection.md`:

```markdown
## DET-XXX — [Title]
Source hunt:  [HUNT-XXX-SX from the hunt plan]
Author:       [from conversation context or "unspecified"]   Reviewer: [unspecified]   Date: [today's date]

### 1. Goal
### 2. ATT&CK categorization
### 3. Strategy abstract
### 4. Technical context
### 5. Logic
### 6. Blind spots and assumptions
### 7. False positives
### 8. Robustness score
### 9. Validation
### 10. Priority and response
```

(Section bodies follow `references/detection-handoff-spec.md`'s template exactly — copy its field structure, don't improvise new fields.)

## Step 5: Self-check against the acceptance gate

Before declaring the handoff done, check `references/detection-handoff-spec.md`'s Acceptance Gate list. If any of the six rejection conditions is true (no validation result, empty/absent blind spots, unknown false-positive volume, hash/IP/domain as the primary condition, absent robustness rationale, no response guidance), the handoff is not done — either fill the gap or state explicitly in the output that this handoff will be rejected pending [specific missing item], and recommend routing to `hunt-validator` next.
```

- [ ] **Step 5: Verify frontmatter**

Run: `bash scripts/validate-frontmatter.sh skills/detection-engineer/SKILL.md name description`
Expected: `OK: name=detection-engineer`, `OK: description=...`, exit code 0.

- [ ] **Step 6: Commit**

```bash
git add skills/detection-engineer
git commit -m "feat: add detection-engineer skill"
```

---

### Task 6: `hunt-validator` skill

**Files:**
- Create: `skills/hunt-validator/SKILL.md`
- Create: `skills/hunt-validator/references/validation-hook.md` (ported from `D:\UnifiedThreatHunting\references\validation_hook.md`)
- Create: `skills/hunt-validator/references/hunt-outcome-documenter.md` (ported from `/tmp/skill_extract/threat-hunt-planner/references/hunt-outcome-documenter.md`)

**Interfaces:**
- Consumes: `./threat-hunting/detections/<slug>-detection.md` (Task 5's `## DET-XXX` section 2 for ATT&CK ID, section 9 as the slot to fill).
- Produces: `./threat-hunting/validations/<slug>-validation.md` with `## Validation Record` and `## Outcome Documentation` sections. This is the pipeline's final stage — no downstream consumer.

- [ ] **Step 1: Verify the skill doesn't validate yet**

```bash
mkdir -p skills/hunt-validator/references
bash scripts/validate-frontmatter.sh skills/hunt-validator/SKILL.md name description
```

Expected: `FAIL: skills/hunt-validator/SKILL.md does not exist`

- [ ] **Step 2: Port the two reference files, then fix the one cross-reference**

```bash
cp "D:/UnifiedThreatHunting/references/validation_hook.md" "skills/hunt-validator/references/validation-hook.md"
cp "/tmp/skill_extract/threat-hunt-planner/references/hunt-outcome-documenter.md" "skills/hunt-validator/references/hunt-outcome-documenter.md"
```

`hunt-outcome-documenter.md`'s Category 3 (Detection Opportunity) template contains the line `# See references/sigma-rule-builder.md for Sigma format`. That file now lives in a different skill. Edit that line in the copied file to read:

```
# Sigma format guidance lives in the detection-engineer skill's sigma-rule-builder.md reference
```

- [ ] **Step 3: Verify both are non-empty and the cross-reference fix landed**

```bash
test -s skills/hunt-validator/references/validation-hook.md && echo "OK: validation-hook.md"
grep -q "detection-engineer skill's sigma-rule-builder.md" skills/hunt-validator/references/hunt-outcome-documenter.md && echo "OK: cross-reference fixed"
```

Expected: both `OK:` lines print.

- [ ] **Step 4: Write the hunt-validator skill**

Create `skills/hunt-validator/SKILL.md`:

```markdown
---
name: hunt-validator
description: "Prove a detection actually fires before it ships, and document the hunt's final typed outcome (visibility gap, security control issue, detection opportunity, hunt opportunity, suspicious security event, or threat intelligence observable). Always trigger when a user asks to validate a detection, test whether telemetry generates for a technique, run an atomic test against a hunt finding, or close out and document a completed hunt. This is Stage 5 (final) of the threat-intel-hunt-framework pipeline — it reads the detection-engineer skill's output."
---

# Hunt Validator

A hunt that finds nothing is only meaningful if you've demonstrated you *would* have seen it. This skill proves the telemetry and logic fire, then documents the hunt's outcome by category so it's trackable and reportable.

## Step 1: Determine if validation is required

Read `./threat-hunting/detections/<slug>-detection.md` if it exists. Check `references/validation-hook.md`'s "When to run" table:

| Situation | Validation required? |
|---|---|
| Hunt produced a candidate detection | Yes — blocks handoff |
| Hunt returned clean, feasibility was CONDITIONAL | Yes |
| Hunt returned clean, feasibility GO, technique never previously validated | Yes |
| Technique validated within the last 90 days, no stack change | No — cite the prior test |

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

## Step 4: Write the output

Write to `./threat-hunting/validations/<slug>-validation.md`:

```markdown
## Validation Record
[The filled record template from Step 2.]

## Outcome Documentation
[One block per applicable category from Step 3, using that category's exact template from references/hunt-outcome-documenter.md.]
```

If Step 3 produced a **Suspicious Security Event**, do not wait for this file write to raise it — flag it to the user immediately, before finishing the rest of the write-up.
```

- [ ] **Step 5: Verify frontmatter**

Run: `bash scripts/validate-frontmatter.sh skills/hunt-validator/SKILL.md name description`
Expected: `OK: name=hunt-validator`, `OK: description=...`, exit code 0.

- [ ] **Step 6: Commit**

```bash
git add skills/hunt-validator
git commit -m "feat: add hunt-validator skill"
```

---

### Task 7: Master pipeline command

**Files:**
- Create: `commands/run-hunt-pipeline.md`

**Interfaces:**
- Consumes: all five skills from Tasks 2-6 by name (`intel-analysis`, `intel-report`, `hunt-planner`, `detection-engineer`, `hunt-validator`) and the pipeline output paths from the **Pipeline Output Interfaces** table.
- Produces: nothing new on disk itself — it is a sequencing prompt. Its "output" is the five files the skills it invokes produce, plus a final summary of their paths.

- [ ] **Step 1: Verify the command doesn't validate yet**

```bash
bash scripts/validate-frontmatter.sh commands/run-hunt-pipeline.md description
```

Expected: `FAIL: commands/run-hunt-pipeline.md does not exist`

- [ ] **Step 2: Write the master command**

Create `commands/run-hunt-pipeline.md`:

```markdown
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
```

- [ ] **Step 3: Verify frontmatter**

Run: `bash scripts/validate-frontmatter.sh commands/run-hunt-pipeline.md description`
Expected: `OK: description=...`, exit code 0.

- [ ] **Step 4: Commit**

```bash
git add commands/run-hunt-pipeline.md
git commit -m "feat: add master run-hunt-pipeline command"
```

---

### Task 8: README and final integration check

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: nothing new — this task verifies everything Tasks 1-7 produced is internally consistent.
- Produces: nothing consumed by another task — this is the last task.

- [ ] **Step 1: Write the README**

Create `README.md`:

```markdown
# Threat Intel Hunt Framework

A Claude Code plugin that runs an agentic, five-stage pipeline from raw cyber threat intelligence to a validated detection — grounded in the [Unified Threat Hunting Process](https://github.com/sims718718/UnifiedThreatHunting).

```
CTI input → intel-analysis → intel-report → hunt-planner → detection-engineer → hunt-validator
```

## Stages

| Stage | Skill | What it produces |
|---|---|---|
| 1 | `intel-analysis` | Actor profile, ATT&CK/TTP mapping, IOCs, related CVEs — researched in parallel via the `intel-researcher` subagent |
| 2 | `intel-report` | A decision-ready actionable intel report: executive summary, key judgments, recommended hunt/detect/mitigate actions |
| 3 | `hunt-planner` | A SMART, rubric-scored hypothesis, feasibility gate, and Jira-structured Epic/Story/Task hunt plan (absorbs the original standalone Threat Hunt Planner skill) |
| 4 | `detection-engineer` | An ADS-lite detection handoff artifact: Sigma rule, robustness score, blind spots, response guidance |
| 5 | `hunt-validator` | A validation record (did the detection actually fire?) plus a typed outcome document |

Each skill triggers independently — jump into any single stage without running the rest. To run everything end-to-end against one input, use `/run-hunt-pipeline`.

## Output convention

Every stage writes to `./threat-hunting/<stage>/<slug>-<stage>.md` in whatever project you're working in — never inside this plugin's own repo. See each skill's `SKILL.md` for its exact output structure.

## Installing locally

This plugin isn't published to a marketplace — install it from this local path:

```bash
claude plugin marketplace add "D:\threat-intel-hunt-framework"
claude plugin install threat-intel-hunt-framework@threat-intel-hunt-framework
```

## Scope (v1)

- No hooks.
- No custom MCP tools or live SIEM/API integrations — intel research uses built-in WebSearch/WebFetch against a static curated source list (`skills/intel-analysis/references/high-reputation-sources.md`).
- The master pipeline command runs straight through with no pause/confirmation gates between stages; review the five output files afterward.
```

- [ ] **Step 2: Verify the plugin.json skills array matches the actual skill directories on disk**

```bash
python -c "
import json, os
manifest = json.load(open('.claude-plugin/plugin.json'))
declared = sorted(p.replace('./skills/', '') for p in manifest['skills'])
actual = sorted(d for d in os.listdir('skills') if os.path.isdir(os.path.join('skills', d)))
assert declared == actual, f'MISMATCH: declared={declared} actual={actual}'
print('OK: plugin.json skills array matches skills/ directory contents:', actual)
"
```

Expected: `OK: plugin.json skills array matches skills/ directory contents: ['detection-engineer', 'hunt-planner', 'hunt-validator', 'intel-analysis', 'intel-report']`

- [ ] **Step 3: Run the frontmatter validator across every skill, agent, and command in one pass**

```bash
for f in skills/*/SKILL.md; do bash scripts/validate-frontmatter.sh "$f" name description || exit 1; done
for f in agents/*.md; do bash scripts/validate-frontmatter.sh "$f" name description || exit 1; done
for f in commands/*.md; do bash scripts/validate-frontmatter.sh "$f" description || exit 1; done
echo "ALL FRONTMATTER VALID"
```

Expected: every file prints its `OK:` lines, no `FAIL:` lines, final line `ALL FRONTMATTER VALID`.

- [ ] **Step 4: Confirm no ported reference file still contains a broken relative reference**

```bash
grep -rln "references/sigma-rule-builder.md" skills/ 2>/dev/null | grep -v "^skills/detection-engineer/"
grep -rln "references/hunt-outcome-documenter.md" skills/ 2>/dev/null | grep -v "^skills/hunt-validator/"
```

Each command's output must be empty. `detection-engineer/SKILL.md` legitimately references its own `references/sigma-rule-builder.md`, and `hunt-validator/SKILL.md` legitimately references its own `references/hunt-outcome-documenter.md` — those are correct self-references, not stale ones, so both are excluded before checking for hits. Any remaining line means a *different* skill still references one of these two moved files — go back to Task 4 Step 2 or Task 6 Step 2 and fix it.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: add README and complete plugin scaffold"
```

---

## Self-Review

**1. Spec coverage.** Every settled decision from the Spec Summary maps to a task: plugin format → Task 1; separate self-contained repo → the whole plan lives in `D:\threat-intel-hunt-framework`; absorb existing skill → Task 4; full pipeline, 5 skills → Tasks 2, 3, 4, 5, 6; subagent for analysis only → Task 2's `intel-researcher`, no other task adds an agent; master command, no pausing → Task 7; static curated source list → Task 2's `high-reputation-sources.md`; no hooks/no custom tools → no task creates a `hooks/` dir or `.mcp.json`; fixed Markdown output convention → the **Pipeline Output Interfaces** table, referenced by every skill task; local-dev-only → Task 1's `marketplace.json` + Task 8's README install instructions, no CI/versioning added.

**2. Placeholder scan.** No task step says "add appropriate content," "TBD," or "similar to Task N" — every file-writing step contains the file's real, complete content, and every ported-file step names an exact source path plus exact edits rather than "port with any needed changes."

**3. Type/interface consistency.** Checked the five pipeline output docs' section headings against every skill that reads or writes them: `intel-analysis` writes and `intel-report` reads the same 7 headings; `intel-report` writes and `hunt-planner` reads `## Recommended Actions > ### Hunt` and `## MITRE ATT&CK Coverage`; `hunt-planner` writes and `detection-engineer` reads `## Environment Profile` and the Story's `### Detection Logic`/`### Expected Outcomes`; `detection-engineer` writes and `hunt-validator` reads the `## DET-XXX` section 2 (ATT&CK) and section 9 (Validation slot). The slug rule is stated identically (kebab-case, ≤6 words) everywhere it's restated. `plugin.json`'s `skills` array (Task 1) is verified against the actual `skills/` directory contents in Task 8 rather than assumed correct.
