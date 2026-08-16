# multi-research-stack

An LLM-driven research collaboration stack: **pi (student/executor) + claude (teacher/mentor) +
optional adversarial reviewer**, built around two planes:

- **Data/state plane (files, not replaceable)** — `RESULTS_LEDGER.md` as the single source of
  truth for every number, `NEXT_TASK.md` / `DONE_LOG.md` / `REVIEW*.md` for handoff and audit,
  and `check_numbers.py` as a fail-closed traceability guard.
- **Transport/control plane (replaceable)** — herdr or tmux; only one-line "please read X.md"
  notifications ever cross it.

## Why

Two failure modes of LLM-driven research are structural, not fixable by "being careful":

1. **Fabricated / misremembered numbers.** Countered mechanically: every number must trace to a
   disk artifact (with sidecar SHA-256), and a guard script re-verifies the manuscript against
   the ledger — including a *second hop* that rejects numbers whose only ledger appearances are
   in retracted/voided contexts. The guard must fail closed (`--selftest` asserts it exits
   non-zero on known-bad inputs).
2. **Rigorous but not novel.** A teacher-side novelty gate (with live full-text literature
   checks, not training memory) must approve any idea before it consumes GPU — and the gate is
   *continuous*: every reframe / hypothesis change / mechanism swap re-enters it.

## Contents

| Path | What it is |
|---|---|
| `SKILL.md` | Bootstrap: role self-configuration workflow, file layout, collaboration loop |
| `roles/teacher.md` | Teacher (mentor) duties: novelty gate, experiment design, integrity, writing |
| `roles/student.md` | Student (executor) duties: run, measure, ledger discipline, SUBMIT-before-run |
| `references/rules.md` | **Iron rules 0–15** — hard constraints for both agents (verify-before-analyze, line-by-line reference reading, one-change-one-verification, baseline-first, conservative reporting, 30-min literature check before novelty claims, falsifiable minimal experiments, citation-before-assertion, adversarial claim review, confirmation-bias discipline at confirming data, novelty gate on every claim mutation, run-identity verification, **fail-closed guards with self-failure tests**, **boundary-first debugging with entry conditions recorded in the artifact**) |
| `templates/` | Scaffolding laid into a project: ledger, task queue, done log, review, ideas, check_numbers.py, COLLAB_PROTOCOL |
| `COLLAB_PROTOCOL_evolved.md` | The collaboration protocol **as battle-tested in a real project** (one measurement-paper campaign, 58 adversarial review rounds), including: evidence-required bug-fix reporting (grep/run evidence, no verbal "done"), structural-before-parametric fixes, per-step asserts in multi-step edits |
| `scripts/` | `init.sh` (role bootstrap, transport autodetect), `collab.sh` (herdr peer discovery), `notify.sh`, `start.sh` |
| `agents/novelty-screener.md` | First-pass novelty screen (abstract-level, produces a `<<<SCREEN_HANDOFF>>>` block with candidate closest-known-works for the reviewer to verify) |
| `agents/novelty-reviewer.md` | **The adversarial novelty gate**: falsification-style review of any idea/hypothesis/claim mutation before it consumes GPU — mandatory live deep search (full-text PDF verification, never training memory), three search directions (domain / general-ML mechanism / fresh preprints), typed evidence anchors, 7 AI-research failure-mode self-checks, verdict NOVEL / PARTIALLY_NOVEL / INCREMENTAL / KNOWN |

## The collaboration loop

```
teacher: idea → novelty gate → NEXT_TASK.md ──(one-line notify)──▶ student
student: read task → RUNNING → execute → numbers into ledger (with sha) → DONE_LOG
teacher: adversarial review → REVIEW.md (PASS/REVISE/REJECT) ──(notify)──▶ student
before delivery: python check_numbers.py   # 0 warnings, both hops
```

Long content always lives in files; the transport plane carries only "please read X.md".

## Provenance

Extracted from a live GPU speech research project (measurement and characterization of a
generative speech-enhancement model on embedded hardware). The stack was not designed upfront —
it accreted around real failures: over ~60 adversarial review rounds between the teacher and a
dedicated reviewer agent, the rules and guard mechanisms repeatedly caught errors before they
reached the record — mixed measurement calibers, contaminated baselines, silently-failing
validation scripts, over-attributed mechanisms, numbers whose retraction had not propagated.
Nothing in the final submission traced to a tainted source. The iron rules below are the
generalized form of those catches: each one exists because its absence once cost real work.
