---
name: gather
description: "Capture and persist the user's environment context — SIEM/data platform, EDR platform, environment type, industry vertical, log retention, and hunt maturity level — into a shared environment profile any stage of the pipeline can read. Always trigger when a user wants to record their environment/stack details, set up SIEM/EDR context, or run an environment intake before hunting. This is a standalone utility skill for the threat-intel-hunt-framework pipeline — it is not tied to a specific stage number and is not invoked automatically by /run-hunt-pipeline, since its whole purpose is to interview the user."
---

# Gather Environment Context

Capture the user's environment once, in one place, so every stage of the threat-intel-hunt-framework pipeline can reuse it instead of re-asking.

## When to Use

Run this any time — before starting a hunt, mid-pipeline, or fully standalone. It is intentionally not wired into `/run-hunt-pipeline`, since that command runs straight through with no pause for user input, and this skill's entire purpose is to interview the user.

## Step 1: Check for an existing profile

Look for `./threat-hunting/environment-profile.md` in the invoking project. If it exists, load it and show the user the current values — ask only about what's missing or what they want to change, rather than re-asking everything.

## Step 2: Capture (or infer) environment context

If any of this is already known from the conversation, skip those items.

| Context | Why It Matters |
|---------|----------------|
| **SIEM / Data Platform** | Splunk SPL vs. KQL vs. Elastic DSL vs. Chronicle affects every query example |
| **EDR Platform** | CrowdStrike, SentinelOne, Defender for Endpoint — affects telemetry field names |
| **Environment Type** | On-premises, cloud-native (AWS/Azure/GCP), or hybrid |
| **Industry Vertical** | Tailors threat actor relevance (finance, healthcare, energy, manufacturing, etc.) |
| **Approximate Log Retention** | Determines what time windows are actually feasible |
| **Hunt Maturity Level** | Score honestly using the `hunt-planner` skill's `references/hunt-maturity-model.md` rather than a free-text guess — first-time hunters need more scaffolding; experienced teams may prefer a skeleton |

**Express path**: If the user wants to move fast, capture only **SIEM platform** and **environment type** — these are the minimum required to produce useful, non-generic outputs.

## Step 3: Write the profile

Write (or update) `./threat-hunting/environment-profile.md` in the invoking project (create the directory if it doesn't exist) with exactly this section:

```markdown
## Environment Profile

| Context | Value |
|---------|-------|
| SIEM / Data Platform | ... |
| EDR Platform | ... |
| Environment Type | ... |
| Industry Vertical | ... |
| Approximate Log Retention | ... |
| Hunt Maturity Level | ... |
```

Leave any uncaptured field as `Unknown` rather than omitting the row.

## When to ask vs. proceed

- **Ask first** — this skill exists specifically to interview the user; do not fabricate environment details.
- **Proceed and annotate** only for fields left uncaptured via the Express path — mark them `Unknown` and invite the user to fill them in later.
