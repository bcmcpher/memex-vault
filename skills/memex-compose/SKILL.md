---
name: memex-compose
description: Synthesize a topic's knowledge into a structured Markdown export. Use when you need to write up what you know about a topic, produce a reading list with evidence, or share your research notes. Triggers on: "compose [topic]", "write up my notes on", "export my research on", "synthesize [topic]", "generate a report on", "write a summary of what I know about". Output goes to _exports/ — vault notes are never modified.
---

# Karpathy Wiki Compose

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill synthesizes vault knowledge into a structured export document. Every sentence in the output traces to an atom body, a source body or an extract claim — nothing is invented. Run `memex-reconcile` and `memex-trust-audit` before composing a topic you plan to share; the quality of the output depends directly on graph integrity and trustworthy confidence signals.

Output files go to `_exports/` (gitignored). Vault notes are never modified.

For the relationship taxonomy and field definitions, read `$VAULT/_meta/schema.md` § Relationship Types.

---

## Prerequisites

Before composing, the topic should ideally have:
- Atoms with `confidence: medium` or higher (low-confidence atoms are included but flagged)
- Sources with `stage: processed` (unread/read sources are included but flagged as unverified)
- Conflict pairs with prose descriptions (bare conflicts will appear in the Tensions section as undescribed)

If none of these are met, compose still runs — it just produces a more heavily-flagged output.

---

## Workflow

### 1. Select scope

Ask:
- **Topic path** — concept, research, or project node to compose from (e.g., `deep-learning`, `rq-scaling-laws-llms`)
- **Atom sub-scope** (optional) — if the topic is large, ask whether to compose all atoms or a named subset
- **Output filename** (optional) — default: `YYYY-MM-DD-<topic-slug>.md`

Locate the topic file:
```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
find "$VAULT/topics" -name "<topic>.md" 2>/dev/null
```

Membership is resolved in step 2. Stop here only if step 2 finds no atoms on any basis.

### 2. Walk the graph

Read the topic file for its `## Overview` and `cites::`. Collect its atom set, and
**say which basis you used** at the top of the export:

1. **Declared membership** — atoms whose `part-of::` names the topic. For a concept
   map, add the members of every map below it in the tree, not only its direct
   children (`$VAULT/_meta/schema.md` § Topic Hierarchy), and group them by leaf in
   the output.
2. **Body links, if (1) is empty** — atoms wikilinked from the topic's own body. A
   topic that relates its atoms in prose is not an empty topic. On the first real
   vault the richest node, a research question with seven atoms discussed inline,
   had deliberately declared no members, and refusing it discarded the most
   considered note in the vault (roadmap M21).

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
# (1) Declared: read membership off the atoms, not the topic file.
# For a concept map, walk part-of:: downward to every descendant map first.
maps=<topic>
frontier=<topic>
n=0
while [ -n "$frontier" ] && [ "$n" -lt 20 ]; do
    next=""
    for m in $frontier; do
        for c in $(grep -lE "^part-of::.*\[\[${m}\]\]" "$VAULT"/topics/concepts/*.md 2>/dev/null); do
            next="$next $(basename "$c" .md)"
        done
    done
    maps="$maps $next"
    frontier=$next
    n=$((n+1))
done
for m in $maps; do
    grep -lE "^part-of::.*\[\[${m}\]\]" "$VAULT"/atoms/*.md 2>/dev/null | while IFS= read -r f; do
        printf '%s\t%s\n' "$m" "$(basename "$f" .md)"
    done
done
# (2) Fallback: atoms linked from the topic body.
grep -oE '\[\[[^]|#]+' "$VAULT/topics/<kind>/<topic>.md" | tr -d '[' | sort -u \
  | while read -r t; do [ -f "$VAULT/atoms/$t.md" ] && echo "$t"; done
```

If both are empty, report that and stop — there is nothing to compose.

**Set retired atoms apart.** An atom is retired when some atom's `supersedes::`
names it (`$VAULT/_meta/schema.md` § Retirement). A retired atom in the set is not
a claim. It goes under Section 1's *Retired* heading only, and is left out of
Evidence, Tensions, Glossary and the Confidence Summary's counts:

```bash
retired=$(grep -rhE '^supersedes::' "$VAULT/atoms" --include='*.md' | grep -oE '\[\[[^]|#]+' | sed 's/^\[\[//' | sort -u)
printf '%s\n' "$retired" | grep -qxF "<atom-slug>" && echo retired
```

In trial 2 the export rendered a split's retirement stub as a live
`[confidence: medium]` core concept with no body, cited it in Evidence, and counted
it among the atoms *"ready to cite"* (T2-44).

For each atom in scope:
- Read the full atom file
- Note: `title`, `confidence:`, `updated:`, `Summary`, `Detail`
- Collect all relation fields: `extends::`, `uses::`, `contrasts-with::`, `contradicts::`, `challenges::`, `limits::`, `cites::`, `supports::`, `demonstrates::`, `supersedes::`
- Resolve each `cites::` target to a source note, by where it lands:
  - **Under `sources/`** — a direct citation. Read the source's `title`, `url`,
    `Summary`, `Key Points` and `stage:`.
  - **Under `extracts/`** — a claim, `[[ext-<source>#^cNN]]`. An extract has no
    `url:`, no `## Summary`, no `## Key Points` and no `stage:`. Resolve the source
    through the extract's `extracted-from::`, and read those fields there. Then take
    the claim's `quote:` sub-bullet; it is quoted inline in Section 2.

  ```bash
  cite='ext-<source>#^c07'            # one cites:: target, brackets stripped
  ext=${cite%%#*}
  c=${cite##*#^}
  f="$VAULT/extracts/$ext.md"
  src=$(grep -m1 '^extracted-from::' "$f" | grep -oE '\[\[[^]|#]+' | sed 's/^\[\[//')
  find "$VAULT/sources" -name "$src.md"
  sed -n "/ \^$c\$/,/^- /p" "$f" | grep -m1 'quote:' | sed 's/^[[:space:]]*- quote:[[:space:]]*//'
  ```

  In trial 2, 132 of the 138 `cites::` in one topic were claims. Read as source
  notes, they would list extracts with empty fields in Evidence, and leave the
  Confidence Summary's source status blank for exactly the best-evidenced atoms
  (T2-44). Several claims from one extract are one source.
- Collect `supersedes::`. A live atom's `supersedes::` is rendered under Section 1's
  *Retired* heading, as the successor of each atom it names.
- Collect `defines::` fields; follow each link to `glossary/<term>.md` and read the `## Definition`, `domain:`, and `stage:` frontmatter field

Do not follow relation chains beyond the topic's atom set — only atoms in the set collected above contribute to the output. External atoms referenced via `extends::` or `uses::` are noted as pointers, not expanded.

### 3. Compose the output

Build a Markdown document with four sections:

---

#### Section 1 — Claims

Group atoms by their structural relationship to each other:

```markdown
## Claims

### Core concepts
<!-- Atoms with no extends:: or uses:: pointing to other in-scope atoms -->

### Extensions and specializations
<!-- Atoms where extends:: points to another in-scope atom -->

### Dependencies
<!-- Atoms where uses:: points to another in-scope atom -->

### Alternatives
<!-- Atoms linked via contrasts-with:: -->
```

For each atom, write:
- The atom title as a subheading
- The atom's `Summary` and `Detail` body content verbatim (do not paraphrase)
- Its `confidence:` level in brackets: `[confidence: high]`
- A `> ⚠ Low confidence` callout for `confidence: low` atoms
- Citation footnote numbers linking to sources in Section 2

Example:
```markdown
### Transformer Architecture [confidence: high]
Transformers use self-attention to process sequences in parallel...
[^1][^2]
```

End Section 1 with a *Retired* heading when the set holds any retired atom, and omit
it when it holds none:

```markdown
### Retired
- **Quality Control** — superseded by [[acquisition-quality-control]], [[tractogram-quality-control]]. <the stub's one sentence saying what replaced it>
```

A retired atom gets no confidence tag and no footnotes. It is listed so a reader
who follows an old link knows where the concept went.

#### Section 2 — Evidence

List all cited sources grouped by the atom that cites them:

```markdown
## Evidence

### Sources for: Transformer Architecture
[^1] **Attention Is All You Need** — Vaswani et al. (2017)
  > [Summary excerpt — first 2 sentences of the source's ## Summary]
  URL: https://arxiv.org/abs/1706.03762 | Status: processed

[^2] **The Illustrated Transformer** — ...
```

A source reached through an extract gets one footnote, like any other source. Under
it, quote each claim the atom cites from that extract, with its anchor:

```markdown
[^3] **Differential Tractography as a Track-Based Biomarker** — Yeh et al. (2019)
  URL: https://… | Status: processed
  - ^c11 "a data set would be rejected if the baseline and follow-up scans have a difference in mean Pearson correlation coefficient greater than 0.1"
  - ^c35 "…"
```

The quote is verbatim from the claim's `quote:`. It is the vault's strongest
evidence, so it is shown instead of the source's summary excerpt.

For sources with `stage: unread` or `read`, prepend:
`> ⚠ Unverified — this source has not been fully processed`

#### Section 3 — Tensions

List all conflict pairs where at least one atom is in scope:

```markdown
## Tensions

### [contradicts] Transformer Architecture ↔ RNN Sequential Processing
Transformers claims parallelism is sufficient; RNNs rely on sequential state.
[Tension description from atom body, if present]
*No tension description recorded.* — Run memex-conflicts to document this.

Confidence: Transformer Architecture (high) | RNN Sequential Processing (medium)
```

Include `challenges::` and `limits::` pairs with lighter formatting. Skip `related::` entirely.

#### Section 5 — Glossary (optional)

If any in-scope atoms carry `defines::` fields, read the linked glossary entries and append this section. Omit entirely if no in-scope atoms define any terms.

```markdown
## Glossary

**term name** — Definition text from glossary/term.md ## Definition.
*(domain: X)*

**another-term** — Definition text.
*(domain: Y)* ⚠ stub — definition not yet reviewed for precision
```

Only include terms reachable via in-scope atoms — do not pull in all of `glossary/`. Flag entries where `stage: stub` so readers know the definition is a first draft. Entries where `stage: reviewed` need no flag.

---

#### Section 4 — Confidence Summary

```markdown
## Confidence Summary

| Atom | Confidence | Sources | Claims | Source Status |
|------|-----------|---------|--------|---------------|
| Transformer Architecture | high | 3 | 7 | 3 processed |
| Attention Mechanism | medium | 2 | 0 | 1 processed, 1 unread |
| Positional Encoding | low | 1 | 0 | 1 unread |

`Sources` counts distinct source notes after resolving extracts. `Claims` counts the
atom's `cites::` that land on an extract. Retired atoms are not rows.

**Reliability assessment:**
- X of Y atoms are high or medium confidence with processed sources → ready to cite
- Z atoms are low confidence or have only unread sources → treat as provisional
```

---

### 4. Write the output file

Default path: `_exports/YYYY-MM-DD-<topic-slug>.md`

Show the user the output path and ask for confirmation before writing. If the file already exists, ask whether to overwrite or use a new name.

The output file opens with a metadata header:
```markdown
---
topic: <topic-slug>
composed: YYYY-MM-DD
atom-count: N
retired-count: R
source-count: M
glossary-term-count: K
vault: <absolute path to the vault root>
---
```

Write the file, then re-read it: it must exist and begin with this header. On a
miss, stop and do not log. An edit tool can report success on a write that did not
happen (trial 1, finding 13).

### 5. Log the session

Last, after the export has asserted, append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] compose | <topic-slug>
url:: n/a
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-compose
notes: exported to _exports/YYYY-MM-DD-<topic-slug>.md; N atoms, M sources
```

---

## What This Skill Does NOT Do

- Never invents claims absent from atoms — every sentence traces to an atom body, a source body or an extract claim
- Never re-grades or modifies `confidence:` (read-only on that field)
- Never modifies vault notes — output is strictly one-way to `_exports/`
- No web fetching during composition
- Does not compose from a topic with zero atoms — there is nothing to synthesize

---

## Common Mistakes to Avoid

- Don't paraphrase atom bodies — copy the `Summary` and `Detail` text as written; the user authored those
- Don't skip the Tensions section when there are no conflicts — write "No tensions recorded in this topic" explicitly so the absence is visible
- Don't hide unread-source flags in footnotes — surface them inline so the reader knows which claims are unverified
- Don't expand atoms outside the topic scope — a `uses:: [[external-atom]]` pointer is a footnote reference, not a reason to pull in that atom's full content
- Don't compose if neither basis in step 2 finds an atom — check first and offer to run `memex-connect` or `memex-topic-init` instead
- Don't read a `cites::` target under `extracts/` as a source note. Resolve it through `extracted-from::` and quote the claim (T2-44)
- Don't render a retired atom as a claim, or count it toward "ready to cite". It belongs under *Retired* only
