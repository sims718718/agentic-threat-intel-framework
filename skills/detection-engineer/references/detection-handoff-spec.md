# Detection Handoff Spec

**Fits at:** Step 8 (Document Outcomes) — required content for any Task of outcome type **Analytics/Detection**.
**Purpose:** A hunt finding is not a detection. This defines the minimum artifact the hunt team hands to detection engineering, so nothing ships as "here's the query I ran."

An ADS-lite: the Palantir Alerting & Detection Strategy fields, trimmed, plus a robustness score.

---

## Handoff template

```markdown
## DET-XXX — [Title]
Source hunt:  HUNT-XXX-SX
Author:       [hunter]   Reviewer: [detection engineer]   Date: [YYYY-MM-DD]

### 1. Goal
[One sentence: what adversary behavior this is intended to catch.]

### 2. ATT&CK categorization
[TXXXX.XXX — Technique — Tactic]

### 3. Strategy abstract
[3–5 sentences, plain English: what data it looks at, how it aggregates or filters,
and what conditions cause it to fire. A responder must understand this without
reading the query.]

### 4. Technical context
[Detail a responder needs and doesn't have: how the logging works, why the field
means what it means, relevant OS/service behavior, naming conventions.]

### 5. Logic
[Sigma rule preferred — portable and reviewable. If the logic cannot be expressed
in Sigma, include the native query plus a note on why.]

### 6. Blind spots and assumptions
- Assumption: [e.g. all in-scope hosts forward 4688 with command line auditing on]
- Blind spot: [what this will not catch — evasions, unlogged paths, scope limits]

### 7. False positives
[Known benign triggers observed during the hunt, with the tuning applied.
"None observed" is only acceptable with the sample size stated.]

### 8. Robustness score
Observable robustness: [ephemeral value → core to the technique]
Event robustness:      [application-layer → kernel/hardware-level telemetry]
Rationale:             [1–2 sentences]
Evasion cost:          [Low | Medium | High — what the adversary changes to break it]

### 9. Validation
Method:   [Atomic Red Team test ID | CALDERA ability | manual procedure]
Result:   [Fired / Did not fire / Fired with delay — date, host, operator]
Evidence: [link to test log / screenshot / ticket]

### 10. Priority and response
Severity:   [Critical | High | Medium | Low | Informational-only]
Response:   [First 3 triage steps for the on-call analyst]
Volume est: [Expected alerts/week based on hunt data]
```

---

## Acceptance gate

Detection engineering **rejects** the handoff if any of these is true:

- [ ] No validation result recorded (section 9)
- [ ] Blind spots section is empty or says "none"
- [ ] False positive volume unknown and unestimated
- [ ] Logic depends on a hash, IP, or domain as the primary condition
- [ ] Robustness rationale absent
- [ ] No response guidance — a detection nobody knows how to triage is an alert-fatigue liability

---

## Robustness guidance

Score every candidate detection on both Summiting the Pyramid axes before promotion:

- **Observable robustness** — is the thing being matched an ephemeral value the adversary sets freely (filename, mutex, user agent), or is it core to how the technique must work regardless of implementation?
- **Event robustness** — is the telemetry produced at the application layer (spoofable, bypassable) or lower in the stack (kernel/sensor-level, harder to evade)?

If both scores are low, the correct outcome is often **not** to ship the detection but to file a Visibility Gap: you are detecting the tool, not the technique, and the rule will die with the next build.

---

## Promotion path

```
Hunt finding → DET-XXX draft → peer review (1 detection engineer)
   → validation execution → tune → merge to detection repo (as-code, CI-tested)
   → 30-day post-deployment review (volume, TP rate, tuning debt)
```

Detections are versioned in the detection repo, not in the hunt ticket. The hunt Task links to the merged rule and closes.

---

**References:** Alerting and Detection Strategy framework, Palantir (https://github.com/palantir/alerting-detection-strategy-framework) · Summiting the Pyramid, Center for Threat-Informed Defense (https://center-for-threat-informed-defense.github.io/summiting-the-pyramid/) · Sigma (https://github.com/SigmaHQ/sigma) · Pyramid of Pain (David Bianco)