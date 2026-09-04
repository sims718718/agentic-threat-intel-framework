# Hypothesis Quality Rubric

**Fits at:** Step 2 (Develop Hypothesis) — gate before Step 4 Feasibility.
**Purpose:** SMART governs the *goal*. ABLE governs *where to look*. This rubric forces both, then scores the result so weak hypotheses go back to the backlog instead of consuming a sprint.

---

## 1. Hypothesis Record

```
ID:                 HUNT-XXX
Hypothesis (SMART): We hypothesize that [BEHAVIOR] may be present in [SCOPE],
                    evidenced by [OBSERVABLES] in [DATA SOURCES], validated by
                    [METHOD] within [TIMEFRAME].

ABLE decomposition
  Actor:            [Named actor, actor class, or "any adversary" — optional field]
  Behavior:         [The specific action being hunted — required]
  Location:         [Where in the environment it would appear — required]
  Evidence:         [The artifact/telemetry that proves it — required]

ATT&CK:             [TXXXX.XXX — Technique — Tactic]  (multiple allowed)
Pyramid level:      [TTP | Tool | Network/Host Artifact | Domain | IP | Hash]
Data components:    [ATT&CK data source: component — one line per requirement]
Expected malicious: [What a true positive looks like]
Expected benign:    [What normal looks like — if you can't state this, you can't hunt it]
Disprovable:        [Y/N — what result would falsify this?]
Priority:           [Crown-jewel exposure / actor relevance / recency]
```

> `Behavior`, `Location`, and `Evidence` are mandatory. `Actor` may be empty — most good hunts are actor-agnostic.

---

## 2. Scoring

Score 1–3 on each dimension. **Threshold: ≥10 total, with no dimension scoring 1.**

| Dimension | 1 | 2 | 3 |
|---|---|---|---|
| **Specificity** | Names a tool or category ("hunt for Cobalt Strike") | Names a technique but not the observable | Names the observable behavior and the field-level evidence |
| **Testability** | No stated query path | Query path exists, output volume unknown | Query path defined; expected result volume estimated |
| **Falsifiability** | Cannot be disproven ("look for anomalies") | Absence is ambiguous | A clean result meaningfully reduces risk |
| **Relevance** | Generic threat | Plausible for the vertical | Tied to a trigger + crown-jewel asset or a known gap |
| **Pyramid level** | Hash/IP only | Domain / host artifact | Tool or TTP level |

**Routing**
- **≥10, no 1s** → proceed to Step 4 Feasibility.
- **7–9** → rewrite once. Most failures are Specificity — push the hypothesis down to a field-level observable.
- **≤6** → back to the hunt-idea backlog with the reason recorded.
- **Any dimension = 1** → blocked regardless of total.

---

## 3. Common failure patterns

| Anti-pattern | Fix |
|---|---|
| "Hunt for [actor name]" | Decompose to 2–4 behaviors from the CTI TTP table; one hypothesis each |
| "Look for anomalous PowerShell" | Define anomalous: which parent, which flags, which user population |
| Benign baseline unstated | Run the baseline first as an EDA hunt, then re-file the hypothesis |
| Hash/IP-level evidence | Re-anchor one level up the Pyramid; IoCs are a matching job, not a hunt |
| Non-disprovable | Add the negative criterion: "no execution matching X across 90 days of Y" |

---

## 4. Worked example

```
ID:                 HUNT-051
Hypothesis:         We hypothesize that an adversary is abusing OAuth application
                    consent to maintain access to M365 mailboxes, evidenced by
                    newly consented third-party apps holding Mail.Read /
                    Mail.ReadWrite granted by non-admin users, in Entra ID audit
                    logs, validated by enumerating consent grants over 90 days.

  Actor:            (unspecified — behavior is broadly used)
  Behavior:         Illicit consent grant to an attacker-controlled app
  Location:         Entra ID tenant / M365 mailboxes
  Evidence:         "Consent to application" audit events + granted mail scopes

ATT&CK:             T1550.001 (Application Access Token) / T1098.003
Pyramid level:      TTP
Data components:    Cloud audit logs: user account modification; application logs
Expected malicious: Consent to an app with no publisher verification, granted by a
                    single user, mail scopes, first-seen app ID
Expected benign:    Consent to org-approved apps already present in the app inventory
Disprovable:        Y — all grants in 90d resolve to inventoried, verified publishers
Priority:           High — identity is primary access vector; exec mailboxes in scope

Score: Specificity 3 · Testability 3 · Falsifiability 3 · Relevance 3 · Pyramid 3 = 15 → GO
```

---

**References:** SMART criteria (Unified Threat Hunting Process Step 2) · ABLE from the PEAK Threat Hunting Framework (Splunk) · Pyramid of Pain (David Bianco) · hypothesis backlog feeds — HEARTH (https://github.com/THORCollective/HEARTH)