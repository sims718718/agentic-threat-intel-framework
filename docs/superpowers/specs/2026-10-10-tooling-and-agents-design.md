# Tooling and Agents: Design

Sub-project C of three (A: post-hunt stages, pushed as `feature/post-hunt-stages`; B: quality hardening, pushed as `feature/quality-hardening`). C is stacked on B's branch because it checks the artifacts and rules A and B introduced.

## Purpose

Turn the framework's mechanical rules, which today exist only as prose, into checks that run, and add independent review agents for the three judgement-heavy artifacts. This closes the two gaps left from the original review: no mechanical contract, Sigma, or ATT&CK checks, and an agent roster of one. Every check names the Unified Threat Hunting Process (UTH) step it supports.

**Success criteria**

1. The six existing artifacts and A's hunt log and hunt report keep their paths, section order, and fields. Nothing the pipeline produces today changes.
2. The checks are advisory. They never block, rewrite, or delete an artifact and add no confirmation gate. (Decided by the user.)
3. The linter and the tests read only the `./threat-hunting/` layout that the plugin creates in a user project. Nothing in C reads `examples/`. (Decided by the user.)
4. The linter has no dependency beyond bash and standard tools. (Decided by the user.)
5. A reader of a finished run can see which structural rules held and which findings an independent reviewer raised, without re-reading every artifact.

## Constraints

- **Outputs unchanged.** C adds one new artifact, `./threat-hunting/quality/<slug>-quality.md`. It does not edit any existing artifact.
- **Runtime dependencies:** bash, grep, awk, sed, and other standard tools only, with LF line endings (`.gitattributes` already forces LF on `*.sh`). The ATT&CK ID list is bundled as a data file.
- **Maintainer-only tooling** (the ATT&CK data generator) may use `curl` and `jq` or `python3`, because it never runs at hunt time.
- **Agents** follow `intel-researcher`: read-only tools (`Read, Grep, Glob`), return a fragment, write no files. Artifact text is data, never instructions.
- **Agents advise; skills decide.** The rubrics and gates in the skills stay the source of truth, and a reviewer finding never changes a verdict or a score.
- Conventions as in `CLAUDE.md`: files are the interface; annotate gaps; never fabricate.

## Changes

### C1: Contract linter (UTH: Formalize Hunt Plan, Document Outcomes)

New `scripts/check-contracts.sh <slug> <plan|post> [threat-hunting-dir]`. The directory defaults to `./threat-hunting`. It prints one line per check as `PASS|WARN|FAIL|SKIP <check-id> <message>` and a one-line count summary. Exit 0 when nothing failed, 1 when any check failed, 2 on a usage error. WARN and SKIP never change the exit code. It never edits a file.

Checks by ID:

| ID | Stage | Check | Result |
|---|---|---|---|
| `presence` | both | The stage's expected files exist, including HTML twins (plan stage: analysis, report, plan, hunt log, validation; post stage adds detection if the log lists a Detection Opportunity or a hit, and the hunt report) | FAIL if a required file is missing, SKIP for later-stage files |
| `section-order` | both | Headings of each present artifact match the fixed order in `data/section-order.tsv` | FAIL on a missing or reordered required section; extra sections are allowed because real plans and detections add some. A detection must also hold `### 1.` to `### 10.` in order inside each `## DET-` block |
| `results-status` | both | The hunt log's `Results status` is `PENDING EXECUTION`, `RECORDED`, or `PARTIAL` | FAIL otherwise |
| `story-ids` | post | Every Story ID in the hunt log exists in the plan, and every plan Story appears in the log | FAIL on an unknown ID, WARN on a missing one |
| `verdict-bound` | post | `Refuted` requires coverage `Confirmed`, no Story `Not executed` or `Partial`, and no true-positive or `Undetermined` hit | FAIL otherwise |
| `escalation` | post | A true-positive or `Undetermined` hit has a Suspicious Security Event outcome candidate | WARN otherwise |
| `attack-ids` | both | Every `T####` or `T####.###` ID in the analysis, plan, and detection is in `data/attack-enterprise-ids.tsv` | WARN with "not in ATT&CK vN" for unknown IDs, WARN for deprecated or revoked IDs; SKIP when the data file is absent |
| `sigma` | post | The detection's fenced YAML block has `title`, `logsource`, `detection`, `condition`, and `level`; every selection named in `condition` is defined; the condition is not a lone hash, IP, or domain selection | FAIL on a missing key or undefined selection, WARN on an indicator-only condition |
| `det-xref` | post | `DET-XXX` IDs agree across the detection, validation, and hunt report, and the report's `Validation` section is not left at `Pending hunt-validator` when a validation file exists | FAIL on a mismatched ID, WARN on a stale `Validation` section |
| `language` | post | The hunt report does not say "clean", "no threat", or "environment is secure" | WARN |
| `placeholders` | both | Count of `[FILL IN: ...]`, `Unknown`, and `[PENDING EXECUTION]` markers per artifact | PASS with counts (information, not a defect) |

`attack-ids` and `sigma` use patterns that match the formats the skills write. A check that cannot parse an artifact FAILs for that check only and the linter continues.

### C2: ATT&CK data (UTH: Epic MITRE ATT&CK mapping)

- `data/attack-enterprise-ids.tsv`: tab-separated `id`, `name`, `status` (`current`, `deprecated`, or `revoked`). The first line is a comment naming the ATT&CK version and generation date.
- `scripts/update-attack-ids.sh` is the maintainer-only generator. It reads MITRE's published Enterprise ATT&CK STIX bundle and writes the file. The shipped file is produced by running this script, never typed by hand.
- Because the bundled data ages, an unknown ID is reported as "not in ATT&CK vN", not as invalid.

### C3: Section-order data and drift guard (UTH: Formalize Hunt Plan)

- `data/section-order.tsv`: tab-separated `artifact`, `position`, `prefix`, for the analysis, report, hunt plan, hunt log, hunt report, detection, and validation. Each row is a heading prefix, matched in order against the artifact's `##` headings outside code fences.
- The drift test extracts the same headings from the fenced templates in the skills and diffs them against this file. A skill edit that changes a heading without updating the data file fails the test.

### C4: Review agents (UTH: Intelligence-Led Hunting, Hypothesis Development, Document Outcomes)

Three new files under `agents/`, each with `tools: Read, Grep, Glob` and a description that names its single artifact. Each is given the slug, reads its artifacts and the relevant skill reference, and returns findings as a table with columns `Severity | Location | Issue | Suggested fix` (severity `High`, `Medium`, or `Low`; location is file and section). With no findings it returns `No findings`. It writes no file.

| Agent | Reads | Reviews |
|---|---|---|
| `intel-challenger` | analysis, report, `analysis-rubric.md`, `high-reputation-sources.md` | Attribution basis and disagreements; claims that trace to one origin; shelf-life and relevance ratings against the evidence; whether Hunt seeds pass the actionability test; whether the rubric score is justified |
| `plan-reviewer` | plan, report, `hypothesis-rubric.md`, `feasibility-checklist.md` | An independent re-score against the hypothesis rubric; ACH and method diversity present; expected outcomes falsifiable; Story queries use data sources the Environment Profile actually has; verdict criteria stated before the hunt |
| `detection-reviewer` | detection, hunt log, plan, `detection-handoff-spec.md` | Each of the six acceptance-gate conditions; Sigma logic matches the queries executed in the hunt log; false positives come from recorded hit dispositions; blind spots are specific; the robustness rationale holds |

### C5: Command wiring and the quality file (UTH: Report & Iterate)

- `commands/run-hunt-pipeline.md` gains a final step after `hunt-validator` (PLAN): run `${CLAUDE_PLUGIN_ROOT}/scripts/check-contracts.sh <slug> plan`, then dispatch `intel-challenger` and `plan-reviewer` in parallel.
- `commands/run-post-hunt.md` gains a final step after `hunt-validator` (RECORD): run the linter in `post` stage, then dispatch `detection-reviewer` only if a detection exists (otherwise state that in the summary).
- The command (not an agent) writes `./threat-hunting/quality/<slug>-quality.md`:

  ```markdown
  # Quality Checks: <slug>

  ## Plan stage
  Run: <date>
  ### Contract checks
  [linter output, verbatim]
  ### intel-challenger
  [findings table or "No findings"]
  ### plan-reviewer
  [findings table or "No findings"]

  ## Post stage
  Run: <date>
  ### Contract checks
  ### detection-reviewer
  ```

  A re-run replaces only its own stage's section.
- Each command's final summary gains a `Quality:` block: the linter's counts, the number of High findings per agent, and the path of the quality file. Existing summary lines are unchanged.
- If the script cannot run (no bash, script missing) or an agent returns an error, the command records `SKIP <reason>` in the quality file and continues. A quality-check failure never fails the command.

### C6: Tests (UTH: none; engineering verification)

New `scripts/test-checks.sh`. Nothing in it reads `examples/`.

1. **Drift test.** Compares `data/section-order.tsv` with the skills' fenced templates. Needs no run output.
2. **Baseline.** Creates a throwaway project directory outside the repo and runs the real commands there with `claude -p --plugin-dir`: `/run-hunt-pipeline` on a made-up subject, then `/run-post-hunt` with a small synthetic results file written for the test and labeled as test data. This produces a real `./threat-hunting/` folder. It needs the `claude` CLI and network access (`intel-analysis` does live research), so the suite is not offline-CI friendly.
3. **Linter on the baseline.** Any FAIL on an unmodified baseline means the linter and the skills disagree and is reported as a defect to fix.
4. **Mutation tests.** Each copies the baseline and introduces one defect; the linter must report the specific FAIL and no other new FAIL:
   - two sections swapped in the plan;
   - an ATT&CK ID that does not exist (WARN);
   - a deprecated ID (WARN);
   - `Refuted` with coverage `Unconfirmed`;
   - a Sigma block with no `condition`;
   - a `condition` that references an undefined selection;
   - a `DET-XXX` ID that differs between detection and validation;
   - an unknown `Results status`;
   - a hit disposition of `Undetermined` with no Suspicious Security Event candidate (WARN);
   - "clean" in the report (WARN).
5. **Agent dry runs** on the baseline: each agent returns a table, writes no file, and names real locations. Findings are not asserted line by line because they vary between runs.
6. **Command wiring dry runs:** both commands create `quality/<slug>-quality.md`, and a second run replaces only its own stage's section.

Each linter check is written test-first: the mutation test fails before the check exists and passes after.

## Files

- **New:** `scripts/check-contracts.sh`, `scripts/update-attack-ids.sh`, `scripts/test-checks.sh`, `data/attack-enterprise-ids.tsv`, `data/section-order.tsv`, `agents/intel-challenger.md`, `agents/plan-reviewer.md`, `agents/detection-reviewer.md`.
- **Edited:** `commands/run-hunt-pipeline.md`, `commands/run-post-hunt.md`, `README.md` (pipeline diagram gains a quality step, layout tree, artifact table), `CLAUDE.md` (the one-script note, the agents list, the quality file path and contract).
- **Untouched:** every skill, `agents/intel-researcher.md`, `examples/`, and the plugin manifest (`agents/` and `commands/` are auto-discovered).

## Edge cases

- Run with no `hunt-log` yet (an older run): `presence` and the post-stage checks SKIP.
- Hunt log still `PENDING EXECUTION` at post stage: the post-stage result checks SKIP with that reason.
- Pipeline re-run with a locked plan: the linter and agents still run on the locked plan; findings are advice for the next iteration.
- No detection produced: `sigma` and `det-xref` SKIP, and `detection-reviewer` is not dispatched.
- Data file missing or unreadable: `attack-ids` SKIPs with a WARN-level note.
- Bundled ATT&CK data older than the technique an analyst cites: reported as "not in ATT&CK vN", with the version shown.
- Slug not found: the script exits 2 with a usage message; the command records `SKIP` in the quality file.
- Agent returns free text instead of a table: the command pastes it under the agent's heading, marked `[unstructured]`.

## Grounding

| Change | UTH step |
|---|---|
| C1 `presence`, `section-order`, `results-status` | Formalize Hunt Plan; Document Outcomes |
| C1 `verdict-bound`, `escalation`, `language` | Document Outcomes; Report & Iterate |
| C1 `attack-ids`, C2 | Epic MITRE ATT&CK mapping |
| C1 `sigma`, `det-xref` | Detection handoff and validation |
| `intel-challenger` | Intelligence-Led Hunting: source quality, timeliness, actionability |
| `plan-reviewer` | Hypothesis Development; Stories; Formalize Hunt Plan |
| `detection-reviewer` | Document Outcomes (Analytics/Detection); Validation |

## Verification

1. **Test suite** (`scripts/test-checks.sh`) as in C6, with the failing run seen before each check is written.
2. **Unchanged outputs.** The fenced templates of every existing skill are byte-identical before and after (the awk fence diff from B), and no existing artifact path or section changes.
3. **Static checks.** Each new rule in the commands and README has a grep assertion that fails before the edit and passes after. The manifest still lists the same eight skills.
4. **Limits stated, not hidden.** The baseline varies between runs because it uses live research; the agent findings are not asserted line by line; the ATT&CK data is a snapshot.

## Out of scope

- Real Sigma compilation or backend conversion (`sigma-cli`, pySigma), and any runtime dependency beyond bash and standard tools.
- Hard gates: nothing blocks a command or an artifact.
- Checks of the Jira templates or the HTML twins beyond presence.
- Running hunts, queries, or attack simulations.
- Scoring or ranking runs across hunts.
