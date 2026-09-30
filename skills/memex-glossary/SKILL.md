---
name: memex-glossary
description: Scan a vault note (atom, source, or topic) and propose technical terms that warrant glossary entries — precise, operational definitions. Use when you want to deliberately build out your glossary for a domain, audit a note for undefined jargon, or prepare research for sharing. Triggers on: "what terms in [note] need defining", "build glossary from [atom]", "scan [topic] for jargon", "what jargon needs a definition", "add terms to my glossary from [note]", "glossary scan [note]", "what should I define from [topic]", or any time the user points at a note and asks what terms should be defined. Does not replace the opportunistic glossary prompts in ingest/connect/meeting — this skill is for deliberate, targeted glossary work on notes that already exist.
---

# Karpathy Wiki Glossary

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill reads a vault note and surfaces the technical terms in it that deserve precise, stable definitions in `glossary/`. Its purpose is to distinguish between terms that are already covered (have atoms or glossary entries) and terms that are used but undefined — jargon that a future reader would need to look up.

The goal is **operational definitions**: specific enough that two people would agree on whether a given thing fits the term. Vague glosses ("X is a type of Y") don't qualify. Definitions should be grounded in how the term is actually used in this note, not generic Wikipedia-level descriptions.

For the relationship taxonomy and field definitions, read `$VAULT/_meta/schema.md` § Relationship Types.

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
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
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

### 5. Write candidates — the whole set

Step 4 decides term by term. Nothing is written until the last term is decided. Then
write a candidate for **every** file the session will change, in one `session:`,
before changing any of them (`$VAULT/_meta/schema.md` § Candidate Lifecycle, "Gate
the whole write set"). The write set is the new entries **and** the `defines::`
wiring that makes them reachable.

In trial 2 this skill gated its creates and wrote the `defines::` back-link as a
direct edit after them. A session interrupted between the two was recovered through
`memex-candidates` as three glossary entries nothing pointed at. The candidate files
never named the scanned note, so the wiring was not on disk to recover (T2-42).
`_meta/lint.sh` section 6e warns on an entry no note wires.

**One create candidate per accepted term.** Run
`find "$VAULT" -name "<kebab-term>.md" -not -path '*/.archive/*' -not -path '*/.git/*'`
first. It must print nothing. A slug already taken by an atom or topic is resolved by
`$VAULT/_meta/schema.md` § Disambiguation Policy, and lint section 1 FAILs the
collision.

```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-glossary
action: create
target: glossary/kebab-term.md
session: YYYY-MM-DD-HHMM
stage: pending
---
```

The body is the full glossary file. Draft it from `$VAULT/_templates/glossary.md`:

```markdown
---
type: Glossary Term
title: Term Name
description: <the definition in one line>
term: term name
aliases: [ALT, ACRONYM]
domain: <inferred from note's topic area>
tags: []
created: YYYY-MM-DD
stage: reviewed
generated:
  by: memex-glossary/claude-opus-5
  at: YYYY-MM-DD
---

## Definition
<drafted definition — or user's edited version>

## Usage Notes
<drafted usage notes, or leave as placeholder if none>

## Source
cites:: [[source-note-filename]]
```

If the user edited the definition in step 4, the body carries their version.

**One wiring candidate for the scanned note.** `defines::` always runs from the note
that *uses* the term to the glossary entry, never the other way round. A term taken
from a source note is wired on that source; a term taken from an atom body is wired
on the atom. All of the session's new terms go on one line. How that line is written
depends on what the note already has:

| The scanned note has | Candidate |
|---|---|
| an empty `defines::` line (the atom and source templates ship one) | replace it: `replaces: "defines:: "`, body `defines:: [[term-a]], [[term-b]]` |
| `defines:: [[x]]` | replace it: `replaces: "defines:: [[x]]"`, body `defines:: [[x]], [[term-a]], [[term-b]]` |
| no `defines::` line (topics, older notes) | append under `## Connections`: `section: "## Connections"`, `change: append`, body `defines:: [[term-a]], [[term-b]]` |

Copy `replaces:` from the file byte for byte, including the empty line's trailing
space. Read it with `grep -n '^defines::' "$VAULT/<note>"`. If the note has no
`## Connections` section, `memex-candidates` asks before appending at the end of the
file, so say so when you show the set.

**An atom's `updated:` line.** When the scanned note is an atom, add a replace of its
`updated:` line with today's date. A `defines::` edit with no bump cannot be told
apart, by date, from one written at seed time (T2-42, as T2-41 records for
`memex-review`). Sources and topics carry no `updated:`.

### 6. Apply

Show the candidate set: each entry's path and definition, plus the wiring line and
the note it lands on. Confirm the set. Then apply the creates first, then the
wiring, then `updated:`. Each one goes write → **assert** → delete candidate. The
assert re-reads the target:

- a create's file exists and equals the candidate body;
- a replace's new line is present and its `replaces:` line is gone;
- an append's line is under `## Connections`.

On a miss, stop. Keep that candidate and every one after it, report the target, and
do not log what did not land. An edit tool can report success on a write that did
not happen (trial 1, finding 13).

If the session drops anywhere in step 5 or 6, every pending candidate shares one
`session:`, so `memex-candidates` recovers the entries and their wiring together.

### 7. Log

Last, after every assert has passed, append to `_meta/log.md`, naming only what
landed:

```markdown
## [YYYY-MM-DD] glossary | <scanned-note-slug>
url:: n/a
atoms:: [[scanned-atom]]
skill:: memex-glossary
notes: created [[multi-head-attention]], [[positional-encoding]]; defines:: on <note path>; skipped <n>
```

`atoms::` names the scanned note only when it is an atom; otherwise leave it empty.
A session that created nothing writes no entry. Without an entry, the glossary
entries a session creates are invisible to `memex-log-query`. In trial 2, five
entries were created and the log recorded none of them (T2-42).

### 8. Session summary

```
Glossary scan complete: atoms/transformer-architecture.md
  Created: [[multi-head-attention]], [[positional-encoding]]
  Skipped: feedforward-sublayer
  Already covered: transformer (atom), attention-mechanism (atom)
  defines:: added to: atoms/transformer-architecture.md
```

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
- Don't write the `defines::` edit directly, after the creates. It is a candidate in the same session, or an interrupted session recovers entries nothing points at (T2-42)
- Don't give each term its own `defines::` line on one note. Extend the existing line, so the note keeps one line that a replace can target
- Don't batch-create silently — confirm each file before writing
- Don't scan notes you haven't read — always read the full body before extracting candidates
