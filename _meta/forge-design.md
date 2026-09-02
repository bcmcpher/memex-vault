# memex-forge — WikiSkill Fork Design

**Status: design only.** Nothing described here is built. The fork begins after `v1.0.0`
final; this document is the plan it will follow, recorded now while the reasoning is fresh.

**Not a vault node.** Like `_meta/ccm-mapping.md`, this is design material rather than a
note: no `type:`, no `stage:`, and `_meta/` is outside every lint node check.

---

## Context

WikiSkill (Tang et al., Google Research, arXiv 2608.27454) co-evolves agent skills with a
persistent knowledge base. It separates **raw execution experience** (`raw/`), **accumulated
knowledge** (`wiki/patterns/`, `logs.md`, `index.md`, `skill-impact.md`), and **executable
skills** (`skills/`, each with a `PURPOSE.md` tracing back to motivating patterns). Four roles
drive the loop: an Inference Agent that executes tasks, a Wiki Maintainer that consolidates traces
into pattern pages, a Wiki-Informed Skill Proposer that emits one atomic skill patch per
iteration, and a validation gate that accepts a patch only if R strictly improves — while the wiki
itself *never* rolls back. Headline ablation: removing persistent knowledge accumulation costs 15
points.

memex-vault at `v1.0.0-rc.1` is already a three-layer knowledge system with a near-exact
isomorphism to that architecture, and most of the mapping lands on **data** (`_meta/domain.md`
fenced lists) rather than code.

| WikiSkill | memex-vault equivalent | Amendment cost |
|---|---|---|
| `raw/` execution traces | new source media + existing `.archive/` + `_meta/normalize.sh` | fenced-list lines |
| trace evidence | `extracts/` — quote-grounded `^cNN` claims; **lint §12d `grep -F`s every quote against the archived transcript** | zero |
| `wiki/patterns/` | `atoms/` — one claim per file, block-anchored `cites::`, `confidence:` | new rubric section |
| skill + `PURPOSE.md` | `topics/skills/` — topics derive membership from `part-of::`, never stored | one OKF Types row |
| `wiki/index.md` | `_meta/index.md` Dataview dashboard | new queries |
| `wiki/logs.md` | `_meta/log.md` — append-only, one block per event | zero |
| `wiki/skill-impact.md` | — **missing** | new file, `log.md`-shaped |
| Skill Proposer + gating | `_meta/candidates/` (`pending -> reviewed`) + `verified:` provenance | **the real work** |

Lint §12d is the sleeper asset: it makes "the agent claims failure mode X occurred in this
rollout" *mechanically verifiable against the transcript*. WikiSkill has no equivalent — its
pattern pages are ungrounded LLM summaries.

### Why a fork rather than a phase

The new node types and a frequency-based confidence rubric are edits to `_meta/schema.md`, which
this repo calls the vault's constitution and which `memex-init` refuses to modify. A breaking
amendment there bumps the major version and forces skill-evolution machinery onto every fork of a
template whose users want a research wiki. `_meta/roadmap.md` already says it: *"Since
v1.0.0-rc.1, the first move is a fork, not a phase."*

The fork is cheap precisely because the isomorphism is high. The schema amendment is **one new
relation field, three new source media, four OKF type rows, two stage vocabularies, and one
confidence rubric.** Everything else is new skills and two scripts.

Working name `memex-forge`, skills prefixed `forge-`. Cosmetic.

---

## The two vaults are not mutually exclusive

They are complementary, and the cleanest way to see it is read/write phase:

> **memex-vault is read by the agent *during* a session. memex-forge is written about the agent
> *after* one.**

|  | memex-vault | memex-forge |
|---|---|---|
| Answers | what is true about the world | what works in this harness |
| Curated by | the user, agent-assisted | the agent, user-gated |
| Evidence | published sources | execution traces, plans, specs |
| Confidence from | independent sources | independent rollouts + validated mitigation |
| Read/write | read at inference time | written after inference |
| Scope | one per person | one per person's harness |

They meet at exactly one place: **the Skill Proposer cites both.** "The atom on RAG-Sequence says
X" is as legitimate a reason to amend a skill as "this failed in three rollouts" — the
*references + evaluated experience* pairing the fork exists to serve.

### Cross-vault reads need no export

Both vaults are plain markdown with YAML frontmatter on a local filesystem. There is no database
to bridge and nothing to serialise: **the forge reads the research vault directly.**

The resolution mechanism already exists. Every skill resolves
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` (Phase 6, commit `ad848aa`); the forge
adds a second variable, **`MEMEX_REF`**, pointing at the research vault, and `--add-dir` grants
tool access to it. Reads are always current, with no build step and no staleness window.

The one real problem is that Obsidian wikilinks do not resolve across vaults. So a cross-vault
citation takes a URI form on the existing relation field:

```
cites:: memex:atoms/flash-attention
```

Greppable, lint-checkable against `$MEMEX_REF` (new §27), and honest about pointing outside the
vault. To make Obsidian's graph render it, symlink `$MEMEX_REF/atoms` into the forge and gitignore
the symlink — a local ergonomic choice that does not touch the data.

**Why not OKF export.** OKF buys schema decoupling, but the forge is a fork of the same template
sharing the same `_meta/schema.md` — the decoupling solves a problem that does not exist while the
fork tracks upstream. It also buys a pinned snapshot for citation reproducibility, but the
research vault is a git repo, so a citation that needs pinning can carry a commit SHA. Phase 8
stays valuable on its own merits (non-Obsidian readers, real interop); **the fork does not wait on
it.**

Reads stay one-directional by policy, not by mechanism: nothing writes from the forge back into
the research vault. That keeps the curation boundary clean. Direct read makes the reverse
direction *possible* later if it ever earns its place.

---

## Harness integration is core, not an add-on

The weak point of any port of this paper is R: replay is expensive and hand-authored eval cases
are the tax that kills such loops. Harness artifacts arrive **pre-labelled for free**, which
changes the economics enough that trace capture should mean *harness artifacts*, not just
transcripts.

| Artifact | Location | Free outcome label |
|---|---|---|
| plan files | `~/.claude/plans/*.md` | approved first try, or rejected + **the rejection text** |
| openspec specs/changes | project `openspec/` | shipped clean vs. amended post-implementation |
| session transcripts | `~/.claude/projects/<mangled>/*.jsonl` | full rollout, tool sequence, outcome |
| commits / PRs | git | survived review, or reverted |

`ExitPlanMode` is already a human gate; a rejection with reasoning is direct supervision, and the
highest-quality signal in the set. **Plan fidelity is computable with no judge and no replay:**
diff the files a plan said it would touch against the files the resulting commit actually touched.

Two guards, both load-bearing:

- **Goodhart.** Optimising for plan approval teaches "get approved," not "be right"; a fatigued
  user approving a weak plan is a poisoned label. Durable post-hoc signals — spec amended after
  implementation, plan/diff fidelity, commit reverted — are **primary**. First-try approval is
  weak secondary evidence and never sufficient alone for `confidence: high`.
- **Redaction.** Transcripts contain pasted credentials, third-party content, and personal
  identifiers. Trace *notes* (metadata, outcome, pointers) are committed; verbatim text goes to
  gitignored `.archive/` behind a redaction pass. The vault's existing node/archive split already
  enforces this shape — F2 must not weaken it.

**Scope.** Patterns like "over-spawns subagents" or "plans that omit file paths get rejected" are
harness-level, not project-level. **One forge**, with project as a tag. Split only if the graph
actually bifurcates.

---

## Runtime: a pure skill / subagent plugin

**No SDK, no orchestrator, no driver program.** Everything is markdown plus the two existing bash
scripts and one new Python capture script. The loop is driven by invoking skills; subagents do the
fan-out work.

This is a real constraint, not an aesthetic one, and it costs exactly one thing — recorded here so
the trade is visible rather than rediscovered later:

> A programmatic driver could run each replay rollout under `claude --bare`, which skips hooks,
> plugin sync, auto-memory and CLAUDE.md auto-discovery and so carries **exactly** the skill set
> under test. That is the paper's blind-inference requirement enforced by the harness. A subagent
> cannot get that isolation — it inherits the parent's configuration — so subagent replay degrades
> to "an agent instructed not to consult the wiki."

That is survivable because **Tier 1 of R is observational and needs no driver at all** (F5), and
replay is the optional second tier. It is also reversible: `_meta/eval-run.sh` is specified by a
**contract** — reads `evals.json`, writes a results JSON, exits 0/1 — never by an implementation.
If the weaker signal proves insufficient, a driver drops in behind that contract without touching
anything else.

Worth recording for that day: "Agent SDK vs. plugin of skills" is a false dichotomy. Per the Agent
SDK docs, skills, commands and memory "load automatically from your project's `.claude/` and from
`~/.claude/`, same as Claude Code," and plugins "package skills, agents, hooks, and MCP servers,
and load them by local path." **The SDK consumes the same artifacts this plan builds.** Nothing
here forecloses it; the artifact is the asset, the driver is a detail.

**Packaging.** For `0.1.0` keep one repo, matching the template/fork model. Extract the `forge-*`
skills, subagents and hooks into a proper plugin at `0.2.0` once they stabilise — the `$VAULT`
portability work already lets a skill operate on a vault it does not live in. Do not over-engineer
this at F0.

---

## Sequencing

The fork starts after **`v1.0.0` final**. That is the only gate — with direct cross-vault reads,
Phase 8 is not a prerequisite.

What blocks `v1.0.0` is the four verification-debt rows, which "cannot be discharged inside this
repository — it needs a vault with real notes." So the prerequisite is **using the vault for
real**.

**Harness-artifact capture can start now, before the fork exists.** Append-only capture to a
holding directory commits to no schema, costs nothing, and is forward-compatible — F2 backfills
from it. This directly addresses the problem that made 1.0 an rc: the fork would otherwise launch
empty, exactly as this repo did. Concretely:

- a `Stop` hook appending `{session_id, cwd, ts, transcript_path}` to a JSONL holding file
- copy `~/.claude/plans/*.md` on write, and record the ExitPlanMode outcome
- **reconcile the stale global skills.** `~/.claude/skills/` still holds `karpathy-wiki-ingest/`
  and `karpathy-wiki-search/` — the pre-rename names, and the ones actually loaded in sessions.
  The repo renamed them to `memex-*` in commit `9f2e921`, *after* which Phase 6 added the `$VAULT`
  portability fix (`ad848aa`). The installed copies therefore predate that fix and probably still
  hard-code an absolute vault path. Traces captured before this is reconciled record the behaviour
  of the *old* skills, which would poison the corpus at its root.

Hook commands must use an explicit `~/.claude-*-tools/bin/<cmd>` path: `nvm` is a shell function
sourced from `.bashrc`, so its bin directory is absent in the non-interactive shells where hooks
run. Confirm before wiring:

```bash
env -i PATH="$HOME/.claude-lsp-tools/bin:/usr/bin:/bin" bash -c '<cmd> --version'
```

| | Phase | Gate |
|---|---|---|
| upstream | populate vault, discharge verification debt -> **v1.0.0** | four debt rows closed |
| in parallel | harness-artifact capture to a holding dir; fix stale global skills | no schema commitment |
| fork | F0-F7 below | |

---

## Fork phase plan

Numbered `F` so it never collides with this repo's phases 0-9, per the rule that phase numbers are
never reassigned.

### F0 — Fork and provenance

Create from template. Do **not** edit `VERSION` (it records provenance, not the fork's version);
add `FORK_VERSION` = `0.1.0`. Add the `template` remote. Run `memex-init`, which reads `VERSION`
and writes `template:: v1.0.0` into `_meta/log.md`. Start a fresh `_meta/roadmap.md`; keep this
repo's as `_meta/roadmap-upstream.md`. Document `MEMEX_REF` in the README.

**Verify:** `bash _meta/lint.sh` exits 0.

### F1 — Schema amendment

The whole constitutional change, in five edits:

- `_meta/domain.md § Source Types` — add `trace`, `plan`, `spec`; create the three folders. Each
  gets naming, frontmatter and type checks for free, with no script edit.
- `_meta/domain.md § OKF Types` — add `sources/{trace,plan,spec}|Source` and
  `topics/skills|Skill Card`.
- `_meta/schema.md § Valid Relation Fields` — add **`mitigates::`** (Skill Card -> Pattern). This
  is `PURPOSE.md` as a graph edge, and it is the *only* new relation: `cites::` already covers
  Pattern -> Trace, `supersedes::` already covers Pattern -> Pattern.
- `_meta/schema.md § Stage Values` — harness sources: `uningested -> observed -> mined`. Skill
  Cards: `candidate -> active -> retired`.
- `_meta/schema.md § Confidence Values` — a Pattern-confidence subsection, scoped to atoms whose
  `cites::` resolve to harness sources.

Plus a short **§ Cross-Vault References** section documenting the `memex:<vault-relative-path>`
citation form and `MEMEX_REF`.

**Pattern confidence.** The bibliographic independence test does not apply; substitute rollout
independence — two traces are *not* independent if they are the same task instance, or the same
session (shared context contaminates both).

| Value | Requires |
|---|---|
| `low` | observed once |
| `medium` | >=2 independent observations, >=1 above Observed tier |
| `high` | >=3 independent observations, >=2 Validated-or-Corrected, >=1 block-anchored `cites:: [[ext-...#^cNN]]`, no unaddressed `contradicts::`, **and** an inbound `mitigates::` from a Skill Card whose proposal passed the gate |

The last clause is the fork's own contribution: **a pattern is not high-confidence until its
mitigation has been validated.** It expresses WikiSkill's `skill-impact.md` feedback loop in
memex's existing confidence grammar and makes the gate outcome load-bearing rather than logged.

Source tiers, **inferred at audit time and never stored**, mirroring the
reviewed/primary/curated/unreviewed ladder in § Confidence Values:

| Tier | Inferred from |
|---|---|
| Validated | replay trace, or a spec that shipped without amendment |
| Corrected | a plan or spec carrying explicit user rejection or amendment text |
| Observed | organic transcript with a recorded task outcome |
| Anecdotal | organic transcript, no outcome |

Corrected ranks high deliberately: a user's rejection text is direct supervision. First-try plan
approval lands no higher than Observed — the Goodhart guard, in the rubric.

**Also in F1, fix the 14-copy hazard.** `references/vault-schema.md` is byte-identical
(`md5 b4bede6ac5d6709bf46bbd15ef166016`) across 14 skills; this amendment would otherwise mean 14
hand-edits and guaranteed drift. Add `_meta/sync-refs.sh` (canonical -> every
`skills/*/references/`) plus a lint check that all copies match the canonical md5. Preserves
offline bundling, kills drift, and is worth offering upstream afterwards.

**Verify:** `bash _meta/lint.sh` exits 0 with new folders empty; hand-write one throwaway trace
source and confirm §1 naming, §2 frontmatter and §11a type checks all fire on it.

### F2 — Harness artifact ingestion

`_meta/harness-capture.py` — Python 3 stdlib only, matching the precedent set for the Phase 8
exporter (bash cannot parse JSONL sanely). The one piece of real code in the fork.

```
python3 _meta/harness-capture.py [--since <date>] [--holding <dir>]
```

Backfills from the holding directory, and emits:

- `sources/trace/YYYY-MM-DD-slug.md` — `medium: trace`, `model:`, `task:`, `outcome:`
- `sources/plan/YYYY-MM-DD-slug.md` — `medium: plan`, `outcome: approved|revised|rejected`,
  `revisions: N`, `fidelity:` once a commit exists
- `sources/spec/YYYY-MM-DD-slug.md` — `medium: spec`, `outcome: clean|amended`

plus redacted, normalised full text to `.archive/`.

Three hard constraints:

1. It must **shell out to `_meta/normalize.sh`**, never reimplement normalisation in Python. A
   drifted copy silently breaks lint §12d, which is the entire grounding guarantee. This is the
   same warning `_meta/roadmap.md` attaches to the Phase 8 exporter.
2. Redaction runs **before** anything reaches `.archive/`, and is fail-closed: a file that cannot
   be redacted is skipped and reported, never written partially.
3. Capture is **append-only and idempotent** — re-running over the same holding dir changes
   nothing.

**Verify:** capture a real session and a real plan; `grep -qF` a quote from the resulting extract
against the archive by hand; `bash _meta/lint.sh` exits 0 with §12 reporting no SKIPs; re-run and
confirm a clean `git status`.

### F3 — Wiki Maintainer

Two skills, both largely *configurations* of existing ones rather than new logic:

- `forge-observe` — harness source -> `extracts/ext-<slug>.md`. Structurally `memex-deep-extract`
  Mode A, with the claim `type:` vocabulary retargeted from
  `finding|definition|limitation|contrast|method` to
  `failure|workaround|strategy|environment|regression`.
- `forge-pattern` — extract claims -> pattern atoms. Structurally Mode B, plus the pattern
  confidence rubric and `part-of:: [[<skill-card>]]`.

Both write through `_meta/candidates/` (existing Candidate Gating) and log to `_meta/log.md`.

**Verify:** run both over 5-10 captured artifacts; lint §12b/§12c/§12d clean; >=1 pattern reaches
`medium`; >=1 pattern derives from a plan rejection rather than a transcript.

### F4 — Skill Proposer and the gate

The genuinely new machinery, and all of it markdown.

- `_meta/impact.md` — append-only, one block per gate event, shaped like `_meta/log.md`:
  `## [YYYY-MM-DD] <skill> | <verdict>` with `proposal::`, `patterns::`, `judge-score::`,
  `replay-score::`, `baseline::`, `outcome::`. **Never rolls back** — this is the paper's
  `skill-impact.md` and the Proposer's memory of what has already failed.
- `_meta/proposals/` — durable and *not* gitignored, unlike ephemeral `_meta/candidates/`. One
  file per proposal: `proposed`, `targets`, `action`,
  `stage: pending -> judged -> replayed -> applied|rejected`; body carries the diff, the
  rationale, and `cites::` into motivating patterns **and `memex:` references into the research
  vault**.
- `skills/forge-propose/` — reads the pattern index and `_meta/impact.md` *first*, then
  selectively opens pattern pages, extracts, and `$MEMEX_REF` atoms on demand (the paper's active
  retrieval, not fixed pre-sampling). Emits exactly **one atomic proposal** targeting **one**
  skill. Refuses to re-propose anything `_meta/impact.md` already rejected.
- `skills/forge-gate/` — stage 1, an LLM judge scores the proposal against cited evidence and the
  impact log; stage 2, optional subagent replay (F5); stage 3, presents the diff for human veto,
  recorded as `verified: - by: human:<user>` — the vault's existing sign-off primitive doing
  exactly the job it was built for. Applies or reverts, then appends to `_meta/impact.md`
  **either way**.

**Verify:** drive one full proposal -> judge -> veto -> apply cycle by hand; confirm a rejected
proposal survives in `_meta/proposals/` and `_meta/impact.md`, and that `forge-propose` declines
to repeat it.

### F5 — R: observational first, subagent replay second

**Tier 1, observational — no execution, no judge, no driver.** Computed from harness sources
already captured in F2: plan/diff fidelity, revision count before approval, spec amendment rate,
revert rate. This is the primary gate and it costs nothing per proposal.

**Tier 2, replay — optional, only for proposals Tier 1 cannot separate.** A `forge-replay`
subagent runs each eval task twice, with and without the candidate skill, and judges against
`expected_output`. Reuses the `skill-creator` `evals.json` format already present in
`skills/memex-ingest/evals/` and `skills/memex-search/evals/`, extended with
`"split": "train"|"val"|"test"`.

**State plainly in the skill doc that this is a weaker signal than clean-room replay.** A subagent
inherits the parent's configuration, so "without the candidate skill" means *instructed not to use
it*, not *unable to see it*. Treat Tier 2 as corroborating evidence, never as the sole basis for
accepting a proposal.

If that proves insufficient, `_meta/eval-run.sh` slots in behind a fixed contract — reads
`evals.json`, writes results JSON, exits 0/1 — with no other change to the design.

**Verify:** Tier 1 rejects a deliberately bad patch without reaching Tier 2; Tier 2 on the shipped
`memex-ingest` evals reproduces its ranking across two runs.

### F6 — Lint for the new layer

New sections in `_meta/lint.sh`, **numbered 20+** — 14-19 reserved for upstream so
`git diff template/main -- _meta/lint.sh` stays a clean append. One script matters: `lint.sh` is
the vault's *only* executable state oracle (`_meta/index.md` renders only inside Obsidian), and
two oracles is strictly worse than one long script.

| § | Check | Level |
|---|---|---|
| 20 | pattern atom with no harness-source backing | WARN |
| 21 | `confidence: high` pattern with no inbound `mitigates::` from a gated Skill Card | FAIL |
| 22 | proposal with no matching `_meta/impact.md` entry, or vice versa | FAIL |
| 23 | Skill Card with no `mitigates::`, or naming a nonexistent skill directory | WARN |
| 24 | harness source stuck at `stage: uningested` > 30 days | WARN |
| 25 | `references/vault-schema.md` copies diverged from canonical md5 | FAIL |
| 26 | committed harness source containing verbatim transcript text (redaction leak) | FAIL |
| 27 | `memex:` reference that does not resolve under `$MEMEX_REF` | WARN, SKIP if unset |

§27 must **SKIP, not FAIL, when `MEMEX_REF` is unset** — the same discipline §5 and §12 already
use for a missing `.archive/`. A forge clone without the research vault beside it is a legal
state, not a broken one.

Extend `count_links` (`_meta/lint.sh:80-95`) for `mitigates::` — it dedupes targets and requires a
populated field, so `mitigates:: [[A]], [[B]]` on one line counts 2. Do **not** reach for
`grep -c`; that is the exact bug commit `0fb8b7c` fixed.

### F7 — Pruning

The paper's own named limitation: the wiki accumulates pages, logs and diffs with no pruning.
`forge-prune` reuses `memex-stale`'s four read-only decay checks over the pattern layer: patterns
`supersedes::`-ed by a newer one, `low` confidence and untouched past a threshold, and mitigations
whose Skill Card is `retired`. Read-only proposals into `_meta/candidates/`; a human applies.

---

## Critical files

| File | Change |
|---|---|
| `_meta/domain.md` | +3 source media, +4 OKF Types rows. **Data only — no script edits.** |
| `_meta/schema.md` | +`mitigates::`, +2 stage vocabularies, +Pattern confidence and tier tables, +Cross-Vault References |
| `_meta/lint.sh` | +8 sections at 20+, extend `count_links` for `mitigates::` |
| `_meta/normalize.sh` | **unchanged** — call it, never reimplement it |
| `_meta/impact.md`, `_meta/proposals/` | new, durable, committed |
| `_meta/harness-capture.py`, `_meta/sync-refs.sh` | new — the only new executables |
| `skills/forge-{observe,pattern,propose,gate,prune}/SKILL.md` | new |
| `agents/forge-replay.md` | new subagent (F5 Tier 2) |
| `skills/*/references/vault-schema.md` | 14 copies -> canonical + `sync-refs.sh` + lint §25 |

**Every new skill must also register in five prose places** or it is invisible: `README.md`
§ Skill Lifecycle, § Workflow Patterns and § Claude Code Skills Reference, plus `memex-tend`'s §2
routing table and §3 ordering chain. Each needs the `$VAULT` preamble block, a
`## What This Skill Does NOT Do` section, a `_meta/log.md` entry template, and Candidate Gating.

## Reuse — do not rebuild these

- `_meta/normalize.sh` — deterministic, idempotent, and the precondition for lint §12d
- `memex-deep-extract` Modes A/B — F3 is a retargeting of these, not new logic
- `_meta/candidates/` lifecycle — already the human-veto primitive
- `verified:` provenance blocks — already the sign-off record; append-only, never bumps `updated:`
- `count_links` / `backing_sources` (`_meta/lint.sh:80-145`) — target counting is already correct
- topic derived membership via `part-of::` — Skill Cards need no member list
- `memex-stale` decay checks — F7's basis
- the `${MEMEX_VAULT:-...}` resolution pattern — `MEMEX_REF` is the same idea, second vault

## Verification

Gate every phase on `bash _meta/lint.sh` exiting 0 (exit 2 means the linter broke, not the vault).

End-to-end, once F5 lands:

1. `python3 _meta/harness-capture.py --since <date>` -> trace, plan and spec sources + archives
2. `forge-observe` -> `ext-*.md`; `bash _meta/lint.sh` §12d reports 0 SKIPs and 0 FAILs — proving
   every quoted claim is really in the transcript — and §26 reports no redaction leak
3. `forge-pattern` -> >=1 pattern at `confidence: medium`, >=1 sourced from a plan rejection
4. `forge-propose` -> exactly one proposal, citing that pattern **and** >=1 `memex:` reference;
   §27 resolves it against `$MEMEX_REF`, and SKIPs cleanly when that variable is unset
5. `forge-gate` -> Tier 1 score, human veto, `_meta/impact.md` entry
6. Re-run `forge-propose`; it must decline to repeat a rejected proposal — the `skill-impact.md`
   memory working, and the single most load-bearing behaviour in the design
7. After several accepted proposals, a pattern reaches `confidence: high` and §21 passes —
   confirming the mitigation-validated clause is reachable, not decorative

**What cannot be verified in-repo:** the four verification-debt rows, which the fork inherits. The
fork's advantage is that it *generates its own corpus* — every session run against it is a trace.
Cut `0.1.0` only after the loop above has run end-to-end on >=10 real artifacts.

## Deliberately out of scope

Any driver program — Agent SDK, orchestrator, or headless CLI harness (revisit only behind the
`eval-run.sh` contract, if Tier 1 proves insufficient). OKF export as a prerequisite. Skill
*retrieval* — the paper punts on it too, injecting skills directly; the vault's description-based
triggering is the analogue. Cross-model transfer experiments. Online refinement inside a single
long rollout. Any write path from the forge back into memex-vault.
