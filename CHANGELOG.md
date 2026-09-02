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

### Planned

- **Phase 8** — OKF export layer: `_meta/okf-export.py` plus a `memex-export`
  skill, emitting an Open Knowledge Format v0.2 bundle to `_okf/`. Designed in
  `_meta/okf-alignment.md`; the only unblocked phase.

### Deferred

- **Phase 5** — Anki render mode on `memex-compose`. Designed, unscheduled.
- **Phase 9** — OKF import (`memex-import`). Waiting on a real consumer; its shape
  depends on what third-party bundles turn out to look like.
- **M3** — temporal claim fields. **M4** — typed open questions. Neither blocks
  anything.

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
