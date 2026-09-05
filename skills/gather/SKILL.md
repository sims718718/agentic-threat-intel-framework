---
name: gather
description: "Capture and persist the user's environment context — SIEM/data platform, EDR platform, environment type, industry vertical, log retention, and hunt maturity level — into a shared environment profile any stage of the pipeline can read. Always trigger when a user wants to record their environment/stack details, set up SIEM/EDR context, or run an environment intake before hunting. This is a standalone utility skill for the threat-intel-hunt-framework pipeline — it is not tied to a specific stage number, and it also runs automatically as Step 1 of /run-hunt-pipeline in a non-interactive mode (see 'Pipeline mode' below) when no environment profile exists yet."
---

# Gather Environment Context

Capture the user's environment once, in one place, so every stage of the threat-intel-hunt-framework pipeline can reuse it instead of re-asking.

## When to Use

Run this any time — before starting a hunt, mid-pipeline, or fully standalone — to interview the user and record real environment values. It also runs automatically, non-interactively, as Step 1 of `/run-hunt-pipeline` (see "Pipeline mode" below) so the pipeline never has to pause for input. Running this skill standalone afterward always overwrites any `Unknown` placeholders the pipeline mode left behind with real, interviewed values.

## Step 1: Check for an existing profile

Look for `./threat-hunting/environment-profile.md` in the invoking project. If it exists, load it and show the user the current values — ask only about what's missing or what they want to change, rather than re-asking everything.

## Pipeline mode vs. standalone mode

**Standalone mode** (default): triggered directly by the user, or by name outside of `/run-hunt-pipeline`. Follow Steps 1-3 below exactly as written — interview the user, ask about anything missing, and never fabricate values.

**Pipeline mode**: triggered because `/run-hunt-pipeline` invoked this skill as its Step 1. You are told explicitly when this is the case (the invocation will say so). In pipeline mode:

- Still perform Step 1 (check for an existing profile) — if `./threat-hunting/environment-profile.md` already exists, reuse it as-is and skip straight to returning control to the pipeline. Do not modify it, do not ask the user anything, even about "what's missing."
- If no profile exists, do **not** interview the user under any circumstance. Instead:
  - Infer whatever you can for each of the six context fields (SIEM/data platform, EDR platform, environment type, industry vertical, log retention, hunt maturity level) strictly from what's already present in the pipeline's input and conversation so far (e.g., a CTI report that names a cloud provider, a user mentioning "our Splunk instance" earlier in the conversation, an industry named in the input).
  - Leave every field you cannot infer with reasonable confidence as the literal string `Unknown` — do not guess, and do not use the Express path (that's an interactive shortcut; it doesn't apply here since there's no interview at all).
  - Write the profile per Step 3 below exactly as you would in standalone mode, then immediately return control to the pipeline — never pause, never ask a clarifying question, never block.
- Whatever the outcome, mention in your handoff back to the pipeline which fields were inferred vs. left `Unknown`, so this is visible in the pipeline's eventual output/summary, and note that the user can re-run `gather` standalone at any time to replace the `Unknown`s with real values.

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

- **Standalone mode: ask first** — this skill's interactive mode exists specifically to interview the user; do not fabricate environment details when invoked directly. Proceed and annotate only for fields left uncaptured via the Express path — mark them `Unknown` and invite the user to fill them in later.
- **Pipeline mode: never ask, always proceed** — infer what you can from context, mark everything else `Unknown`, and never pause. This mirrors every other stage's "proceed and annotate gaps rather than block" philosophy.
