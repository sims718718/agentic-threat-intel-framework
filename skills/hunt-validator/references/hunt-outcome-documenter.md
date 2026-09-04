# Hunt Outcome Documenter

Structure and categorize threat hunt findings using the six-category outcome framework adapted from AIMOD2.

## The Six Outcome Categories

Every threat hunt produces outcomes. Even hunts that find "nothing" generate value through visibility gaps, control assessments, or detection opportunities. Document all findings using these six categories:

| Category | Description | Action Owner |
|----------|-------------|--------------|
| **Visibility Gap** | Missing telemetry preventing detection | Security Engineering |
| **Security Control Issue** | Deficiencies in preventive/detective controls | Control Owner |
| **Detection Opportunity** | New detection logic identified | Detection Engineering |
| **Hunt Opportunity** | Future hypothesis to investigate | Threat Hunt Team |
| **Suspicious Security Event** | Activity requiring IR investigation | SOC / IR Team |
| **Threat Intelligence Observable** | New indicators or knowledge | CTI Team |

## Category 1: Visibility Gap

### Definition
A visibility gap exists when required telemetry is missing, incomplete, or inaccessible, preventing the threat hunt team from detecting potential threats.

### Examples
- Log source not ingested into SIEM
- Logging disabled on critical systems
- Retention period shorter than analysis window
- Parsing errors causing field extraction failures
- Network segments not monitored
- Cloud workloads lacking agent deployment
- Encrypted traffic without inspection

### Documentation Template

```markdown
## Visibility Gap: [Brief Title]

### Discovery Context
- Hunt: [Parent Epic/Story reference]
- Date Identified: [YYYY-MM-DD]
- Analyst: [Name]

### Gap Description
[Detailed description of what telemetry is missing]

### Affected Systems/Scope
- Systems: [List affected systems or segments]
- Estimated Coverage Loss: [X% of environment]

### Impact Assessment
**Hunt Impact**: 
[How this gap affected the current hunt - could not validate hypothesis, 
reduced confidence, required alternative approach]

**Detection Impact**:
[What threats cannot be detected due to this gap]

**MITRE Coverage Impact**:
| Technique ID | Technique Name | Detection Capability |
|--------------|----------------|---------------------|
| TXXXX | [Name] | BLIND - No visibility |
| TXXXX | [Name] | DEGRADED - Partial visibility |

### Remediation Recommendation

**Technical Solution**:
[Specific steps to close the gap - enable logging, deploy agent, 
adjust parsing, extend retention]

**Effort Estimate**: [Low | Medium | High]
**Priority**: [P1 | P2 | P3]

### Owner Assignment
- Remediation Owner: [Team/Individual]
- Target Date: [YYYY-MM-DD]
- Tracking Ticket: [Reference]
```

### Severity Classification

| Severity | Criteria |
|----------|----------|
| Critical | Blindness to active attack techniques in crown jewel systems |
| High | No visibility for common attack techniques environment-wide |
| Medium | Partial visibility degrading detection confidence |
| Low | Gap affects edge cases or low-risk systems |

---

## Category 2: Security Control Issue

### Definition
A security control issue is a deficiency in preventive, detective, or corrective controls that increases organizational risk exposure.

### Examples
- Misconfigured firewall rules allowing unexpected traffic
- Disabled endpoint protection features
- Excessive privileged access permissions
- Missing MFA on critical accounts
- Unpatched systems with known vulnerabilities
- Network segmentation failures
- Backup/recovery gaps

### Documentation Template

```markdown
## Security Control Issue: [Brief Title]

### Discovery Context
- Hunt: [Parent Epic/Story reference]
- Date Identified: [YYYY-MM-DD]
- Analyst: [Name]

### Issue Description
[Detailed description of the control deficiency]

### Evidence
[Specific data, queries, or observations that revealed the issue]

### Affected Assets
- Systems: [List]
- Users/Accounts: [List if applicable]
- Data: [Classification if applicable]

### Risk Assessment

**Threat Scenario**:
[How an attacker could exploit this control gap]

**Likelihood**: [Low | Medium | High]
- Justification: [Why this likelihood rating]

**Impact**: [Low | Medium | High]  
- Justification: [What damage could result]

**Risk Rating**: [Low | Medium | High | Critical]

**MITRE Mapping**:
| Technique ID | Technique Name | Exploitation Method |
|--------------|----------------|---------------------|
| TXXXX | [Name] | [How gap enables technique] |

### Remediation Recommendation

**Immediate Actions** (if critical):
1. [Action 1]
2. [Action 2]

**Long-term Remediation**:
[Sustainable fix for the control gap]

**Compensating Controls** (if remediation delayed):
[Temporary measures to reduce risk]

### Owner Assignment
- Control Owner: [Team/Individual]
- Remediation Owner: [Team/Individual]
- Target Date: [YYYY-MM-DD]
- Tracking Ticket: [Reference]
```

---

## Category 3: Detection Opportunity

### Definition
A detection opportunity is a newly identified method for detecting malicious activity that should be operationalized as a rule, alert, dashboard, or analytic.

### Examples
- Sigma rule for observed technique
- SIEM correlation rule
- EDR custom detection
- Behavioral baseline with alerting threshold
- Dashboard for ongoing monitoring
- Threat hunting query for scheduled execution

### Documentation Template

```markdown
## Detection Opportunity: [Detection Name]

### Discovery Context
- Hunt: [Parent Epic/Story reference]
- Date Identified: [YYYY-MM-DD]
- Analyst: [Name]

### Detection Description
[What malicious activity this detection identifies]

### MITRE Coverage
| Technique ID | Technique Name | Tactic |
|--------------|----------------|--------|
| TXXXX | [Name] | [Tactic] |

### Detection Artifact

**Type**: [Sigma Rule | SIEM Correlation | EDR Detection | Dashboard | Scheduled Query]

**Logic**:
```yaml
# Include Sigma rule or detection pseudocode
# Sigma format guidance lives in the detection-engineer skill's sigma-rule-builder.md reference
```

**Data Sources Required**:
| Source | Fields | Platform |
|--------|--------|----------|
| [Source] | [Fields] | [SIEM/EDR] |

### Validation Results

**True Positive Rate**: [X%] based on [sample size]
**False Positive Rate**: [X%] based on [sample size]

**Known False Positives**:
- [FP scenario 1]
- [FP scenario 2]

**Tuning Applied**:
[Filters or thresholds added to reduce FP]

### Operationalization Plan

**Detection Tier**: 
- [ ] Tier 1 - Automated alert to SOC
- [ ] Tier 2 - Scheduled hunt query
- [ ] Tier 3 - Dashboard for periodic review

**Alert Priority**: [Critical | High | Medium | Low | Informational]

**Response Playbook**: [Link if exists, or "To be developed"]

### Owner Assignment
- Detection Engineering Owner: [Team/Individual]
- Target Deployment: [YYYY-MM-DD]
- Tracking Ticket: [Reference]
```

### Detection Maturity Levels

| Level | Description | Maintenance |
|-------|-------------|-------------|
| Experimental | Newly developed, limited testing | Weekly review |
| Test | Validated in test environment | Bi-weekly review |
| Stable | Production-deployed, tuned | Monthly review |
| Deprecated | Superseded or no longer relevant | Remove |

---

## Category 4: Hunt Opportunity

### Definition
A hunt opportunity is a newly identified hypothesis or investigation area discovered during the current hunt that warrants future exploration.

### Examples
- Adjacent technique not covered by current hypothesis
- Anomaly requiring deeper investigation in future sprint
- New threat actor TTP relevant to environment
- Data source discovered that enables new hunt types
- Pattern observed that could indicate different threat

### Documentation Template

```markdown
## Hunt Opportunity: [Brief Title]

### Discovery Context
- Parent Hunt: [Epic/Story reference]
- Date Identified: [YYYY-MM-DD]
- Analyst: [Name]

### Opportunity Description
[What was observed that suggests a new hunt is warranted]

### Proposed Hypothesis
[Draft SMART hypothesis - will be refined during planning]

### Triggering Observation
[Specific finding from current hunt that led to this opportunity]

### Relevance Assessment

**Threat Likelihood**: [Low | Medium | High]
**Business Impact**: [Low | Medium | High]
**Detection Gap**: [Yes | No | Partial]

### Preliminary Scoping

**Estimated Complexity**: [Low | Medium | High]
**Data Sources Likely Needed**: [List]
**Skills Required**: [List]

### Recommended Priority

**Priority**: [P1 | P2 | P3 | P4]

**Justification**:
[Why this priority level]

**Recommended Sprint**: [Sprint name/number or "Backlog"]

### Owner Assignment
- Backlog Owner: [Hunt Lead]
- Tracking Ticket: [Reference]
```

---

## Category 5: Suspicious Security Event

### Definition
A suspicious security event (SEOI - Security Event of Interest) is activity identified during the hunt that may indicate active compromise or policy violation requiring incident response investigation.

### Examples
- Indicators matching known threat actor TTPs
- Unauthorized access to sensitive systems
- Data exfiltration indicators
- Malware artifacts discovered
- Credential compromise evidence
- Policy violations with security implications

### Documentation Template

```markdown
## Suspicious Security Event: [Brief Title]

### IMMEDIATE ACTIONS
**Escalation Status**: [Escalated | Pending | Under Review]
**IR Ticket**: [Reference number]
**Escalation Time**: [YYYY-MM-DD HH:MM UTC]

### Discovery Context
- Hunt: [Parent Epic/Story reference]
- Date/Time Identified: [YYYY-MM-DD HH:MM UTC]
- Analyst: [Name]

### Event Summary
[Concise description of suspicious activity - who, what, when, where]

### Detailed Findings

**Timeline**:
| Timestamp (UTC) | Event | Source |
|-----------------|-------|--------|
| [Time] | [Event description] | [Log source] |

**Affected Assets**:
- Hostnames: [List]
- IP Addresses: [List]
- User Accounts: [List]

**Indicators Observed**:
| Indicator Type | Value | Context |
|----------------|-------|---------|
| [IP/Hash/Domain/etc.] | [Value] | [Where observed] |

### Evidence Preservation

**Artifacts Collected**:
- [ ] Log exports: [Location]
- [ ] Memory captures: [Location]
- [ ] Disk images: [Location]
- [ ] Network captures: [Location]
- [ ] Screenshots: [Location]

**Chain of Custody**: [Reference to evidence handling doc]

### Initial Assessment

**Confidence Level**: [Low | Medium | High]
**Potential Impact**: [Low | Medium | High | Critical]

**Preliminary Classification**:
- [ ] True Positive - Confirmed malicious
- [ ] Likely True Positive - High confidence
- [ ] Requires Investigation - Uncertain
- [ ] Likely False Positive - Low confidence
- [ ] False Positive - Confirmed benign

**MITRE Mapping (if applicable)**:
| Technique ID | Technique Name | Observed Evidence |
|--------------|----------------|-------------------|
| TXXXX | [Name] | [What was seen] |

### Recommended Response

**Immediate**:
- [ ] Isolate affected systems
- [ ] Disable compromised accounts
- [ ] Block indicators at perimeter
- [ ] Preserve additional evidence

**Investigation**:
[Recommended next steps for IR team]

### Escalation Path
- Initial Escalation To: [SOC | IR Team | Management]
- Secondary Escalation: [CISO | Legal | etc.]
- Communication Plan: [Internal | External notification requirements]
```

### Escalation Criteria

| Severity | Criteria | Response Time |
|----------|----------|---------------|
| Critical | Active compromise of crown jewels, data exfiltration in progress | Immediate |
| High | Confirmed malware, lateral movement, credential compromise | < 1 hour |
| Medium | Suspicious activity requiring investigation | < 4 hours |
| Low | Policy violation, minor anomaly | < 24 hours |

---

## Category 6: Threat Intelligence Observable

### Definition
A threat intelligence observable is new knowledge, indicators, or context gained during the hunt that expands organizational understanding of threats and should be shared with CTI functions.

### Examples
- New indicators of compromise (IoCs)
- Threat actor TTP refinements
- Infrastructure patterns observed
- Malware behavior characteristics
- Campaign timing or targeting patterns
- Relationships between entities

### Documentation Template

```markdown
## Threat Intelligence Observable: [Brief Title]

### Discovery Context
- Hunt: [Parent Epic/Story reference]
- Date Identified: [YYYY-MM-DD]
- Analyst: [Name]

### Observable Type
- [ ] Indicator of Compromise (IoC)
- [ ] Tactic/Technique/Procedure (TTP)
- [ ] Threat Actor Attribution
- [ ] Campaign Pattern
- [ ] Infrastructure Mapping
- [ ] Malware Behavior
- [ ] Other: [Specify]

### Observable Details

**For IoCs**:
| Type | Value | First Seen | Last Seen | Confidence |
|------|-------|------------|-----------|------------|
| [IP/Domain/Hash/etc.] | [Value] | [Date] | [Date] | [Low/Med/High] |

**For TTPs**:
| MITRE ID | Technique | Observed Variation |
|----------|-----------|-------------------|
| TXXXX | [Name] | [How it differed from standard] |

**For Attribution**:
- Suspected Actor: [Name/Designation]
- Confidence: [Low | Medium | High]
- Supporting Evidence: [What links to this actor]

### Context and Analysis

**Observation Narrative**:
[Detailed explanation of what was discovered and its significance]

**Relationship to Known Threats**:
[How this connects to existing intelligence]

**Environmental Context**:
[Why this was observed in your environment - targeting, opportunity, etc.]

### Intelligence Value Assessment

**Novelty**: [Known | Partially Known | Novel]
**Actionability**: [Immediate | Near-term | Strategic]
**Shareability**: [Internal Only | Sector Sharing | Public]

### Recommended Actions

**Internal**:
- [ ] Add to internal TIP
- [ ] Update detection rules
- [ ] Brief relevant teams

**External Sharing** (if applicable):
- [ ] Share with ISAC
- [ ] Submit to threat feed
- [ ] Coordinate with law enforcement
- [ ] Publish advisory

### Owner Assignment
- CTI Owner: [Team/Individual]
- TIP Update: [Reference]
- Sharing Approval: [If required]
```

---

## Outcome Documentation Workflow

### During Hunt Execution

1. **Capture in Real-Time**: Document findings as discovered, not after
2. **Categorize Immediately**: Assign to one of six categories
3. **Preserve Evidence**: Save queries, screenshots, data exports
4. **Flag Urgent Items**: Escalate SEOIs immediately, don't wait for hunt completion

### Post-Hunt Processing

1. **Review All Findings**: Ensure nothing was missed
2. **Validate Categories**: Confirm correct categorization
3. **Complete Templates**: Fill in all required fields
4. **Assign Owners**: Ensure every finding has an accountable party
5. **Create Tickets**: Generate tracking tickets in appropriate systems
6. **Link to Epic**: Associate all Tasks with parent Hunt Epic

### Handoff Requirements

| Category | Handoff To | Required Information |
|----------|------------|---------------------|
| Visibility Gap | Security Engineering | Gap details, impact, remediation steps |
| Control Issue | Control Owner | Risk assessment, remediation recommendation |
| Detection Opportunity | Detection Engineering | Complete detection logic, validation data |
| Hunt Opportunity | Hunt Backlog | Draft hypothesis, preliminary scoping |
| Suspicious Event | IR Team | Evidence, timeline, affected assets |
| Intel Observable | CTI Team | Observable details, context, sharing recommendation |

---

## Metrics from Outcomes

Track these metrics to measure hunt program value:

### Quantity Metrics
- Total outcomes per hunt
- Outcomes by category
- Outcomes by severity/priority

### Quality Metrics
- Time from identification to remediation (gaps, controls)
- Detection opportunity deployment rate
- True positive rate for escalated events
- Intel observables shared externally

### Value Metrics
- Visibility gaps closed (improved coverage %)
- Controls strengthened (risk reduction)
- Detections deployed (new coverage)
- Incidents prevented/detected early
- Mean time to detect improvement

### Reporting Format

```markdown
## Hunt Outcome Summary: [Hunt Name]

**Hunt Period**: [Start] to [End]
**Execution Duration**: [X days]

### Outcomes by Category

| Category | Count | Critical/High | Medium | Low |
|----------|-------|---------------|--------|-----|
| Visibility Gap | X | X | X | X |
| Control Issue | X | X | X | X |
| Detection Opportunity | X | X | X | X |
| Hunt Opportunity | X | - | - | - |
| Suspicious Event | X | X | X | X |
| Intel Observable | X | - | - | - |
| **Total** | **X** | **X** | **X** | **X** |

### Key Findings
1. [Most significant finding]
2. [Second most significant]
3. [Third most significant]

### Immediate Actions Taken
- [Action 1]
- [Action 2]

### Follow-up Required
- [Item 1 - Owner - Due Date]
- [Item 2 - Owner - Due Date]
```
