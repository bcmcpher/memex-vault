# Deep Extract — Design

Written: 2026-07-09. Design for roadmap Phase 3 (finding E1).
**Implemented 2026-08-25.** Six things changed between the design and the build;
they are recorded in *Implementation decisions* at the end, and the body below has
been corrected to match what actually shipped.

Infrastructure doc — not a vault node. No frontmatter, and nothing should link to
it with a wikilink.

---

## The problem

The vault captures sources at **document granularity**. A source note holds a
human-written `## Summary` and `## Key Points`, and typed relations point from
that whole document at hand-curated atoms. Nothing in the vault stores what a
source *actually said, sentence by sentence*.

Tools like [Hyper-Extract](https://github.com/yifanfeng97/Hyper-Extract) and
[sift-kg](https://github.com/juanceresa/sift-kg) attack the same problem from the
other end: exhaustive chunk-level extraction of entities and relations, followed
by a reconciliation pass that merges duplicates. sift-kg reports 425 entities from
12 papers.

Dumping that output into `atoms/` would destroy this vault: 425 single-cite
`confidence: low` atoms, every topic blown past the 15-atom lint threshold, and the
"one hand-curated concept per file" invariant gone.

**The extraction output is not atoms.** It is the evidence layer the atom layer has
always implied exists but never stored.

---

## Design thesis

Three moves, each extending an existing vault convention rather than inventing a
parallel one.

**1. `_meta/schema.md` already is the extraction ontology.** sift-kg's `academic`
domain ships `SUPPORTS, CONTRADICTS, EXTENDS, IMPLEMENTS, USES_METHOD`. This
vault's constitution ships `supports, contradicts, extends, uses, limits,
contrasts-with`. That convergence is not a coincidence. Deep-extract therefore runs
in sift-kg's *closed-vocabulary* mode with `schema.md` as the domain file. No
second ontology, nothing to reconcile between two vocabularies.

**2. Provenance anchors already go one level deeper than the vault uses them.**
`schema.md` mandates `cites:: [[note#Section]]` with heading anchors. Obsidian
block references give `cites:: [[note#^c17]]` for free — a citation to a single
extracted claim rather than to a whole `## Key Points` section. Same field, finer
grain. `schema.md` must document this as an extension rather than let it drift in.

**3. Candidate gating already is sift-kg's review pipeline.** sift-kg runs
`extract → build → resolve → review (merge_proposals.yaml, stage: DRAFT) →
apply-merges`. This vault runs `propose → _meta/candidates/ (stage: pending) →
user confirms → write`. Structurally identical. The only mismatch is scale: a
30-page paper yields ~50 claims and you cannot ask 50 confirmation questions.
Fix: **the extract note itself is the review artifact**, exactly as
`merge_proposals.yaml` is sift-kg's. One document to read, not 50 prompts.

The strongest idea borrowed here is
[DeepPaperNote](https://github.com/917Dhj/DeepPaperNote)'s **grounding lint**:
every claim carries a verbatim quote, and `grep -F` checks it actually appears in
the archived raw text. Fabricated claims become mechanically detectable, with no
LLM in the verification loop. Fabrication is deep extraction's characteristic
failure mode and this is the cheapest possible defense — but only if built
carefully. See "Making the grounding check real."

---

## The new layer: `extracts/`

One file per deep-extracted source, filename derived from the source's with an
`ext-` prefix:

```
sources/paper/2026-04-27-lewis-rag-retrieval-augmented-generation.md
extracts/ext-2026-04-27-lewis-rag-retrieval-augmented-generation.md
```

The prefix is load-bearing. Mirroring the filename *exactly* — which this document
originally specified — puts two notes in the vault under one name, and Phase 2's
own § Disambiguation Policy opens by stating that Obsidian resolves wikilinks by
filename. Every `cites:: [[2026-04-27-lewis-rag-…]]` already written on an atom
would have gone ambiguous the moment its extract appeared, silently. The prefix
keeps the mapping mechanical in both directions while leaving one name per file.

Density sits between `.archive/` (raw text, gitignored) and `sources/` (prose
summary). In the `_meta/ccm-mapping.md` framing this is the missing rung of the
lazy raw surface: an extract is written once and **harvested many times**. An
extract made in January can be re-promoted in June, when an atom finally exists
that wants its evidence.

### Format

Claims are **bullet list items**, because Obsidian only allows a block identifier
at the end of a paragraph's last line or directly on a bullet.

Per-claim metadata uses plain single-colon `key:` sub-bullets, deliberately **not**
Dataview `::` fields. Two reasons, both verified:

- Dataview inline fields in a paragraph **lift to page level**. Fifty claims would
  collapse `type` / `about` / `quote` into three merged page-level arrays — you
  could never query "the quote for `^c17`" anyway. Per-claim retrieval is text
  parsing (`grep` / `awk`), not Dataview, and the format should be honest about
  that.
- Bare `about:: [[atom]]` would fire once per claim, emitting ~50 phantom graph
  edges into the atom graph before a human approved any of them.

Single-colon keys are inert to Dataview and to lint's unknown-relation-field scan,
and stay inert if that scan is ever widened. Only two real Dataview fields exist,
both at the top of the note.

````markdown
---
type: Extract
title: "Extract: Retrieval-Augmented Generation for Knowledge-Intensive NLP"
description: Claim-level extraction of the RAG paper.
extracted: 2026-07-09
claims: 47
generated:
  by: memex-deep-extract/claude-opus-5
  at: 2026-07-09
---

extracted-from:: [[2026-04-27-lewis-rag-retrieval-augmented-generation]]
mentions:: [[retrieval-augmented-generation]], [[dense-passage-retrieval]]

## Claims

- RAG combines a pretrained seq2seq generator with a dense vector index of Wikipedia accessed by a neural retriever. ^c01
    - type: method
    - about: `retrieval-augmented-generation`, `dense-passage-retrieval`
    - quote: "RAG models which combine pre-trained parametric and non-parametric memory for language generation."

- RAG-Sequence conditions on a single retrieved document for the whole output; RAG-Token may draw each token from a different document. ^c07
    - type: contrast
    - about: `rag-sequence`, `rag-token`
    - quote: "...each target token may be drawn from a different document."

## Concepts

| Mention | Resolution | Target |
|---|---|---|
| retrieval-augmented generation | matched | `retrieval-augmented-generation` |
| RAG-Token | new (7 claims) | — |
| attention | ambiguous | `attention-transformers` / `attention-cogsci` |

## Proposed Relations

| Subject | Relation | Object | Via |
|---|---|---|---|
| `rag-sequence` | `contrasts-with` | `rag-token` | `^c07` |

## Promotion Log
<!-- appended by mode B, one line per promoted claim -->
````

Staging tables use **backticked slugs, never `[[wikilinks]]`**. A proposed relation
is not yet a graph edge; rendering it as a link would create edges the human never
approved.

Three fields from the original sketch are gone. `source:` and `medium:` were
derivable — the filename and `extracted-from::` already name the source twice, and
`medium:` belongs to the source note — so keeping them would have rebuilt the
duplication Phase 1 spent its whole budget removing. `grounded: true` was worse: a
cached lint verdict stored inside the file it judges, which goes stale on the next
edit and which a fabricating writer can simply assert. Grounding is what lint
computes, never what a note claims about itself. `claims:` survives, because
Dataview cannot count block ids and the index needs the figure — and lint
cross-checks it so it cannot drift.

`type:` is the bridge from free extraction into the vault's closed vocabulary:
`finding → supports::`, `definition → glossary`, `limitation → limits::`,
`contrast → contrasts-with::`, `method → uses::`.

---

## Making the grounding check real

The anti-fabrication guarantee is the best idea here, and a naive implementation of
it is worthless. Three obstacles, each with a fix.

**1. `lint.sh` had no exit code.** `error()` only incremented a counter shared with
`warn()`; the script returned `0` even with FAILs present. A grounding check that
"hard FAILs" would have gated nothing.

> Fixed in Phase 0. `lint.sh` now separates `fails` from warnings and exits `1`.
> This also promoted the two pre-existing FAIL sites — source naming and archive
> mismatch — into real gates. Both denote genuine corruption, so that is the right
> contract; it was a deliberate change, not a side effect. Grounding becomes the
> **third** FAIL site.

**2. `grep -F` against raw PDF text produces false failures.** PDF-to-text output
is hard-wrapped, so any multi-sentence quote spans line breaks and never matches.
Ligatures (`ﬁ`), smart quotes, soft hyphens, non-breaking spaces, hyphenation
across line breaks, and em-dash-vs-hyphen all break literal matching. An LLM's
transcription of messy source text normalizes silently.

> Fix: **normalize once, at archive time.** `memex-deep-extract` writes
> `.archive/<slug>.md` already normalized — paragraphs **unwrapped to one line
> each**, whitespace collapsed, ligatures folded, smart quotes and dashes flattened
> to ASCII, line-break hyphenation rejoined — and extracts quotes from *that
> artifact*. Exact match then holds by construction, and a mismatch really is
> fabrication or post-hoc editing. Two rules follow: quotes are single-line, and
> **no ellipsis inside a quote** — emit two quote lines instead.

**3. `.archive/` is gitignored, so the check cannot run on a clone.** Raw full text
is a copyright hazard and must stay ignored. If the grounding section FAILed on a
missing archive, every fresh clone would fail lint.

> Fix: a missing archive is a **SKIP**, not a FAIL. *Unverifiable* is not
> *fabricated*. The section FAILs only when the archive exists and the quote is
> absent from it. The guarantee is therefore inherently local-only — worth stating
> plainly rather than pretending it runs in CI.

---

## Skill: `memex-deep-extract` (one skill, two modes)

Following `memex-refactor`'s existing three-mode precedent. One skill, not two —
roadmap P4 already names "17 peer skills, no meta-skill … decision paralysis" as a
problem, and this work should not deepen it.

### Mode A — extract

Writes exactly one file: `extracts/<source>.md`. Mutates nothing else.

1. **Require grounding.** Read the source's `raw::` archive. If absent, fetch the
   URL, write a *normalized* `.archive/` file, add `raw::` to the source note, then
   proceed. Refuse if neither is possible — a claim with no checkable quote is not
   a claim.
2. **Pass 1 — claims.** Emit propositions, each with a verbatim quote. This is
   Hyper-Extract's `atomic_facts` field, whose spec is literally "exact string
   copies of the atomic facts or sentences from the source text that provide
   evidence for this relationship."
3. **Pass 2 — concepts.** Derive concept mentions *from the claim set*, never from
   the raw text. That is Hyper-Extract's ordering, and it guarantees every concept
   is grounded in at least one quoted fact.
4. **Pass 3 — relations.** Typed edges between concepts, each carrying a `via`
   claim id. Vocabulary restricted to `schema.md`'s Valid Relation Fields.
5. **Pass 4 — resolve.** Match each mention against the vault: exact slug
   (`ls atoms/`), alias (`grep -rl "aliases:"`), then LLM comparison against the
   atom title list. Mark `matched` / `new (N claims)` / `ambiguous`. This is
   sift-kg's Layer 1 + Layer 2 without embeddings — the vault has bash and an LLM,
   not SemHash, and keeping it that way is a goal.
6. **Write the extract, run the grounding check, report.**

No chunking machinery. Hyper-Extract's 2048-char windows and sift-kg's 10k-char
chunks exist because those pipelines target small-context batch models. A paper
fits in context; long sources go section-wise.

### Mode B — promote

Turns reviewed extract content into atom changes, through ordinary candidate
gating, one confirmation at a time. Re-runnable: an extract is a standing source of
evidence, not a one-shot import.

- Enrich `## Detail` on matched atoms, citing `cites:: [[extract#^c17]]`.
- Recompute `confidence:` from **independent claims across independent sources**,
  not source count.
- Propose typed relations from the staging table.
- Propose glossary stubs for `type: definition` claims.
- **Propose atom stubs only for concepts appearing in ≥ 3 claims** (threshold
  configurable). The chosen middle path: it bounds the explosion that produced
  sift-kg's 425 entities while still surfacing load-bearing concepts not yet
  atomized. Under-threshold concepts stay in the extract as unpromoted evidence.
- **Propose `contradicts::` / `challenges::` links** where two claims about the same
  concept, from different sources, assert incompatible things.

Every proposed atom edit routes through `memex-refactor`'s revise semantics: bump
`updated:`, and ask about `confidence:` as a **separate explicit question**, never
bundled into the content change.

### What it does NOT do

- Mode A never writes an atom, glossary entry, or topic. One file, that is all.
- It does not replace `memex-ingest` (which summarizes) or `memex-connect` (which
  wires whole sources to atoms). Ingest first, then extract.
- It never deletes atoms. Retirement stays `supersedes::` plus a stub.
- It is **user-invoked and selective**, never automatic or vault-wide. sift-kg costs
  $0.72 for 12 papers; this is the most expensive skill in the vault.

### Do not touch `memex-conflicts`

`memex-conflicts` declares, three times in its SKILL.md, that it "does not infer
conflicts from atom content — only follows explicit relation fields already in the
graph." That is its defining contract.

Claim-comparison inference therefore lives in deep-extract **mode B**, which is a
*proposing* skill and already candidate-gates every write. It proposes a
`contradicts::` edge; the human approves it; the explicit field now exists; and
`memex-conflicts` audits it exactly as designed, with its invariant intact. The
inference happens at promotion time, not at audit time. `memex-conflicts` gets
better inputs and zero code changes.

---

## Anki: a new mode of `memex-compose` *(Phase 5 — deferred, unscheduled)*

> **Not Phase 3.** `_meta/roadmap.md` gives Anki its own phase, and the roadmap
> wins: Phase 3 touched nothing Anki-related — no `anki/` folder, no
> `.obsidian/app.json` change, no `memex-compose` render mode. The section below
> stands as the Phase 5 design and is unchanged by the build.
>
> **Phase 5 was then deferred outright (2026-08-25)** — low priority against the
> refactoring ahead of it. This section is kept whole rather than trimmed: its
> one dependency, extract claims, already exists, so the work is unblocked
> whenever it is wanted and does not need re-deriving. See `_meta/roadmap.md`
> § Phase 5.

The claim layer is what makes flashcards good. Without it you can export glossary
terms and atom summaries — thin, definitional, mostly things you already know. A
claim is already a proposition with a verbatim citation attached: exactly the
atomic unit spaced repetition wants.

`memex-compose` already walks topic → atoms → `cites::` sources, read-only, and
renders to a file. Anki export is the *same traversal with a different renderer*.
Making it a compose mode keeps the net skill count at 18, not 19.

### Card sources

- **Extracted claims** → Cloze cards. The primary source.
- **Glossary terms** → Basic term → definition cards. Only `stage: reviewed`
  entries, never `stub`. This half works today, with no extract needed.

Atom summaries are deliberately excluded: atom prose is discursive and makes poor
recall cards.

### Card rules

- **One card per claim**, not per atom.
- Cloze when the claim turns on a specific name, quantity, or comparison.
- **Every card back carries the `[[source]]` link plus the verbatim quote.**
- **Do not drill unverified claims.** Skip claims whose atom is `confidence: low`
  unless the user opts in. Only possible because the vault tracks confidence — and
  a direct argument for anchoring confidence properly (P2).
- Claims under an active `contradicts::` become a **contrast card**, never an
  assertion card.

### Output format and idempotence

Obsidian_to_Anki plain-text format — zero dependencies, preserving the vault's
one-bash-script property.

```
TARGET DECK: Memex::deep-learning
FILE TAGS: memex claim

START
Cloze
Text: RAG-Token may draw each token from a {{c1::different document}}, unlike RAG-Sequence.
Back Extra: [[2026-04-27-lewis-rag-retrieval-augmented-generation]] — "...each target token may be drawn from a different document."
Tags: rag foundational
<!--ID: 1751993847221-->
END
```

Card identity keys off the extract block id, stable across re-exports, resolved by
`grep` / `awk` — **not** Dataview, which cannot see per-block fields. The plugin
writes Anki note IDs back as `<!--ID: ...-->`, turning a re-export into an update
rather than a duplicate.

**Those written-back IDs are durable state, not a throwaway render.** So decks do
**not** go in `_exports/`:

1. `.gitignore` excludes `_exports/` as a *directory*. Git never descends into it,
   so a `!_exports/anki/` negation cannot re-include anything. Rescuing it needs
   `_exports/*` plus a negation: a footgun for a template repo.
2. Durable state inside a folder named "exports," where everything else is an
   ephemeral render, is confusing.

Decks go in a versioned top-level `anki/`, added to `.obsidian/app.json`'s
`userIgnoreFilters`.

---

## What the extract layer unlocks

| Payoff | Gap it closes |
|---|---|
| `confidence:` derived from independent claims, not source count | **P2** — "three blog posts agreeing isn't `high`" |
| Inferred `contradicts::` proposals, fed to `memex-conflicts` as explicit fields | conflicts can only audit what is already explicit; nothing ever proposed |
| A remediation path for "under-extracted source" | lint 8d and `memex-trust-audit` G13 — the lint already detects this and nothing could fix it |
| `memex-compose` footnotes resolving to verbatim quotes | strengthens its "nothing is invented" invariant |
| Concept co-occurrence inside a claim as a 4th clustering signal | `memex-topic-emerge` — finds topics *before* atoms exist |
| Flashcards carrying real propositions with provenance | Phase 5 — *deferred, unscheduled* |
| `raw::` / `.archive/` acquires its first real consumer | `_meta/ccm-mapping.md` lazy raw surface |

### Extracts and `memex-search`

`memex-search`'s thesis is top-down traversal — topics → atoms → sources, sources
never grepped directly. That rule exists because sources are unstructured prose:
grepping them yields unranked hits with no epistemic status.

Extracts are structured, typed, and quote-grounded, so that objection does not apply
to them. But making them a primary search surface would quietly gut the curation
discipline. The rule:

> Extracts are a **gap-finding** surface, never an answer surface. Reach a claim
> through an atom's `cites::`. When a direct extract search runs as a fallback,
> every hit is reported as *unpromoted evidence*, never as vault knowledge.

That is a genuinely new capability: *"the vault has evidence about X but has not
formed a concept about it."* A coverage-gap detector with the evidence attached,
feeding `memex-topic-emerge`. It slots into `memex-search`'s existing grep fallback
path without disturbing the primary traversal.

---

## Changes required (Phase 3) — *as shipped*

Every `lint.sh` scan is folder-scoped (`find "$VAULT/atoms"`, `.../sources`,
`.../topics`, `.../glossary`). **A new `extracts/` folder is therefore inert to all
existing sections** — no defensive edits to naming, frontmatter, or bloat
heuristics are needed. That held; the work was additive throughout.

**Create**
- `skills/memex-deep-extract/SKILL.md` + `references/vault-schema.md` copy
- `_templates/extract.md`
- `extracts/.gitkeep`
- `_meta/normalize.sh` — not in the original list. The design assumed
  `memex-deep-extract` would normalize at archive time, but `memex-ingest` was
  already writing un-normalized archives, so extracts taken from them would have
  thrown false grounding FAILs. Normalization is now a standalone script and
  **every** archive-writing skill pipes through it. See *Implementation
  decisions* 1.

**Modify**
- `_meta/schema.md` — extract node type; `extracted-from::` and `mentions::`
  relation fields; `[[note#^claim-id]]` block anchors; § Extract Claims;
  **§ Confidence Values rewritten** on the independent-claims rubric; § Archive
  rewritten around `normalize.sh`; `ext-` in Naming Conventions; the orphan
  definition amended to name `extracts/` as non-curated
- `_meta/domain.md` — `extracts|Extract` in the OKF Types table
- `_meta/lint.sh` — new section 12 (grounding: FAIL on a missing quote, SKIP on a
  missing archive), plus section 2 extract fields, the section 5 clone fix, and
  7e scanning `extracts/`
- `_meta/index.md` — `## Extracts`, "extracts with unpromoted claims", "processed
  sources with no extract"
- `skills/memex-ingest/SKILL.md` — archives written through `normalize.sh`
- `skills/memex-search/SKILL.md` — extracts as a gap-finding fallback surface only
- `skills/memex-trust-audit/SKILL.md` and `skills/memex-stale/SKILL.md` — recommend
  `memex-deep-extract` for under-extracted sources
- `skills/*/references/vault-schema.md` — **14 identical copies.** The list above
  originally named only the one new copy; the per-skill schema reference fans out
  to every skill, and Phase 1 under-counted the same way. All 14 kept
  byte-identical (verified: one md5)
- `README.md` — layer diagram, new skill, new folders, `ext-` rationale

**Moved in:** the confidence rubric (roadmap **P2**) was scheduled for Phase 4 but
written here, while the schema was already open. Phase 4 shrinks accordingly.

**Moved out, to Phase 5:** `anki/.gitkeep`, `.obsidian/app.json`'s
`userIgnoreFilters`, and `skills/memex-compose/SKILL.md`'s render mode.

**Explicitly unchanged:** `skills/memex-conflicts/SKILL.md`. That held — no edit
was needed or made.

**Reference while writing:** `skills/memex-ingest/SKILL.md` (richest writer, the
candidate-gating pattern), `skills/memex-refactor/SKILL.md` (in-place atom edits,
multi-mode skill shape), `skills/memex-compose/SKILL.md` (read-only traversal).

---

## Verification (Phase 3)

1. `bash _meta/lint.sh` on a clean vault → passes, `echo $?` = 0.
2. Ingest one real arXiv paper with `memex-ingest`, archiving raw text.
3. Run mode A. `git status --short` shows **exactly one** added file under
   `extracts/` and nothing else.
4. **Grounding, positive:** lint passes the grounding section, `echo $?` = 0.
5. **Grounding, negative:** hand-edit one `quote:` to text absent from the archive.
   Lint must print FAIL **and** `echo $?` = 1. *This is the load-bearing test.* If
   the exit code is 0, the anti-fabrication guarantee is decorative.
6. **Grounding, skip:** `mv .archive /tmp` and re-run. The section must SKIP, not
   FAIL — this is what a fresh clone looks like, and step 1 must still hold.
7. **Normalization:** choose one quote spanning a hyphenated line break and one
   containing a ligature or smart quote in the original PDF. Both must ground
   cleanly. This is exactly where a naive implementation throws false failures.
8. Open the extract in Obsidian. Hover `cites:: [[extract#^c07]]` from an atom; the
   block preview must show the claim with its quote sub-bullet.
9. **Orphan divergence:** create an atom with no `cites::` that an extract
   `mentions::`. It must be treated identically by `lint.sh` section 4 and by
   `index.md`'s orphan query. (Phase 0 unified the definition; `extracts/` is not a
   curated folder, so the atom stays an orphan in both.)
10. Run mode B. Each atom write is individually confirmed and writes a
    `_meta/candidates/` file first. Kill the session mid-promotion; confirm
    `memex-candidates` resurfaces the pending ones.
11. `grep -c '\^c' extracts/*.md` equals the `claims:` frontmatter count.
12. ~~Run compose in `anki` mode, import via Obsidian_to_Anki, re-run and
    re-import. Cards must **update, not duplicate**.~~ **Phase 5.**
13. `memex-search` a term appearing only in an extract. It must report "unpromoted
    evidence," not present it as vault knowledge.

---

## OKF correspondence

Recorded so Phase 8 does not reinvent it. **No design change follows from this
section** — it names a correspondence that already exists.

Open Knowledge Format v0.2 §5.1 attributes claims *per claim* rather than per
document, using a footnote key joined to a `sources[]` entry id:

```markdown
RAG-Token may draw each token from a different document.[^lewis-2020]
```

That is the same object as a claim block id. An extract's `^c07` addresses one
proposition, `extracted-from::` names the source, and `quote:` carries the
verbatim evidence — so the exporter renders one as the other mechanically:
`^c07` becomes the footnote key, `extracted-from::` resolves to the
`sources[].id`, and the `quote:` sub-bullet becomes the footnote body. Nothing
needs to be stored twice, and no frontmatter field exists to keep in sync.

The corollary matters more than the mapping: **block-reference addressing was the
right call independently**, and the format the vault picked for Obsidian's sake
turns out to be the format the interchange standard wants. Full analysis in
`_meta/okf-alignment.md`; the exporter is roadmap Phase 8.

---

## Non-goals

- No embeddings, no SemHash, no Python, no vector store. Resolution is grep plus an
  LLM. The vault's bash-and-an-LLM property is worth keeping — Phase 3 added
  `_meta/normalize.sh` as a second bash script beside `lint.sh`, and that is the
  shape any further tooling should take. (Phase 8's exporter is stdlib Python by
  its own separate decision; it is not part of this pipeline.)
- No n-ary hyperedges. Hyper-Extract's `participants: [A, B, C]` model is elegant,
  but the vault's relation vocabulary is binary throughout, and a claim's `about:`
  list already carries the n-ary grouping informally.
- No triple store, no Neo4j. Markdown and Dataview stay the substrate.
- No automatic vault-wide extraction.
- No change to `memex-conflicts`' no-inference contract.

---

## Open questions — *resolved*

Both were settled during the build.

- **The `≥ 3 claims` stub threshold.** It stays a **stated default**, not a hidden
  constant: mode B announces the threshold it is using at the top of each run, so
  a user can see it and override it for that run. It is still untuned against a
  real paper — but that is a tuning task with a visible knob, not an open design
  question, and shipping it silent was the only outcome worth avoiding.
- **Whether `extracts/` should be a `memex-search` fallback at all.** It shipped,
  under the gap-finding rule above. `skills/memex-search/SKILL.md` checks
  `extracts/` **last**, after the topic → atom → source traversal, and reports
  every hit as *unpromoted evidence, not vault knowledge*. The curation
  discipline is preserved by the ordering and by the labelling, not by refusing
  the capability.

---

## Implementation decisions

Six ways the build diverged from the design above. The first five were confirmed
with the user before building; the sixth was forced by a defect found while
testing. All six are reflected in the body of this document and in
`_meta/roadmap.md` § Phase 3.

**1. Archive normalization became its own script.** The design had
`memex-deep-extract` write normalized archives on first use. But `memex-ingest`
was already writing archives with no normalization at all, so any extract taken
from an ingest-written archive would have thrown false grounding FAILs — the
exact failure mode "Making the grounding check real" exists to prevent.

*Shipped:* `_meta/normalize.sh` — bash/awk, deterministic, idempotent — and every
skill that writes `.archive/` pipes through it. *Rejected:* normalizing in place
on first extract, which leaves the guarantee dependent on which skill happened to
save the file.

**2. Anki deferred entirely to Phase 5.** The design's change list included
`anki/.gitkeep`, the `.obsidian/app.json` exclusion, and the `memex-compose`
render mode. `_meta/roadmap.md` makes Anki its own phase. The roadmap won; Phase 3
touched nothing Anki-related.

**3. The confidence rubric (P2) landed here, not in Phase 4.** Extracts are what
make the rubric expressible, and the schema was already open, so
`_meta/schema.md` § Confidence Values was rewritten in this phase: the unit is
**independent claims across independent sources**, source tiers are inferred at
audit time and never stored, and an atom with no extract is capped at `medium`.
Phase 4 consequently shrinks to the `memex-trust-audit` rebuild.

**4. `grounded:`, `source:`, and `medium:` dropped from extract frontmatter.**
`grounded: true` is a cached lint verdict stored inside the file it judges — it
goes stale on the next edit, and a fabricating writer can simply assert it.
Grounding is what lint computes, never what a note claims about itself. `source:`
and `medium:` were derivable: the filename and `extracted-from::` name the source
twice already, and `medium:` belongs to the source note.

*Kept:* `claims:`, because Dataview cannot count block ids and the index needs the
figure — with a lint cross-check (12b) so it cannot drift.

**5. Extract filenames take an `ext-` prefix.** The design mandated mirroring the
source filename *exactly*. That collides head-on with Phase 2's own
§ Disambiguation Policy, which opens by stating that Obsidian resolves wikilinks
by filename: every `cites:: [[<source-slug>]]` already written on an atom would
have gone silently ambiguous the moment its extract appeared. Confirmed in a
fixture — two files, one name. *Shipped:* `extracts/ext-<source-slug>.md`, which
keeps the mapping mechanical in both directions while leaving one name per file.

**6. The missing-archive SKIP rule had to extend past the grounding check.**
Obstacle 3 above applies the SKIP-on-missing-archive rule to *grounding*. Testing
found `_meta/lint.sh` **section 5** — the archive-mismatch check, a FAIL site
since Phase 0 — walking into the same trap one section earlier: `.archive/` is
gitignored, so every fresh clone FAILed on the first `raw::` it met.

*Shipped:* the rule is now split by cause. `.archive/` absent entirely is the
clone case and **SKIPs**; a file missing while the folder exists is a real
mismatch and still **FAILs**. *Unverifiable* is not *corrupt*, and the gate is
preserved everywhere it means anything.
