# Jira Templates for Threat Hunt Planning

Complete field templates for Epics, Stories, and Tasks.

## Epic Template

```
================================================================================
EPIC: [HUNT-YYYY-XXX] [Descriptive Hunt Title]
================================================================================

LABELS: threat-hunt, [hunt-type], [priority]
COMPONENTS: Threat Hunting
SPRINT: [Sprint Name/Number]
STORY POINTS: [Total estimated points]

--------------------------------------------------------------------------------
HYPOTHESIS
--------------------------------------------------------------------------------
[Full SMART hypothesis statement]

We hypothesize that [specific threat/behavior] may be present in [target environment], 
evidenced by [observable indicators] within [data sources]. This can be validated 
by [methodology] within [timeframe].

--------------------------------------------------------------------------------
TRIGGERING EVENT
--------------------------------------------------------------------------------
Type:           [CTI | Incident | Red Team | TTP Coverage | Stakeholder | Vuln Disclosure]
Source:         [Report name, feed, ticket reference]
Date Received:  [YYYY-MM-DD]
Classification: [TLP:CLEAR | TLP:GREEN | TLP:AMBER | TLP:RED]

Relevance to Organization:
[2-3 sentences explaining why this trigger is relevant to business operations, 
crown jewels, or threat landscape]

--------------------------------------------------------------------------------
INITIAL RESEARCH SUMMARY
--------------------------------------------------------------------------------
Internal Sources Reviewed:
- [ ] Previous hunt reports: [List relevant hunts]
- [ ] Architecture documentation: [Diagrams reviewed]
- [ ] Detection coverage: [Current rules/gaps]
- [ ] Asset inventory: [Relevant systems identified]

External Sources Reviewed:
- [ ] MITRE ATT&CK: [Techniques researched]
- [ ] Threat reports: [Vendor/OSINT reports]
- [ ] Sigma rules: [Existing rules identified]
- [ ] Threat actor profiles: [Actors researched]

Key Findings from Research:
1. [Finding 1]
2. [Finding 2]
3. [Finding 3]

--------------------------------------------------------------------------------
FEASIBILITY ASSESSMENT
--------------------------------------------------------------------------------
| Criterion        | Status      | Notes                                    |
|------------------|-------------|------------------------------------------|
| Data Availability| [GO/NO-GO]  | [Details]                                |
| Data Quality     | [GO/NO-GO]  | [Details]                                |
| Team Skillset    | [GO/NO-GO]  | [Details]                                |
| Timeline         | [GO/NO-GO]  | [Estimated: X days execution]            |
| Tooling          | [GO/NO-GO]  | [Details]                                |

OVERALL DECISION: [GO | NO-GO | CONDITIONAL]

Assumptions/Conditions (if applicable):
- [Assumption 1]
- [Assumption 2]

--------------------------------------------------------------------------------
SCOPE DEFINITION
--------------------------------------------------------------------------------
Target Environment:
- [ ] Production servers
- [ ] Workstations/endpoints
- [ ] Cloud infrastructure (AWS/Azure/GCP)
- [ ] Network perimeter
- [ ] DMZ
- [ ] Other: [Specify]

Time Window: [Start Date] to [End Date] ([X] days)

In-Scope Assets:
- [Asset group 1]
- [Asset group 2]

Explicit Exclusions:
- [Exclusion 1 with justification]
- [Exclusion 2 with justification]

--------------------------------------------------------------------------------
OBJECTIVES
--------------------------------------------------------------------------------
Primary Objectives:
1. [Objective 1 - must be achieved to validate/invalidate hypothesis]
2. [Objective 2]

Secondary Objectives:
1. [Objective 1 - value-add if time permits]
2. [Objective 2]

Success Metrics:
- [ ] Hypothesis validated or invalidated with evidence
- [ ] All Stories completed within timeline
- [ ] Findings documented per outcome category
- [ ] Report delivered to stakeholders

--------------------------------------------------------------------------------
MITRE ATT&CK MAPPING
--------------------------------------------------------------------------------
| Technique ID | Technique Name                    | Tactic              |
|--------------|-----------------------------------|---------------------|
| TXXXX        | [Name]                            | [Tactic]            |
| TXXXX.XXX    | [Sub-technique Name]              | [Tactic]            |

--------------------------------------------------------------------------------
DATA SOURCES REQUIRED
--------------------------------------------------------------------------------
| Data Source           | Platform    | Key Fields                | Retention |
|-----------------------|-------------|---------------------------|-----------|
| [Source 1]            | [SIEM/EDR]  | [field1, field2]          | [X days]  |
| [Source 2]            | [SIEM/EDR]  | [field1, field2]          | [X days]  |

--------------------------------------------------------------------------------
REFERENCES
--------------------------------------------------------------------------------
- [Reference 1 - URL or document name]
- [Reference 2 - URL or document name]
- [Reference 3 - URL or document name]

--------------------------------------------------------------------------------
LINKED STORIES
--------------------------------------------------------------------------------
- [HUNT-YYYY-XXX-S1] [Story 1 Title]
- [HUNT-YYYY-XXX-S2] [Story 2 Title]

================================================================================
```

## Story Template

```
================================================================================
STORY: [HUNT-YYYY-XXX-S1] [Investigation Title]
================================================================================

PARENT EPIC: [HUNT-YYYY-XXX]
LABELS: threat-hunt-story, [technique-id]
ASSIGNEE: [Hunter name]
STORY POINTS: [Estimated points]
SPRINT: [Sprint Name/Number]

--------------------------------------------------------------------------------
OBJECTIVE
--------------------------------------------------------------------------------
[Clear statement of what this specific investigation aims to determine]

--------------------------------------------------------------------------------
HYPOTHESIS COMPONENT
--------------------------------------------------------------------------------
This Story tests the following component of the Epic hypothesis:
[Specific aspect being validated - e.g., "Validates whether encoded PowerShell 
commands are being executed by non-administrative users"]

--------------------------------------------------------------------------------
METHODOLOGY
--------------------------------------------------------------------------------
Phase 1: Data Collection
1. [Step 1 - e.g., Query SIEM for target log source]
2. [Step 2 - e.g., Export baseline dataset]
3. [Step 3 - e.g., Validate data completeness]

Phase 2: Analysis
1. [Step 1 - e.g., Apply detection logic]
2. [Step 2 - e.g., Triage results]
3. [Step 3 - e.g., Investigate anomalies]

Phase 3: Validation
1. [Step 1 - e.g., Correlate with additional sources]
2. [Step 2 - e.g., Confirm true/false positives]
3. [Step 3 - e.g., Document findings]

--------------------------------------------------------------------------------
DATA SOURCES
--------------------------------------------------------------------------------
| Source              | Fields Required                      | Query Location   |
|---------------------|--------------------------------------|------------------|
| [Log source]        | [timestamp, user, process, cmdline]  | [SIEM index]     |
| [Log source]        | [timestamp, src_ip, dst_ip, port]    | [SIEM index]     |

--------------------------------------------------------------------------------
DETECTION LOGIC
--------------------------------------------------------------------------------
Primary Query (Pseudocode/SPL/KQL):
```
[Query or detection logic]
```

Sigma Rule (if applicable):
```yaml
title: [Rule Title]
status: [experimental|test|stable]
description: [Description]
logsource:
    product: [product]
    service: [service]
detection:
    selection:
        [field]: [value]
    condition: selection
falsepositives:
    - [Known FP 1]
level: [informational|low|medium|high|critical]
tags:
    - attack.[tactic]
    - attack.[technique_id]
```

--------------------------------------------------------------------------------
EXPECTED OUTCOMES
--------------------------------------------------------------------------------
If Malicious Activity Present:
- [Evidence type 1 - e.g., "Process creation events with encoded commands"]
- [Evidence type 2 - e.g., "Correlation with known C2 infrastructure"]
- [Action: Escalate to IR per incident response plan]

If Hypothesis Invalid:
- [Evidence type 1 - e.g., "No matching events in time window"]
- [Evidence type 2 - e.g., "All matches attributed to legitimate activity"]
- [Action: Document as negative finding, close Story]

--------------------------------------------------------------------------------
ACCEPTANCE CRITERIA
--------------------------------------------------------------------------------
- [ ] Data sources validated and accessible
- [ ] Queries executed across full time window
- [ ] Results triaged (true/false positive determination)
- [ ] Findings documented with evidence
- [ ] Tasks created for outcomes (detection, gap, incident, etc.)

--------------------------------------------------------------------------------
LINKED TASKS (Outcomes)
--------------------------------------------------------------------------------
- [HUNT-YYYY-XXX-T1] [Outcome 1]
- [HUNT-YYYY-XXX-T2] [Outcome 2]

================================================================================
```

## Task Templates (By Outcome Category)

### Task: New Hunt Idea

```
================================================================================
TASK: [HUNT-YYYY-XXX-T1] New Hunt Idea: [Brief Title]
================================================================================

PARENT STORY: [HUNT-YYYY-XXX-S1]
CATEGORY: New Hunt Idea
LABELS: hunt-outcome, new-hunt-idea

--------------------------------------------------------------------------------
DESCRIPTION
--------------------------------------------------------------------------------
During execution of [Parent Story], the following potential hunt opportunity 
was identified:

[Description of the new hypothesis or area to investigate]

--------------------------------------------------------------------------------
RATIONALE
--------------------------------------------------------------------------------
[Why this is worth pursuing - connection to current hunt, observed gaps, etc.]

--------------------------------------------------------------------------------
SUGGESTED APPROACH
--------------------------------------------------------------------------------
- Trigger Type: [CTI | TTP Coverage | Emerging from current hunt]
- Estimated Complexity: [Low | Medium | High]
- Recommended Priority: [P1 | P2 | P3]

--------------------------------------------------------------------------------
ACTION
--------------------------------------------------------------------------------
Add to hunt backlog for future sprint planning.

================================================================================
```

### Task: Analytics/Detection

```
================================================================================
TASK: [HUNT-YYYY-XXX-T2] Detection: [Rule/Dashboard Name]
================================================================================

PARENT STORY: [HUNT-YYYY-XXX-S1]
CATEGORY: Analytics/Detection
LABELS: hunt-outcome, detection-engineering

--------------------------------------------------------------------------------
DESCRIPTION
--------------------------------------------------------------------------------
[Description of the detection opportunity identified]

--------------------------------------------------------------------------------
DETECTION ARTIFACT
--------------------------------------------------------------------------------
Type: [Sigma Rule | SIEM Correlation | Dashboard | Alert]

```yaml
[Detection logic - Sigma, SPL, KQL, etc.]
```

--------------------------------------------------------------------------------
RECOMMENDED ACTION
--------------------------------------------------------------------------------
- [ ] Submit to detection engineering pipeline
- [ ] Assign to: [Detection Engineer]
- [ ] Target deployment: [Date]

================================================================================
```

### Task: Security Incident

```
================================================================================
TASK: [HUNT-YYYY-XXX-T3] Security Incident: [Brief Description]
================================================================================

PARENT STORY: [HUNT-YYYY-XXX-S1]
CATEGORY: Security Incident
LABELS: hunt-outcome, security-incident, [severity]
PRIORITY: [Critical | High | Medium | Low]

--------------------------------------------------------------------------------
DESCRIPTION
--------------------------------------------------------------------------------
[Description of the suspicious/malicious activity identified]

--------------------------------------------------------------------------------
EVIDENCE
--------------------------------------------------------------------------------
- [Evidence item 1 with timestamps]
- [Evidence item 2 with timestamps]
- [Query/screenshot references]

--------------------------------------------------------------------------------
AFFECTED ASSETS
--------------------------------------------------------------------------------
- [Asset 1]
- [Asset 2]

--------------------------------------------------------------------------------
ESCALATION
--------------------------------------------------------------------------------
- Escalated to: [IR Team / SOC]
- Escalation time: [Timestamp]
- IR Ticket: [Reference number]

================================================================================
```

### Task: Visibility Gap

```
================================================================================
TASK: [HUNT-YYYY-XXX-T4] Visibility Gap: [Gap Description]
================================================================================

PARENT STORY: [HUNT-YYYY-XXX-S1]
CATEGORY: Visibility Gap
LABELS: hunt-outcome, visibility-gap

--------------------------------------------------------------------------------
DESCRIPTION
--------------------------------------------------------------------------------
[Description of the missing telemetry or logging gap]

--------------------------------------------------------------------------------
IMPACT
--------------------------------------------------------------------------------
- Hunt Impact: [How this gap affected the current hunt]
- Detection Impact: [What threats cannot be detected due to this gap]
- MITRE Coverage: [Techniques that cannot be detected]

--------------------------------------------------------------------------------
REMEDIATION
--------------------------------------------------------------------------------
Recommended Fix:
- [Technical solution - e.g., enable specific logging, deploy agent]

Owner: [Team responsible for remediation]
Priority: [P1 | P2 | P3]

================================================================================
```

### Task: Security Control Issue

```
================================================================================
TASK: [HUNT-YYYY-XXX-T5] Control Issue: [Issue Description]
================================================================================

PARENT STORY: [HUNT-YYYY-XXX-S1]
CATEGORY: Security Control Issue
LABELS: hunt-outcome, control-issue, [control-domain]

--------------------------------------------------------------------------------
DESCRIPTION
--------------------------------------------------------------------------------
[Description of the security control deficiency identified]

--------------------------------------------------------------------------------
EVIDENCE
--------------------------------------------------------------------------------
- [Evidence of control gap]

--------------------------------------------------------------------------------
RISK ASSESSMENT
--------------------------------------------------------------------------------
- Likelihood: [Low | Medium | High]
- Impact: [Low | Medium | High]
- Risk Rating: [Low | Medium | High | Critical]

--------------------------------------------------------------------------------
RECOMMENDED REMEDIATION
--------------------------------------------------------------------------------
- [Remediation step 1]
- [Remediation step 2]

Owner: [Team responsible]
Target Date: [YYYY-MM-DD]

================================================================================
```

### Task: Written Report

```
================================================================================
TASK: [HUNT-YYYY-XXX-T6] Report: [Hunt Title] Final Report
================================================================================

PARENT STORY: [HUNT-YYYY-XXX-S1] (or link to Epic)
CATEGORY: Written Report
LABELS: hunt-outcome, hunt-report

--------------------------------------------------------------------------------
REPORT LOCATION
--------------------------------------------------------------------------------
[Link to report document or wiki page]

--------------------------------------------------------------------------------
DISTRIBUTION
--------------------------------------------------------------------------------
- Primary Audience: [Stakeholders]
- Distribution Date: [YYYY-MM-DD]
- Classification: [TLP level]

--------------------------------------------------------------------------------
REPORT CONTENTS
--------------------------------------------------------------------------------
- [ ] Executive Summary
- [ ] Hypothesis and Trigger
- [ ] Methodology
- [ ] Findings Summary
- [ ] Metrics (Total Duration, Execution Duration)
- [ ] Recommendations
- [ ] Appendix (queries, evidence)

================================================================================
```
