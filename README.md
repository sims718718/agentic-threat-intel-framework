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

Each skill triggers independently — jump into any single stage without running the rest. To run everything end-to-end against one input, use `/run-hunt-pipeline`, e.g.:

```
/run-hunt-pipeline CVE-2026-41205
```

## Output convention

Every stage writes to a fixed path in whatever project you're working in — never inside this plugin's own repo:

| Stage | Output path |
|---|---|
| intel-analysis | `./threat-hunting/intel-analysis/<slug>-analysis.md` |
| intel-report | `./threat-hunting/intel-reports/<slug>-report.md` |
| hunt-planner | `./threat-hunting/hunt-plans/<slug>-hunt-plan.md` |
| detection-engineer | `./threat-hunting/detections/<slug>-detection.md` |
| hunt-validator | `./threat-hunting/validations/<slug>-validation.md` |

See each skill's `SKILL.md` for its exact output structure.

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
