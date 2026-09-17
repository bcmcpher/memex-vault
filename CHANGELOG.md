# Changelog

All notable changes to memex-vault are recorded here.

This is a **template repository**. A vault created from it with GitHub's *Use this
template* starts from a single fresh commit and carries none of the history below,
so this file and the root `VERSION` file are how a fork identifies what it was
built from. `memex-init` records that version in `_meta/log.md` at fork time.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) as
applied to the vault's *format*: the major version changes when a schema change
would require an existing fork to migrate its notes.

Phase numbers refer to `_meta/roadmap.md`, which tracks the work in more detail
and is the authority on what remains.

## [Unreleased]

**Two roadmap items applied before trial 2**, at the user's request. Both were
chosen on one test: does it change *what* the trial measures, or *how reliably* it
is measured? Neither changes vault semantics, so the trial still measures `rc.2`'s
behaviour — with a better instrument and a safer working directory. Everything else
open was left alone, because applying a behaviour change and then trialling it is
what `rc.1` did.

### Added

- **`R9` — regression fixtures and CI for `lint.sh`.** `_meta/test-lint.sh` plus
  eight fixtures in `_meta/lint-fixtures/`, and `.github/workflows/test.yml`.

  Lint is 1,700 lines of bash and the vault's only executable state oracle, and it
  was verified by reading its output and deciding the output looked right. Two
  defects got past that: **M20**, a provenance parser that read note prose as
  provenance and shipped in `v1.0.0-rc.1` because the field it parses had never
  been written; and the **7h** hole, where `cites:: [[ghost]]` linted clean at
  exit 0 *and* suppressed the orphan warning that would have caught the atom —
  found by reading another project's linter, not by testing this one. Both are now
  fixtures.

  Each fixture is a sparse overlay holding only the notes under test; the harness
  builds the scaffold from this vault's real `schema.md` and `domain.md`, so a
  fixture tests lint rather than restating the schema. Coverage: the zero-note case
  `memex-init` runs on, dangling targets, `url:` uniqueness and credentials, the
  M20 parser, the two FAIL checks (so `exit 1` itself is pinned), quote grounding,
  the four topic-tree rules, and M15 independence.

  **Verified the suite can fail.** Deleting section 7h fails `dangling-targets`;
  removing the M20 parser bounds fails `provenance-prose`. A suite that cannot fail
  is decoration.

  A green CI check deliberately does not claim everything: `.archive/` is
  gitignored, so section 12 SKIPs there and quote grounding is never verified in
  CI. It is a local guarantee by construction, and the workflow says so.

### Changed

- **`R14` — skills refuse to write when `$VAULT` is not a memex vault.** The
  invariant vault-root block in all 21 skills now carries
  `[ -f "$VAULT/_meta/schema.md" ]`, with the instruction to stop and tell the user
  rather than create the missing paths. A stale `MEMEX_VAULT`, or a skill invoked
  from an unrelated repository, otherwise writes `sources/`, `atoms/` and
  `_meta/log.md` into *that* repository, and the first sign is `git status`.

- **Open roadmap rows now carry a release target**, not just a status. *Deferred*
  said whether something was done, never whether it blocks `1.0` — different
  questions, and the second is the one a release decision turns on. Of the fourteen
  rows not yet done: **eleven are `1.x`** (new capability; the vault is coherent
  without them), **one blocks `1.0` in part** (`R2`, the labelling half — the README
  says quote-grounded and M19 showed the guarantee is narrower than it reads), **one
  is undecided and with the user** (`R8`, a demonstrated defect whose only known fix
  is a runtime), and `R4` is a partial whose remaining half is `1.x`.

*Next: trial 2 — a full run against this tree on a fresh fork. A trial that
surfaces nothing new worth fixing promotes `v1.0.0`; a trial that surfaces
something produces the next RC, which is the process working rather than failing.*

## [1.0.0-rc.2] — 2026-09-17

Applies every trial-1 finding that was going to be applied, adds one skill, and
dispositions every known open question — including fifteen differences against a
comparable system. **Tagging this does not promote anything:** what promotes
`v1.0.0` is a trial against the tag that finds nothing new, and the honest
expectation is that trial 2 finds something.

Findings referenced as `M*` are in `_meta/roadmap-applied.md`; open work is
`R1`–`R16` in `_meta/roadmap.md`.

### Added

- **`memex-seed` — manifest-driven bulk seed.** The 21st skill, and the one new
  capability in RC-2 (roadmap Stage 6). Input is a manifest path plus a directory
  of already-fetched, already-normalized archives; output is N paper source notes
  with their `.archive/` copies, a concept-map scaffold, and **one** grouped log
  entry. Six steps: validate, report independence, propose the topic tree, one
  shared question round, write, log and hand off to `memex-deep-extract` mode A.
  It fetches nothing, creates no atoms, wires no relations and assigns no
  `confidence:` — stated in the skill so it cannot drift.

  The gap it fills is narrow on purpose. When a corpus is already retrieved, the
  expensive and failure-prone step has happened, and the per-URL path just asks the
  same five questions N times. So this is not a batched `memex-save`.

  Four decisions worth recording, because each is a trap:
  - A manifest's own validation verdict is **ignored**. It is a snapshot of
    whichever validator built it; on the RC-2 reference corpus it records four
    failures the current `_meta/validate-archive.sh` passes. Seed re-validates at
    seed time, one file per call, and reports exit 2 apart from exit 1 — a usage
    error is not a verdict about a document.
  - Independence (M15) is **connected components** of a
    shares-a-person-key-or-cites relation, not pairwise author overlap. Dependence
    is transitive, so an A–B–C author chain is one unit and no pairwise test finds
    it. Seed refuses to proceed quietly past any component of size ≥ 2.
  - Archives are copied in and normalized **before** their note is written, since
    a `raw::` naming a missing file is a lint FAIL. Seed is also the one skill that
    creates `.archive/` and `_meta/candidates/`, both gitignored and so absent from
    the fresh clone it runs on.
  - Candidate gating cannot cover the `_meta/log.md` append, because no skill gates
    the log and `memex-candidates` never writes one. Seed logs before reporting and
    documents the manual recovery.

  Registered in the README skill tables and lifecycle block, `_meta/schema.md`
  § Workflow Stages, and `memex-candidates`' producer list. The skill count moves
  **20 → 21**; the "20 skills" statements inside released sections below are
  historical records of what `v1.0.0-rc.1` shipped and are left alone.

- **Three `lint.sh` checks adopted from claude-obsidian** (roadmap Stage 7,
  `_meta/comparison-claude-obsidian.md`). Each closes a hole demonstrated on a
  throwaway clone, and each is a WARN — a dangling link and a duplicate URL are
  bookkeeping a human resolves, not corruption.
  - **7h — dangling relation target.** Until now a `[[target]]` was resolved in
    exactly two places: `part-of::`, and a `cites::` whose anchor was *block*-form.
    So `cites:: [[ghost]]` and `cites:: [[ghost#Summary]]` both linted clean at
    exit 0 — and worse, writing one into an isolated atom *silenced* the section 4
    orphan warning, because section 6b counts `cites::[[` occurrences without
    resolving them. A fabricated citation read as evidence and suppressed the only
    check that would have caught the atom. 7h resolves every `field:: [[Target]]`
    on every layer against one table. On the reference vault it resolved **191
    targets with no findings** and cost 0.25s.
  - **2b — two sources at one URL.** A duplicate adds no evidence, and if neither
    note carries `authors:`/`channel:`/`tool:` it adds a phantom unit to the
    independent-source count that § Confidence Values reads. Comparison is
    deliberately shallow: scheme and host lowercased, one trailing slash and any
    `#fragment` dropped. The three capture skills had three different answers to
    this and none of them was in the oracle.
  - **2c — a credential in a saved URL.** `sources/` is tracked, so a signed link
    or share token pasted once is committed and rewriting history is the only
    removal. The sensitive-key vocabulary is ported from claude-obsidian's
    `url_safety.py` rather than invented, which is what catches the vendor forms
    (`X-Amz-Signature`, `X-Amz-Security-Token`).

- **`memex-reconcile` gained Pass 2 — dangling everything else.** 7h's findings
  needed an owner, or a new WARN class would simply accumulate. The pass takes
  `cites::` first and separately: a dangling `related::` is a broken
  cross-reference, a dangling `cites::` is an atom that reads as grounded and is
  not. Its old Pass 2 is now Pass 3.

- **`_meta/comparison-claude-obsidian.md`** — the Stage 7 output. Fifteen
  differences against `claude-obsidian` pinned at `32ac5a0` (v2.2.0, 2026-09-10),
  each with a verdict and evidence: 3 adopted, 7 roadmap, 5 declined. Two
  architectural questions are recorded for the user rather than decided. Required
  by RC-2 Decision 4 — an undecided difference is something trial 2 would report
  as new.

### Changed

- **`_meta/schema.md` § Source URLs.** A new subsection under Node Types stating
  the two rules section 2 now checks: one source note per URL, and a URL never
  carries a credential. `memex-save` and `memex-ingest` cite it instead of each
  carrying a private version of the rule.

- **`year:` on source notes is now `published:`, with variable precision.**
  `year:` could only ever hold the coarsest publication date, so a skill that
  fetched a real one — arXiv gives a full submission date — had nowhere to put
  anything but the year. `published:` takes the most precise value reliably known:
  `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`. Padding a partial date is forbidden;
  `2012-01-01` for a paper known only to be from 2012 is a fabricated day that
  reads as a measured one. `published:` and `saved:` answer different questions and
  a paper note carries both. New `_meta/schema.md` § Publication Dates; updated in
  `_templates/source-digital.md`, `_meta/okf-alignment.md`, and the
  `memex-save` / `memex-ingest` / `memex-connect` field lists.

  **Forks with existing paper notes:** rename the field. `year:` was required by
  schema but never checked by `_meta/lint.sh`, so nothing flags a note left
  behind.

### Fixed

- **Lint counted relation lines, not link targets.** `_meta/lint.sh` sections 6c,
  8d, and 8e used `grep -c`, which counts matching *lines*, while the schema
  blesses `introduces:: [[A]], [[B]]` on one line. 8d therefore warned
  "under-extracted" about sources that had yielded several atoms, and 6c's
  bloated-atom check could never fire. All three now use a `count_links()` helper;
  thresholds are unchanged. Roadmap Phase 2, item 15.

### Changed

- **Atom promotion is documented as plural.** `memex-ingest` step 6 now enumerates
  every candidate concept and asks per atom, matching how step 7 already handles
  glossary terms and how `memex-connect` and `memex-meeting` were already written.
  `README.md`, `_meta/schema.md` § Node Types, and `topics/concepts/getting-started.md`
  now say explicitly that "one concept per file" bounds an *atom*, not a source.

### Documentation

- **The roadmap reached the template, and split in two.** This repository's copy
  stopped at M5 while skills in it already cited roadmap M8, M11, M11a, M11c, M13,
  M14, M16, M18, M20 and M21 — ten labels absent from the file they pointed at. The
  2026-09-11 fork revision is now ported (M6–M22 and § The RC-2 seed corpus), every
  finding carries a status marker, and the file is split by status:

  - **`_meta/roadmap.md`** — what is **open**. Sixteen `R` rows, the release state,
    the phase sequence, and what trial 2 is for.
  - **`_meta/roadmap-applied.md`** — what **shipped**. 25 applied findings with
    their full arguments and their original labels, the seven completed phases, and
    the retired verification-debt rows.

  The old convention was six prefixes — `L S E P M O F` — whose meanings appeared
  nowhere, with `M` spanning two tiers, numbers ordered by discovery, ad-hoc
  sub-letters, no status field, and no way to record that two findings were one.
  Eighteen live rows became sixteen because `M6`, `M19` and comparison verdict 1
  were one problem stated three times; `R2` merges them and keeps all three original
  statements. Applied labels were **not** renamed: nine of the ten labels cited from
  code are applied ones, and `lint.sh` cites them in comments that explain why the
  code is shaped as it is. § Renumbering carries the mapping.

  Three stale claims were corrected in the port rather than carried forward — most
  importantly § The RC-2 seed corpus, which described a manifest field that does not
  exist and four validator failures that a re-run does not reproduce.

- **`_meta/skill-evaluation.md` ships empty, with instructions.** A template has no
  usage to evaluate, and trial evidence belongs to the vault that produced it: the
  trial-1 campaign ran on 16 sources by named authors in one field, and shipping it
  would hand a fork a filled-in log of somebody else's vault. The findings that
  generalized are in the roadmap, carrying the measurement they rest on. What ships
  is the scaffold plus the rule that makes it useful — a finding needs an observed
  trigger, or it belongs in the roadmap as an idea.

- **README documents the concept-map hierarchy.** New § Concept maps nest, and only
  concept maps: `part-of::` does double duty, the child names the parent, one parent
  maximum, `topics/projects/` and `topics/research/` sit outside the tree, and an
  atom names a leaf. The `_meta/` tree listing is also current — it was missing the
  roadmap, the validators, and `_meta/candidates/`.

### Planned

- **R1 / Phase 8** — OKF export layer: `_meta/okf-export.py` plus a `memex-export`
  skill, emitting an Open Knowledge Format v0.2 bundle to `_okf/`. Designed in
  `_meta/okf-alignment.md`; the only unblocked phase. Ships as `v1.1.0`.

### Deferred

Full statements with evidence in `_meta/roadmap.md` § Open Work.

- **Phase 5** — Anki render mode on `memex-compose`. Designed, unscheduled.
- **Phase 9** — OKF import (`memex-import`). Waiting on a real consumer; its shape
  depends on what third-party bundles turn out to look like.
- **R2** *(was M6 + M19)* — source version model and the content hash that would
  make drift detectable. **R3** *(M8)* — conceptual extraction from code
  repositories. **R4** *(M10)* — the Zotero retrieval tier; its validation half
  shipped. **R5** *(M3)* — temporal claim fields. **R6** *(M4)* — typed open
  questions. **R7** *(S2)* — a worked example.
- **R8–R14, from the `claude-obsidian` comparison** — recorded, not scheduled, to be
  evaluated alongside other pending plans. Transactional multi-file writes (`R8`,
  architectural — it means a second language in the tree); lint fixtures and CI
  (`R9`, the highest-value one); source authority (`R10`) and bounded session context
  (`R11`), both pending evidence that this vault has the problem; log rollup (`R12`);
  a retrieval index (`R13`); and a `$VAULT` sanity guard (`R14`, the cheapest).

## [1.0.0-rc.1] — 2026-09-02

First tagged release. The vault is feature-complete for use: 20 skills covering
the full lifecycle, a schema split into constitution and instance vocabulary, an
evidence layer, and an orchestrator. Interchange (Phase 8) is the one planned
capability still outstanding.

Released as a **release candidate** rather than a final because of known
verification debt, described below. That debt cannot be discharged inside this
repository — it needs a vault with real notes in it, and this repository is a
template that deliberately ships empty.

### Added

- **`memex-tend` orchestrator** (Phase 7). Routes `_meta/lint.sh` findings to the
  skill that resolves each one, in dependency order. Triage is the default mode.
  It never invokes `memex-deep-extract`, `memex-compose`, `memex-refactor`, or
  `memex-init` — the expensive and the destructive stay manual.
- **`memex-init` onboarding skill** (Phase 6). Five questions, then it rewrites
  `_meta/domain.md`, scaffolds the folders that vocabulary implies, seeds one
  topic, writes the `_okf/` Obsidian exclusion, and leaves the vault passing lint.
- **Evidence layer** (Phase 3). A new `extracts/` node type holding quote-grounded
  claims addressable by block reference, plus `memex-deep-extract` to build them
  and `_meta/normalize.sh` as the canonical text-folding implementation. Lint
  section 12 greps every quote against the normalized archive, which makes
  fabricated quotes mechanically detectable. This also gave `.archive/` its first
  consumer.
- **`_meta/domain.md`** (Phase 2). Instance vocabulary — domain name, three tag
  groups, the `medium:` vocabulary, and the folder-to-`type:` table — split out of
  `_meta/schema.md`, which is now purely the constitution. `lint.sh` reads its tag
  and node-type vocabulary from here, so extending a vocabulary means editing one
  file. `README.md` § Specializing This Template is the fork guide.
- **Atom writing style spec** (Phase 2). `_meta/schema.md` § Atom Writing Style:
  five rules, each tied to an existing lint signal, so the spec is checkable rather
  than aspirational.
- **OKF v0.2 frontmatter** (Phase 2). Additive keys across every template and
  writing skill, landed here rather than in Phase 8 because this phase already
  rewrote all of them.
- **Provenance blocks** (Phase 4). `memex-trust-audit` writes `verified:` blocks;
  lint section 13 checks them.

### Changed

- **`memex-trust-audit` rebuilt on the claim rubric** (Phase 4).
- **Confidence derives from evidence** (Phase 3). The unit is independent claims
  across independent sources, not source count. Source tiers are inferred at audit
  time and never stored, and an atom with no extract is capped at `medium`.
- **`covers::` is now derived, not stored** (Phase 1). Topic membership comes from
  `part-of::` via Dataview; `covers::` was the same data in a second place, and
  keeping the two in sync was the whole reason `memex-reconcile` existed.
  **Breaking** for any vault predating this release.
- **`status:` renamed to `stage:`** (Phase 2). `status:` collided with OKF v0.2.
  Ours moved; `status:` is now unused in-vault, so OKF's "absent means stable"
  default applies. **Breaking** for any vault predating this release.
- **`topic-type:` retired** (Phase 2) in favour of a single `type:` discriminator
  at node granularity. `medium:` remains the source subtype.
- **`related::` promotion pass** folded into `memex-reconcile` (Phase 1),
  surfacing untyped links older than 30 days for typed-relation assignment.
  Phase 7 routes lint section 7's findings to it.
- **All 20 skills resolve the vault root at run time** (Phase 6) as
  `${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}`. Previously 18 skills
  hard-coded the template author's absolute path on 54 lines, which broke every
  fork silently — the real reason a fork did not work, and a problem the roadmap
  had never named.
- **`lint.sh` reads source media from `_meta/domain.md`** (Phase 6) instead of
  hard-coding five values. A fork's new source folder previously got no checks at
  all, silently, while the README claimed otherwise.
- **Obsidian plugin requirements trimmed to one** (Dataview). Everything else the
  templates use is covered by core Templates.

### Fixed

- **`lint.sh` can now fail** (Phase 0). `warn()` and `error()` incremented the same
  counter, the script had no `exit 1`, and the summary reported both alike. The two
  genuine-corruption checks — source naming and archive mismatch — gated nothing,
  so any hook or CI job shelling out to lint passed silently.
- **One definition of an orphan atom** (Phase 0). `lint.sh` and `_meta/index.md`
  disagreed, and the index's version was latently broken: `_meta/log.md` records
  `atoms:: [[...]]` on every ingest, so on the first real log entry
  `length(file.inlinks) = 0` would have gone false for every atom ever ingested and
  the orphan query would have returned nothing, permanently, with no error. Both
  now use the single definition in `_meta/schema.md`, which counts inbound links
  only from curated folders.

### Known verification debt

Four things are built and pass against fixtures but have never run over real
notes, because the template ships with 0 atoms, 0 sources, 0 extracts, and 0
glossary terms. This is the reason for the `-rc` suffix.

| What | Built in | Verified by |
|---|---|---|
| Every Dataview query in `_meta/index.md` | Phases 1–2 | Opening a vault with notes in Obsidian |
| `memex-init`'s five-question flow | Phase 6 | The first real fork |
| `memex-tend`'s ordering | Phase 7 | The first vault with enough findings to sequence |
| `memex-deep-extract` end to end | Phase 3 | The first deep extraction of a real source |

Fixture-testing caught two real bugs during Phase 6, so it is not worthless. But
no amount of it substitutes for one pass over real notes.

## Pre-release history

Untagged. Summarized for orientation; `git log` is the record.

- **2026-07-09** — Roadmap revision. `_meta/deep-extract-design.md` written.
  Lint's `FAIL` level made to gate (Phase 0).
- **2026-06-10** — `_meta/roadmap.md` added, the improvement plan this changelog
  tracks against. `_meta/ccm-mapping.md` added.
- **2026-05-07** — Skill inventory settled at 17. `memex-capture` and `memex-read`
  collapsed into `memex-save`; `memex-topic-emerge` added.
- **2026-05-01** — Repository renamed to memex-vault and skills renamed from
  `karpathy-wiki-*` to `memex-*`. Provenance citations and candidate gating added.
- **2026-04-29** — Glossary, capture, connect, review, and topic-init skills.
- **2026-04-27** — Initial commit: README, the `getting-started` concept map, and
  `_meta/lint.sh`.

[Unreleased]: https://github.com/bcmcpher/memex-vault/compare/v1.0.0-rc.1...HEAD
[1.0.0-rc.1]: https://github.com/bcmcpher/memex-vault/releases/tag/v1.0.0-rc.1
