# Feasibility Assessment Checklist

Use this checklist to determine if a hunt should proceed, be backlogged, or proceed with conditions.

## Assessment Criteria

### 1. Data Availability

| Question | Status | Notes |
|----------|--------|-------|
| Are required log sources ingested into SIEM/data lake? | ☐ Yes ☐ No | |
| Is the retention period sufficient for the analysis window? | ☐ Yes ☐ No | |
| Are there known collection gaps or outages? | ☐ Yes ☐ No | |
| Can missing data be obtained (if needed)? | ☐ Yes ☐ No | |

**GO Criteria**: All required sources available with adequate retention  
**NO-GO Criteria**: Critical data sources missing with no remediation path  
**CONDITIONAL**: Some sources missing but hunt can proceed with reduced scope

### 2. Data Quality

| Question | Status | Notes |
|----------|--------|-------|
| Are logs parsed correctly with required fields extracted? | ☐ Yes ☐ No | |
| Is timestamp normalization consistent? | ☐ Yes ☐ No | |
| Are there known parsing errors or data corruption? | ☐ Yes ☐ No | |
| Is field cardinality appropriate for analysis? | ☐ Yes ☐ No | |

**GO Criteria**: Data is parsed, normalized, and queryable  
**NO-GO Criteria**: Data quality issues prevent meaningful analysis  
**CONDITIONAL**: Minor quality issues documented as assumptions

### 3. Team Skillset

| Question | Status | Notes |
|----------|--------|-------|
| Does the team have experience with the target data sources? | ☐ Yes ☐ No | |
| Are required analysis techniques within team capabilities? | ☐ Yes ☐ No | |
| Is domain knowledge available (internal SME or documentation)? | ☐ Yes ☐ No | |
| Does complexity require external support? | ☐ Yes ☐ No | |

**GO Criteria**: Team has skills or can acquire them within timeline  
**NO-GO Criteria**: Skill gap too large to bridge without significant investment  
**CONDITIONAL**: Training or external support identified and scheduled

### 4. Timeline

| Question | Status | Notes |
|----------|--------|-------|
| Is the hunt achievable within the allocated sprint? | ☐ Yes ☐ No | |
| Are there competing priorities that may impact delivery? | ☐ Yes ☐ No | |
| Is the time-bound objective realistic? | ☐ Yes ☐ No | |
| Is there buffer for unexpected findings requiring investigation? | ☐ Yes ☐ No | |

**Estimation Guide**:
- Simple hypothesis, familiar data: 1-2 days execution
- Moderate complexity, some unknowns: 3-5 days execution
- Complex hypothesis, unfamiliar terrain: 1-2 weeks execution
- Research-heavy, EDA required: 2-4 weeks total

**GO Criteria**: Timeline is realistic with buffer  
**NO-GO Criteria**: Timeline impossible given scope  
**CONDITIONAL**: Scope reduced to fit timeline

### 5. Tooling

| Question | Status | Notes |
|----------|--------|-------|
| Is SIEM/query platform accessible? | ☐ Yes ☐ No | |
| Are specialized tools available (notebooks, ML platforms)? | ☐ Yes ☐ No | |
| Is EDR console accessible with required permissions? | ☐ Yes ☐ No | |
| Are threat intel platforms available for enrichment? | ☐ Yes ☐ No | |

**GO Criteria**: All required tools accessible with appropriate permissions  
**NO-GO Criteria**: Critical tool unavailable with no alternative  
**CONDITIONAL**: Workarounds identified for missing tools

### 6. Cloud & SaaS Environment (complete only if hunt involves cloud or SaaS assets)

| Question | Status | Notes |
|----------|--------|-------|
| Are cloud audit logs enabled and ingested? (CloudTrail, Azure Activity Log, GCP Audit Logs) | ☐ Yes ☐ No ☐ N/A | |
| Is cloud log retention sufficient for the analysis window? | ☐ Yes ☐ No ☐ N/A | |
| Are identity/IAM logs available? (Azure AD Sign-In Logs, AWS CloudTrail IAM events, GCP Admin Activity) | ☐ Yes ☐ No ☐ N/A | |
| Is a CASB or SaaS audit log source available for SaaS apps in scope? | ☐ Yes ☐ No ☐ N/A | |
| Are VPC flow logs / NSG flow logs or equivalent network telemetry available? | ☐ Yes ☐ No ☐ N/A | |
| Is a cloud-native SIEM or security data lake configured? (Sentinel, Chronicle, AWS Security Lake) | ☐ Yes ☐ No ☐ N/A | |
| Have query costs been estimated and approved for large-scale cloud log searches? | ☐ Yes ☐ No ☐ N/A | |

**GO Criteria**: Required cloud telemetry is enabled, ingested, and queryable within budget  
**NO-GO Criteria**: Cloud audit logging is disabled or not ingested — hunt cannot proceed  
**CONDITIONAL**: Partial cloud coverage; scope hunt to available log sources and document gaps

> ⚠️ **Cost Warning**: Cloud hunts frequently surface unexpected query costs. Always estimate costs upfront for large time windows or high-cardinality datasets (e.g., CloudTrail S3 data events, VPC flow logs at full fidelity).

## Decision Matrix

| Data | Quality | Skills | Timeline | Tools | Cloud | Decision |
|------|---------|--------|----------|-------|-------|----------|
| GO | GO | GO | GO | GO | N/A | **PROCEED** |
| GO | GO | GO | GO | COND | N/A | PROCEED with tool workaround |
| GO | GO | COND | GO | GO | N/A | PROCEED with skill support plan |
| GO | COND | GO | GO | GO | N/A | PROCEED with quality assumptions documented |
| COND | GO | GO | COND | GO | N/A | PROCEED with reduced scope |
| GO | GO | GO | GO | GO | GO | **PROCEED** (cloud hunt) |
| GO | GO | GO | GO | GO | COND | PROCEED — scope to available cloud telemetry |
| NO-GO | * | * | * | * | * | **BACKLOG** - Address data gaps first |
| * | NO-GO | * | * | * | * | **BACKLOG** - Address quality issues first |
| * | * | NO-GO | * | * | * | **BACKLOG** - Skill development required |
| * | * | * | NO-GO | * | * | **BACKLOG** - Re-scope or re-prioritize |
| * | * | * | * | NO-GO | * | **BACKLOG** - Tool procurement required |
| * | * | * | * | * | NO-GO | **BACKLOG** - Enable and ingest cloud audit logs first |

## Backlog Template

When a hunt is backlogged, document the remediation plan:

```markdown
## Backlogged Hunt: [Hunt Title]

### Blocking Factor
[Data | Quality | Skills | Timeline | Tools]

### Specific Issue
[Description of what is blocking the hunt]

### Remediation Plan
1. [Action item 1]
2. [Action item 2]

### Owner
[Team/individual responsible]

### Target Resolution Date
[YYYY-MM-DD]

### Re-assessment Trigger
[What event should trigger re-evaluation of this hunt]
```

## "Is the Juice Worth the Squeeze?" Framework

For borderline cases, evaluate effort vs. impact:

| Factor | Low | Medium | High |
|--------|-----|--------|------|
| **Threat Likelihood** | Theoretical risk | Observed in industry | Active targeting |
| **Business Impact** | Non-critical systems | Important assets | Crown jewels |
| **Detection Gap** | Partial coverage | Limited coverage | No coverage |
| **Effort Required** | Days | Weeks | Months |

**Proceed if**: High likelihood + High impact + Any detection gap  
**Evaluate carefully if**: Medium likelihood + Medium impact  
**Deprioritize if**: Low likelihood + Low impact + High effort
