# High-Reputation Intelligence Sources

**Used by:** the intel-analysis skill and the intel-researcher subagent it dispatches.
**Purpose:** Ground web-sourced findings in primary and vendor-authoritative sources rather than aggregators, forums, or unverified blogs — keeps intel-analysis output consistent and reviewable.

## Guiding principle

Prefer, in order: (1) primary/government sources, (2) the vendor or researcher who originally published the finding, (3) MITRE/community-maintained technical references. Treat aggregator sites, unattributed blog reposts, and forum threads as leads to verify against a source below — never cite them directly as the source of a claim.

## Curated source list (v1 — static, extend as needed)

| Source | Type | Best for |
|---|---|---|
| [MITRE ATT&CK](https://attack.mitre.org/) | Technique reference | TTP definitions, technique/sub-technique IDs, data sources |
| [CISA Known Exploited Vulnerabilities (KEV)](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) | Government advisory | Confirmed in-the-wild exploitation, patch urgency |
| [NVD (National Vulnerability Database)](https://nvd.nist.gov/) | Government advisory | CVE scoring, affected products, CWE mapping |
| [Mandiant (Google Cloud)](https://cloud.google.com/blog/topics/threat-intelligence) | Vendor threat intel | APT/actor tracking, campaign analysis |
| [CrowdStrike Intelligence](https://www.crowdstrike.com/en-us/blog/category/threat-intel-research/) | Vendor threat intel | Adversary profiles, eCrime and targeted intrusion |
| [Unit 42 (Palo Alto Networks)](https://unit42.paloaltonetworks.com/) | Vendor threat intel | Malware analysis, campaign TTPs |
| [Recorded Future](https://www.recordedfuture.com/blog) | Vendor threat intel | Actor infrastructure, predictive intelligence |
| [GTIG (Google Threat Intelligence Group)](https://cloud.google.com/blog/topics/threat-intelligence) | Vendor threat intel | Merged Mandiant/TAG reporting, nation-state activity |

## When a claim has no source on this list

Say so explicitly rather than silently citing a lower-quality source: `Source not on the curated list — verify independently: [URL]`. Do not omit the finding; flag it.

## Extending this list

This list is intentionally static for v1. To add a source, append a row with the same three columns — no other file needs to change.
