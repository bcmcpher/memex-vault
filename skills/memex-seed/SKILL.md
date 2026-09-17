---
name: memex-seed
description: Seed a vault in one pass from a pre-fetched corpus — a manifest plus a directory of normalized archives becomes N paper source notes, a topic scaffold, and one grouped log entry. Use when the sources are already on disk and validated and the remaining job is bulk structure rather than per-URL capture, typically once, right after memex-init. Triggers on: "seed my vault", "seed from manifest", "bulk load this corpus", "I have a manifest of papers", "import this archive directory", "bootstrap my vault from these papers", "load the seed corpus". Fetches nothing and creates no atoms — for a single URL use memex-save or memex-ingest, to read a seeded paper claim by claim use memex-deep-extract mode A, and to wire seeded notes into the graph use memex-connect.
---

# Karpathy Wiki Seed

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.
**Manifest:** `$MANIFEST`, the path the operator names. Archive paths inside it
resolve against `$(dirname "$MANIFEST")`, **not** against `$VAULT`.

The vault's normal capture path takes one URL at a time because fetching is the
expensive, failure-prone step: it can 404, paywall, or return a cookie notice, and
each outcome needs a decision. When fetching has already happened out of band —
someone assembled a corpus, normalized the text, and wrote a manifest — none of
that risk remains. What is left is structure, and asking for it per URL asks the
same five questions N times, where the Nth answer is always the first answer.

This skill does that once. It validates, reports how many *independent* units the
batch really contains, proposes a topic tree, asks one round of questions, writes N
source notes with their archives, and hands off.

It fetches nothing. For a URL, use `memex-save` or `memex-ingest`. To read a seeded
paper claim by claim, use `memex-deep-extract` mode A. To wire seeded notes into
atoms, use `memex-connect`.

For the relationship taxonomy and full field definitions, read: `references/vault-schema.md`

---

## When to Use This Skill

- Right after `memex-init`, when a corpus was assembled out of band and the fork is
  otherwise empty.
- When a manifest of already-fetched, already-normalized documents needs to become
  source notes without N capture conversations.
- **Not** for a URL — that is `memex-save` or `memex-ingest`. **Not** for a PDF you
  have not normalized — run `_meta/pdf-clean.sh` and `_meta/normalize.sh` first.
  **Not** for a single paper, where the per-source path is simpler and asks better
  questions.

### Has this vault already been seeded?

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
grep -c "skill:: memex-seed" "$VAULT/_meta/log.md" 2>/dev/null || echo 0
```

**Zero** — run the full workflow.

**One or more** — say what the previous run seeded, then report which rows of the
new manifest are not already present. **Match on `doi`, never on the slug or the
filename:** a source filename carries the date of the run that wrote it, so the same
paper seeded twice has two different filenames and comparing them finds nothing.

```bash
# Rows already in the vault, by DOI.
grep -l "doi.org/$DOI" "$VAULT"/sources/paper/*.md 2>/dev/null
```

Re-running is legal. Silently re-seeding a row that is already there is not.

---

## The Manifest Contract

A manifest is a JSON array of objects, one per document. These are the keys this
skill uses; anything else is ignored.

| Key | Required | Used for |
|---|---|---|
| `title` | yes | `title:`, and the filename's title tail |
| `doi` | yes | `url:` as `https://doi.org/<doi>`, and the cross-run duplicate key |
| `year` | yes | `published:` |
| `authors` | yes | `authors:` — see step 1's truncation check |
| `archive` | yes | the file copied into `.archive/` |
| `venue` | no | `venue:` |
| `surnames` | no | strengthens step 2's independence report |
| `slug` | no | the archive's filename; derived from `title` when absent |
| `branch` | no | step 3 and 4 topic routing **only** |
| `version`, `route`, `retrieval_note` | no | the provenance comment |
| `validate_pass`, `validate_detail` | — | **ignored**, deliberately. See step 1 |
| `pdf`, `zotero_key`, `overlap_with_trial1`, `archive_bytes` | — | ignored: local-machine state, not vault content |

**Path resolution.** A row's `archive` resolves against `$(dirname "$MANIFEST")`.
An absolute path is honoured as given. A row whose archive does not resolve is a
step-1 finding — do not prompt for a different base directory and retry, because a
manifest whose paths do not work is a manifest the operator needs to see.

**`branch` is routing input, not vault vocabulary.** It never lands on a note.
`_meta/domain.md` has no branch block and will not get one; the mapped topic slug is
what gets written.

### Reading the manifest

The vault ships no JSON parser and depends on none. Probe once, report which tier is
in use, and do not add a dependency:

```bash
if   command -v jq      >/dev/null 2>&1; then TIER=jq
elif command -v python3 >/dev/null 2>&1; then TIER=python3
else TIER=read
fi
echo "manifest tier: $TIER"
```

All three tiers emit the same TSV, so exactly one loop is written downstream. List
fields join on `|`, because an author entry contains commas and spaces but never a
pipe.

```bash
# Tier 1 — jq.
manifest_tsv() {
  jq -r '.[] | [
      (.slug // ""), .archive, .title, (.doi // ""), (.year // ""), (.venue // ""),
      ((.authors // []) | join("|")), ((.surnames // []) | join("|")),
      (.branch // ""), (.version // ""), (.route // ""), (.retrieval_note // "")
    ] | @tsv' "$1"
}
```

```bash
# Tier 2 — python3. Same columns, same order.
manifest_tsv() {
  python3 - "$1" <<'PY'
import json, sys
cols = ["slug","archive","title","doi","year","venue",
        "authors","surnames","branch","version","route","retrieval_note"]
for r in json.load(open(sys.argv[1])):
    out = []
    for c in cols:
        v = r.get(c) or ""
        out.append("|".join(map(str, v)) if isinstance(v, list) else str(v))
    print("\t".join(out))
PY
}
```

**Tier 3 — neither is installed: read the manifest with the Read tool and tabulate
it yourself.** This is a legitimate path, not a degraded one; a twelve-row manifest
is small and you are a competent parser. Tiers 1 and 2 exist because a
hand-tabulated hundred-row manifest is where transcription errors live.

---

## Workflow

### 1. Validate the manifest and every archive

Everything in this step happens before any write.

**Shape.** The top level is an array of objects. Every row carries the required keys
above with non-empty values. Every `archive` resolves to a readable file. Report
row by row; abort on any miss.

**Re-validate every archive, now.** `_meta/validate-archive.sh` takes **one file**,
has no batch mode, and rejects a directory — so loop:

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
BASE="$(cd "$(dirname "$MANIFEST")" && pwd)"

manifest_tsv "$MANIFEST" | while IFS=$'\t' read -r slug archive title rest; do
    f="$archive"; [ "${f#/}" = "$f" ] && f="$BASE/$archive"
    if bash "$VAULT/_meta/validate-archive.sh" --quiet "$f"; then
        printf '  PASS    %s\n' "$slug"
    else
        printf '  REJECT  %s (exit %d)\n' "$slug" "$?"
    fi
done
```

`--quiet` must be `$1`; it is only checked there. Exit **0** passes, **1** rejects,
and **2 is a usage error or a bad path — never a verdict about the document**.
Report exit 2 separately and stop; it means this skill or the path is wrong, not
that the paper is.

**Ignore the manifest's own verdict.** Where a manifest carries `validate_pass` or
`validate_detail`, they are a snapshot of whichever validator ran when the manifest
was built, which may predate the one in this vault. On the RC-2 reference corpus
they record four failures that the current validator passes. Never read them. The
loop above is the verdict.

**A REJECT is a conversation, not a flag.** Re-run the validator on that file
*without* `--quiet` so the operator sees its own three diagnostic lines, name the
row, and ask. The default answer is **exclude the row and seed the rest**. A blanket
"override everything" is refused: the point of the check is that a landing page and
a paper are indistinguishable downstream — quotes ground against whatever is in the
file, so a bad archive makes the grounding guarantee intact and worthless.

**Check `authors` for truncation.** A manifest often carries a display byline
(`["Leila Cammoun", "et al."]`) while `surnames` carries the whole group. This
matters because step 2's person keys come from `authors:`, and `et al.` yields no
key — so a truncated row silently loses its co-authors from every independence
check the vault will ever run.

Flag a row when it has an `et al.` entry, or when `surnames` is present and longer
than `authors`. For each flagged row, read the head of that row's archive — the
byline is in the first lines, and this is a local file read, not a fetch:

```bash
head -c 1200 "$BASE/$archive"
```

Extract the full author list with given names, **show it to the operator against
the manifest's `surnames` for confirmation**, and write that. If the byline is not
recoverable, write the manifest list verbatim and carry the row into step 2's report
as **author-incomplete**, so the number it produces reads as the weak verdict it is.

### 2. Report independence (M15)

`_meta/schema.md` § Confidence Values counts *independent* claims, and `_meta/lint.sh`
section 8 counts independent sources the same way. Compute it here, before anything
is written, because a correlated batch is a fact about the corpus that the operator
should learn now rather than from a lint warning six skills later.

**The rule, matching `_meta/lint.sh` exactly.**

- A **person key** is first initial + surname: letters only, hyphens read as spaces,
  non-ASCII dropped. `Klaas E. Stephan` → `k.stephan`, and `Julio E. Villalón-Reina`
  → `j.villalonreina`. A single-token name yields the bare surname. **`et al.`
  yields nothing.** `channel:` and `tool:` compare as whole values, case-insensitively.
- Two documents are **dependent** when they share a person key, or when one cites
  the other, directly or through a chain of `cites::` inside the vault.
- An **independent unit** is a **connected component** of that relation — *not* a
  disjoint pair. Dependence is transitive through documents: if A and B share an
  author and B and C share a *different* author, then {A, B, C} is **one** unit, and
  no pairwise test finds it. Count components. Never count pairs.
- A document carrying none of `authors:`, `channel:` or `tool:` cannot be checked.
  It counts as its own unit and is reported as **unchecked**, so the number never
  reads as a verdict.

Use `surnames` for the batch computation when the manifest has it — it is complete
by construction, which makes this report at least as strict as lint's. Where the two
would differ, print both numbers and name the reason.

**Three outputs, all required.**

1. **Within the batch.** Print it in lint's own wording, so the operator can diff it
   against the lint summary afterwards:
   `Independent units: <K> of <N> sources`, plus `<U> unchecked`.
2. **Against existing `sources/`.** Read `authors:`, `channel:` and `tool:` from the
   frontmatter of every existing source note and every `^cites::` line, and fold
   them into the same computation. On an empty fork this is a no-op. On a second
   seed it is the whole point.
3. **The refusal.** Name every component of size ≥ 2, its members, and the key that
   joined them. Then **stop and ask.**

> Trial 1 got **5 independent units from 16 documents** because the saves were
> correlated by construction, and nothing warned. Seven correctly-hedged atoms were
> reported as upgrade candidates off the back of it (M15).

The operator may choose to proceed. They may not proceed without seeing the pairs,
and a correlated row is never silently dropped.

### 3. Propose the topic scaffold

**Concept maps only.** `topics/concepts/` is the only tree; projects and research
questions cut across it and have no parent (`_meta/schema.md` § Topic Hierarchy).
Refuse to seed into `topics/projects/` or `topics/research/` — nothing in a manifest
says a document belongs to a project.

Group the rows by `branch` and propose **one root plus one leaf per branch**. For
each group, propose a slug and a title drawn from the titles in it, and name which
entries of `_meta/domain.md` § Domain Tags the group plausibly sits under. **Read
that vocabulary; do not recite one.** If nothing in it fits, say so and point at
`memex-init`'s re-run subset, which extends the tag blocks — do not invent a tag,
because lint section 10 warns on every tag the vocabulary does not declare.

**D2 wiring.** The **child** carries `part-of:: [[<root-slug>]]` on its own
`## Sub-topics and Relations` line. A parent never lists its children — that is the
derived "Via sub-topics" Dataview block. One parent maximum, no cycles, and the
root's `part-of::` stays **empty**.

The root having **zero direct members is correct, not a gap.** An atom names one
*leaf*, and its broader domains derive by walking `part-of::` upward. A root that
accumulates direct atoms is the flat topic layer M21 was about.

Never overwrite an existing topic file. If a proposed slug is taken, say so, and
either wire the batch into the existing topic or pick another slug.

**Do not call `memex-topic-init`.** Its value is searching existing atoms and
sources to wire a new topic in, and a freshly seeded vault has no atoms — the search
returns nothing and the extra machinery buys nothing.

### 4. Ask the one shared question round

One round. Every answer is overridable per row, but the questions are asked once.
Say the rule out loud, because it is the reason this skill exists: *asking these per
row is the same question N times, and the Nth answer is always the first answer.*

1. **Topic slugs and titles** — confirm or replace step 3's proposal for the root and
   each leaf.
2. **The `branch` → topic map** — confirm the grouping, and allow moving individual
   rows between leaves.
3. **Default `tags:`** — from `_meta/domain.md` § Domain Tags, § Type Tags and
   § Stage Tags, with per-branch and per-row overrides. **Reject any tag the
   vocabulary does not declare**, here, rather than shipping N notes that each raise
   a lint section 10 warning. Offer `memex-init` to extend it.
4. **`stage:`** — default `unread`. `read` is a claim about what the operator has
   done, so it is only ever set when they say so.
5. **`## Why Saved`** — one line per *branch*, not per row, in the operator's own
   words: what this seed is for.

Then present the whole resolved plan as one table — row → filename → topic → tags →
stage — and take **one** confirmation.

That confirmation replaces the per-note confirmations. It does not replace the
candidate files; see § Candidate Gating.

### 5. Write

Both directories this skill needs are gitignored, so they are absent from a fresh
clone — and a fresh clone is exactly what this skill runs on:

```bash
mkdir -p "$VAULT/.archive" "$VAULT/_meta/candidates"
```

**Topics first**, so the tree exists when the notes land. Then, per row, in this
order and no other:

1. **Copy** the archive to `$VAULT/.archive/<corpus-slug>.md`.
2. **Normalize it in place:**
   ```bash
   bash "$VAULT/_meta/normalize.sh" --in-place "$VAULT/.archive/<corpus-slug>.md"
   ```
   Never a bare `cp`. Normalization has to happen in every skill that writes an
   archive: extract quotes are checked with `grep -F` against these bytes, so if one
   writer skips it, whether a quote grounds depends on which skill happened to save
   the file. The script is deterministic and idempotent, so running it on an
   already-normalized corpus costs nothing and is always safe.
3. **Write the source-note candidate**, show it, apply on confirmation, delete the
   candidate.

**The order is not stylistic.** `_meta/lint.sh` section 5 FAILs — not warns — on a
`raw::` naming a file that does not exist while `.archive/` is present. A note
written before its archive is a hard lint failure.

**Archives are not candidate-gated.** `.archive/` is gitignored working state, not a
vault note, and `memex-ingest` does not gate its archive either. The consequence is
worth stating: an interrupted run can leave an archive with no note, which is
harmless and is cleaned up by re-running.

**Filenames.** The source note is `sources/paper/YYYY-MM-DD-<title-tail>.md` using
**today's date, never the publication date** — `_meta/lint.sh` section 1 FAILs
without a full `YYYY-MM-DD-` prefix, and a manifest year alone cannot supply one.
The archive **keeps the corpus slug unchanged**, so `.archive/` stays 1:1 with the
corpus it came from and the file that was validated is the file that is named. The
two filenames therefore differ on purpose, and `raw::` is the link between them.
Do not "fix" one to match the other.

**The source note.** From `_templates/source-digital.md`, with the paper fields:

```markdown
---
type: Source
title: Mapping the human connectome at multiple scales with diffusion spectrum MRI
description: 
url: https://doi.org/10.1016/j.jneumeth.2011.09.031
medium: paper
saved: 2026-09-17
tags: [neuroscience]
stage: unread
authors: [Leila Cammoun, Xavier Gigandet, Djalel Meskaldji, Jean Philippe Thiran, Olaf Sporns, Kim Q. Do, Philippe Maeder, Reto Meuli, Patric Hagmann]
published: 2012
venue: Journal of Neuroscience Methods
generated:
  by: memex-seed/<model>
  at: 2026-09-17
---

## Why Saved
<the one line for this row's branch, from step 4 question 5>

## Summary
<!-- 2–3 sentence digest — filled by memex-save or memex-connect from the fetched
     URL, or by memex-deep-extract mode B from promoted claims.
     Condense the first sentence into frontmatter `description:`. -->

## Key Points
- 

## Connections
supports:: 
introduces:: 
demonstrates:: 
challenges:: 
refutes:: 
cites:: 
rebuts:: 
related:: 
<!-- provenance: memex-seed 2026-09-17
     manifest: ~/Projects/memex-seed-corpus/manifest.json
     corpus-slug: 2012-cammoun-mapping-the-human-connectome-at
     doi: 10.1016/j.jneumeth.2011.09.031
     route: zotero
     retrieved: local PDF attachment, zotero key 4F8X4FX9
     version: version of record -->
raw:: .archive/2012-cammoun-mapping-the-human-connectome-at.md
```

- **`description:` and `## Summary` stay empty**, with the template's comment
  preserved. This skill reads nothing. A written summary on a note marked
  `stage: unread` is a claim nobody made.
- **`published:`** takes the most precise value reliably known — usually just the
  manifest's year. Never pad it to a month or a day
  (`_meta/schema.md` § Publication Dates).
- **`status:` never appears.** It is `stage:`, and lint FAILs on `status:`.
- **The provenance comment uses single colons.** `_meta/lint.sh` section 7 scans
  body lines matching `^[a-z][a-z-]*::` against the relation taxonomy, so a
  `doi::` line would be an unknown-relation warning this skill created. Indent the
  continuation lines. Keep `version` **last**: it is free text and may contain a
  colon, a comma or parentheses, so it needs the position with no delimiter after
  it. Omit a key whose manifest value is absent rather than writing it empty.

**The topics.** From `_templates/topic-concept.md`. **Copy both Dataview blocks
byte-for-byte** — they are self-referential through `this.file.link` and use
`row["part-of"]` in bracket form, because Dataview parses a bare hyphenated field in
a `WHERE` clause as subtraction and silently matches nothing. A hand-typed copy is
how a stub drifted from the template before. Ship `reviewed:` **empty** on every
topic: the template has it, and a scaffold that omits it starts the fork one field
short of its own template. `cites::` stays empty — wiring is a non-goal. Leaves
carry `part-of:: [[<root-slug>]]`; the root's is blank.

### 6. Log, then hand off

**Log first.** Nothing recovers the log entry if the session dies — `memex-candidates`
finishes notes and explicitly never writes a log entry — so the append goes in as
soon as the last note lands, before the report.

Exactly **one grouped entry**, immediately below the anchor line in `_meta/log.md`
(`<!-- Add new entries below this line, most recent first -->`), most recent first:

```markdown
## [2026-09-17] paper | seed: 12 sources across 3 topics
url:: n/a
atoms:: 
skill:: memex-seed
notes: manifest ~/Projects/memex-seed-corpus/manifest.json; 12 rows, 12 validated (validate-archive.sh exit 0, 0 overrides); 12 independent units of 12, 0 unchecked; topics brain-connectivity (+2 leaves: tractography-methods, effective-connectivity); tags [neuroscience]; stage unread; 12 archives normalized into .archive/; session 2026-09-17-1430
```

- `<medium>` is `paper` when the batch is homogeneous; a mixed manifest uses `mixed`
  and enumerates the media in `notes:`.
- `url:: n/a` — the batch has no single URL, the same as meeting and reconcile
  entries. Individual DOIs live on the notes.
- **`atoms::` is empty** — `atoms:: ` with nothing after it. This skill creates no
  atoms, and `memex-log-query` reads an empty list as exactly that signal.
- `notes:` carries every count the operator will want to diff against lint, plus the
  candidate session id, so a dropped session is traceable from the log to
  `_meta/candidates/`.

**Then hand off:**

> N sources seeded across K topics; M independent units of N. Run
> `memex-deep-extract` mode A on each paper to build the evidence layer, then
> `memex-connect` to wire the notes into atoms.
>
> `bash _meta/lint.sh` should exit 0 with N section-6a *inbox-only source* warnings —
> that is what `stage: unread` with empty `## Connections` means — and report
> `Independent units: M of N sources`.

Give the operator the expected lint result, not just an instruction to run it. A
number they can check is the only way they find out the seed went wrong.

---

## Candidate Gating

**Session ID** is `YYYY-MM-DD-HHMM`, taken once at the start of the run. Every
candidate in the batch shares it, which is what lets `memex-candidates` group the
whole seed as one session.

**File name** is `_meta/candidates/YYYY-MM-DD-HHMMSS-{action}-{target-slug}.md`
(`_meta/schema.md` § Candidate Lifecycle, which is authoritative where
`memex-ingest` shows a `YYYYMMDD-` variant). One file per write, `HHMMSS`; one
session per run, `HHMM`.

Every candidate this skill writes is a **create** candidate — it modifies nothing,
so no `section:`, `change:` or `replaces:` key ever appears:

```markdown
---
proposed: 2026-09-17 14:31
skill: memex-seed
action: create
target: sources/paper/2026-09-17-mapping-the-human-connectome.md
session: 2026-09-17-1430
stage: pending
---

<the full note, including its own --- frontmatter block>
```

A create candidate's body is a whole note, which starts with its own frontmatter, so
the file holds **two `---` blocks**; `memex-candidates` step 4 splits them.

**A batched confirmation is allowed; skipping candidates is not.** Step 4 asks its
questions once and takes one yes for the whole batch — that is the design. But a
batched yes replaces the *confirmations*, not the *candidates*. Candidates exist for
crash recovery, not for approval. This is the longest write sequence in the vault:
N archives, N notes, K topics. A run that dies after a batched yes with no
candidates on disk leaves a half-seeded `sources/paper/`, no record of what was
still to come, and archives whose notes were never written.

**The log entry is the one thing candidates cannot recover.** No skill gates the
log, and `memex-candidates` never writes one. So after a resumed session: if
`sources/paper/` has notes but `grep -c "skill:: memex-seed" _meta/log.md` is `0`,
the log append is the outstanding work. Write it by hand with the real counts,
naming the original session id.

---

## What This Skill Does NOT Do

- **Does not fetch anything** — no URL, no DOI resolution, no PDF retrieval. The
  corpus must already be on disk and normalized. For a URL, use `memex-save` or
  `memex-ingest`.
- **Does not create atoms.** Not one, not a stub. A topic asserts no evidence and
  cannot be over-confident; an atom stub written before anyone read the paper can be
  both wrong and confident.
- **Does not wire the graph.** Every relation field on a seeded note ships empty.
  `memex-connect` wires them.
- **Does not assign `confidence:`.** It creates nothing that carries one.
- **Does not read the papers**, summarize them, or fill `## Summary` or
  `description:`. `stage: unread` is the truth about a seeded note. Reading one is
  `memex-deep-extract` mode A.
- **Does not write to `topics/projects/` or `topics/research/`** — only
  `topics/concepts/` is in the tree.
- **Does not read a manifest's `validate_pass`, `validate_detail`, `pdf`,
  `zotero_key` or `overlap_with_trial1`.**
- **Does not write `branch` to a note**, and does not extend `_meta/domain.md` — a
  tag the vocabulary lacks is a question for `memex-init`.
- **Does not touch anything `memex-init` owns** — `_meta/domain.md`, the templates,
  `getting-started.md`.

---

## Concurrency

The rule is `_meta/schema.md` § Concurrency. How it applies here: **`memex-seed`
never fans out.**

The rule permits parallelism when a step's writes are keyed to a single source slug
*and* its reads do not depend on vault state another concurrent run is writing.
Seed's per-row writes satisfy the first half — one archive, one note, one candidate,
all keyed to the row. It fails the second half twice. Step 2 reads the whole batch
plus all of `sources/`, and every row not yet written changes its answer. And the
run ends in a single append to `_meta/log.md`, which is shared: concurrent appends
below one anchor lose entries, and **the losing write reports success.**

Because there is one coordinator, the batch's single wall-clock session id is safe.
The hazard `memex-deep-extract` mode A guards against — every worker started in the
same minute sharing an id — cannot arise with one worker.

Do not "optimize" this into per-row workers without first lifting both the
independence computation and the log append out to a coordinator. At that point the
workers are doing `memex-save`'s job, worse.

---

## Common Mistakes to Avoid

- **Don't trust a manifest's `validate_pass`.** On the RC-2 reference corpus it
  records four failures the current validator passes — it is a snapshot of whichever
  validator built the manifest. Re-run `_meta/validate-archive.sh` on every archive
  at seed time.
- **Don't pass a directory to `_meta/validate-archive.sh`**, and don't put `--quiet`
  anywhere but `$1`. Both exit 2.
- **Don't read exit 2 as a rejection.** It is a usage error or a bad path and says
  nothing about the document — stop and fix the call.
- **Don't test independence pairwise.** Dependence is transitive, so an A–B–C author
  chain reports as three units under a pairwise test and one under the real rule.
  Count connected components — see § step 2.
- **Don't proceed past a component of size ≥ 2** without showing the operator the
  documents and the shared key. Trial 1's 5 units from 16 documents warned nobody.
- **Don't write `authors: [Someone, et al.]`.** `et al.` yields no person key, so
  the independence check silently loses every co-author. Recover the byline from the
  archive head — see § step 1.
- **Don't write the source note before its archive is in `.archive/` and
  normalized.** A `raw::` pointing at a missing file is a lint FAIL, not a warning.
- **Don't `cp` an archive in without `_meta/normalize.sh --in-place`.** It is
  idempotent, so running it on an already-normalized corpus costs nothing, and
  re-running on an archive of unknown provenance is always safe.
- **Don't use the publication date in a source filename.** Today's date, always;
  `published:` carries the publication date, at whatever precision is known.
- **Don't rename the archive to match the source note.** They differ on purpose and
  `raw::` is the link.
- **Don't write a `key::` line inside the provenance comment.** Lint section 7 scans
  body lines for relation fields; single colons only.
- **Don't use a tag `_meta/domain.md` does not declare** — lint section 10 warns on
  every one of them, N times. Extend the vocabulary with `memex-init` first.
- **Don't write `branch:` onto a note.** It is routing input, not vault vocabulary.
- **Don't write `status:` on anything.** It is `stage:`; lint FAILs on `status:`.
- **Don't take a batched yes as permission to skip candidate files.** The yes
  replaces the confirmations, not the candidates — see § Candidate Gating.
- **Don't type the Dataview blocks by hand.** Copy both from
  `_templates/topic-concept.md`, keeping `row["part-of"]` in bracket form.
- **Don't ship a topic without `reviewed:`**, even empty. The template has it.
- **Don't write more than one log entry.** One grouped entry for the whole batch.
- **Don't fill `## Summary` or `description:`.** Nobody has read the paper; that is
  what `stage: unread` means.
- **Don't seed a root topic that atoms will name directly.** Atoms name leaves; a
  root with direct members is the flat topic layer M21 was about.
