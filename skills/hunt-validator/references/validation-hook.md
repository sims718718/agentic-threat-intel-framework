# Validation Hook

**Fits at:** between Step 8 (Document Outcomes) and Step 9 (Report & Iterate). Mandatory for any Analytics/Detection outcome; optional but recommended for CONDITIONAL hunts.
**Purpose:** Prove the telemetry and the logic actually fire. A hunt that finds nothing is only meaningful if you have demonstrated you *would have* seen it.

---

## When to run

| Situation | Validation required? |
|---|---|
| Hunt produced a candidate detection | **Yes** — blocks handoff |
| Hunt returned clean, feasibility was CONDITIONAL | **Yes** — otherwise the negative result is unsupported |
| Hunt returned clean, feasibility was GO, technique never previously validated | **Yes** — first-time coverage claim |
| Technique validated within the last 90 days, no stack change | No — cite the prior test |

---

## Finding a prior validation (90-day reuse check)

The "technique validated within the last 90 days, no stack change" exemption above requires a qualifying prior test — do not assume one exists just because the technique sounds familiar.

1. Take the ATT&CK technique ID(s) from the current hunt's detection artifact (section 2) or, if none exists yet, the hunt plan's Epic `### MITRE ATT&CK Mapping`.
2. Scan `./threat-hunting/validations/*.md`, skipping the current slug. For each file, read its `## Validation Record` block: the `ATT&CK:` line, the `Date/Time UTC:` stop date, and the `Outcome:` line.
3. A file qualifies only if: the ATT&CK ID matches (same technique or sub-technique), `Outcome:` is `Validated`, and the stop date is within the last 90 days. `[PENDING EXECUTION]` records never qualify.
4. **Stack change isn't recorded in the validation file** — confirm with the user/hunter that the SIEM/EDR platform and relevant telemetry pipeline haven't changed since that date before relying on the exemption. If they can't confirm, treat it as a stack change and require re-validation.
5. If a qualifying match is found, cite it in the validation record's `Follow-up:` field: `Prior validation reused: <prior-slug> — tested <date> — see ./threat-hunting/validations/<prior-slug>-validation.md`. If no `./threat-hunting/validations/` directory exists, it's empty, or nothing matches, validation is required — say so rather than assuming the exemption applies.

## Procedure

1. **Select the test.** Prefer an Atomic Red Team test mapped to the same ATT&CK sub-technique; use CALDERA for multi-step chains. If neither covers the procedure, write the manual steps into the record — do not skip.
2. **Coordinate.** Notify SOC leadership and the on-call channel. Record the change/approval reference. Use a designated test host or account; never an unannounced production execution.
3. **Set a marker.** Note exact start/stop UTC, host, and account so the analyst can bound the search.
4. **Execute** the procedure.
5. **Query blind.** The hunter runs the original hunt query over the test window without knowing the exact timestamps where practical.
6. **Record the result** in the table below.
7. **Clean up** — revert changes, remove artifacts, confirm with the host owner.

---

## Validation record

```
Test ID:        [ART Txxxx.xxx test #N | CALDERA ability | MANUAL-XX]
ATT&CK:         [TXXXX.XXX]
Date/Time UTC:  [start] – [stop]
Host / Account: [target]     Operator: [name]     Approval ref: [ticket]

Telemetry generated:  [Y / N]  — which source, which fields
Detection fired:      [Y / N / Delayed — Xm]
Hunt query matched:   [Y / N]
Time to visibility:   [ingest lag observed]

Outcome:  [Validated | False negative | Partial — describe]
Follow-up: [gap ticket / tuning / none]
```

---

## Interpreting failures

| Result | Meaning | Action |
|---|---|---|
| No telemetry generated | Collection gap — the sensor never saw it | Visibility Gap ticket; hunt result is **not** a clean finding |
| Telemetry present, query missed | Logic error or field-name mismatch | Fix the query, re-run the hunt over the original window |
| Fired but delayed beyond usefulness | Ingest/pipeline latency | Pipeline ticket; note the operational impact on response time |
| Fired as expected | Coverage claim supported | Attach to the handoff, cite in the report |

A **false negative is the most valuable output of this step** — it converts an assumed-covered technique into a measured gap.

---

## Program-level use

- Maintain a rolling validation log keyed by ATT&CK technique with last-tested date.
- Any technique untested for >12 months should be treated as unverified coverage in reporting, not as covered.
- Feed recurring false negatives into the next quarter's hunt prioritization — they are higher-value triggers than most external CTI.

---

**References:** Atomic Red Team (https://github.com/redcanaryco/atomic-red-team) · MITRE CALDERA (https://github.com/mitre/caldera) · Purple Operations hunt type (DPO) in the Unified Threat Hunting Process