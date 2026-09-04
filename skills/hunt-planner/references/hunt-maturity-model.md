# Maturity and Metrics

**Fits at:** Step 9 (Report & Iterate) for metrics; Step 0 (Environment Context) references the maturity level to set scaffolding depth.
**Purpose:** Say where the program is, and measure whether it works — not whether it is busy.

---

## 1. Hunt program maturity

Adapted from the Hunting Maturity Model (David Bianco / Sqrrl). Assess honestly; most programs overstate by one level.

| Level | Name | Data | Hunting | Test to claim it |
|---|---|---|---|---|
| HMM0 | Initial | Little/no routine collection | Alert-driven only | — |
| HMM1 | Minimal | Some routine collection | IoC-led searching from CTI | You can search historical data against new intel |
| HMM2 | Procedural | Broad routine collection | Executes procedures others published | You run others' hunt procedures repeatably |
| HMM3 | Innovative | Broad collection + quality management | Creates new hunt procedures | Your hunters author original hypotheses and analysis techniques |
| HMM4 | Leading | Broad + managed | Automates successful procedures | Successful hunts are automated into detections as routine |

**Progression rule used by this framework:** you do not advance a level by hunting more. You advance by (a) measuring telemetry visibility (HMM2→3) and (b) closing the hunt→detection→validation loop reliably (HMM3→4).

Pair with a detection-engineering maturity view for the handoff side of the program (see Detection Engineering Maturity Matrix, Kyle Bailey).

---

## 2. Metrics

Split activity from outcome. Report both; lead with outcome.

### Outcome metrics — *is it working?*

| Metric | Definition | Target direction |
|---|---|---|
| **Threats found that automated detection missed** | Confirmed incidents originating from a hunt, not an alert | Headline number |
| **Net-new detections shipped per hunt** | Merged, validated DET-XXX per completed hunt | ≥0.5 sustained |
| **Visibility gaps closed** | Gap tickets remediated / raised, per quarter | Ratio trending up |
| **Validated technique coverage** | Techniques with a passing validation in last 12 months | Growing, and stated as *validated*, not assumed |
| **Detection robustness mix** | Share of shipped detections at tool/TTP level vs. artifact level | Shift upward |
| **Hunt→detection cycle time** | Finding to merged, validated rule | Days, not weeks |

### Activity metrics — *is it running?*

| Metric | Definition |
|---|---|
| Hunt throughput | Completed hunts per quarter, by hunt type (EDA/HBO/TIO/DPO) |
| Hypothesis conversion | Backlog ideas passing the rubric / total submitted |
| Feasibility mix | GO / CONDITIONAL / NO-GO ratio (rising NO-GO = telemetry debt, not team failure) |
| Findings yield | Hunts producing ≥1 typed outcome / total hunts |
| Time to conclusion | Median days from Epic open to report |

**Do not report:** hours spent, queries run, hunts started, records searched. They reward volume and are trivially gamed.

---

## 3. Reporting cadence

| Audience | Cadence | Content |
|---|---|---|
| Hunt team | Per hunt | Full report + typed outcomes |
| SOC / detection engineering | Weekly | New DET-XXX handoffs, validation failures, tuning debt |
| Security leadership | Monthly | Outcome metrics, incidents found, gaps closed |
| Exec / risk | Quarterly | Coverage trend, top 3 residual gaps, one narrative case |

---

## 4. Caveats to state in every report

- Coverage figures derived from DeTT&CT are **visibility-scored**, not proof of detection.
- Clean hunt results are bounded by the stated telemetry caveat (see Telemetry Gap Assessment §3).
- A quarter with zero incidents found is not a failed quarter if gaps closed and detections shipped; state that explicitly before someone else frames it as wasted spend.

---

**References:** Hunting Maturity Model, David Bianco (Sqrrl / ThreatHunting.net) · PEAK Threat Hunting Framework maturity and metrics guidance (Splunk) · Detection Engineering Maturity Matrix, Kyle Bailey · SANS Threat Hunting Survey series (program formalization and effectiveness measurement trends)