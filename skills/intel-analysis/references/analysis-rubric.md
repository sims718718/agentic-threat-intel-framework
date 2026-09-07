# Analysis Quality Gate

Apply after synthesis. This is a local workflow rubric, not an externally validated score or a probability of correctness.

| Dimension | 0 — Missing/unsafe | 1 — Partial | 2 — Sufficient |
|---|---|---|---|
| Decision and time scope | No question or date boundary | Scope stated, ambiguity remains | Question, decision, explicit window/cutoff; background separated |
| Evidence traceability | Material claims unsupported | Sources present, provenance/locators incomplete | Material claims traceable; origins and source limitations evaluated |
| Analytical reasoning | Assertion presented as fact | Reasoning or assumptions incomplete | Evidence, inference, assumptions and calibrated confidence distinguished |
| Alternatives | Central explanation unchallenged | Alternative named but not tested | Plausible alternative tested against discriminating evidence; unresolved ambiguity explicit |
| Technical and operational relevance | Unsupported mappings/attribution or unsafe indicators | Supported findings with relevance gaps | Evidence-specific TTP/IOC/CVE treatment and conditional operational implications |

**READY:** 8–10, no dimension at 0, no unresolved integrity defect.
**LIMITED:** usable findings remain, but collection gaps prevent READY; identify the affected judgments and next collection action.
**INSUFFICIENT:** no supported answer to the central question, regardless of total.

Integrity defects override the score: fabricated evidence/IOCs, circular reporting presented as independent corroboration, unsupported actor/CVE linkage, out-of-window events presented as current, or external reporting presented as local validation. Correct or remove these claims before handoff; do not merely label them LIMITED.

Review cases:
- Three articles repeat one vendor claim: one origin, not three corroborations.
- A new article describes an old intrusion: background unless event dates meet scope.
- An actor profile lists a technique but the campaign report does not: historical capability, not observed campaign behavior.
- An IP belongs to shared hosting: retain provenance/context; no blanket blocking recommendation.
- KEV lists a vulnerability without actor linkage: exploitation known, actor association unestablished.
- No telemetry or accessible evidence: explicit gaps and LIMITED/INSUFFICIENT, never a clean-environment finding.

Methodological grounding: [ODNI ICD 203](https://www.dni.gov/files/documents/ICD/ICD-203.pdf) for sourcing, uncertainty, and alternatives; [CISA ATT&CK mapping guidance](https://www.cisa.gov/news-events/news/best-practices-mitre-attckr-mapping) for evidence-based technique mapping. The scoring thresholds above are framework conventions.