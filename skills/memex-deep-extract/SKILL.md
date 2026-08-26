---
name: memex-deep-extract
description: Read one source claim by claim and write a quote-grounded extract, then promote reviewed claims into atoms. Use when a source is dense enough that a document-level summary loses what it actually said — a long paper, a technical spec, a survey. Triggers on: "deep extract [source]", "extract the claims from [paper]", "read [X] properly", "what did [paper] actually say", "pull the claims out of this source", "promote the claims in [extract]", "this source is under-extracted", "ground my atoms in real quotes". Also triggers from lint's "under-extracted source" warning and from memex-trust-audit's ungrounded-confidence findings. This skill is expensive and never runs automatically or vault-wide.
---

# Karpathy Wiki Deep Extract

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.

This skill builds and harvests the vault's **evidence layer**. Sources are stored
at document granularity — a human-written `## Summary` and `## Key Points` — so
nothing records what a source said *sentence by sentence*. An extract does: one
file per source, holding propositions, each carrying a verbatim quote checkable
against the archived text.

For the relationship taxonomy and field definitions, read: `references/vault-schema.md`
Full design rationale: `_meta/deep-extract-design.md`

**Two modes.** Mode A writes exactly one file and mutates nothing else. Mode B
turns reviewed claims into atom changes, one confirmation at a time. They are
deliberately separate: extraction is cheap to redo and expensive to trust, so a
human reads the extract before anything touches `atoms/`.

---

## The two invariants

Everything below follows from these. If a step seems to conflict with one, the
invariant wins.

**1. Extraction output is not atoms.** Exhaustive claim extraction on a dozen
papers yields hundreds of entities. Dumping those into `atoms/` would end the
"one hand-curated concept per file" property that makes the vault searchable.
Claims live in `extracts/` and are promoted selectively, by a human, or not at
all. An extract written in January can be harvested in June, when an atom finally
exists that wants its evidence.

**2. Every claim carries a verbatim quote, and lint checks it.** Fabrication is
deep extraction's characteristic failure mode. `_meta/lint.sh` section 12 runs
`grep -F` for each quote against the source's `raw::` archive and **FAILs** on a
miss. No LLM is in that verification loop, which is the entire point. A claim you
cannot quote is a claim you do not write.

---

## Mode A — extract

Writes exactly one file: `extracts/ext-<source-slug>.md`. Touches nothing else —
no atom, no glossary entry, no topic, no `part-of::`, no confidence change.

### 1. Require grounding first

Read the source note. Look for `raw::`.

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
grep "^raw::" "$VAULT/sources/paper/<slug>.md"
```

**If `raw::` exists and the file is present** — check it is normalized. A legacy
archive written before Phase 3 is not, and every multi-line quote from it will
fail grounding. Normalizing is idempotent, so it is always safe:

```bash
bash "$VAULT/_meta/normalize.sh" --in-place "$VAULT/.archive/<slug>.md"
```

Tell the user you did this and why. It is a real edit to a file another skill
wrote.

**If `raw::` is absent** — fetch the URL, normalize, save, and wire it up:

```bash
# whatever fetch is appropriate for the medium, piped through the normalizer
... | bash "$VAULT/_meta/normalize.sh" > "$VAULT/.archive/<slug>.md"
```

Then add `raw:: .archive/<slug>.md` to the source note's `## Connections`. Ask
before writing that line — it is a change to an existing note.

**If neither is possible** — a paywall, a binary PDF that will not extract, a
video with no transcript — **stop**. Say so plainly:

> "I can't reach the full text of this source, so I can't ground any claim I'd
> write. An extract with unverifiable quotes is worse than no extract: it looks
> checked and isn't. Options: paste the text yourself, or use `memex-connect` to
> wire the source at document level instead."

Do not offer to extract from the source note's own `## Summary`. That summary is
already a lossy human reading; claims drawn from it would be grounded in a
paraphrase, and the whole guarantee would be circular.

### 2. Pass 1 — claims

Read the normalized archive and emit propositions. Each claim is:

- **One proposition.** If it needs "and" to stay honest, it is two claims.
- **Stated in the vault's voice** — present tense, declarative, per
  `_meta/schema.md` § Atom Writing Style. Not "the authors argue that…".
- **Backed by a verbatim quote** copied from the archive, exactly, including
  punctuation.

Two hard rules on quotes, both consequences of how the check works:

- **Single-line.** Normalization puts each paragraph on one line, so a quote
  cannot span a paragraph boundary. If the evidence does, that is two claims.
- **No ellipsis.** An elided span is unmatchable by `grep -F`. Emit two `quote:`
  lines under the same claim instead.

Number claims `^c01`, `^c02`, … in reading order, zero-padded to two digits, never
reused within a file. The ids are stable addresses — an atom will cite
`[[ext-<slug>#^c07]]` and that reference must keep meaning the same thing.

No chunking machinery. A paper fits in context; work section by section for
anything longer.

### 3. Pass 2 — concepts

Derive concept mentions **from the claim set, never from the raw text**. This
ordering is what guarantees every concept is grounded in at least one quoted
fact. A concept nobody made a claim about is not a concept this source
contributed.

### 4. Pass 3 — relations

Propose typed edges between concepts, each carrying the `via` claim id that
supports it. **Vocabulary is restricted to `_meta/schema.md` § Valid Relation
Fields** — there is no second ontology to reconcile. The vault's relation set was
built for exactly this and the convergence is not a coincidence.

Map claim types onto it:

| `type:` | Promotes to |
|---------|-------------|
| `finding` | `supports::` on an atom |
| `definition` | a `glossary/` entry |
| `limitation` | `limits::` |
| `contrast` | `contrasts-with::` |
| `method` | `uses::` |

### 5. Pass 4 — resolve mentions against the vault

Three tiers, cheapest first. No embeddings, no vector store — grep and judgement.

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
ls "$VAULT/atoms/" | grep -i "concept-keyword"                  # exact slug
grep -rl "aliases:.*concept-keyword" "$VAULT/atoms/"            # alias
grep -rl "concept-keyword" "$VAULT/glossary/"                   # already a term
```

Then compare the remaining mentions against the atom title list by reading. Mark
each:

- `matched` — an atom or glossary entry exists; record the target slug
- `new (N claims)` — nothing exists; N is how many claims mention it
- `ambiguous` — two atoms could be meant. Record **both** candidates and resolve
  nothing. `_meta/schema.md` § Disambiguation Policy governs; an extract is not
  where that decision gets made.

### 6. Write the extract

Build from `_templates/extract.md`. Filename is the source's slug with an `ext-`
prefix — `sources/paper/2026-04-27-lewis-rag.md` → `extracts/ext-2026-04-27-lewis-rag.md`.

**The prefix is required, not stylistic.** Without it the extract and its source
share a filename, and Obsidian resolves wikilinks by filename: every
`cites:: [[2026-04-27-lewis-rag]]` already written on an atom would silently go
ambiguous the moment the extract appeared.

````markdown
---
type: Extract
title: "Extract: <source title>"
description: <one line: what this source is and what kind of claims it yields>
extracted: <today YYYY-MM-DD>
claims: <count>
generated:
  by: memex-deep-extract/claude-opus-5
  at: <today YYYY-MM-DD>
---

extracted-from:: [[<source-slug>]]
mentions:: [[concept-a]], [[concept-b]]

## Claims

- RAG combines a pretrained seq2seq generator with a dense vector index of Wikipedia accessed by a neural retriever. ^c01
    - type: method
    - about: `retrieval-augmented-generation`, `dense-passage-retrieval`
    - quote: "RAG models which combine pre-trained parametric and non-parametric memory for language generation."

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

Three format rules, each with a reason:

- **Sub-bullets use plain single-colon keys, never Dataview `::`.** Dataview
  inline fields in a body lift to page level, so fifty claims would merge
  `type` / `about` / `quote` into three page-level arrays and the quote for
  `^c07` would be unrecoverable. And a bare `about:: [[atom]]` would fire ~50
  unapproved graph edges before a human saw any of them.
- **Staging tables use backticked slugs, never `[[wikilinks]]`.** A proposed
  relation is not a graph edge yet. Rendering it as a link creates the edge.
- **`mentions::` only for concepts that already exist.** It is the extract's one
  real graph edge and it is deliberately weak — it does not rescue an atom from
  orphanhood, because collecting evidence is not curating a concept.

**No `source:` and no `medium:` frontmatter.** The filename and `extracted-from::`
already record the source twice; a third copy is a third thing to keep in step.
**No `grounded:` field** — grounding is what lint computes, and a note asserting
its own verification is exactly what a fabricating writer would emit.

### 7. Run the grounding check and report

```bash
bash "$VAULT/_meta/lint.sh" 2>&1 | sed -n '/12. Extract Grounding/,/^$/p'
```

If any quote FAILs, **fix the extract, do not fix the archive.** A failing quote
means the claim was transcribed wrong or invented; editing the archive to match
would destroy the only independent record.

Report: N claims, M concepts (K matched / L new / P ambiguous), Q relations
proposed, and the grounding result. Then stop — mode A ends here.

### Candidate gating in mode A

Mode A writes one new file and nothing else, so a create candidate covers the
whole operation:

```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-deep-extract
action: create
target: extracts/ext-<source-slug>.md
session: YYYY-MM-DD-HHMM
stage: pending
---
```

Body: the full extract. Write candidate → show the user → write to vault →
delete candidate.

The `raw::` line added to the source note in step 1 is a separate modify
candidate, since it edits an existing file.

---

## Mode B — promote

Turns reviewed extract content into atom changes, through ordinary candidate
gating, **one confirmation at a time**. Re-runnable by design: an extract is a
standing source of evidence, not a one-shot import.

Start by reading the extract's `## Promotion Log` so already-promoted claims are
not offered twice.

### 1. Enrich matched atoms

For each claim whose `about:` resolves to an existing atom, propose adding its
substance to that atom's `## Detail`, cited at claim granularity:

```
cites:: [[ext-2026-04-27-lewis-rag#^c07]]
```

Bump `updated:`. Ask about `confidence:` as a **separate explicit question**,
never bundled into the content change — that is `memex-refactor`'s revise
semantics and it applies here for the same reason.

### 2. Recompute confidence

Per `_meta/schema.md` § Confidence Values, the unit is **independent claims
across independent sources**, not source count. Before proposing an upgrade,
check independence: sources are not independent when one `cites::` the other,
they share an author, or one restates the other. Where it is unclear, treat them
as dependent — overstating independence is how `high` stops meaning anything.

`high` additionally requires at least one block-anchored `cites::`, which is
exactly what step 1 produces. This is the only path to `high` in the vault.

### 3. Propose glossary stubs

For `type: definition` claims whose term is not already in `glossary/`. Same
stub shape as `memex-connect` writes, with the claim's quote as the drafting
cue and `cites:: [[ext-<slug>#^cNN]]` as the source.

### 4. Propose atom stubs — threshold-gated

**Only for concepts appearing in ≥ 3 claims.** The threshold bounds the entity
explosion that makes bulk extraction unusable, while still surfacing load-bearing
concepts the vault has not atomized. Under-threshold concepts stay in the extract
as unpromoted evidence, which is a perfectly good place for them — that is what
`_meta/index.md`'s "extracts with unpromoted claims" query is for.

The threshold is a starting value, not a law. Say what it is when you apply it,
so the user can override for a specific run.

### 5. Propose conflict links

Where two claims about the same concept, **from different sources**, assert
incompatible things, propose `contradicts::` or `challenges::` — with the
sentence explaining the tension, because `_meta/lint.sh` section 9 fails a bare
conflict link and a bare one is unusable anyway.

This is where claim-comparison inference lives, and it lives here on purpose.
`memex-conflicts` declares three times over that it "does not infer conflicts
from atom content — only follows explicit relation fields already in the graph."
That is its defining contract. Mode B *proposes*; the human approves; the
explicit field now exists; `memex-conflicts` then audits it exactly as designed,
invariant intact. **Never edit `memex-conflicts` to do this.**

### 6. Append to the Promotion Log

One line per promoted claim, so a re-run does not re-offer it:

```
- ^c07 → atoms/rag-token.md (cites, 2026-08-25)
```

### 7. Log and report

Append to `_meta/log.md`:

```markdown
## [YYYY-MM-DD] deep-extract/promote | <source title>
url:: <source url or n/a>
atoms:: [[atom-a]], [[atom-b]]
skill:: memex-deep-extract
notes: N claims promoted; M atoms enriched; K stubs; L conflicts proposed
```

Mode A logs the same way with `deep-extract/extract` and `notes: N claims, M concepts`.

---

## What this skill does NOT do

- **Mode A never writes an atom, glossary entry, or topic.** One file. If mode A
  is about to touch a second file — other than the `raw::` line on the source —
  something has gone wrong.
- **It does not replace `memex-ingest` or `memex-connect`.** Ingest summarizes,
  connect wires whole sources to atoms, extract reads claim by claim. Ingest
  first, then extract.
- **It never deletes an atom.** Retirement stays `supersedes::` plus a stub.
- **It never edits `memex-conflicts`.** See mode B step 5.
- **It never runs automatically or vault-wide.** This is the most expensive skill
  in the vault. It is user-invoked and selective, always.
- **It never edits an archive to make a quote match.**

---

## Scope guards

Stop and ask if any of these hold:

- The source has no reachable full text → refuse, per mode A step 1.
- The extract would exceed ~80 claims → propose splitting by section instead;
  past that nobody reviews it, and an unreviewed extract is a liability.
- Mode B would touch more than 10 atoms in one run → batch it, confirm each.
- A `mentions::` target does not exist → do not create it in mode A. Record it
  as `new (N claims)` in the Concepts table and let mode B decide.

---

## Common Mistakes to Avoid

- Don't extract from the source note's `## Summary` — that is a paraphrase, and
  grounding claims in it makes the check circular
- Don't paraphrase inside `quote:` — it must be a byte-for-byte copy from the
  normalized archive, or lint FAILs and it should
- Don't use an ellipsis to shorten a quote; emit two `quote:` lines
- Don't write `about:: [[atom]]` with Dataview syntax — single colon, backticked
  slug, no link
- Don't put `[[wikilinks]]` in the Concepts or Proposed Relations tables
- Don't reuse or renumber a `^cNN` id once atoms cite it
- Don't skip normalization on a legacy archive and then blame the model when
  every quote fails
- Don't promote in mode A, and don't extract in mode B
- Don't upgrade confidence on source count alone — the unit is independent claims
