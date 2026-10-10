# Initial Assessment Checklist

**Fits at:** `hunt-planner` Step 3 (Initial Assessment).
**UTH step:** Initial Assessment: previous hunts and lessons learned, known-good behavior (which becomes the exclusion list), and RFIs to trusted external organisations.
**Where findings go:** the Epic's existing `### Initial Research`; known-good candidates also go in the Scope `Exclusions` line. No new field is added to the hunt plan.

## 1. Prior-hunt check

Scan `./threat-hunting/hunt-logs/` and `./threat-hunting/hunt-reports/` for hunts that touched the same ATT&CK techniques or data sources. Skip the current slug and any log whose `Results status` is `PENDING EXECUTION`; they hold no results. Reports and logs do not carry the technique list, so match through each prior slug's `./threat-hunting/hunt-plans/<prior-slug>-hunt-plan.md` Epic `### MITRE ATT&CK Mapping`.

For each match, record one line in `Initial Research`:

```
Prior hunt: <prior-slug> — executed <date, or Unknown> — verdict <Supported | Refuted | Inconclusive> — coverage <Confirmed | Unconfirmed> — <note>
```

| Prior hunt | Note to record |
|---|---|
| `Refuted`, same technique, within 90 days, no stack change | "likely duplicate: consider extending scope or window instead of repeating" |
| `Inconclusive` for coverage reasons | The telemetry fix it needed, so this plan does not repeat the gap |
| `Supported` or an `Undetermined` hit | Link to the follow-up; reuse its triage notes |

A "likely duplicate" is an annotation only. The plan is still produced; the hunter decides.

If nothing matches, record `None found (no prior hunts in ./threat-hunting)`.

## 2. Known-good seeding

Copy entries from matching prior logs' `## Known-Good / Exclusion List` (only entries whose `Confirmed by` holds a real person or team, never `[PENDING EXECUTION]`) into `Initial Research`, and list them on the Scope `Exclusions` line, each marked `from <slug>, reconfirm`. They are candidates, never approved exclusions: do not describe them as excluded from the hunt until the owner reconfirms, because an unconfirmed exclusion can hide a real finding.

## 3. RFIs

When open-source research cannot answer a question and a trusted external organisation is available (sector ISAC, peer, vendor), list the RFI in `Initial Research` as `RFI: <recipient> — <the question>`. Do not send anything; the framework only records it.

## Mode behavior

| Mode | Behavior |
|---|---|
| Standalone | Ask once whether prior hunts are kept outside `./threat-hunting/` (for example Jira or Confluence); record the answer. Then run checks 1-3 |
| Pipeline / non-interactive | Run checks 1-3 on what is on disk, annotate gaps, never ask |
| Express Mode | Run check 1 as a single line only |
