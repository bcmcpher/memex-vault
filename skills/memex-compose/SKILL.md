---
name: memex-compose
description: Synthesize a topic's knowledge into a structured Markdown export. Use when you need to write up what you know about a topic, produce a reading list with evidence, or share your research notes. Triggers on: "compose [topic]", "write up my notes on", "export my research on", "synthesize [topic]", "generate a report on", "write a summary of what I know about". Output goes to _exports/ — vault notes are never modified.
---

# Karpathy Wiki Compose

**Vault root:** `/home/bcmcpher/Projects/claude/memex-llm-obsidian-template`

This skill synthesizes vault knowledge into a structured export document. Every sentence in the output traces to an atom or source body — nothing is invented. Run `memex-reconcile` and `memex-trust-audit` before composing a topic you plan to share; the quality of the output depends directly on graph integrity and trustworthy confidence signals.

Output files go to `_exports/` (gitignored). Vault notes are never modified.

For the full relationship taxonomy, read: `references/vault-schema.md`

---

## Prerequisites

Before composing, the topic should ideally have:
- Atoms with `confidence: medium` or higher (low-confidence atoms are included but flagged)
- Sources with `status: processed` (unread/read sources are included but flagged as unverified)
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
VAULT=/home/bcmcpher/Projects/claude/memex-llm-obsidian-template
find "$VAULT/topics" -name "<topic>.md" 2>/dev/null
```

If the topic has no `covers::` atoms, report that and stop — there is nothing to compose.

### 2. Walk the graph

Read the topic file. Collect `covers::` atom list.

For each atom in scope:
- Read the full atom file
- Note: `title`, `confidence:`, `updated:`, `Summary`, `Detail`
- Collect all relation fields: `extends::`, `uses::`, `contrasts-with::`, `contradicts::`, `challenges::`, `limits::`, `cites::`, `supports::`, `demonstrates::`, `supersedes::`
- Follow `cites::` links to source files; read each source's `title`, `url`, `Summary`, `Key Points`, `status:`
- Collect `defines::` fields; follow each link to `glossary/<term>.md` and read the `## Definition`, `domain:`, and `status:` frontmatter field

Do not follow relation chains beyond the topic's atom set — only atoms in `covers::` contribute to the output. External atoms referenced via `extends::` or `uses::` are noted as pointers, not expanded.

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

For sources with `status: unread` or `read`, prepend:
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

Only include terms reachable via in-scope atoms — do not pull in all of `glossary/`. Flag entries where `status: stub` so readers know the definition is a first draft. Entries where `status: reviewed` need no flag.

---

#### Section 4 — Confidence Summary

```markdown
## Confidence Summary

| Atom | Confidence | Sources | Source Status |
|------|-----------|---------|---------------|
| Transformer Architecture | high | 3 | 3 processed |
| Attention Mechanism | medium | 2 | 1 processed, 1 unread |
| Positional Encoding | low | 1 | 1 unread |

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
source-count: M
glossary-term-count: K
vault: /home/bcmcpher/Projects/claude/memex-llm-obsidian-template
---
```

### 5. Log the session

Append to `_meta/log.md`:
```markdown
## [YYYY-MM-DD] compose | <topic-slug>
url:: n/a
atoms:: [[Atom A]], [[Atom B]]
skill:: memex-compose
notes: exported to _exports/YYYY-MM-DD-<topic-slug>.md; N atoms, M sources
```

---

## What This Skill Does NOT Do

- Never invents claims absent from atoms — every sentence traces to an atom or source body
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
- Don't compose if the topic's `covers::` list is empty — check first and offer to run `memex-ingest` or `memex-topic-init` instead
