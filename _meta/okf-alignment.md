# OKF Alignment

Written: 2026-08-25. Companion to `_meta/roadmap.md`; holds the full design for
Phases 8–9 and the frontmatter changes those phases depend on in Phase 2.

Infrastructure doc — not a vault node. No frontmatter, and nothing should link to
it with a wikilink.

Target: **Open Knowledge Format v0.2**, `GoogleCloudPlatform/open-knowledge-format`.
Section references (§) below are to that repo's `SPEC.md`.

---

## Why bother

OKF is a vendor-neutral spec for knowledge as plain markdown plus YAML
frontmatter, with first-class provenance, trust, and lifecycle families. It is
architecturally the same object this vault is. Aligning costs little and buys an
interchange path; not aligning costs nothing today and forecloses one later.

The audit's finding is that the gap is **small and almost entirely additive**,
with exactly one collision that reads *wrong* rather than merely absent.

## The two-layer split

The organising constraint is that **nothing may regress Obsidian or Dataview**.
That rules out changing four things in-vault that OKF wants:

| OKF wants | Vault has | Why it cannot change in-vault |
|---|---|---|
| Markdown links `[t](/p.md)` (§6.1) | `[[wikilink]]` | Dataview inline fields resolve wikilinks; Obsidian backlinks and graph view depend on them |
| ISO 8601 + UTC offset (§5) | `YYYY-MM-DD` | Date-only is honest for "when I saved this", and is what Templater and the `YYYY-MM-DD-slug` naming convention emit |
| Materialized `index.md` (§8) | Dataview queries in `_meta/index.md` | The Dataview dashboard is a feature; a static list would go stale immediately |
| Untyped links (§6.1) | 16 typed epistemic relations | The typed vocabulary is the vault's constitution and is strictly richer than OKF |

So the work splits in two:

1. **In-vault (Phase 2):** additive keys and one rename. Free, and each item also
   pays for itself independent of OKF.
2. **Export layer (Phase 8):** a deterministic, LLM-free Python script that
   *translates* the four items above rather than changing them.

## Field mapping

| OKF field | Vault field | Disposition |
|---|---|---|
| `type` (required, §4.1) | — | **Add in Phase 2.** The only hard conformance blocker |
| `title` | `title:` | Already exact, all seven templates |
| `description` | `## Summary` / `## Definition` / `## Overview` prose | **Add in Phase 2.** Right content, wrong location |
| `resource` | `url:` (sources) | Keep `url:`. Exporter maps it. Absent on abstract nodes, correctly |
| `tags` | `tags:` | Already exact. The vault's controlled vocabulary is stricter than OKF requires, which is legal |
| `sources[]` (§5.1) | `cites::` / `rebuts::` / `raw::` | **Never duplicate into frontmatter.** Derived at export |
| `generated.{by,at}` (§5.2) | — (`skill::` in `_meta/log.md`) | **Add in Phase 2.** Information exists, at the wrong granularity |
| `verified[]` (§5.2) | — | **Define in Phase 2, write in Phase 4** |
| `status` (§5.4) | `status:` | **Collision.** Rename ours to `stage:` |
| `stale_after` (§5.5) | — | **Decline.** See divergences |
| Actor convention (§7) | — | Adopt in Phase 2 alongside `generated:` |
| `Attested Computation` (§10) | — | Not applicable. A reading vault has no computations |
| `okf_version` (§12) | — | Emitted by the exporter on the bundle-root `index.md` only |

Extension keys kept as-is, permitted by §4.1: `confidence:`, `aliases:`,
`medium:`, `authors:`, `year:`, `venue:`, `channel:`, `tool:`, `domain:`,
`term:`, `question:`, `attendees:`, `context:`, `created:`, `updated:`,
`saved:`, `reviewed:`.

## Deliberate divergences

Four places where the vault knowingly does not follow OKF. Recorded so they are
not re-litigated as bugs.

**`stale_after` is not adopted on atoms.** OKF wants a declared absolute instant.
The roadmap already removed temporal atom decay from `memex-stale` (commit
`8c6b5cc`) and M3 records that refusal as deliberate: an atom does not become
false by sitting still. Lint 7c's computed freshness warning stays as the
heuristic. The exporter omits the field rather than synthesising a fake one.

**`_meta/log.md` keeps its format.** OKF §9 wants `## YYYY-MM-DD` headings
grouping prose bullets. Ours is `## [YYYY-MM-DD] <medium> | <title>` with
Dataview inline fields, which `memex-log-query` parses. Changing it would churn
ten writing skills and one reading skill for a file OKF marks optional. The
exporter regroups it instead.

**`url:` is not renamed to `resource:`.** `url` is clearer in a reading vault,
and the rename would touch lint, six index queries, and most skills for a pure
aliasing gain.

**Typed relations survive export as labelled prose.** §6.1 says relationship kind
is carried "by the surrounding prose, not by the link itself", so an OKF consumer
flattens all sixteen to untyped edges. The exporter renders them under a
`# Relations` heading as labelled bullets with real markdown links: legal
structural markdown per §4.2, lossless for a memex-aware reader, degrading
cleanly for everyone else.

## Where the vault is ahead of OKF v0.2

Not conformance gaps. Recorded so the non-conformance is not misread as
inferiority, and so none of these get traded away chasing the spec.

- **Typed epistemic relations.** OKF has untyped edges only.
- **Controlled tag vocabulary with lint enforcement.** OKF tags are free-form.
- **Candidate gating** (`_meta/candidates/`). OKF has no notion of a
  proposed-but-unapplied write.
- **A lint gate that actually fails** (Phase 0). OKF specifies no validator.
- **The Phase 3 evidence layer.** OKF's `sources[]` records *where* a claim came
  from; it cannot detect fabrication. Grounding every claim's verbatim quote
  against normalized `.archive/` text with `grep -F` makes fabrication
  mechanically detectable. OKF has no equivalent at any tier.

One genuine convergence worth noting: OKF §5.1 stores per-source credibility
*signals* (`author`, `usage_count`, `last_modified`) and refuses to store a
score, on the grounds that a score is "subjective, unportable across consumers,
and goes stale". That is the identical conclusion roadmap P2 reached
independently — "source count is the wrong unit no matter how it is weighted".
Phase 4 should borrow OKF's field names rather than invent parallel ones.

## Exporter derivation table

Every OKF field is computed. Nothing below is hand-maintained in the vault.

| OKF output | Derived from |
|---|---|
| `type`, `title`, `description`, `tags` | verbatim passthrough |
| `resource` | `url:` on sources; omitted for abstract nodes |
| `status` | `stage:` → `stub` ⇒ `draft`; `abandoned` ⇒ `deprecated`; else `stable` |
| `generated`, `verified` | verbatim passthrough |
| timestamps | `YYYY-MM-DD` → `YYYY-MM-DDT00:00:00Z` |
| `sources[]` | one entry per `cites::` / `rebuts::` / `raw::` target. `id` = target slug; `resource` = bundle-relative path, or the target's `url:` when external; `title` = target's `title:`; `author` = target's `authors:` / `channel:` / `tool:` |
| per-claim attribution | `cites:: [[note#Section]]` anchors → `[^slug]` footnotes keyed to `sources[].id` (§5.1) |
| body links | `[[note]]` → `[title](/path/note.md)`; `[[note#Sec]]` → `[title](/path/note.md#sec)` |
| typed relations | `# Relations` heading, labelled bullets, real markdown links |
| topic `covers` | materialized by scanning atoms' `part-of::` — the Phase 1 dependency |
| `index.md` | generated per directory from each concept's `title` + `description`; no frontmatter except `okf_version: "0.2"` at the bundle root (§8, §12) |
| `log.md` | `_meta/log.md` regrouped into §9 `## YYYY-MM-DD` headings with prose bullets |
| excluded | `_meta/` except the transformed `log.md`; `_templates/`; `_exports/`; `.obsidian/`; `.archive/` unless `--include-archive` |

### Output location

`_okf/`, top-level, git-tracked. The bundle is the shippable artifact and §3
recommends git distribution, so it should be diffable in history.

> **Hard requirement.** `_okf/` is a full second copy of every note. It **must**
> be added to Obsidian's *Settings → Files & Links → Excluded files*. Without
> that, every note appears twice in search, quick-switcher, graph view, and every
> Dataview query — the one way this work could regress Obsidian functionality.
> `memex-init` (Phase 6) scaffolds the exclusion; until then it is manual.

## Conformance checklist (§11)

The three hard MUSTs, and their status once Phases 2 and 8 land.

| Rule | Today | After |
|---|---|---|
| 1. Every non-reserved `.md` has parseable YAML frontmatter | ⚠️ templates yes, `_meta/*.md` infra docs no | ✅ `_meta/` excluded from the bundle |
| 2. Every frontmatter has a non-empty `type` | ❌ 0 of 7 templates | ✅ Phase 2 |
| 3. `index.md` / `log.md` follow §8 / §9 | ❌ wrong path and format | ✅ Phase 8 generates both |
