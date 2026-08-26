# Schema

This file is the vault's constitution. Update it when adding or retiring relationship types, node types, stage values, or naming conventions. All other notes defer to it.

Subject-matter vocabulary — tags, the domain name, the OKF type names — lives in
`_meta/domain.md`, not here. This file is what every memex-vault shares; that one
is what a fork changes.

---

## Node Types

| Node | Folder | `type:` | Granularity | Other required fields |
|------|--------|---------|-------------|-----------------------|
| Source (web) | `sources/web/` | `Source` | One file per URL | `title`, `url`, `medium`, `saved`, `stage` |
| Source (video) | `sources/video/` | `Source` | One file per URL | `title`, `url`, `medium`, `channel`, `saved`, `stage` |
| Source (paper) | `sources/paper/` | `Source` | One file per URL | `title`, `url`, `medium`, `authors`, `year`, `saved`, `stage` |
| Source (docs) | `sources/docs/` | `Source` | One file per URL | `title`, `url`, `medium`, `tool`, `saved`, `stage` |
| Source (meeting) | `sources/meeting/` | `Source` | One file per meeting | `title`, `medium`, `date`, `stage` |
| Extract | `extracts/` | `Extract` | One file per deep-extracted source | `title`, `extracted`, `claims` |
| Atom | `atoms/` | `Atom` | One concept per file | `title`, `created`, `confidence` |
| Glossary | `glossary/` | `Glossary Term` | One term per file | `title`, `term`, `domain`, `stage` |
| Concept map | `topics/concepts/` | `Concept Map` | One domain per file | `title` |
| Project | `topics/projects/` | `Project` | One project per file | `title`, `stage` |
| Research | `topics/research/` | `Research Question` | One research question per file | `title`, `question` |
| Export | `_exports/` | — | One file per compose session | (generated — no required frontmatter) |
| Candidate | `_meta/candidates/` | — | One file per proposed write | `proposed`, `skill`, `action`, `target`, `session`, `stage` |

`type:` is required on every curated node and is the single node-type
discriminator. `medium:` remains the *sub*type of a source, so a paper is
`type: Source` + `medium: paper` and no fact is stored twice. `topic-type:` was
retired — `type:` subsumed it exactly.

The folder-to-`type:` mapping is data, not code: it lives in `_meta/domain.md`
under **OKF Types**, which is what `_meta/lint.sh` validates against. A fork that
renames `Atom` to `Note` edits that one table.

`_exports/` and `_meta/candidates/` carry no `type:` — neither is a knowledge
node. Exports are generated artifacts and candidates are ephemeral proposals;
both are excluded from the OKF bundle.

**Extracts are evidence, not knowledge.** An extract records what one source
said, claim by claim, each claim carrying a verbatim quote checkable against the
archived text. Atoms remain the curated layer: one hand-written concept per file.
Nothing is ever promoted from `extracts/` to `atoms/` automatically — see
§ Extract Claims and `_meta/deep-extract-design.md`.

---

## Relationship Types (Dataview Inline Fields)

Syntax: `relation:: [[Target Note]]` or `relation:: [[A]], [[B]]` in note body.

Relationships are grouped by **epistemic role**: affirmative (source builds on target), skeptical (source questions or limits target), structural (hierarchy and dependency), and navigational (fallback / cross-domain).

### Source → Atom/Topic — Affirmative
| Field | Meaning |
|-------|---------|
| `supports::` | Source provides evidence for a claim in this atom |
| `introduces::` | Source is where this concept first appears in the vault |
| `demonstrates::` | Source shows a concrete worked example of the concept |

### Source → Atom/Topic — Skeptical
| Field | Meaning |
|-------|---------|
| `challenges::` | Source questions or weakens a claim without fully refuting it; the tension should be described in the atom body |
| `refutes::` | Source provides evidence directly against the claim; stronger than `challenges::` |

### Atom → Atom — Structural
| Field | Meaning |
|-------|---------|
| `extends::` | Builds on / specializes another concept (A is a subtype or elaboration of B) |
| `uses::` | Applies or depends on another concept (A requires B to function) |
| `part-of::` | Component of a broader concept; drives concept map membership |

### Atom → Atom — Epistemic
| Field | Meaning |
|-------|---------|
| `contradicts::` | Direct logical conflict with another concept or claim; document the tension in both atoms |
| `challenges::` | A weakens or questions B without direct contradiction; softer than `contradicts::` |
| `supersedes::` | A replaces or obsoletes B in modern understanding; B remains for historical context |
| `limits::` | A defines the boundary conditions or failure modes where B breaks down or only partially applies |
| `contrasts-with::` | A is an alternative approach to the same problem as B; not contradictory, just different |

### Any Note → Source
| Field | Meaning |
|-------|---------|
| `cites::` | This note references that source as evidence (affirmative or neutral) |
| `rebuts::` | This note references that source as counter-evidence to a claim |

**Provenance anchors:** Use `[[note#Section]]` heading anchors on `cites::` to record which section of a source supports the specific claim in this atom. Valid section names match the source note's `##` headings: `Summary`, `Key Points`, `Why Saved`, `Decisions Made`, `Key Concepts Discussed`. Example: `cites:: [[2026-04-27-flash-attention#Key Points]]`. Bare `[[note]]` remains valid when the whole source is relevant or the section is indeterminate. Multiple sources may mix anchored and bare forms on the same field.

**Block anchors.** The same field addresses a single extracted claim with an
Obsidian block reference: `cites:: [[2026-04-27-slug#^c07]]`. Heading anchors
point at a section a human wrote; block anchors point at one proposition with a
verbatim quote attached. This is the finest provenance grain the vault has, and
it is what makes a claim-derived `confidence:` possible — see § Confidence
Values. The target lives in `extracts/` and carries the `ext-` prefix
(`cites:: [[ext-2026-04-27-slug#^c07]]`), so the citation reads *this atom rests
on that specific sentence of that source*, and hovering it in Obsidian previews
the claim with its quote.

### Extract → Source / Concepts
| Field | Meaning |
|-------|---------|
| `extracted-from::` | This extract is the claim-level reading of that source. Exactly one target, always. |
| `mentions::` | A concept this extract's claims talk about. **Not** an assertion that the concept is atomized, and never a substitute for `part-of::` or `supports::` |

`mentions::` is deliberately weak. It exists so an extract is reachable from the
graph at all, and so `memex-search` can answer "the vault has evidence about X
but has formed no concept about it." It is the only relation field that points at
targets which may not exist yet, and it therefore **does not rescue an atom from
orphanhood** — `extracts/` is not a curated folder (see the orphan definition
below). An atom whose only inbound link is an extract's `mentions::` is still an
orphan in both `_meta/lint.sh` and `_meta/index.md`, which is the correct reading:
evidence was collected, nobody curated it.

Both fields are written only by `memex-deep-extract`, and only in `extracts/`.

### Any Note → Glossary
| Field | Meaning |
|-------|---------|
| `defines::` | This note elaborates or is the canonical definition for this term |

### Topic → Atoms

**Derived, not written.** Topic membership has one source of truth: the atom's
`part-of::` field. A topic does not list its own atoms. `covers::` was retired in
roadmap Phase 1 — it duplicated `part-of::` and required a reconcile pass to keep
the two in step.

Topic notes surface their membership with a Dataview query:

```dataview
LIST FROM "atoms"
WHERE contains(row["part-of"], this.file.link)
```

Two details in that query are load-bearing, not style:

- **`row["part-of"]`, never `part-of`.** Dataview parses a bare hyphenated field
  in a `WHERE` clause as subtraction (`part` minus `of`), so the bare form
  silently matches nothing. The bracket accessor is the documented escape.
- **`this.file.link`, never a hardcoded `[[Title]]`.** Obsidian resolves
  wikilinks by *filename*, not by the `title:` frontmatter field. A topic whose
  file is `deep-learning.md` and whose title is "Deep Learning" would never match
  atoms writing `part-of:: [[deep-learning]]`. The self-reference sidesteps the
  question and survives renames.

Both failure modes are silent: an empty topic looks identical to a correct query
over a topic with no atoms yet.

Outside Obsidian, the same set is recovered by reverse lookup:

```bash
grep -rlE "^part-of::.*\[\[<topic-slug>\]\]" atoms/
```

### Navigational (any → any)
| Field | Meaning |
|-------|---------|
| `related::` | Loosely connected; use as a fallback only — review monthly for a more precise type |

---

### Choosing Between Skeptical Relations

```
Source challenges an atom?
  └─ Is there direct empirical counter-evidence?
       ├─ Yes → refutes::
       └─ No  → challenges::

Atom A questions atom B?
  └─ Are they logically incompatible?
       ├─ Yes → contradicts::
       └─ No  → Does A define where B fails?
                  ├─ Yes → limits::
                  └─ No  → Is A an older version replaced by B?
                              ├─ Yes → B supersedes:: A
                              └─ No  → contrasts-with:: (different approach)
```

When using `challenges::`, `refutes::`, or `contradicts::`, always write a sentence in the note body explaining the specific tension. Bare link with no context is not useful.

---

## Stage Values

`stage:` is this vault's **workflow** position — where a note sits in the pipeline
that runs from capture to fully integrated. The vocabulary is closed and differs
per node type; `_meta/lint.sh` validates each note's value against the table for
its folder.

The field is deliberately *not* called `status:`. In the Open Knowledge Format,
`status:` is a reserved document-lifecycle field with exactly three values
(`draft`, `stable`, `deprecated`) and a documented default of `stable` when
absent. Writing `status: unread` into an OKF-aware reader does not read as
"missing" — it reads as **wrong**. Leaving `status:` unused in-vault means the
safe default applies, and the Phase 8 exporter synthesizes a real `status:` from
`stage:` at export time.

**`status:` must never appear in a vault note.** Lint fails on it.

### Sources
| Value | Meaning |
|-------|---------|
| `unread` | Saved, not yet read |
| `read` | Read, not yet processed into atoms |
| `processed` | Connections and atoms created |

### Meeting
| Value | Meaning |
|-------|---------|
| `unprocessed` | Notes taken, follow-ups not yet acted on |
| `processed` | Action items done, follow-up sources captured |

### Projects
| Value | Meaning |
|-------|---------|
| `active` | In progress |
| `paused` | On hold |
| `complete` | Finished |
| `abandoned` | Dropped |

### Glossary
| Value | Meaning |
|-------|---------|
| `stub` | Created opportunistically; definition drafted but not reviewed for operational precision |
| `reviewed` | Definition vetted for operational precision via `memex-glossary` workflow |

### Candidate
| Value | Meaning |
|-------|---------|
| `pending` | Proposed, awaiting review by `memex-candidates` |
| `reviewed` | Seen by a human; applied or rejected |

Atoms have no `stage:`. An atom is not in a pipeline — it is either written or it
is not. What varies is how well-evidenced it is, which is `confidence:`.

---

## Extract Claims

An **extract** is the claim-level reading of one source:
`extracts/ext-<source-slug>.md`. One extract per source, written by
`memex-deep-extract` and by nothing else. Full rationale in
`_meta/deep-extract-design.md`.

The `ext-` prefix is not decoration. Without it the extract and its source share
a filename, and § Disambiguation Policy above exists precisely because Obsidian
resolves wikilinks by filename: every `cites:: [[2026-04-27-lewis-rag]]` already
written on an atom would become ambiguous the moment the extract appeared, with
no error anywhere. The prefix keeps the mapping mechanical in both directions —
strip `ext-` for the source, prepend it for the extract — while leaving one name
per file.

An extract stores **no fact that lives elsewhere**. There is no `source:` and no
`medium:` field: the filename mirrors the source and `extracted-from::` carries
the edge, so a third copy would only be a third thing to keep in step. There is
no `grounded:` field either — grounding is what lint computes, and a note that
asserts its own verification is exactly what a fabricating writer would emit.

```yaml
---
type: Extract
title: "Extract: Retrieval-Augmented Generation for Knowledge-Intensive NLP"
description: Claim-level extraction of the RAG paper (extracts/ext-2026-04-27-lewis-rag.md).
extracted: 2026-07-09
claims: 47
---
```

`claims:` is the one derived number kept in frontmatter, because Dataview cannot
count block ids and the index needs the figure. Lint section 12 cross-checks it
against the actual count, so it cannot drift silently.

### Claim format

Claims are **bullet list items**. Obsidian accepts a block identifier only at the
end of a bullet or of a paragraph's last line, so the bullet is not a style
choice.

```markdown
- RAG-Sequence conditions on a single retrieved document for the whole output; RAG-Token may draw each token from a different document. ^c07
    - type: contrast
    - about: `rag-sequence`, `rag-token`
    - quote: "...each target token may be drawn from a different document."
```

Sub-bullets use **plain single-colon keys, never Dataview `::` fields**, and this
is load-bearing rather than cosmetic:

- Dataview inline fields in a body **lift to page level**. Fifty claims would
  collapse `type` / `about` / `quote` into three merged page-level arrays, so the
  quote for `^c07` would be unrecoverable anyway. Per-claim retrieval is text
  parsing — `grep`, `awk` — and the format should be honest about that.
- A bare `about:: [[atom]]` would fire once per claim, pushing ~50 unapproved
  edges into the atom graph before a human saw any of them.

Single-colon keys are inert to Dataview and to lint's unknown-relation-field
scan, and stay inert if that scan is ever widened.

| Key | Required | Meaning |
|-----|----------|---------|
| `type:` | yes | `finding` / `definition` / `limitation` / `contrast` / `method` |
| `about:` | yes | Backticked concept slugs this claim concerns |
| `quote:` | yes | Verbatim text from the normalized archive |

`type:` is the bridge from free extraction into the vault's closed vocabulary:
`finding → supports::`, `definition → glossary`, `limitation → limits::`,
`contrast → contrasts-with::`, `method → uses::`.

Staging tables (`## Concepts`, `## Proposed Relations`) use **backticked slugs,
never `[[wikilinks]]`**. A proposed relation is not a graph edge; rendering it as
a link would create edges nobody approved.

### Grounding

Every claim carries a verbatim `quote:`, and `_meta/lint.sh` section 12 runs
`grep -F` for it against the source's `raw::` archive. A quote that is not in the
archive is a **FAIL**: fabrication is deep extraction's characteristic failure
mode, and this is the whole defense.

The check only works against normalized text, so `.archive/` files are written
through `_meta/normalize.sh` — by every skill that writes one, not just by
`memex-deep-extract`. Two rules follow for the writer:

- **A quote is single-line.** Normalization puts each paragraph on one line, so
  a quote cannot span a paragraph boundary.
- **No ellipsis inside a quote.** Emit two `quote:` lines instead. An elided span
  is unmatchable, and allowing it would reopen the hole the check exists to close.

A **missing** archive is a SKIP, not a FAIL. `.archive/` is gitignored, so it is
absent on every fresh clone, and *unverifiable* is not *fabricated*. The
guarantee is therefore local-only — worth stating plainly rather than pretending
it runs in CI.

---

## Confidence Values

Atoms only. Measures **evidence strength**, not workflow position and not human
sign-off.

### The unit is an independent claim, not a source

Counting sources is the wrong measure and no weighting fixes it: three blog posts
summarizing the same paper are one piece of evidence, and a single paper making
four separately-tested assertions is four. The unit is a **claim** — one
proposition, with a verbatim quote, from `extracts/` — grouped by **independent**
source.

Two sources are **not** independent when any of these holds:

- one `cites::` the other, directly or through a chain in the vault;
- they share an author (`authors:`, `channel:`, `tool:`);
- one is a restatement of the other — a blog post about a paper, a talk given on
  a paper, vendor docs describing a vendor's own release.

Where that is unclear, treat them as dependent. Overstating independence is how
`high` becomes meaningless, and `high` is the only value that changes anyone's
behaviour.

### Rubric

| Value | Requires |
|-------|----------|
| `low` | One supporting claim, or several claims that trace back to one source |
| `medium` | ≥ 2 supporting claims from ≥ 2 independent sources, at least one of them reviewed or primary |
| `high` | ≥ 3 supporting claims from ≥ 3 independent sources, at least two reviewed or primary, **and** no unaddressed `contradicts::` or `refutes::` on the atom |

**`high` requires claim-level grounding.** At least one `cites::` on a `high`
atom must be block-anchored — `cites:: [[extract#^c07]]` — so the assertion
resolves to specific sentences of specific sources rather than to a pile of
filenames. Lint section 12 warns when it does not.

### Where no extract exists

Most atoms will never be deep-extracted: `memex-deep-extract` is the most
expensive skill in the vault and is deliberately selective. Those atoms fall back
to counting **independent sources** rather than claims, using the same
independence test, and are **capped at `medium`**. That is not a penalty; it is
the accurate reading. Nobody has checked what those sources actually said, so the
vault cannot distinguish three real corroborations from three restatements.

### Source-type weighting

The secondary term. It is inferred from signals the source note already carries —
**no rigor score is ever stored in frontmatter.** A stored score is a judgement
frozen at capture time that nothing will ever revisit; the signals below are
facts that stay true.

| Tier | Inferred from |
|------|---------------|
| Reviewed | `medium: paper` with a `venue:` |
| Primary | `medium: paper` without a `venue:` (preprint), or `medium: video` of a talk by the work's own authors |
| Curated | `medium: docs` — accurate about the tool, and about nothing else |
| Unreviewed | `medium: web`, and everything else |

"Reviewed or primary" in the rubric above means the first two tiers.

### Relationship to `verified:`

`confidence:` is orthogonal to `verified:` (below): confidence measures how much
evidence stands behind a claim, `verified:` records who checked it. A `high`
confidence atom nobody has reviewed is entirely possible, and so is a `low`
confidence atom a human has explicitly signed off as correctly hedged.

---

## Atom Writing Style

An atom is one claim, stated plainly, with its evidence attached. These five
rules exist because the alternative — atoms drifting into essays — is what makes
a vault unsearchable.

1. **One claim per atom.** If the summary needs the word "and" to stay honest,
   there are two atoms. `memex-refactor` splits them; lint flags the symptom
   (`cites::` > 5 *and* `related::` > 4 *and* body > 100 lines).
2. **Present tense, declarative.** "Flash attention tiles the softmax to avoid
   materializing the full attention matrix" — not "the paper argues that…". The
   atom states what is true as far as the vault knows; attribution is what
   `cites::` is for.
3. **Hedge single-source claims in the prose, not just in `confidence:`.** A
   claim standing on one unreplicated paper should say so in words. `confidence:
   low` is a machine signal; a reader skimming the body needs the same warning.
4. **Use relations, not inline prose, for connections.** Write
   `contrasts-with:: [[flash-attention]]`, not "unlike flash attention…". Prose
   links are invisible to the graph, to Dataview, and to every skill.
5. **Name the tension when you assert one.** `contradicts::`, `refutes::`, and
   `challenges::` each require a sentence in the body saying *what* conflicts.
   Lint section 9 fails a bare conflict link, because a bare one is unusable —
   the reader learns two notes disagree and nothing about how.

The target length is a Wikipedia stub: a `## Summary` a stranger can read in
fifteen seconds, and a `## Detail` that earns every line it adds.

---

## Disambiguation Policy

Two notes may not share a filename, and Obsidian resolves wikilinks by filename,
so collisions are decided at creation time. There are two cases and they resolve
differently.

**True homonyms** — unrelated senses that happen to share a word. Suffix the slug
with the disambiguating domain, and never create the bare slug:

```
atoms/attention-transformers.md
atoms/attention-neuroscience.md
```

The bare `attention.md` is left permanently unused. A note that exists at the
ambiguous name is worse than none, because every future `part-of:: [[attention]]`
will silently resolve to whichever sense was written first.

**Polysemous senses** — one concept read differently in two contexts. Keep one
atom and give each reading a `##` section, then anchor citations at the section:

```
cites:: [[2026-04-27-source#Systems Reading]]
```

Splitting these produces two atoms that must be kept in step forever, which is
the failure mode `covers::` was retired for.

**The test:** would a change to one sense oblige a change to the other? Yes ⇒ one
atom with sections. No ⇒ two suffixed atoms.

Record the decision in the atom body when it is not obvious. `aliases:` carries
the surface forms a reader might search for — `aliases: [attention]` on both
homonyms is correct and useful, because aliases disambiguate at read time without
creating a resolvable link target.

---

## Provenance: `generated:` and `verified:`

Two optional frontmatter blocks recording **who produced a note** and **who has
since checked it**. Both use the Open Knowledge Format actor convention (OKF §7),
so the values survive export without translation.

### Actor strings

| Form | Use | Example |
|------|-----|---------|
| `<producer>/<version>` | An automated producer and the model or version behind it | `memex-ingest/claude-opus-5` |
| `human:<id>` | A person | `human:bcmcpher` |
| `process:<id>` | A non-interactive job | `process:nightly-lint` |

### `generated:`

Written **once, at creation**, by whichever skill created the note. Never updated
— it records origin, not last touch. `updated:` is the authoritative
last-modified timestamp and is what changes when a note is revised.

```yaml
generated:
  by: memex-ingest/claude-opus-5
  at: 2026-08-25
```

This is a genuine capability gain, not conformance overhead. Authorship exists
today only as `skill::` in `_meta/log.md`, which means it is recoverable for a
batch but not for a note: open an atom and there is currently no way to tell
whether a human wrote it or a model did.

### `verified:`

A **list**, appended to whenever someone confirms the note is still accurate. It
is the human sign-off record, so entries are only ever added, never rewritten.

```yaml
verified:
  - by: human:bcmcpher
    at: 2026-08-25
```

`skills/memex-trust-audit` is its writer, and the only one. A note with no
`verified:` key has simply never been checked, which is the honest default.

Three rules govern it.

**Append-only.** Entries are added, never rewritten or removed. A sign-off is a
statement about a moment — "I read this on this date and it was right" — and
editing one falsifies a record about a person. Two sign-offs by the same person
on different dates are two entries, correctly.

**Sign-off does not touch `updated:`.** This is the rule most likely to be
broken by accident, and it is load-bearing in two places. `memex-stale` reads
`updated:` to find atoms drifting away from their sources; if confirming an atom
were to refresh it, verification would launder staleness into freshness. And
this file's own *stale confidence* signal — an incoming `challenges::` or
`refutes::` dated after `updated:` — would be cleared by the act of signing off,
which is exactly backwards: a human confirming an atom should not erase the
evidence that someone else disputed it. Checking a note is not revising it.

**Sign-off is asked separately from `confidence:`.** They are different
questions — how much evidence exists, versus who has looked — and bundling them
into one prompt produces confirmations nobody meant to give. Same discipline
`memex-refactor` applies to `confidence:` and content edits.

A sign-off therefore goes **stale** rather than expiring: when `updated:` is
later than the newest `verified.at`, someone signed off on a version of the note
that no longer exists. That is a warning, not a failure — lint section 13 reports
it, and the entry stays.

See `## Confidence Values` above for why `verified:` and `confidence:` are
orthogonal and must not be collapsed into one field.

---

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Sources (all except meeting) | `YYYY-MM-DD-kebab-title.md` | `2026-04-27-attention-is-all-you-need.md` |
| Meetings | `YYYY-MM-DD-kebab-context.md` | `2026-04-27-team-rag-sync.md` |
| Extracts | `ext-<source-filename>.md` | `ext-2026-04-27-attention-is-all-you-need.md` |
| Atoms | `kebab-concept-name.md` | `transformer-architecture.md` |
| Glossary | `term.md` (lowercase, hyphenated) | `self-attention.md` |
| Concept maps | `kebab-domain.md` | `deep-learning.md` |
| Projects | `proj-kebab-name.md` | `proj-rag-pipeline.md` |
| Research | `rq-kebab-question.md` | `rq-scaling-laws-llms.md` |

---

## Archive

Full source text may optionally be saved to `.archive/YYYY-MM-DD-slug.md`. This folder is gitignored and excluded from Obsidian's indexer. Reference it from a source note with:

```
raw:: .archive/2026-04-27-slug.md
```

**Archives are always written through `_meta/normalize.sh`**, which folds
ligatures, smart quotes, dashes and exotic spaces to ASCII, rejoins words split
by line-break hyphenation, and unwraps each paragraph onto one line:

```bash
curl -s "$URL" | pandoc -f html -t plain | bash _meta/normalize.sh > .archive/2026-04-27-slug.md
bash _meta/normalize.sh --in-place .archive/2026-04-27-slug.md   # bring a legacy archive up to standard
```

This is not tidiness. Extract quotes are checked against the archive with
`grep -F` (§ Extract Claims), and raw `pdftotext` or scraped-HTML output fails
that check on every multi-line quote. Normalization has to happen at write time,
in every skill that writes an archive — if one writer skips it, whether a quote
grounds depends on which skill happened to save the file. The script is
deterministic and idempotent, so re-running it on an archive of unknown
provenance is always safe.

`_meta/lint.sh` section 5 FAILs when `raw::` names a file that is missing while
`.archive/` exists — that is a real mismatch. When `.archive/` is absent
altogether, both section 5 and the grounding check SKIP: that is what a fresh
clone looks like, and a clone must not fail lint.

---

## Workflow Stages

Skills that write vault notes, and what they produce:

| Skill | What it creates | Graph wiring | Log entry |
|-------|----------------|--------------|-----------|
| `memex-save` | Source note with fetched title + summary draft; branches on read stage; optional collaborative summary | None | Yes |
| `memex-ingest` | Source note + atoms + connections | Full | Yes |
| `memex-connect` | Updates existing unread notes | Full | Yes |
| `memex-meeting` | Meeting source note + atom/glossary stubs | Full | Yes |
| `memex-topic-init` | New topic map + atom back-wires | Full | Yes |
| `memex-topic-emerge` | Proposed topic maps from atom clusters + atom back-wires | Full | Yes |
| `memex-deep-extract` | Mode A: one file in `extracts/`, nothing else. Mode B: atom edits from reviewed claims | Mode B only | Yes |
| `memex-refactor` | Rewrites/splits/merges existing atoms | Varies | Yes |
| `memex-glossary` | Glossary entries from existing notes | `defines::` only | No |
| `memex-candidates` | Applies pending candidates from `_meta/candidates/` | Varies | No |
| `memex-compose` | Export document in `_exports/` | None (read-only) | Yes |

Atom bodies may be modified by multiple skills (`memex-refactor` revise, `memex-connect` back-wiring, `memex-review` accepted findings). This is expected — the `updated:` frontmatter field is the authoritative timestamp for when an atom last changed, regardless of which skill made the change.

---

## Candidate Lifecycle

Candidate files in `_meta/candidates/` are ephemeral proposals written by writing skills before each vault change. They make proposed content durable across session drops. Use `memex-candidates` to review and apply pending candidates.

**Two candidate types:**

*Create candidate* — full proposed file content in body:
```markdown
---
proposed: YYYY-MM-DD HH:MM
skill: memex-ingest
action: create
target: atoms/flash-attention.md
session: YYYY-MM-DD-HHMM
stage: pending
---

[full file content to write]
```

*Modify candidate* — structured append to a specific section:
```markdown
---
proposed: YYYY-MM-DD HH:MM
skill: memex-connect
action: modify
target: atoms/attention-mechanism.md
section: "## Sources"
change: append
session: YYYY-MM-DD-HHMM
stage: pending
---

cites:: [[2026-05-01-flash-attention#Key Points]]
```

**Lifecycle:** Candidate written → user confirms interactively → vault file written → candidate deleted. If session ends before confirmation, candidate persists. `memex-candidates` resurfaces pending candidates for approval or rejection.

**File naming:** `YYYY-MM-DD-HHMMSS-{action}-{target-slug}.md`

`_meta/candidates/` is gitignored — candidates are ephemeral working state, not vault history.

---

A source note with `stage: unread` and no populated Dataview fields in `## Connections` is considered **inbox-only** — captured but not yet integrated into the graph. Run `memex-connect` to process inbox notes.

An atom is an **orphan** when it has no `cites::` *and* no inbound wikilink from a **curated folder** — `sources/`, `atoms/`, `topics/`, or `glossary/`. It neither cites evidence nor is referenced by anything, so it is disconnected from the graph in both directions.

Links from `_meta/`, `_exports/`, `extracts/`, and `.archive/` never count.
`extracts/` is excluded on purpose: an extract's `mentions::` records that
evidence was collected, not that anyone curated a concept, so an atom whose only
inbound link is a `mentions::` is still disconnected in the sense that matters. `_meta/log.md` records `atoms:: [[Atom A]]` for every atom it touches, so counting it would mark every ingested atom as connected and make the check vacuous. Both `_meta/lint.sh` (section 4) and `_meta/index.md` implement this definition; changing one without the other makes them disagree silently.

An atom's `part-of::` is **orphaned** when it names a topic file that does not
exist. Since membership is derived from this field alone, a typo'd or stale
`part-of::` silently removes the atom from its topic with no other symptom.
`_meta/lint.sh` section 7a checks it.

A source can legitimately have multiple targets on a single relation field (e.g., a conference talk citing several papers via `cites:: [[Paper A]], [[Paper B]]`). This is not a schema violation — multiple `cites::` entries on one source note are expected and correct.

---

## Lint Heuristics (Informational)

These thresholds are soft signals surfaced as WARNings, not hard failures. They flag candidates for human review, not automatic fixes.

| Check | Level | Threshold | Notes |
|-------|-------|-----------|-------|
| Source: unread + no Connections | Source | any | Inbox-only; run `memex-connect` |
| Atom: no populated relations | Atom | any | Fully isolated atom; check for orphan or missing wiring |
| Atom: bloated | Atom | `cites::` > 5 AND `related::` > 4 AND body > 100 lines | May cover multiple concepts; consider splitting |
| Topic map: too many atoms | Concept map | > 15 atoms with `part-of::` pointing at it | May span multiple domains; consider sub-topics |
| Extract: `claims:` count wrong | Extract | frontmatter ≠ `^cNN` block ids in body | Hand edit drifted from the frontmatter; recount |
| Atom: `high` without grounding | Atom | `confidence: high` and no `cites:: [[…#^…]]` | Confidence rests on filenames, not sentences; run `memex-deep-extract` |

Note: high `cites::` count on a **source** note is not a smell. A survey paper or conference talk legitimately references many prior works.

---

## Valid Relation Fields

Machine-readable list used by `_meta/lint.sh` Section 7 to detect unknown relation fields. Update this list when adding or retiring relation types.

```
supports
introduces
demonstrates
challenges
refutes
extends
uses
part-of
contradicts
supersedes
limits
contrasts-with
cites
rebuts
defines
related
raw
extracted-from
mentions
```

---

## Tag Vocabulary

Controlled vocabulary for `tags:` frontmatter lives in **`_meta/domain.md`**,
under *Domain Tags*, *Type Tags*, and *Stage Tags*. Lint section 10 warns on any
tag not listed there.

It is not here because tags are the most instance-specific thing in the vault:
a fork covering, say, constitutional law replaces every domain tag and keeps
every relation type. Splitting the two means a fork edits one file and inherits
the rest.

Add a tag to `_meta/domain.md` before using it.
