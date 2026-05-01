---
name: memex-glossary
description: Scan a vault note (atom, source, or topic) and propose technical terms that warrant glossary entries — precise, operational definitions. Use when you want to deliberately build out your glossary for a domain, audit a note for undefined jargon, or prepare research for sharing. Triggers on: "what terms in [note] need defining", "build glossary from [atom]", "scan [topic] for jargon", "what jargon needs a definition", "add terms to my glossary from [note]", "glossary scan [note]", "what should I define from [topic]", or any time the user points at a note and asks what terms should be defined. Does not replace the opportunistic glossary prompts in ingest/connect/meeting — this skill is for deliberate, targeted glossary work on notes that already exist.
---

# Karpathy Wiki Glossary

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`

This skill reads a vault note and surfaces the technical terms in it that deserve precise, stable definitions in `glossary/`. Its purpose is to distinguish between terms that are already covered (have atoms or glossary entries) and terms that are used but undefined — jargon that a future reader would need to look up.

The goal is **operational definitions**: specific enough that two people would agree on whether a given thing fits the term. Vague glosses ("X is a type of Y") don't qualify. Definitions should be grounded in how the term is actually used in this note, not generic Wikipedia-level descriptions.

For the full relationship taxonomy, read: `references/vault-schema.md`

---

## When to Use This Skill

- After building out a new topic area: "scan this atom/topic for terms that need definitions"
- Before composing or sharing research: ensure jargon is pinned down for readers
- When a note uses domain-specific terms without linking to atoms or glossary entries
- Periodic glossary hygiene across a domain or topic

This skill does NOT duplicate the glossary prompts in `memex-ingest`, `memex-connect`, or `memex-meeting`. Those capture terms opportunistically during source processing. This skill is for deliberate, systematic glossary work on notes that already exist.

---

## Input

Accept any of:
- A specific note path: `atoms/transformer-architecture.md`, `topics/concepts/deep-learning.md`
- A topic name or concept keyword: "deep learning" → find `topics/concepts/deep-learning.md`
- A folder scope: "scan all atoms" → list and confirm before reading
- Free text pasted inline: extract terms from the pasted content directly

If the input is ambiguous, ask: "Which note or area should I scan?"

---

## Workflow

### 1. Read the target note(s)

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault
cat "$VAULT/<note-path>"
```

For folder-level scans, list notes first and confirm scope:
```bash
ls "$VAULT/atoms/"
ls "$VAULT/topics/concepts/"
```

Read the full body, including `## Summary`, `## Detail`, and `## Connections` sections.

### 2. Extract term candidates

Identify technical terms that fit this profile:

**Strong candidates:**
- Domain-specific nouns and noun phrases used without definition in this note
- Abbreviations or acronyms (e.g., MHA, RLHF, FFN) — especially if used but not spelled out
- Terms borrowed from another field used in a precise technical sense here
- Terms that appear in `[[wikilinks]]` but have no existing atom or glossary entry
- Terms the note treats as assumed knowledge that a new reader to this domain would not have

**Skip these:**
- Terms already in `glossary/` — check first
- Terms that already have atoms — the atom's `## Summary` usually provides sufficient definition
- General English terms (not domain-specific)
- Terms so universally known in this domain that definition adds no value
- Proper nouns (model names, author names, tool names) unless the term has a technical meaning

Check existing coverage before proposing:
```bash
ls "$VAULT/atoms/" | grep -i "<term-keyword>"
ls "$VAULT/glossary/" | grep -i "<term-keyword>"
```

### 3. Draft operational definitions

For each surviving candidate:
- Write 1–2 sentences that pin down the precise meaning
- Make the definition specific to how the term is used in THIS note, not a general-purpose gloss
- Distinguish from adjacent terms where confusion is common (e.g., "attention" vs. "self-attention" vs. "cross-attention")
- Note any context-specific meaning if the term has different uses in different fields

A definition is operational if it answers: "If I showed someone an example, could they tell whether this term applies?" If not, it's too vague.

### 4. Present proposals

Group by confidence, most valuable first:

```
## Proposed glossary terms from: atoms/transformer-architecture.md

### Strong candidates
1. **multi-head attention** (MHA)
   Definition: An attention mechanism that computes self-attention in parallel
   across H independent subspaces ("heads"), concatenates the results, and
   projects to the output dimension. Enables the model to attend to different
   aspects of the input simultaneously.
   Usage Notes: "Heads" are parallel, not sequential — the H in "multi-head"
   refers to independent projection matrices, not layers.

2. **positional encoding**
   Definition: A vector added to each token embedding to inject information
   about the token's position in the sequence. Necessary because self-attention
   is permutation-invariant — without it, "the cat sat" and "sat the cat" produce
   identical representations.

### Worth considering
3. **feedforward sublayer** — used twice but meaning is implied; create if this
   term recurs in other atoms you're building.

### Already covered — no action needed
- transformer: atoms/transformer-architecture.md
- attention mechanism: atoms/attention-mechanism.md
```

For each proposal, ask: "Create this entry? (Yes / Edit / Skip)"

### 5. Create accepted stubs

For each accepted term, create `glossary/kebab-term.md`:

```markdown
---
title: Term Name
term: term name
aliases: [ALT, ACRONYM]
domain: <inferred from note's topic area>
tags: []
created: YYYY-MM-DD
status: reviewed
---

## Definition
<drafted definition — or user's edited version>

## Usage Notes
<drafted usage notes, or leave as placeholder if none>

## Source
cites:: [[source-note-filename]]
```

Then add `defines:: [[term-name]]` to the scanned note's `## Connections` section. If no `## Connections` section exists, append one. If the term came from a source note, add `defines::` to that source; if the term came from an atom body, add `defines::` to the atom. The `defines::` direction is always: the note that *uses* the term points at the glossary entry — not the other way around.

If the user edits the definition during the "Yes / Edit / Skip" step, write their version.

Ask before creating each stub.

### 6. Session summary

```
Glossary scan complete: atoms/transformer-architecture.md
  Created: [[multi-head-attention]], [[positional-encoding]]
  Skipped: feedforward-sublayer
  Already covered: transformer (atom), attention-mechanism (atom)
  defines:: added to: atoms/transformer-architecture.md
```

No log entry for glossary-only sessions. If `defines::` fields were added to existing notes, those files are the only ones modified.

---

## Atom vs. Glossary

The distinction matters because it determines how the term is referenced:

| | Glossary entry | Atom |
|---|---|---|
| Purpose | Pins a stable definition | Accumulates claims + evidence |
| Value | "What does this mean?" | "What do I believe about this?" |
| Referenced via | `defines::` | `supports::`, `introduces::`, etc. |
| Changes over time | Rarely | Yes, as evidence accumulates |

A term can have BOTH if the definition is worth pinning separately from the claim-accumulation work. But if an atom's `## Summary` already gives a tight operational definition, a glossary entry is redundant — note that and skip.

---

## Common Mistakes to Avoid

- Don't propose entries for terms well-covered by existing atoms without checking first
- Don't use generic definitions — ground each one in how the term is used in the scanned note
- Don't create entries for terms the user clearly already knows and is using correctly — the glossary is for terms a future reader of these notes would need
- Don't add `defines::` links before a stub is accepted — only wire after confirmation
- Don't batch-create silently — confirm each file before writing
- Don't scan notes you haven't read — always read the full body before extracting candidates
