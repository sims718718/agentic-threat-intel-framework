# Modern Domain Matrix

**Fits at:** Step 0 (Environment Context) and Step 2 (Hypothesis Development) — pick the domain before writing the hypothesis, because the telemetry model changes completely.
**Purpose:** The lifecycle is domain-agnostic. The telemetry, the identity model, and the analysis technique are not. Endpoint-only hunting no longer matches the threat surface: malware-free, credential- and identity-driven intrusion is now the dominant pattern reported across major annual threat reports.

---

## Domain reference

| Domain | Core telemetry | Identity boundary | Example technique | Example hypothesis seed |
|---|---|---|---|---|
| **Endpoint** | Process creation, command line, module loads, registry, file events (EDR, Sysmon, 4688) | Local + domain account | T1059.001 PowerShell | Encoded PowerShell spawned by an Office parent process |
| **Identity (on-prem AD)** | 4624/4625/4672/4768/4769/4776, DC replication events | Kerberos / NTLM | T1558.004 AS-REP Roasting | Accounts with pre-auth disabled requesting AS-REP tickets |
| **Identity (cloud IdP)** | Entra ID / Okta sign-in + audit logs, MFA events, token issuance | OAuth / SAML / conditional access | T1621 MFA Request Generation, T1550.001 token abuse | Repeated MFA prompts followed by a successful sign-in from a new ASN |
| **Cloud control plane** | CloudTrail / Azure Activity / GCP Audit, IAM change events | IAM role / service principal | T1078.004 Valid Accounts: Cloud | Role assumption chain ending in a privilege the principal never previously used |
| **SaaS** | M365 Unified Audit Log, Google Workspace audit, app consent grants, sharing events | OAuth app + delegated scopes | T1098.003, T1114 mail collection | New third-party app granted mail scopes by a non-admin user |
| **Containers / K8s** | API server audit, admission events, runtime (eBPF/Falco), image registry | Service account / RBAC | T1610 Deploy Container, T1613 discovery | Pod created with hostPath mount or privileged securityContext outside CI |
| **Network / edge** | Flow, DNS, TLS metadata (JA3/JA4), proxy, VPN, edge-device logs | Device / appliance account | T1071 C2 over app-layer protocol | Long-lived beacon-like periodicity from a server VLAN to a new destination |
| **OT / ICS** | Historian, protocol captures, engineering workstation logs | Vendor / engineer accounts | ATT&CK for ICS techniques | Engineering workstation initiating unexpected protocol writes off-schedule |

---

## What changes by domain

| | Endpoint | Cloud / SaaS / Identity |
|---|---|---|
| Primary artifact | Process and file | Log event and API call |
| Adversary "malware" | Binary | Valid credential, token, or consented app |
| Baseline unit | Host | Principal (user, role, service principal, app) |
| Retention risk | Weeks–months, high volume | Often shorter by default; audit logging frequently off or licence-gated |
| Dominant technique | Peer-set stacking by host | Peer-set stacking by principal + first-seen analysis |
| Biggest gap | Command-line auditing off | Audit log not enabled, or scoped to a subset of the tenant |

---

## Domain-specific feasibility checks

Add to Step 4 when the hunt touches these domains:

- **Cloud:** Is control-plane logging enabled in *every* account/subscription/project in scope, including recently created ones? Are data-plane events (e.g. object-level access) logged, or only management events?
- **Identity:** Do sign-in logs cover both interactive and non-interactive/service-principal sign-ins? Is the export retaining longer than the IdP's default portal window?
- **SaaS:** Is unified audit logging on for all workloads? Are app consent events retained? Is there an app inventory to diff "first-seen" against?
- **Containers:** Is API server audit policy at a level that records request bodies for the resources in scope? Does runtime telemetry exist at all, or only orchestration?
- **OT:** Passive collection only — confirm no query touches a device that could be destabilized. Read-only, out-of-band, coordinated with process engineering.

---

## Balance guidance

Aim for a rolling hunt portfolio that is not majority-endpoint. A workable split for an enterprise with cloud and M365 exposure:

| Domain | Share of hunts |
|---|---|
| Identity (on-prem + cloud IdP) | ~30% |
| Cloud control plane + SaaS | ~30% |
| Endpoint | ~25% |
| Network / edge | ~10% |
| Containers / OT (where present) | ~5% |

Adjust to the actual attack surface — but if the portfolio is 80% Windows endpoint, the program is hunting where the telemetry is comfortable rather than where the adversary is.

---

**References:** MITRE ATT&CK Enterprise matrices for Cloud, SaaS, Identity Provider, and Containers; ATT&CK for ICS · CrowdStrike Global Threat Report (malware-free intrusion and cloud-conscious intrusion trends) · Verizon DBIR (credential abuse as initial access) · Mandiant M-Trends (stolen credentials as initial infection vector)