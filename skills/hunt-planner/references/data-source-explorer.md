# Data Source Explorer

Guide Exploratory Data Analysis (EDA) activities for understanding log sources before and during threat hunt execution. Based on the AIMOD2 DAIKI model, EDA hunts operate at the Data level to answer "what" before progressing to hypothesis-based operations.

## When to Use This Guide

- Hunting against unfamiliar log sources
- Onboarding new data into SIEM/data lake
- Assessing data quality for feasibility assessment
- Building baselines for behavioral detection
- Investigating data gaps or parsing issues
- Preparing for hypothesis-based hunts

## EDA Process Overview

```
1. Data Source Discovery    → What data exists and where?
2. Log Source Profiling     → What does this data contain?
3. Field Analysis           → What fields are available and useful?
4. Data Quality Assessment  → Is the data reliable?
5. Baseline Development     → What is "normal"?
6. Hunt Readiness           → Can we proceed to hypothesis testing?
```

---

## Step 1: Data Source Discovery

### Inventory Questions

| Question | Purpose |
|----------|---------|
| What log sources are ingested? | Identify available telemetry |
| Where is data stored? | SIEM, data lake, raw storage |
| What is the retention period? | Determine analysis window limits |
| Who owns the data source? | Identify SME for questions |
| What collection method is used? | Agent, syslog, API, etc. |

### Discovery Queries

**SIEM Index Inventory (Splunk)**
```spl
| eventcount summarize=false index=* 
| dedup index 
| table index
```

**Source Type Inventory (Splunk)**
```spl
| metadata type=sourcetypes index=*
| table sourcetype totalCount firstTime lastTime
| sort -totalCount
```

**Log Source Volume (Generic)**
```
Group by: log_source, date
Aggregate: count, bytes
Sort by: count descending
```

### Data Source Catalog Template

```markdown
## Data Source: [Name]

### Basic Information
- **Index/Table**: [Location in SIEM/lake]
- **Source Type**: [Sourcetype or category]
- **Collection Method**: [Agent/Syslog/API/etc.]
- **Vendor/Product**: [Origin system]
- **Owner**: [Team responsible]

### Coverage
- **Systems Covered**: [What sends this data]
- **Estimated Coverage**: [X% of target systems]
- **Known Gaps**: [Systems not sending]

### Retention
- **Hot/Searchable**: [X days]
- **Warm/Archive**: [X days]
- **Total Retention**: [X days]

### Volume
- **Daily Events**: [Approximate count]
- **Daily Size**: [GB/TB]
- **Peak Hours**: [When volume highest]

### Documentation
- **Vendor Docs**: [URL]
- **Internal Wiki**: [URL]
- **Schema Reference**: [URL]
```

---

## Step 2: Log Source Profiling

### Profiling Objectives

1. Understand the event types within the source
2. Identify key fields for hunting
3. Determine field population rates
4. Assess parsing quality
5. Map to MITRE ATT&CK data sources

### Event Type Analysis

**Identify Distinct Event Types**
```spl
index=<target> earliest=-7d
| stats count by EventID
| sort -count
| head 50
```

**Event Type Distribution**
```spl
index=<target> earliest=-24h
| stats count by EventType
| eventstats sum(count) as total
| eval percentage=round((count/total)*100,2)
| table EventType count percentage
```

### Log Source Profile Template

```markdown
## Log Source Profile: [Name]

### Event Types

| Event ID/Type | Description | Volume (24h) | Hunt Relevance |
|---------------|-------------|--------------|----------------|
| [ID] | [What it captures] | [Count] | [High/Med/Low] |

### Key Fields

| Field Name | Description | Population Rate | Cardinality |
|------------|-------------|-----------------|-------------|
| [field] | [What it contains] | [X%] | [High/Med/Low] |

### Parsing Status
- **Parser**: [Parser name/version]
- **Extraction Quality**: [Good/Partial/Poor]
- **Known Issues**: [Field extraction problems]

### MITRE Data Source Mapping
| ATT&CK Data Source | Coverage |
|--------------------|----------|
| [Data Source name] | [Full/Partial/None] |
```

---

## Step 3: Field Analysis

### Field Discovery

**List All Fields**
```spl
index=<target> earliest=-1h
| fieldsummary
| table field count distinct_count is_exact
| sort -count
```

**Field Value Samples**
```spl
index=<target> earliest=-1h
| stats values(<field>) as sample_values by <grouping_field>
| head 20
```

### Field Quality Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Population Rate** | % of events with field populated | >95% for key fields |
| **Cardinality** | Number of distinct values | Depends on field type |
| **Consistency** | Format uniformity | 100% for structured fields |
| **Accuracy** | Values match expected format | 100% |

**Population Rate Query**
```spl
index=<target> earliest=-24h
| stats count as total, 
        count(eval(isnotnull(<field>))) as populated
| eval population_rate=round((populated/total)*100,2)
```

**Cardinality Query**
```spl
index=<target> earliest=-24h
| stats dc(<field>) as cardinality, count as total
| eval cardinality_ratio=round((cardinality/total)*100,4)
```

### Field Analysis Template

```markdown
## Field Analysis: [Log Source]

### High-Value Fields for Hunting

| Field | Type | Population | Cardinality | Hunt Use Case |
|-------|------|------------|-------------|---------------|
| user | string | 99.8% | Medium | Account-based hunting |
| src_ip | ip | 95.2% | High | Network correlation |
| process | string | 100% | Medium | Process execution |
| cmdline | string | 87.3% | High | Command analysis |

### Field Relationships

| Parent Field | Child Field | Relationship |
|--------------|-------------|--------------|
| [field1] | [field2] | [one-to-many, etc.] |

### Normalization Status

| Raw Field | Normalized Field | Mapping |
|-----------|------------------|---------|
| [vendor_field] | [common_field] | [transformation] |

### Missing/Sparse Fields

| Field | Expected Use | Actual Population | Impact |
|-------|--------------|-------------------|--------|
| [field] | [hunting need] | [X%] | [what we can't do] |
```

---

## Step 4: Data Quality Assessment

### Quality Dimensions

| Dimension | Question | Assessment Method |
|-----------|----------|-------------------|
| **Completeness** | Is all expected data present? | Compare expected vs actual volume |
| **Timeliness** | Is data arriving on time? | Measure ingestion latency |
| **Accuracy** | Are values correct? | Validate against source |
| **Consistency** | Is format uniform? | Check field patterns |
| **Validity** | Do values make sense? | Range/pattern validation |

### Quality Checks

**Completeness: Event Volume Trend**
```spl
index=<target> earliest=-7d
| timechart span=1h count
| eval expected=<baseline_hourly_count>
| eval deviation=round(((count-expected)/expected)*100,1)
```

**Timeliness: Ingestion Latency**
```spl
index=<target> earliest=-1h
| eval latency=_indextime-_time
| stats avg(latency) as avg_latency, 
        max(latency) as max_latency,
        perc95(latency) as p95_latency
```

**Consistency: Field Format Validation**
```spl
index=<target> earliest=-24h
| rex field=<field> "(?<valid>^expected_pattern$)"
| stats count(eval(isnotnull(valid))) as valid,
        count(eval(isnull(valid))) as invalid
| eval consistency_rate=round((valid/(valid+invalid))*100,2)
```

**Validity: Timestamp Sanity**
```spl
index=<target> earliest=-24h
| where _time > now() OR _time < relative_time(now(), "-30d")
| stats count as future_or_old_events
```

### Data Quality Report Template

```markdown
## Data Quality Report: [Log Source]

**Assessment Date**: [YYYY-MM-DD]
**Assessment Period**: [Time range analyzed]

### Quality Scores

| Dimension | Score | Status | Notes |
|-----------|-------|--------|-------|
| Completeness | [X%] | [Good/Warning/Critical] | [Details] |
| Timeliness | [X sec avg] | [Good/Warning/Critical] | [Details] |
| Accuracy | [X%] | [Good/Warning/Critical] | [Details] |
| Consistency | [X%] | [Good/Warning/Critical] | [Details] |
| Validity | [X%] | [Good/Warning/Critical] | [Details] |

### Issues Identified

| Issue | Severity | Impact on Hunting | Remediation |
|-------|----------|-------------------|-------------|
| [Issue] | [H/M/L] | [What we can't do] | [Fix] |

### Gaps and Outages

| Period | Type | Duration | Cause | Events Lost |
|--------|------|----------|-------|-------------|
| [Dates] | [Gap/Outage] | [Duration] | [Reason] | [Estimate] |

### Recommendation
- [ ] Proceed with hunting (quality sufficient)
- [ ] Proceed with caveats (document limitations)
- [ ] Remediate before hunting (quality insufficient)
```

---

## Step 5: Baseline Development

### Baseline Types

| Type | Purpose | Method |
|------|---------|--------|
| **Volume Baseline** | Detect collection anomalies | Time-series statistics |
| **Behavioral Baseline** | Detect activity anomalies | Entity profiling |
| **Frequency Baseline** | Detect periodic patterns | Interval analysis |
| **Relationship Baseline** | Detect unusual connections | Graph analysis |

### Volume Baseline

**Hourly Volume Statistics**
```spl
index=<target> earliest=-30d
| timechart span=1h count
| stats avg(count) as avg, 
        stdev(count) as stdev,
        min(count) as min,
        max(count) as max
| eval upper_bound=avg+(2*stdev)
| eval lower_bound=avg-(2*stdev)
```

**Day-of-Week Pattern**
```spl
index=<target> earliest=-30d
| eval dow=strftime(_time, "%A")
| stats avg(count) as avg_volume by dow
| sort dow
```

### Behavioral Baseline

**User Activity Profile**
```spl
index=<target> earliest=-30d
| stats dc(dest) as unique_destinations,
        dc(action) as unique_actions,
        count as total_events,
        earliest(_time) as first_seen,
        latest(_time) as last_seen
  by user
| eval activity_days=round((last_seen-first_seen)/86400,0)
| eval daily_avg=round(total_events/activity_days,1)
```

**Process Execution Baseline**
```spl
index=<target> sourcetype=sysmon EventID=1 earliest=-30d
| stats count by Image, User
| eventstats sum(count) as user_total by User
| eval frequency=round((count/user_total)*100,2)
| where frequency < 1
| table User Image count frequency
```

### Baseline Documentation Template

```markdown
## Baseline: [Entity/Behavior Type]

**Baseline Period**: [Start] to [End]
**Data Source**: [Log source]
**Entity**: [What is baselined - user, host, process, etc.]

### Statistical Summary

| Metric | Value | Notes |
|--------|-------|-------|
| Mean | [X] | |
| Median | [X] | |
| Std Dev | [X] | |
| Min | [X] | |
| Max | [X] | |
| P95 | [X] | |
| P99 | [X] | |

### Thresholds

| Threshold Type | Value | Rationale |
|----------------|-------|-----------|
| Upper Bound (warning) | [X] | Mean + 2σ |
| Upper Bound (alert) | [X] | Mean + 3σ |
| Lower Bound (warning) | [X] | Mean - 2σ |
| Lower Bound (alert) | [X] | Mean - 3σ |

### Known Patterns

| Pattern | Description | Frequency |
|---------|-------------|-----------|
| [Pattern] | [Explanation] | [When it occurs] |

### Exclusions

| Exclusion | Reason |
|-----------|--------|
| [Entity/value] | [Why excluded from baseline] |

### Refresh Schedule
- **Frequency**: [Weekly/Monthly]
- **Next Refresh**: [Date]
- **Owner**: [Team/person]
```

---

## Step 6: Hunt Readiness Assessment

### Readiness Checklist

Before proceeding from EDA to hypothesis-based hunting:

| Criterion | Status | Notes |
|-----------|--------|-------|
| Data source documented | ☐ | Catalog complete |
| Event types understood | ☐ | Profile complete |
| Key fields identified | ☐ | Field analysis done |
| Data quality acceptable | ☐ | Quality report reviewed |
| Baselines established | ☐ | If needed for hunt |
| Gaps documented | ☐ | Known limitations recorded |
| SME consulted | ☐ | If questions remain |

### Readiness Levels

| Level | Definition | Proceed? |
|-------|------------|----------|
| **Green** | Full understanding, quality data, baselines ready | Yes |
| **Yellow** | Partial understanding, some quality issues, gaps documented | Yes, with caveats |
| **Red** | Insufficient understanding or critical quality issues | No, more EDA needed |

### Hunt Readiness Statement

```markdown
## Hunt Readiness: [Log Source] for [Hunt Name]

**Assessment Date**: [YYYY-MM-DD]
**Assessor**: [Name]

### Readiness Level: [GREEN/YELLOW/RED]

### Summary
[2-3 sentence summary of readiness state]

### Strengths
- [What we understand well]
- [What data is high quality]

### Limitations
- [Gaps in understanding]
- [Quality issues]
- [Missing fields or coverage]

### Assumptions
- [What we're assuming about the data]
- [Risks if assumptions are wrong]

### Recommendations
- [ ] Proceed to hypothesis testing
- [ ] Conduct additional EDA on [specific area]
- [ ] Remediate [specific issue] before hunting
```

---

## Common Log Source Guides

### Windows Security Events

**Key Event IDs for Hunting**

| Event ID | Description | Hunt Use |
|----------|-------------|----------|
| 4624 | Successful logon | Access analysis, lateral movement |
| 4625 | Failed logon | Brute force, credential attacks |
| 4648 | Explicit credential logon | Pass-the-hash, runas |
| 4672 | Special privileges assigned | Privilege escalation |
| 4688 | Process creation | Execution (if enabled) |
| 4698/4702 | Scheduled task created/updated | Persistence |
| 4720 | User account created | Persistence |
| 4732 | Member added to local group | Privilege escalation |
| 4768 | Kerberos TGT requested | Authentication |
| 4769 | Kerberos service ticket | Lateral movement |
| 4776 | NTLM authentication | Credential validation |
| 5140 | Network share accessed | Lateral movement, data access |
| 5145 | Share object access checked | Detailed share access |

**Key Fields**
- `SubjectUserName`, `TargetUserName` - Accounts involved
- `IpAddress`, `WorkstationName` - Source of activity
- `LogonType` - How authentication occurred
- `ProcessName`, `NewProcessName` - Execution context

### Sysmon Events

**Key Event IDs for Hunting**

| Event ID | Description | Hunt Use |
|----------|-------------|----------|
| 1 | Process creation | Execution, full command line |
| 3 | Network connection | C2, lateral movement |
| 7 | Image loaded | DLL side-loading |
| 8 | CreateRemoteThread | Injection |
| 10 | Process access | Credential dumping (LSASS) |
| 11 | File create | Dropper, webshell |
| 12/13/14 | Registry events | Persistence |
| 15 | File create stream hash | ADS abuse |
| 17/18 | Pipe events | Named pipe C2 |
| 22 | DNS query | C2, exfiltration |
| 23 | File delete | Anti-forensics |
| 25 | Process tampering | Evasion |

**Key Fields**
- `Image`, `OriginalFileName` - Process identity
- `CommandLine`, `ParentCommandLine` - Full execution context
- `ParentImage` - Process lineage
- `Hashes` - File integrity
- `User` - Execution context

### Network/Firewall Logs

**Key Fields**

| Field | Description | Hunt Use |
|-------|-------------|----------|
| `src_ip` | Source address | Origin of connection |
| `dst_ip` | Destination address | Target of connection |
| `src_port` | Source port | Ephemeral or service |
| `dst_port` | Destination port | Service identification |
| `protocol` | TCP/UDP/ICMP | Connection type |
| `action` | Allow/deny/drop | Policy enforcement |
| `bytes_in/out` | Transfer volume | Exfiltration detection |
| `duration` | Connection length | Long-lived connections |
| `application` | L7 identification | Application tunneling |

**Baseline Focus**
- Normal ports per source type
- Expected internal-external ratios
- Typical connection durations
- Volume patterns by time of day

### DNS Logs

**Key Fields**

| Field | Description | Hunt Use |
|-------|-------------|----------|
| `query` | Domain requested | C2, DGA detection |
| `query_type` | A, AAAA, TXT, MX | DNS tunneling |
| `response_code` | NOERROR, NXDOMAIN | Failed lookups |
| `src_ip` | Requesting client | Attribution |
| `answer` | Resolved address | Fast-flux detection |

**Hunting Techniques**
- High entropy domain names (DGA)
- Unusual TXT record queries (tunneling)
- High NXDOMAIN rates (DGA, tunneling)
- Queries to rare TLDs
- High query volume to single domain

### Cloud Audit Logs (AWS CloudTrail Example)

**Key Fields**

| Field | Description | Hunt Use |
|-------|-------------|----------|
| `eventName` | API action | Activity type |
| `eventSource` | AWS service | Target service |
| `userIdentity` | Who performed action | Attribution |
| `sourceIPAddress` | Origin IP | Location analysis |
| `errorCode` | Failure reason | Unauthorized attempts |
| `requestParameters` | Action details | What was attempted |
| `responseElements` | Action results | What succeeded |

**High-Value Events**
- `ConsoleLogin` - User authentication
- `CreateUser`, `CreateAccessKey` - Persistence
- `AuthorizeSecurityGroupIngress` - Network exposure
- `StopLogging` - Defense evasion
- `GetSecretValue` - Credential access

### Proxy/Web Logs

**Key Fields**

| Field | Description | Hunt Use |
|-------|-------------|----------|
| `url` | Full request URL | Malicious destinations |
| `domain` | Target domain | C2, categorization |
| `user_agent` | Client identifier | Beacon patterns |
| `method` | GET/POST/etc. | Data transfer type |
| `status_code` | HTTP response | Success/failure |
| `bytes` | Transfer size | Exfiltration |
| `category` | URL categorization | Uncategorized = suspicious |
| `src_ip` | Client address | Attribution |

**Hunting Techniques**
- Uncategorized domains
- Unusual user agents
- Beaconing patterns (regular intervals)
- Large POST requests (exfiltration)
- Connections to newly registered domains

---

## EDA Query Library

### Universal Exploration Queries

**First Look at Data**
```
# What does this data look like?
SELECT * FROM <source> LIMIT 100

# What are the distinct event types?
SELECT event_type, COUNT(*) as count 
FROM <source> 
GROUP BY event_type 
ORDER BY count DESC
```

**Time Distribution**
```
# When does activity occur?
SELECT DATE_TRUNC('hour', timestamp) as hour, COUNT(*) 
FROM <source> 
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY hour 
ORDER BY hour
```

**Top Talkers**
```
# Who/what generates most events?
SELECT <entity_field>, COUNT(*) as events 
FROM <source> 
WHERE timestamp > NOW() - INTERVAL '24 hours'
GROUP BY <entity_field> 
ORDER BY events DESC 
LIMIT 50
```

**Rare Events**
```
# What happens infrequently?
SELECT <event_field>, COUNT(*) as count 
FROM <source> 
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY <event_field> 
HAVING COUNT(*) < 10
ORDER BY count ASC
```

**Field Cardinality**
```
# How many unique values per field?
SELECT 
  COUNT(DISTINCT field1) as field1_cardinality,
  COUNT(DISTINCT field2) as field2_cardinality,
  COUNT(*) as total_events
FROM <source>
WHERE timestamp > NOW() - INTERVAL '24 hours'
```

**Outlier Detection (Statistical)**
```
# Find values beyond 3 standard deviations
WITH stats AS (
  SELECT 
    AVG(<metric>) as mean,
    STDDEV(<metric>) as stddev
  FROM <source>
  WHERE timestamp > NOW() - INTERVAL '7 days'
)
SELECT * FROM <source>, stats
WHERE <metric> > (mean + 3*stddev)
   OR <metric> < (mean - 3*stddev)
```

---

## Quick Reference: EDA Checklist

```markdown
## EDA Checklist: [Log Source]

### Discovery
- [ ] Log source location identified
- [ ] Retention period documented
- [ ] Collection method understood
- [ ] Data owner contacted

### Profiling
- [ ] Event types enumerated
- [ ] Key events identified for hunting
- [ ] Volume patterns documented

### Field Analysis
- [ ] All fields inventoried
- [ ] High-value fields identified
- [ ] Population rates calculated
- [ ] Cardinality assessed

### Quality
- [ ] Completeness verified
- [ ] Timeliness measured
- [ ] Parsing issues documented
- [ ] Gaps identified

### Baseline
- [ ] Volume baseline established (if needed)
- [ ] Behavioral baseline established (if needed)
- [ ] Thresholds defined

### Readiness
- [ ] Readiness level assigned
- [ ] Limitations documented
- [ ] Hunt can proceed: [YES/NO]
```
