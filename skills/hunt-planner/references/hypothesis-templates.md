# Hypothesis Framework

Guidance for developing rigorous, testable threat hunting hypotheses.

## SMART Hypothesis Criteria

Every hypothesis must satisfy all five criteria:

### Specific
- Names the exact threat, technique, or behavior being investigated
- Identifies specific data sources and observables
- Avoids vague language ("suspicious activity", "potential threats")

**Bad**: "Attackers may be in our network"  
**Good**: "APT33 may be conducting credential harvesting via spear-phishing, evidenced by anomalous email attachment execution followed by LSASS memory access"

### Measurable
- Defines what evidence would prove or disprove the hypothesis
- Specifies quantifiable thresholds where applicable
- Establishes clear acceptance criteria

**Bad**: "We'll look for malicious PowerShell"  
**Good**: "We will identify PowerShell executions with Base64-encoded commands exceeding 500 characters, targeting >95% coverage of endpoint telemetry"

### Achievable
- Data sources exist and are accessible
- Team has skills to execute the analysis
- Scope is realistic given resources

**Bad**: "Analyze all network traffic for the past year for C2 beaconing"  
**Good**: "Analyze DNS query logs for the past 30 days to identify beaconing patterns using frequency analysis on endpoints in the finance segment"

### Relevant
- Aligns with organizational risk priorities
- Addresses realistic threat scenarios for the industry
- Supports business objectives or regulatory requirements

**Bad**: "Hunt for nation-state APT because it sounds interesting"  
**Good**: "Hunt for APT10 techniques given our healthcare vertical and recent FBI advisory on targeted campaigns"

### Time-bound
- Has defined start and end dates
- Fits within sprint/planning cycle
- Includes checkpoints for progress assessment

**Bad**: "We'll work on this until we find something"  
**Good**: "Execute from 2024-01-15 to 2024-01-22, with daily standups and final report by 2024-01-24"

## Hypothesis Templates

### Template 1: Threat Actor Focused

```
We hypothesize that [THREAT ACTOR] may be targeting our organization due to 
[MOTIVATION/INDUSTRY ALIGNMENT], potentially using [KNOWN TTPS] as evidenced 
by [SPECIFIC OBSERVABLES] in [DATA SOURCES]. We will validate this by 
[METHODOLOGY] within [TIMEFRAME].
```

**Example**:
```
We hypothesize that APT33 (Elfin) may be targeting our organization due to 
our petrochemical industry presence, potentially using spear-phishing with 
malicious attachments (T1566.001) followed by credential dumping (T1003), 
as evidenced by anomalous Office document child processes and LSASS access 
events in Sysmon and EDR telemetry. We will validate this by analyzing 
endpoint logs for the past 45 days within a 5-day execution window.
```

### Template 2: Technique/TTP Focused

```
We hypothesize that [TECHNIQUE NAME] ([MITRE ID]) may be occurring in our 
environment, specifically targeting [ASSETS/SYSTEMS], observable through 
[INDICATORS] in [DATA SOURCES]. We will test this by [METHODOLOGY] over 
[TIME WINDOW] within [EXECUTION TIMEFRAME].
```

**Example**:
```
We hypothesize that credential dumping via LSASS memory access (T1003.001) 
may be occurring in our environment, specifically targeting domain-joined 
workstations, observable through process access events to lsass.exe with 
PROCESS_VM_READ permissions in Sysmon Event ID 10. We will test this by 
querying all workstation Sysmon logs for the past 30 days, baseline 
legitimate tooling, and investigate anomalies within a 3-day execution window.
```

### Template 3: Behavioral/Anomaly Focused

```
We hypothesize that anomalous [BEHAVIOR TYPE] may indicate [THREAT TYPE], 
detectable by [DEVIATION FROM BASELINE] in [DATA SOURCES]. We will establish 
baseline from [BASELINE PERIOD] and identify deviations during [ANALYSIS WINDOW] 
within [EXECUTION TIMEFRAME].
```

**Example**:
```
We hypothesize that anomalous administrative logon patterns may indicate 
lateral movement or compromised credentials, detectable by deviations from 
normal logon times, source IPs, and target systems in Windows Security Event 
Logs (4624/4672). We will establish baseline from 90-day historical data and 
identify deviations in the past 14 days within a 4-day execution window.
```

### Template 4: Intelligence-Driven

```
Based on [CTI SOURCE] dated [DATE] regarding [THREAT/CAMPAIGN], we hypothesize 
that our environment may contain [INDICATORS/BEHAVIORS] targeting [ASSETS]. 
We will validate by [METHODOLOGY] using [DATA SOURCES] within [TIMEFRAME].
```

**Example**:
```
Based on CISA Alert AA23-215A dated August 2023 regarding Citrix NetScaler 
exploitation (CVE-2023-3519), we hypothesize that our environment may contain 
webshells or unauthorized access to our three internet-facing NetScaler 
appliances. We will validate by analyzing NetScaler access logs, HTTP request 
patterns, and post-exploitation indicators (scheduled tasks, new local accounts) 
within a 2-day execution window.
```

### Template 5: Express / Rapid (Time-Constrained)

Use when you need a workable hypothesis in under 2 minutes — skeleton only, to be fleshed out before execution.

```
[THREAT/TTP] ([MITRE ID if known]) may be present in [ENVIRONMENT SEGMENT], 
detectable via [1-2 DATA SOURCES] within [TIMEFRAME].
```

**Example**:
```
LSASS credential dumping (T1003.001) may be occurring on domain-joined 
workstations, detectable via Sysmon Event ID 10 logs within the past 14 days.
```

> ⚠️ **EXPRESS** — upgrade to a full SMART hypothesis template before hunt execution. Missing: measurability criteria, methodology detail, achievability validation, and organizational relevance justification.

## Hypothesis Quality Checklist

Before proceeding to hunt planning, verify:

| Criterion | Question | ☐ |
|-----------|----------|---|
| Specific | Does the hypothesis name exact techniques, actors, or behaviors? | |
| Specific | Are data sources and observables explicitly identified? | |
| Measurable | Is there clear criteria for proving/disproving the hypothesis? | |
| Measurable | Can progress be tracked quantitatively? | |
| Achievable | Do required data sources exist and are they accessible? | |
| Achievable | Does the team have skills for the required analysis? | |
| Relevant | Does this align with organizational risk priorities? | |
| Relevant | Is the threat realistic for our industry/environment? | |
| Time-bound | Is there a defined execution window? | |
| Time-bound | Is the deadline realistic for the scope? | |

**Minimum passing score**: All 10 checkboxes must be marked.

## Competing Hypotheses Method

For complex hunts or ambiguous triggers, develop multiple hypotheses and systematically evaluate them.

### Process (Adapted from Heuer's Analysis of Competing Hypotheses)

**Step 1: Enumerate Hypotheses**
List all reasonable explanations for the observed trigger or concern. Include at least one "null hypothesis" (benign explanation).

**Step 2: Gather Evidence**
Collect evidence from initial research that could support or refute each hypothesis.

**Step 3: Build Comparison Matrix**
| Evidence | H1: APT Actor | H2: Insider Threat | H3: Benign Activity |
|----------|---------------|--------------------|--------------------|
| Evidence A | Supports (++) | Neutral (0) | Contradicts (--) |
| Evidence B | Neutral (0) | Supports (+) | Supports (+) |
| Evidence C | Supports (+) | Supports (+) | Contradicts (-) |

**Step 4: Eliminate Low-Value Evidence**
Remove evidence that supports all hypotheses equally (provides no differentiation).

**Step 5: Rank Hypotheses**
Score each hypothesis based on supporting/contradicting evidence weight.

**Step 6: Assess Sensitivity**
Identify which hypotheses depend on limited evidence. Flag if key evidence could be incorrect.

**Step 7: Document and Select**
Document the comparison and select the most supported hypothesis for hunting.

### When to Use Competing Hypotheses

- Ambiguous triggering events with multiple interpretations
- High-stakes hunts where wrong focus has significant cost
- When initial research reveals conflicting information
- Complex scenarios involving multiple potential actors or techniques

### Output

After completing the competing hypotheses analysis, document:

```markdown
## Competing Hypotheses Analysis

### Hypotheses Evaluated
1. H1: [Description]
2. H2: [Description]
3. H3: [Description] (null/benign)

### Evidence Matrix
[Include matrix from Step 3]

### Selected Hypothesis
[Which hypothesis is being pursued and why]

### Confidence Level
[High | Medium | Low] - based on evidence strength

### Alternative Hypotheses to Monitor
[Which alternatives should remain on radar during hunting]
```
