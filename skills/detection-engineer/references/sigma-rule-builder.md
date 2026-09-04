# Sigma Rule Builder

Generate Sigma detection rules from hunt findings, hypotheses, or TTP descriptions.

## Sigma Overview

Sigma is a generic signature format for SIEM systems. Rules are YAML-based and platform-agnostic, allowing conversion to vendor-specific query languages (Splunk SPL, Microsoft KQL, Elastic Query DSL, etc.).

## Rule Structure

Every Sigma rule contains these components:

```yaml
title: [Descriptive title - max 256 chars]
id: [UUID - generate with uuidgen]
status: [experimental | test | stable | deprecated | unsupported]
description: [What the rule detects]
references:
    - [URL to threat intel, blog, or documentation]
author: [Your name/team]
date: [YYYY/MM/DD created]
modified: [YYYY/MM/DD last modified]
tags:
    - attack.[tactic]
    - attack.[technique_id]
logsource:
    category: [category]
    product: [product]
    service: [service]
detection:
    [detection logic]
    condition: [boolean logic combining selections]
falsepositives:
    - [Known false positive scenario]
level: [informational | low | medium | high | critical]
```

## Building Rules Step-by-Step

### Step 1: Define the Detection Objective

Before writing YAML, answer:
- What specific behavior or indicator are you detecting?
- What log source contains the evidence?
- What fields identify malicious vs. benign activity?
- What is the expected false positive rate?

### Step 2: Select Log Source

Common logsource configurations:

**Windows Process Creation**
```yaml
logsource:
    category: process_creation
    product: windows
```

**Windows Security Events**
```yaml
logsource:
    product: windows
    service: security
```

**Sysmon Events**
```yaml
logsource:
    product: windows
    service: sysmon
```

**PowerShell**
```yaml
logsource:
    product: windows
    service: powershell
    # or for script block logging:
    service: powershell-classic
```

**Network/Firewall**
```yaml
logsource:
    category: firewall
```

**Proxy/Web**
```yaml
logsource:
    category: proxy
```

**DNS**
```yaml
logsource:
    category: dns
```

**Linux Process**
```yaml
logsource:
    category: process_creation
    product: linux
```

**Linux Auditd**
```yaml
logsource:
    product: linux
    service: auditd
```

### Step 3: Build Detection Logic

Detection logic uses selections (what to match) and conditions (how to combine).

**Basic Selection**
```yaml
detection:
    selection:
        FieldName: 'value'
    condition: selection
```

**Multiple Values (OR)**
```yaml
detection:
    selection:
        FieldName:
            - 'value1'
            - 'value2'
            - 'value3'
    condition: selection
```

**Multiple Fields (AND)**
```yaml
detection:
    selection:
        FieldName1: 'value1'
        FieldName2: 'value2'
    condition: selection
```

**Modifiers**
```yaml
detection:
    selection:
        FieldName|contains: 'substring'
        FieldName|endswith: '.exe'
        FieldName|startswith: 'C:\Users'
        FieldName|re: '.*pattern.*'
        FieldName|cidr: '10.0.0.0/8'
        FieldName|base64: 'decoded_string'
        FieldName|base64offset: 'decoded_string'
    condition: selection
```

**Common Modifier Combinations**
```yaml
detection:
    selection:
        CommandLine|contains|all:
            - 'keyword1'
            - 'keyword2'
        # Matches if ALL keywords present
    condition: selection
```

**Filters (Exclusions)**
```yaml
detection:
    selection:
        Image|endswith: '\powershell.exe'
    filter_legitimate:
        ParentImage|endswith: '\svchost.exe'
        CommandLine|contains: '-EncodedCommand'
    filter_admin:
        User|contains: 'SYSTEM'
    condition: selection and not (filter_legitimate or filter_admin)
```

**Complex Conditions**
```yaml
detection:
    selection_process:
        Image|endswith: '\cmd.exe'
    selection_args:
        CommandLine|contains:
            - '/c'
            - '/k'
    selection_parent:
        ParentImage|endswith:
            - '\outlook.exe'
            - '\winword.exe'
    condition: selection_process and selection_args and selection_parent
```

### Step 4: Map to MITRE ATT&CK

Use proper tag format:
```yaml
tags:
    - attack.execution                    # Tactic (lowercase)
    - attack.t1059.001                    # Technique ID (lowercase)
    - attack.defense_evasion
    - attack.t1027                        # Can have multiple techniques
```

**Common Tactic Tags**:
- `attack.reconnaissance`
- `attack.resource_development`
- `attack.initial_access`
- `attack.execution`
- `attack.persistence`
- `attack.privilege_escalation`
- `attack.defense_evasion`
- `attack.credential_access`
- `attack.discovery`
- `attack.lateral_movement`
- `attack.collection`
- `attack.command_and_control`
- `attack.exfiltration`
- `attack.impact`

### Step 5: Assess Detection Level

| Level | Criteria |
|-------|----------|
| `informational` | Useful context, not inherently suspicious |
| `low` | Unusual but often legitimate |
| `medium` | Suspicious, warrants investigation |
| `high` | Likely malicious, prioritize response |
| `critical` | Almost certainly malicious, immediate action |

Consider:
- False positive rate (higher FP = lower level)
- Threat severity if true positive
- Detection specificity

### Step 6: Document False Positives

List known legitimate scenarios:
```yaml
falsepositives:
    - Legitimate administrative scripts
    - Software deployment tools
    - Security scanning products
    - Developer activity on approved workstations
```

## Rule Templates by Use Case

### Template: Process Execution (Suspicious Binary)

```yaml
title: Suspicious Process Execution - [Binary Name]
id: [UUID]
status: experimental
description: Detects execution of [binary] which may indicate [threat]
references:
    - [URL]
author: [Author]
date: [YYYY/MM/DD]
tags:
    - attack.execution
    - attack.t1059
logsource:
    category: process_creation
    product: windows
detection:
    selection:
        Image|endswith: '\[binary].exe'
    filter_legitimate:
        ParentImage|endswith:
            - '[legitimate_parent1]'
            - '[legitimate_parent2]'
    condition: selection and not filter_legitimate
falsepositives:
    - [Known FP]
level: medium
```

### Template: Command Line Pattern

```yaml
title: Suspicious Command Line Pattern - [Description]
id: [UUID]
status: experimental
description: Detects command line containing [pattern] indicative of [technique]
references:
    - [URL]
author: [Author]
date: [YYYY/MM/DD]
tags:
    - attack.[tactic]
    - attack.[technique_id]
logsource:
    category: process_creation
    product: windows
detection:
    selection_process:
        Image|endswith:
            - '\cmd.exe'
            - '\powershell.exe'
    selection_cmdline:
        CommandLine|contains:
            - '[suspicious_string1]'
            - '[suspicious_string2]'
    condition: selection_process and selection_cmdline
falsepositives:
    - [Known FP]
level: medium
```

### Template: Encoded PowerShell

```yaml
title: Encoded PowerShell Command Execution
id: [UUID]
status: experimental
description: Detects execution of PowerShell with Base64-encoded commands
references:
    - https://attack.mitre.org/techniques/T1059/001/
author: [Author]
date: [YYYY/MM/DD]
tags:
    - attack.execution
    - attack.t1059.001
    - attack.defense_evasion
    - attack.t1027
logsource:
    category: process_creation
    product: windows
detection:
    selection:
        Image|endswith:
            - '\powershell.exe'
            - '\pwsh.exe'
        CommandLine|contains:
            - '-enc'
            - '-EncodedCommand'
            - '-ec'
    filter_short:
        CommandLine|re: '-[eE]([nN])?[cC]?\s+[A-Za-z0-9+/=]{1,50}\s*$'
    condition: selection and not filter_short
falsepositives:
    - Legitimate scripts using encoding for special characters
    - Some software installers
level: high
```

### Template: Registry Modification (Persistence)

```yaml
title: Registry Persistence - [Location]
id: [UUID]
status: experimental
description: Detects modification of [registry key] for persistence
references:
    - [URL]
author: [Author]
date: [YYYY/MM/DD]
tags:
    - attack.persistence
    - attack.t1547.001
logsource:
    product: windows
    service: sysmon
detection:
    selection:
        EventID: 13
        TargetObject|contains:
            - '\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
            - '\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    filter_legitimate:
        Image|endswith:
            - '\msiexec.exe'
            - '\software_installer.exe'
    condition: selection and not filter_legitimate
falsepositives:
    - Legitimate software installation
level: medium
```

### Template: Network Connection (C2)

```yaml
title: Suspicious Outbound Connection - [Description]
id: [UUID]
status: experimental
description: Detects outbound connections to [indicators] potentially indicating C2
references:
    - [URL]
author: [Author]
date: [YYYY/MM/DD]
tags:
    - attack.command_and_control
    - attack.t1071
logsource:
    category: firewall
detection:
    selection:
        dst_port:
            - 443
            - 80
            - 8080
        dst_ip|cidr:
            - '[suspicious_range]'
    selection_process:
        Image|endswith:
            - '\rundll32.exe'
            - '\regsvr32.exe'
    condition: selection or selection_process
falsepositives:
    - [Known FP]
level: medium
```

### Template: Credential Access (LSASS)

```yaml
title: LSASS Memory Access
id: [UUID]
status: experimental
description: Detects process accessing LSASS memory for credential dumping
references:
    - https://attack.mitre.org/techniques/T1003/001/
author: [Author]
date: [YYYY/MM/DD]
tags:
    - attack.credential_access
    - attack.t1003.001
logsource:
    product: windows
    service: sysmon
detection:
    selection:
        EventID: 10
        TargetImage|endswith: '\lsass.exe'
        GrantedAccess|contains:
            - '0x1010'
            - '0x1410'
            - '0x1438'
            - '0x143a'
            - '0x1fffff'
    filter_system:
        SourceImage|endswith:
            - '\wmiprvse.exe'
            - '\taskmgr.exe'
            - '\MsMpEng.exe'
            - '\csrss.exe'
    filter_av:
        SourceImage|contains:
            - '\Microsoft\Windows Defender\'
            - '\CrowdStrike\'
            - '\Carbon Black\'
    condition: selection and not (filter_system or filter_av)
falsepositives:
    - Legitimate security tools
    - System processes during startup
level: high
```

### Template: File Creation (Webshell/Dropper)

```yaml
title: Suspicious File Created - [Location/Type]
id: [UUID]
status: experimental
description: Detects creation of [file type] in [location] potentially indicating [threat]
references:
    - [URL]
author: [Author]
date: [YYYY/MM/DD]
tags:
    - attack.persistence
    - attack.t1505.003
logsource:
    product: windows
    service: sysmon
detection:
    selection:
        EventID: 11
        TargetFilename|contains:
            - '\inetpub\wwwroot\'
            - '\xampp\htdocs\'
        TargetFilename|endswith:
            - '.asp'
            - '.aspx'
            - '.php'
            - '.jsp'
    condition: selection
falsepositives:
    - Legitimate web application deployment
    - Developer activity
level: high
```

## Field Reference by Log Source

### Windows Process Creation (Sysmon EID 1 / Security EID 4688)

| Field | Description |
|-------|-------------|
| `Image` | Full path to executable |
| `OriginalFileName` | PE header original name |
| `CommandLine` | Full command line |
| `ParentImage` | Parent process path |
| `ParentCommandLine` | Parent command line |
| `User` | Account that ran process |
| `IntegrityLevel` | Process integrity |
| `Hashes` | File hashes (Sysmon) |
| `CurrentDirectory` | Working directory |

### Sysmon Network Connection (EID 3)

| Field | Description |
|-------|-------------|
| `Image` | Process making connection |
| `DestinationIp` | Remote IP |
| `DestinationPort` | Remote port |
| `DestinationHostname` | Remote hostname |
| `SourceIp` | Local IP |
| `SourcePort` | Local port |
| `Protocol` | tcp/udp |

### Sysmon Registry (EID 12/13/14)

| Field | Description |
|-------|-------------|
| `EventType` | Create/Delete/Set/Rename |
| `TargetObject` | Registry key path |
| `Details` | Value data (EID 13) |
| `Image` | Process modifying registry |

### Windows Security Logon (EID 4624)

| Field | Description |
|-------|-------------|
| `TargetUserName` | Account logged in |
| `TargetDomainName` | Domain |
| `LogonType` | Type code (3=network, 10=RDP) |
| `IpAddress` | Source IP |
| `WorkstationName` | Source hostname |
| `LogonProcessName` | Auth package |

## Quality Checklist

Before finalizing a Sigma rule, verify:

- [ ] Title is descriptive and unique
- [ ] UUID generated and included
- [ ] Status accurately reflects testing state
- [ ] Description explains what is detected
- [ ] References link to supporting intel
- [ ] Logsource matches target environment
- [ ] Detection logic tested against real data
- [ ] Filters exclude known false positives
- [ ] MITRE tags are accurate and complete
- [ ] Level reflects true positive confidence
- [ ] False positives section is populated

## Converting Hunt Findings to Rules

When a hunt identifies malicious behavior:

1. **Extract Observables**: What fields/values identified the threat?
2. **Identify Log Source**: Where was evidence found?
3. **Define Selection**: Build matching criteria
4. **Baseline Legitimate**: What normal activity looks similar?
5. **Build Filters**: Exclude confirmed false positives
6. **Test and Tune**: Validate against historical data
7. **Document**: Add references to hunt findings

**Example Workflow**:
```
Hunt Finding: Discovered encoded PowerShell with obfuscated Invoke-Mimikatz
↓
Observable: CommandLine contains Base64 > 500 chars with "mimikatz" decoded
↓
Log Source: process_creation (Windows)
↓
Selection: powershell.exe + encoded command + length filter
↓
Baseline: Some installers use short encoded commands
↓
Filter: Exclude commands < 100 chars
↓
Result: High-fidelity credential access rule
```
