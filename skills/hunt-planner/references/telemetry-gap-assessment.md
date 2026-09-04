# Telemetry Gap Assessment

**Fits at:** Step 4 (Feasibility Assessment) — this produces the Data Availability and Data Quality inputs to the GO / NO-GO / CONDITIONAL decision.
**Purpose:** Turn "Visibility Gap" from a post-hoc Jira outcome into a *pre-hunt* measurement. Also yields the program's ATT&CK coverage metric as a byproduct.

---

## 1. Map hypothesis → data components

For each ATT&CK technique in the hypothesis, list the required data components (ATT&CK Data Sources v2 model — a data source contains data components, e.g. *Process: Process Creation*).

| ATT&CK | Data component | Log source in our stack | Present? |
|---|---|---|---|
| T1558.004 | Network Traffic: Network Traffic Content | Windows Security 4768/4769 | Y |
| T1550.001 | Application Log: Application Log Content | Entra ID audit | Y |
| … | | | N |

Cross-reference which sensor actually emits the component using **Sensor Mappings to ATT&CK** (Center for Threat-Informed Defense) rather than assuming an EDR covers it.

---

## 2. Score visibility and quality

Score each required component using DeTT&CT's model.

**Visibility (0–5)** — do we see the behavior at all?

| Score | Meaning |
|---|---|
| 0 | No visibility |
| 1 | Minimal — detects only the most obvious case |
| 2 | Partial — significant blind spots |
| 3 | Good — most executions visible |
| 4 | Very good — near-complete |
| 5 | Excellent — all known procedure variants visible |

**Data quality (0–5 per dimension)** — five dimensions:

| Dimension | Question |
|---|---|
| Device completeness | What % of in-scope assets ship this log? |
| Data field completeness | Are the fields the hunt needs actually populated? |
| Timeliness | Ingest lag vs. the hunt's time sensitivity |
| Consistency | Stable schema/parsing across sources |
| Retention | Does retention cover the required lookback? |

---

## 3. Decision rules → Step 4 output

| Condition | Feasibility decision |
|---|---|
| All required components visibility ≥3, retention covers window | **GO** |
| Any required component visibility 0 | **NO-GO** — backlog + raise Visibility Gap task now, don't wait for execution |
| Visibility 1–2, or device completeness <70%, or retention shorter than window | **CONDITIONAL** — proceed with the caveat stated verbatim in the Epic |
| Fields present but parsing inconsistent | **CONDITIONAL** — fix parsing first if it's a one-sprint fix |

**Mandatory caveat wording for CONDITIONAL hunts** (goes in the Epic and the final report):

> Findings are bounded by [component] visibility of [X/5] and device completeness of [Y%] across [asset scope]. A negative result does **not** establish absence outside that coverage.

---

## 4. Gap outputs

Every gap found produces one of:

| Gap type | Action | Owner |
|---|---|---|
| Source not collected | Onboarding request with the ATT&CK justification attached | Log/platform engineering |
| Collected, fields missing | Audit policy / sensor config change | Endpoint or platform team |
| Retention too short | Retention exception or targeted long-term index | SIEM engineering |
| Parsing inconsistent | Parser fix / normalization to OSSEM CDM naming | Detection engineering |

Track these as first-class backlog items — unremediated gaps are the reason the same hunt returns NO-GO twice.

---

## 5. Program-level use

Maintain a standing DeTT&CT data-source YAML for the environment and regenerate the ATT&CK Navigator visibility layer quarterly. Two uses:

1. **Coverage metric** — visibility delta over time is the coverage number in the metrics page (avoid claiming "ATT&CK coverage %" without stating it is visibility-scored, not detection-validated).
2. **Hunt prioritization** — techniques with high actor relevance and low visibility are the strongest NO-GO-to-engineering pipeline in the program.

---

**References:** DeTT&CT (https://github.com/rabobank-cdc/DeTTECT) · MITRE ATT&CK Data Sources (data components model) · Sensor Mappings to ATT&CK, Center for Threat-Informed Defense (https://github.com/center-for-threat-informed-defense/sensor-mappings-to-attack) · OSSEM (https://github.com/OTRF/OSSEM) · MITRE CAR (https://car.mitre.org)