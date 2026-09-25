---
name: memex-deep-extract
description: Read one source claim by claim and write a quote-grounded extract, then promote reviewed claims into atoms. Use when a source is dense enough that a document-level summary loses what it actually said — a long paper, a technical spec, a survey. Triggers on: "deep extract [source]", "extract the claims from [paper]", "read [X] properly", "what did [paper] actually say", "pull the claims out of this source", "promote the claims in [extract]", "this source is under-extracted", "ground my atoms in real quotes". Also triggers from lint's "under-extracted source" warning and from memex-trust-audit's ungrounded-confidence findings. This skill is expensive and never runs automatically or vault-wide.
---

# Karpathy Wiki Deep Extract

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill builds and harvests the vault's **evidence layer**. Sources are stored
at document granularity — a human-written `## Summary` and `## Key Points` — so
nothing records what a source said *sentence by sentence*. An extract does: one
file per source, holding propositions, each carrying a verbatim quote checkable
against the archived text.

For the relationship taxonomy and field definitions, read `$VAULT/_meta/schema.md` § Relationship Types.
Full design rationale: `_meta/deep-extract-design.md`

**Two modes.** Mode A writes exactly one file and mutates nothing else. Mode B
turns reviewed claims into atom changes, then brings the source note up to date. They are
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
A="$VAULT/.archive/<slug>.md"
before=$( (sha256sum "$A" 2>/dev/null || shasum -a 256 "$A") | cut -d' ' -f1)
bash "$VAULT/_meta/normalize.sh" --in-place "$A"
after=$( (sha256sum "$A" 2>/dev/null || shasum -a 256 "$A") | cut -d' ' -f1)
```

Tell the user you did this and why. It is a real edit to a file another skill
wrote. **If `$before` and `$after` differ, the note's `archive-sha256:` is now
stale** — `_meta/lint.sh` section 5 warns on the mismatch, and the hash exists to say
which bytes the quotes were checked against (`_meta/schema.md` § Source Archive
Hash). Propose updating it to `$after`, as a replace candidate (§ Candidate gating
in mode A). A note with `raw::` and no hash at all gets one the same way.

**If `raw::` is absent** — fetch the URL, normalize, save, and wire it up:

```bash
# whatever fetch is appropriate for the medium, piped through the normalizer
... | bash "$VAULT/_meta/normalize.sh" > "$VAULT/.archive/<slug>.md"
```

Then hash it with the `$after` command from the block above, and add both lines to the source note:
`raw:: .archive/<slug>.md` in `## Connections`, and `archive-sha256: <hash>` in
frontmatter. Ask before writing them — they are a change to an existing note. The
two travel together: lint section 5 warns on either without the other.

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

One soft rule: **prefer a span that does not cross a de-hyphenation join.**
`normalize.sh` step 4 drops the hyphen at every line-break split, so a compound
the PDF broke after its own hyphen archives fused — `realvalued`, `illposed`,
`DesikanKilliany` in trial 2 (T2-8). The fused form is then the only quotable
form, and a quote carries it into every atom promoted from the claim. It still
grounds; it just reads wrong. Where another sentence carries the same evidence,
quote that one; where none does, quote the fused form exactly — never repair it.

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

Then check the claim count three ways, and report all three:

```bash
E="$VAULT/extracts/ext-<source-slug>.md"
grep -m1 '^claims:' "$E"                        # declared
grep -cE ' \^c[0-9]{2,}$' "$E"                  # ids on claim lines
grep -oE '\^c[0-9]{2,}$' "$E" | sort -u | wc -l # distinct ids
```

All three must agree. Grounding alone does not catch a body that belongs to another
source: in trial 2 parallel workers shared a scratch file (T2-6), and a same-length
cross-contaminated body passes a count check on its own but not the pair of checks
together with grounding against *this* source's archive.

Report: N claims, M concepts (K matched / L new / P ambiguous), Q relations
proposed, the three counts, and the grounding result. Then stop — mode A ends here.

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
**assert** → delete candidate (`_meta/schema.md` § Candidate Lifecycle). The assert
re-reads the extract and checks it equals the candidate body; an edit tool can
report success on a write that did not happen (trial 1, finding 13). On a miss,
keep the candidate and stop.

Step 1's edits to the source note are modify candidates, since they edit an
existing file:

- `raw::` — `section: "## Connections"`, `change: append`.
- `archive-sha256:` — frontmatter is not a section, so this is a
  `change: replace` anchored on a line the note is sure to have. To add the hash,
  `replaces:` the note's `medium:` line and the body is that same line followed by
  `archive-sha256: <hash>`. To update a stale one, `replaces:` the old
  `archive-sha256:` line and the body is the new one.

---

## Mode B — promote

Turns reviewed extract content into atom changes, through candidate gating
(§ Candidate gating in mode B, below). Re-runnable by design: an extract is a
standing source of evidence, not a one-shot import.

Start by reading the extract's `## Promotion Log` so already-promoted claims are
not offered twice.

### 0. Reconcile concept slugs across extracts

Run this first whenever the vault holds extracts nobody has reconciled — always
after a batch of mode A, and on the first mode B a vault ever runs. Skip it only
for a single extract promoted into a vault whose other extracts were reconciled
before.

Mode A pass 4 cannot see sibling extracts, so one concept arrives under several
slugs — trial 2's twelve extracts filed tractography under fourteen, among them
`fiber-tractography`, `streamline-tractography` and `diffusion-mri-tractography`
(T2-11). Steps 4 and 5 compare `about:` slugs literally, so until those are
merged every count below is split across the variants: a concept that clears the
threshold in fact misses it on paper, and two claims about one concept never meet
in step 5 (T2-16).

Take the union, with how many claims and how many extracts use each slug:

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
grep -h '^ *- about:' "$VAULT"/extracts/ext-*.md | grep -oE '`[^`]+`' | tr -d '`' \
  | sort | uniq -c | sort -rn                                   # claims per slug
for f in "$VAULT"/extracts/ext-*.md; do
  grep '^ *- about:' "$f" | grep -oE '`[^`]+`' | tr -d '`' | sort -u
done | sort | uniq -c | sort -rn                                # extracts per slug
```

Cluster by reading: plural and singular, abbreviation and expansion, a modifier
dropped or reordered, and any slug that names an existing atom or glossary entry
under another form. For each cluster propose one canonical slug — the existing
atom's or glossary entry's where there is one — and show the clusters to the
operator before any rewrite. A merge the operator rejects stays two concepts.

Then **rewrite the extracts, not a side table**: the `about:` lines and the
`## Concepts` rows that carry a non-canonical slug. Each changed line is a modify
candidate, `change: replace`, with the old line in `replaces:`. Claim text,
`quote:` lines and `^cNN` ids are never touched — the rewrite changes what a claim
is filed under, not what it says, and lint section 12 grounds quotes, not slugs. A
Concepts row whose resolution was `new` and whose canonical slug is an existing
atom becomes `matched`.

Say how many slugs went in and how many came out. Every count in steps 3–5 is over
the reconciled set.

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

### 3. Propose glossary stubs — threshold-gated

**Only for a term with a `type: definition` claim that ≥ 2 claims in the reconciled
set name** — the definition, and at least one use. Say the bar when you apply it,
as step 4 does, so the operator can override it for a run. Unlike step 4 this bar
does not ask for independent sources: a definition needs a definer, not
corroboration. Without a bar the pass is unbounded — trial 2's twelve extracts
proposed 98 entries (T2-14).

Then skip any term whose slug already exists in **either** folder:

```bash
ls "$VAULT/glossary/<term-slug>.md" "$VAULT/atoms/<term-slug>.md" 2>/dev/null
```

Obsidian resolves wikilinks by filename across the whole vault, so a glossary
entry named like an atom makes every link to either one ambiguous, and
`_meta/lint.sh` section 1 FAILs it — the same reasoning as mode A's `ext-` prefix.
Trial 1 found the collision (finding 10) and lint gained the check; the writer kept
proposing the stubs lint rejects (T2-15). List the skipped terms and why. Where the
concept really needs both an atom and a short definition, that is
`_meta/schema.md` § Disambiguation Policy and the operator's call — surface it,
do not drop it silently.

Same stub shape as `memex-connect` writes, with the claim's quote as the drafting
cue and `cites:: [[ext-<slug>#^cNN]]` as the source.

**Every entry needs its back-link.** Add `defines:: [[<term-slug>]]` to the source
note's `## Connections` — the note whose claim defines the term, following
`memex-glossary`'s rule that the note using a term points at its entry. It is a
modify candidate on the source note: `change: replace` of its `defines::` line
(empty in the template, or holding earlier terms) with the extended list. Without
it the entry is unreachable from the graph: none of the 12 entries trial 2's mode B
wrote had an inbound `defines::`, so `memex-compose`, which finds terms through
that field, would have omitted the layer (T2-21). `_meta/lint.sh` section 6e now warns on it.

### 4. Propose atom stubs — threshold-gated

**Only for concepts appearing in ≥ 3 claims.** The threshold bounds the entity
explosion that makes bulk extraction unusable, while still surfacing load-bearing
concepts the vault has not atomized. Under-threshold concepts stay in the extract
as unpromoted evidence, which is a perfectly good place for them — that is what
`_meta/index.md`'s "extracts with unpromoted claims" query is for.

**When the run promotes more than one extract, add a second gate: the claims come
from ≥ 2 independent sources.** Independence is step 2's test — no shared author,
neither cites nor restates the other. The ≥ 3 bar was written for one extract
promoted into a mature vault, where clearing it means something against existing
coverage. Applied to twelve extracts promoted into an empty vault it proposed 134
atoms (T2-10): with nothing atomized yet, every concept a single paper discusses
three times clears it. A single-extract run keeps the plain ≥ 3 rule.

Count after step 0 — over reconciled slugs — and state the result before
proposing anything: *"N concepts clear ≥ 3 claims from ≥ 2 independent sources."*
If N is past § Scope guards' limit, that guard applies here: batch it, confirm
each.

The threshold is a starting value, not a law. Say what it is when you apply it,
so the user can override for a specific run.

### 5. Propose conflict links

Where two claims about the same concept, **from different sources**, assert
incompatible things, propose a conflict link — with the sentence explaining the
tension, because `_meta/lint.sh` section 9 warns on a bare conflict link and a bare
one is unusable anyway.

**Say which placement you mean; the schema has two** (`_meta/schema.md`
§ Relationship Types):

- **Source → atom** — `challenges::` or `refutes::` on the *source note* whose
  claim disputes an atom. This is the usual case here: one concept, one atom,
  two sources disagreeing about it. The source that agrees already `supports::`
  the atom (step 1); the one that disagrees gets the skeptical link, and the
  tension sentence goes in the atom body.
- **Atom → atom** — `contradicts::` or `challenges::` between two *atoms*, when
  the promoted claims landed in different atoms that cannot both hold. Document
  the tension in both.

Both placements are real and both are now audited: lint section 9 and
`memex-conflicts` scan `sources/` as well as `atoms/`, and match `challenges::`
and `limits::` beside `contradicts::` and `refutes::`. Until rc.3 both read
`atoms/` only and skipped `challenges::`, so the source-level form this step
most often produces had no oracle (T2-17).

**Matching `about:` slugs is a lower bound on shared concepts, not the set.**
Step 0 merges the variants it can see; two claims filed under slugs nobody
clustered still describe one concept sometimes. When a claim reads like it
disputes something, check the neighbouring slugs by reading before concluding
there is no counterpart (T2-16).

This is where claim-comparison inference lives, and it lives here on purpose.
`memex-conflicts` declares three times over that it "does not infer conflicts
from atom content — only follows explicit relation fields already in the graph."
That is its defining contract. Mode B *proposes*; the human approves; the
explicit field now exists; `memex-conflicts` then audits it exactly as designed,
invariant intact. **Never edit `memex-conflicts` to do this.**

### 6. Append to the Promotion Log

One line per promoted claim, so a re-run does not re-offer it. Write each row as
soon as that claim's atom edit lands — after its assert passes — not in one batch
at the end: a run interrupted between the two leaves a citation with no row:

```
- ^c07 -> atoms/rag-token.md (cites, 2026-08-25)
```

The arrow is ASCII `->`. `_meta/lint.sh` 12g reads rows in exactly that shape
(the target may also be written `rag-token` or `[[rag-token]]`) and warns on every
block-anchored citation whose row it cannot find.

### 7. Bring the source note up to date

Once at least one claim from this extract is promoted, the source has been read
claim by claim and wired through atoms, and its note should say so. Propose:

- **`stage: processed`**, if the note is `unread` or `read`. `processed` means
  connections and atoms exist (`_meta/schema.md` § Stage Values), and now they do.
  As in `memex-connect` step 9, this one-field edit is asked, not gated.
- **`## Summary` and `## Key Points`**, only if they are empty or hold nothing but
  the template's placeholder. Draft them from the promoted claims, in the vault's
  voice, as modify candidates on those sections. Never rewrite text a person wrote:
  if either section has content, leave it and say so.

Mode A's one-file rule is unchanged. The source note waits for mode B because until
a human has reviewed and promoted claims, nothing has been processed. On trial 1
the operator made exactly these edits after promoting, and the source template's
placeholder names this skill as a writer of `## Summary`.

### 8. Log and report

Append to `_meta/log.md`:

```markdown
## [YYYY-MM-DD] deep-extract/promote | <source title>
url:: <source url or n/a>
atoms:: [[atom-a]], [[atom-b]]
skill:: memex-deep-extract
notes: N claims promoted; M atoms enriched; K stubs; L conflicts proposed
```

Mode A logs the same way with `deep-extract/extract` and `notes: N claims, M concepts`.

### Candidate gating in mode B

Every write in mode B — an atom's `## Detail` and `cites::`, a glossary or atom
stub, a conflict link, a Promotion Log row, a source-note section or `defines::`
line, a step 0 slug rewrite — gets a candidate first, with the same lifecycle as
mode A's one file: write candidate → confirm → write to vault → **assert** → delete
candidate, and the log last (`_meta/schema.md` § Candidate Lifecycle). The assert
re-reads the target: a create equals its candidate body, an append's lines sit under
the named section, a replace's new line is present and its `replaces:` line is gone.
On a miss, keep the candidate, stop, and report the target; the log entry lists
only writes that passed. Mode B's long write sequences are where an edit that
reports success without happening does the most damage (trial 1, finding 13). Edits
to existing files are modify candidates:

```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-deep-extract
action: modify
target: atoms/rag-token.md
section: "## Detail"
change: append
session: YYYY-MM-DD-HHMM
stage: pending
---
```

**A batched confirmation is allowed; skipping candidates is not.** Mode B asks many
questions, and asking them all before any write is fine. But a batched yes replaces
the confirmations, not the candidates. Candidates exist for crash recovery, not for
approval: mode B is the longest write sequence in the vault and the likeliest to be
interrupted, and a run that dies after a batched yes with no candidates on disk
leaves atoms half-edited and no record of what was still to come. On trial 1 the
operator skipped candidates for six atom writes after one batched confirmation; that
was the wrong call.

A `confidence:` change stays its own question even inside a batch (step 1).

---

## What this skill does NOT do

- **Mode A never writes an atom, glossary entry, or topic.** One file. If mode A
  is about to touch a second file — other than the `raw::` and `archive-sha256:`
  lines on the source — something has gone wrong.
- **It does not replace `memex-ingest` or `memex-connect`.** Ingest summarizes,
  connect wires whole sources to atoms, extract reads claim by claim. Ingest
  first, then extract.
- **It never deletes or retires an atom.** Retirement is `memex-refactor`'s: the
  *successor* carries `supersedes:: [[retired-atom]]` and the retired file stays
  as a body-only stub (`_meta/schema.md` § Retirement). The direction matters —
  trial 2's only writer had it backwards (T2-33), and lint section 7i now warns
  on it.
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
- Mode B would create or edit more than 10 curated notes — atoms **and glossary
  entries** — in one run → batch it, confirm each. The unit was atoms until trial
  2, where a 98-entry glossary pass reported no guard violation at all (T2-14).
- A `mentions::` target does not exist → do not create it in mode A. Record it
  as `new (N claims)` in the Concepts table and let mode B decide.

---

## Concurrency

The rule is `_meta/schema.md` § Concurrency. Here is how it applies.

**Mode A may fan out, one worker per source.** Each worker's writes are keyed to its
source slug — `.archive/<slug>.md`, `extracts/ext-<slug>.md`, that source's own
`raw::` and `archive-sha256:` lines, **and every scratch file**, which comes from
`mktemp -d` or carries the slug in its name, never a fixed `/tmp/<name>.md`. In
trial 2 workers staging at one fixed path overwrote each other's bodies (T2-6). Its reads are of state no mode A run writes: its own archive, and
`atoms/` for pass 4 resolution. Two conditions:

- **Workers do not append to `_meta/log.md`.** The coordinator writes every entry,
  one after another, once the workers finish. Concurrent appends below one anchor
  lose entries, and the losing write reports success.
- **Candidate session ids come from the worker**, `YYYY-MM-DD-HHMM-<source-slug>`,
  never from the wall clock alone, which gives every worker started in the same
  minute the same id.

**Mode B never runs in parallel**, not even for two sources that look unrelated. It
recomputes `confidence:` from every source an atom cites, and independence is a
property of the whole vault: concurrent promoters each see the vault as it was
before either wrote, and each counts itself as a new independent source. On trial 1,
four of the six papers queued together shared an author. The `high` that parallel
promotion would have produced looks correct in every individual run. Atom edits and
stub proposals collide the same way.

The payoff from parallel mode A is **context, not wall time**: a normalized archive is
75–100 KB, and fitting several in one window is the binding constraint.

**The cost is vocabulary.** Pass 4 resolves mentions against `atoms/` and
`glossary/`, and no worker can see the slugs its siblings are coining. On an empty
vault every mention resolves `new`, and twelve workers in trial 2 minted one concept
under several slugs (T2-11, T2-16). A serial run has the same blind spot until
atoms exist. Mode B step 0 reconciles the union before anything is promoted; run it
after any batch of mode A, parallel or not.

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
- Don't skip mode B's candidates because the user approved a batch — see
  § Candidate gating in mode B
- Don't run mode B for two sources at once — see § Concurrency
- Don't write a Promotion Log row with a Unicode arrow — lint reads `->` only
