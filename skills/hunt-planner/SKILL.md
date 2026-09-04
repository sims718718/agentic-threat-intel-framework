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
