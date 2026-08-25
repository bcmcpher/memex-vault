# PaperGuru-CCM ↔ memex-vault mapping

Generated: 2026-06-10. Reference note comparing this vault's design to the
**Capital Chunk Memory (CCM)** architecture described in the PaperGuru
paper. This is infrastructure documentation, **not a vault node** — it has
no frontmatter and is not an atom, source, or topic. Do not link to it with
typed relations.

---

## What the PaperGuru-Benchmark repo actually is

The [PaperGuru-Benchmark](https://github.com/PaperGuru-AI/PaperGuru-Benchmark)
repo is **not a plugin** and contains no importable skill/agent/plugin
structure. It is a research artifact with four top-level parts:

- `paper/PaperGuru-CCM.pdf` — a NeurIPS-2026 submission describing
  **Capital Chunk Memory (CCM)**, an instance of **Lifecycle-Aware Memory
  (LAM)** for long-horizon LLM agents.
- `PaperBench/submissions/` — 23 reproductions of *other people's* ML
  papers (adaptive-pruning, robust-clip, pinn, …) used to **score** the
  system. These are evaluation targets, not PaperGuru's own code.
- `SurveyBench/{pdf,markdown,latex}` — 20 generated survey documents
  (outputs, analogous to this vault's `_exports/`).
- `assets/` — figures, demos, badges.

There are no skills, agents, MCP servers, Obsidian config, or runnable
PaperGuru implementation here. Any product implementation lives outside
this repo (likely private). So nothing can be copied file-for-file — the
useful connection is **conceptual**.

---

## Why it maps onto this vault

CCM's two central ideas are ones this vault already implements by hand:

1. **A two-surface memory** — a compact, bounded, indexed *routing surface*
   over an unbounded *raw-content surface* accessed only on demand.
2. **A two-class typed graph** — edges split into *structural* relations
   (how artifacts connect) and *historical-causality* relations (how
   claims change over time).

The vault separates `sources/` summaries (indexed) from `.archive/` raw
text (off-index, fetched via `raw::`), and `_meta/schema.md` already groups
relations into structural vs. epistemic/skeptical classes. CCM is the same
design with formal names and an algorithmic framing. The user's intuition —
that PaperGuru "connects with the existing layout" — holds at the design
level, even though there is no plugin to import.

---

## Mapping table

| PaperGuru CCM concept | memex-vault equivalent | Fit |
|---|---|---|
| **Chunk heads** — compact bounded routing surface, one per artifact | `sources/*` notes ("URL + why-saved + short summary. Never full article text"), indexed by Obsidian/Dataview | strong |
| **Chunk contents** — unbounded raw text, accessed lazily on demand | `.archive/YYYY-MM-DD-slug.md` referenced via `raw::`; gitignored + excluded from the indexer | strong |
| Routing layers *above* the head | `atoms/` → `topics/` hierarchy (vault adds layers CCM does not describe) | vault exceeds |
| **Structural edges**: `cites`, `introduced-by`, `implements` | `cites::`, `introduces::`, plus atom→atom `uses::` / `extends::` / `part-of::` (which also carries topic membership) | strong |
| **Historical-causality edges**: `superseded-by`, `deprecated-by`, `retracted-by`, `discussed-in` | `supersedes::` (direct match) plus skeptical `contradicts::` / `refutes::` / `challenges::` / `limits::`; no first-class `deprecated-by` / `retracted-by` | partial |
| **Axiom 1** — versioned content; staleness after revision/deprecation/retraction | `updated:` timestamp, `confidence`, `supersedes::`, `stale`/`needs-review` tags — but no automatic staleness propagation | partial (see Gaps) |
| **Axiom 2** — structural multi-hop relevance ("evidence two citations away, not one cosine hop") | top-down typed traversal `topics/ → atoms/ → sources/`; "sources are never searched directly" (README *Concept*) | strong — this vault's core thesis |
| **Axiom 3** — bounded query cost under unbounded archive growth | layered routing (search hits topics/atoms, not all sources) + lint split thresholds (bloated atom, topic > 15 atoms) + off-index `.archive/` | good |
| **Axiom 4** — provenance-grounded composition (every claim traces to a verifiable artifact) | `cites:: [[note#Section]]` provenance anchors (`_meta/schema.md`) + `memex-compose` ("every sentence traces to an atom or source body") | strong |
| **Pipeline**: Search → Extract → Reason (**Compose → Critique → Mutate**) → Verify | `memex-search` → `memex-ingest` → `memex-compose` → `memex-reconcile` / `memex-trust-audit` / `memex-conflicts` | maps, with one gap (see Gaps) |

---

## Strong alignments (already implemented)

- **Head/content split.** `sources/` notes hold only a summary and
  why-saved; full text is opt-in under `.archive/` via `raw::`, gitignored
  and excluded from Obsidian's indexer. See `_meta/schema.md` → *Archive*
  and README → *Source Text Archival*. This is exactly CCM's chunk-head vs.
  chunk-content separation, including the "raw is lazy / on-demand" property.

- **Two-class typed graph.** `_meta/schema.md` already groups relations by
  epistemic role: structural (`extends::`, `uses::`, `part-of::`, `cites::`)
  vs. epistemic/skeptical (`contradicts::`, `supersedes::`, `limits::`,
  `refutes::`, `challenges::`). CCM's structural vs. historical-causality
  split is the same partition arrived at independently.

- **Structural multi-hop retrieval.** The vault is explicitly graph-first,
  not embedding-first: "Sources are never searched directly — instead, they
  feed upward into concept atoms, which feed upward into topic maps"
  (README → *Concept*). `memex-search` walks typed edges top-down. This is
  CCM Axiom 2 ("the right evidence is two citations away, not one
  cosine-similarity hop").

- **Provenance-grounded composition.** `cites:: [[note#Section]]` heading
  anchors record exactly which section of a source backs a claim, and
  `memex-compose` is read-only with the invariant that "every sentence in
  the output traces to an atom or source body — nothing is invented." This
  is CCM Axiom 4.

---

## Gaps (considered, not adopted)

These are the two places where CCM goes beyond the current vault. **Neither
is being adopted now** — they are recorded so future sessions need not
re-derive them.

- **First-class lifecycle / retraction edges.** CCM distinguishes
  `deprecated-by` and `retracted-by` from `superseded-by`, and treats
  supersession as a trigger for staleness. The vault folds all replacement
  into a single `supersedes::` edge and does not auto-flag a superseded atom
  as stale. **Deferred** — this is open roadmap item **M3** in
  `_meta/roadmap.md` ("No temporal model on claims — `supersedes::` handles
  atom replacement, not time-bounded claims"). It also runs against a
  deliberate decision: `skills/memex-stale/SKILL.md` removed atom temporal
  decay because "atom freshness is domain-dependent and left to the user's
  judgment." Adopting CCM Axiom 1 would reverse that stance, so it is left
  as an open question, not a recommendation.

- **Compose → Critique → Mutate loop.** CCM's Reason stage iterates: draft
  a segment, critique it, mutate, repeat. `memex-compose` is single-pass
  and instead relies on the user manually chaining `memex-reconcile` →
  `memex-trust-audit` → `memex-conflicts` *before* composing (README
  *Maintenance cadence*: "Before sharing research"). The critique/mutate
  function is therefore distributed across separate skills rather than run
  as an inline loop. Recorded as an observation only — no change proposed.

---

## Source

- Repo: <https://github.com/PaperGuru-AI/PaperGuru-Benchmark>
- Paper: `paper/PaperGuru-CCM.pdf` in that repo (CCM / Lifecycle-Aware
  Memory, NeurIPS-2026 submission).
