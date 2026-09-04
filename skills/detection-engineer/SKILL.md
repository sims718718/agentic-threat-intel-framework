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
