# Environment Context

**Used by:** `gather` (Step 2) and `hunt-planner` (Step 0).
**Purpose:** The single definition of the six environment contexts, so queries, field names, time windows, and scaffolding are tailored to the user's real stack rather than written generically. This is Step 0 of the Unified Threat Hunting Process.

| Context | Why It Matters |
|---|---|
| **SIEM / Data Platform** | Splunk SPL vs. KQL vs. Elastic DSL vs. Chronicle affects every query example |
| **EDR Platform** | CrowdStrike, SentinelOne, Defender for Endpoint — affects telemetry field names |
| **Environment Type** | On-premises, cloud-native (AWS/Azure/GCP), or hybrid |
| **Industry Vertical** | Tailors threat actor relevance (finance, healthcare, energy, manufacturing, etc.) |
| **Approximate Log Retention** | Determines what time windows are actually feasible |
| **Hunt Maturity Level** | Score honestly using `../../hunt-planner/references/hunt-maturity-model.md` rather than a free-text guess — first-time hunters need more scaffolding; experienced teams may prefer a skeleton |

## Express path

If the user wants to move fast, capture only **SIEM platform** and **environment type**. These are the minimum required to produce useful, non-generic outputs; with less, queries will be generic.

## Unknown

A value that cannot be captured or inferred reads `Unknown`. Never guess a value, and never omit the row.

## Profile location

`./threat-hunting/environment-profile.md`, written by `gather` (its Step 3 holds the `## Environment Profile` table template).
