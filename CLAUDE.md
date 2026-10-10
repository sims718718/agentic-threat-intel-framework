# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code **plugin**, not an application. There is no build or lint step; `scripts/test-checks.sh` tests the quality checks (see Scripts below). The "source code" is prompt content: skill/command/agent Markdown files that Claude executes at runtime. Editing means editing instructions, so a change in one skill can silently break the next stage's expectations. `README.md` is the authoritative description of the pipeline; keep it in sync when behavior changes.

Scripts: `scripts/validate-frontmatter.sh <file> <field>...` (non-empty YAML frontmatter fields), `scripts/check-contracts.sh <slug> <plan|post> [dir]` (the advisory contract linter both commands run), `scripts/update-attack-ids.sh` (maintainer-only; regenerates `data/attack-enterprise-ids.tsv`), and `scripts/test-checks.sh` (`drift` runs offline, and `lint` runs offline once a baseline exists; building the baseline and the agent and wiring dry runs use the real commands, so they need the `claude` CLI and network; it never reads `examples/`). None is wired into a hook or CI. Do not edit `scripts/test-checks.sh` while a `baseline` or dry run is executing: bash reads scripts incrementally. When changing a skill, also verify that the fenced template blocks of artifacts you did not mean to change are byte-identical before and after (extract the fenced lines with awk and diff them).

Plugin wiring: `.claude-plugin/plugin.json` (lists the eight skills explicitly; a new skill must be added there), `.claude-plugin/marketplace.json` (local marketplace), `.claude/settings.json` (enables the plugin for this repo). `agents/` and `commands/` are auto-discovered.

## Pipeline architecture

Two commands, split at the point where a **human runs the hunt** (the framework never runs queries or attack simulations):

- `/run-hunt-pipeline` (`commands/run-hunt-pipeline.md`): `gather → intel-analysis → intel-report → hunt-planner → hunt-execution (WORKSHEET) → hunt-validator (PLAN)`
- `/run-post-hunt` (`commands/run-post-hunt.md`), which needs hunt results: `hunt-execution (INTAKE) → detection-engineer (conditional) + hunt-reporter → hunt-validator (RECORD)`

Contracts that span multiple files:

- **Files are the interface.** Stages share no in-memory state. Each reads the predecessor's file and writes its own, under `./threat-hunting/` **in the user's project, never in this repo** (`threat-hunting/` is gitignored). Paths: `environment-profile.md`, `intel-analysis/<slug>-analysis.md`, `intel-reports/<slug>-report.md` (+`.html`), `hunt-plans/<slug>-hunt-plan.md` (+`.html`), `hunt-logs/<slug>-hunt-log.md`, `detections/<slug>-detection.md`, `hunt-reports/<slug>-hunt-report.md` (+`.html`), `validations/<slug>-validation.md`, `quality/<slug>-quality.md` (advisory; written by the commands). Renaming a path or section in one skill requires updating every skill that reads it.
- **One slug per run**, kebab-case, ≤6 words, derived by `intel-analysis` Step 0 and reused by every stage.
- **Section order is a downstream contract.** Fixed section orders in the analysis, report, hunt plan, hunt log, and hunt report are read by later stages (e.g. `hunt-planner` consumes the report's `Recommended Actions > Hunt` seeds; `hunt-execution` consumes each plan Story's `Detection Logic`, `Scope > Time Window`, and expected outcomes; `detection-engineer` consumes the plan's Environment Profile and Epic ATT&CK mapping plus the hunt log's executed queries and hit dispositions). Don't reorder or rename them casually.
- **The hunt log's `Results status` drives behavior.** `PENDING EXECUTION` (blank worksheet), `RECORDED`, or `PARTIAL`. `hunt-validator` runs in PLAN mode unless the status is `RECORDED`/`PARTIAL`; `hunt-execution` WORKSHEET mode and `hunt-validator` PLAN mode never overwrite recorded results.
- **A plan is locked once its hunt log holds results.** `hunt-planner` writes nothing if `hunt-logs/<slug>-hunt-log.md` holds results (the recorded results reference the plan's Story IDs). A blank worksheet does not lock it.
- **Step 0 has one home.** The six environment contexts, the Express path, and the `Unknown` rule live in `skills/_shared/references/environment-context.md`; `gather` and `hunt-planner` link to it instead of copying the table.
- **Never fabricate, annotate instead.** Gaps become `Unknown`, `[FILL IN: ...]`, `Not assessed`, `Not provided`, or `[PENDING EXECUTION]`. `/run-hunt-pipeline` has no confirmation gates. `/run-post-hunt` has one: it stops if no hunt results are supplied. A true-positive or `Undetermined` hit is escalated before anything else is written.
- **Verdicts are bounded by coverage.** `Refuted` requires every Story executed and coverage confirmed over the planned window; an untriaged hit is `Undetermined`, never benign; reports say "no evidence found in X over Y", never "clean".
- **Two modes for `gather`**: standalone interviews the user; pipeline mode never asks and writes `Unknown`.
- **`hunt-validator` RECORD mode writes back** into the detection's section 9 (if a detection exists) and the hunt report's `Validation` section (if a report exists); the files cross-reference by `DET-XXX` ID.
- **Quality gates** live in skills and their `references/` (intel-analysis rubric READY/LIMITED/INSUFFICIENT with integrity defects overriding score; hypothesis rubric ≥10 with no 1s; GO/CONDITIONAL/NO-GO feasibility; detection robustness on two axes plus a 6-condition acceptance gate). Tune thresholds in the reference file, not by restating them elsewhere.
- **Quality checks are advisory.** Both commands end by running `scripts/check-contracts.sh` and dispatching reviewers (`intel-challenger`, `plan-reviewer` after planning; `detection-reviewer` after post-hunt), then write `quality/<slug>-quality.md` (each stage replaces only its own section). Findings never block, edit another artifact, or change a verdict. `data/section-order.tsv` must match the skills' fenced templates (`scripts/test-checks.sh drift` checks this), so a heading change in a skill also needs the data file updated. `data/attack-enterprise-ids.tsv` is a snapshot; refresh it with `scripts/update-attack-ids.sh`.
- **Markdown is the source of truth.** HTML twins for intel-report, hunt-planner, and hunt-reporter are rendered in the same turn from `skills/_shared/references/html-report-shell.md`.
- **Subagents**: `intel-analysis` dispatches four parallel `intel-researcher` agents (`agents/intel-researcher.md`, tools limited to WebSearch/WebFetch/Read/Grep/Glob, returns a fragment, writes no files), one per angle: Actor, ATT&CK/TTP, IOCs, CVEs. Three read-only reviewers (`intel-challenger`, `plan-reviewer`, `detection-reviewer`; tools Read/Grep/Glob) advise after each command and write no files. Under `claude -p --plugin-dir` the plugin's agents are not registered, so the commands fall back to performing the review inline from the agent file (marked `[inline fallback]`), never to a broader-tool substitute agent.

## Conventions

- Skill layout: `skills/<name>/SKILL.md` (frontmatter `name`, `description`) plus `references/*.md` loaded on demand. The `description` is the trigger text, so keep it specific.
- `examples/` holds a sample run for `pan-os-cve-2026-0257`, one file per stage. It is output from an unattended planning run (environment profile all `Unknown`, validation `[PENDING EXECUTION]`), so use it as a format reference, not as evidence of validated detections. `examples/hunt-logs/` holds a blank worksheet only; a filled example would need invented hunt results. `examples/` is not listed in every README section.
- `.gitattributes` forces LF on `*.sh`; keep shell scripts LF on Windows.
- `agentic-threat-intel-framework` at the repo root is a gitlink (mode 160000) with no `.gitmodules`, and the directory is empty. Leave it alone unless asked.
- The methodology implemented is the [Unified Threat Hunting Process](https://github.com/sims718718/UnifiedThreatHunting). The plugin plans, records, and documents the hunt; executing queries and attack simulations is deliberately left to humans.
- Design docs for changes live in `docs/superpowers/specs/` and `docs/superpowers/plans/`.
