---
name: memex-review
description: Evaluate the semantic validity and structural coherence of topic-level nodes in the vault. Use when the user wants to audit a concept map, research note, or project for correctness, coverage gaps, mislabeled relationships, and implicit contradictions. Triggers on: "review this topic", "validate my concept map", "audit [topic]", "check coherence of [topic]", "LLM review", "review my wiki topics", "are these connections right". Not for routine source ingestion or searching — run occasionally (monthly or after major new sources are processed).
---

# Karpathy Wiki Review

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill performs a semantic audit of topic-level nodes. It reads a topic map alongside all its linked atoms and sources, then evaluates whether the knowledge structure makes sense — flagging misclassified relationships, surface-level contradictions that haven't been acknowledged, atoms that belong in a different topic, atoms missing from this topic, and relationship types that could be made more precise.

This is an LLM-assisted synthesis task, not a mechanical check. Run it occasionally — after accumulating new sources, before writing a research synthesis, or when a topic feels muddled.

For the relationship taxonomy and field definitions, read `$VAULT/_meta/schema.md` § Relationship Types.

---

## Scope

This skill operates on **topic-level nodes** only:
- `topics/concepts/` — domain concept maps
- `topics/research/` — research synthesis notes
- `topics/projects/` — project workspaces (optional; more useful for concepts and research)

It reads downward into the atoms and sources those topics cover, but does not audit free-floating atoms or raw sources in isolation.

---

## Workflow

### 1. Select the topic to review
Ask the user which topic to audit (or list available topics):

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
ls "$VAULT/topics/concepts/"
ls "$VAULT/topics/research/"
ls "$VAULT/topics/projects/"
```

One topic per session — each audit is deep work. For multiple topics, run the skill again. If the named topic doesn't exist yet, say so and offer to list what's available.

### 2. Load the topic graph
Read the topic file in full. Then collect all linked content.

**A concept map's members include its sub-topics' members** (`_meta/schema.md`
§ Topic Hierarchy). Load the map, then every concept map below it, and then the atoms
of each:

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
topic=<topic>

# The map and every descendant, found by walking part-of:: downward
maps=$topic
frontier=$topic
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

# Each map's own atoms, as map<TAB>atom — membership is derived, so read it off the atoms
for m in $maps; do
    grep -lE "^part-of::.*\[\[${m}\]\]" "$VAULT"/atoms/*.md 2>/dev/null | while IFS= read -r f; do
        printf '%s\t%s\n' "$m" "$(basename "$f" .md)"
    done
done

# Sources cited by the topic itself
grep "^cites::" "$VAULT/topics/concepts/${topic}.md"
```

Drop retired atoms, meaning any atom named in some `supersedes::`
(`_meta/schema.md` § Retirement). A retirement stub points at its successor and
belongs to no domain. For a research question or a project, the first loop finds
nothing below it, because those topics are outside the tree. Their members are
their direct members.

Group the atoms by the map they name. Atoms that name the reviewed map **directly
while it has sub-topics** are a structural defect in their own right. Each one is a
lint section 7g warning, *"part-of:: [[<topic>]] has sub-topics; name the leaf this
atom belongs to"*. List them as their own group, because Lens F works on them.

rc.2 loaded direct members only. In trial 2 that meant reviewing
`structural-connectomics` read 12 of its 20 atoms. The 8 in its two children were
invisible to every lens, and nothing flagged the 12 it did read as stranded on a
non-leaf (T2-40).

If the map **and its sub-topics** have no atom yet, skip lenses A, C, D, and E, since
they need atoms. Run only Lens B (coverage gaps) to surface candidates, and Lens F
(structural integrity) to assess whether the topic definition makes sense. Tell the
user the topic has not been populated yet. A parent whose atoms have all moved down
to its leaves is **populated**, and in the state the schema asks for. Do not report it
as empty.

For each member atom:
- Read the atom file
- Note its `confidence:`, `cites::`, and all relation fields (`extends::`, `uses::`, `contradicts::`, `challenges::`, `supersedes::`, `limits::`, `contrasts-with::`, `part-of::`)

For each source cited by atoms, read its Summary and Key Points sections. Do not read sources the user marks as too numerous — ask for a cap if the source count exceeds ~10.

### 3. Evaluate coherence — six lenses

Work through each lens and collect findings before presenting them:

**Lens A — Scope fit**  
Does each atom actually belong in this topic? Flag atoms that seem like they belong in a different domain or are only weakly related to the topic's stated overview. For each misfit, propose the leaf concept map it belongs on: a change to that atom's `part-of::`. If that leaf does not exist yet, the move is a new topic, which Lens F hands off.

**Lens B — Coverage gaps**  
Based on the atoms present and the sources they cite, are there obvious concepts central to this domain that have no atom? List up to 5 candidate atoms worth creating. Don't invent — only propose gaps that the existing sources clearly point to.

**Lens C — Relationship precision**  
Are `related::` links between atoms that could be made more specific? Look for pairs where a more precise type (`extends::`, `uses::`, `contradicts::`, `contrasts-with::`, `limits::`) clearly fits. Flag each with the proposed replacement.

First read the links `memex-reconcile` has already settled, and leave them out:

```bash
grep -h '^kept::' "$VAULT/_meta/log.md" 2>/dev/null
```

Each line is `kept:: <note path> -> [[target]]`: the user looked at that `related::`
link and chose to keep it untyped. Offering it again reopens a decision the user
already made. In trial 2, 14 of the 29 `related::` links on the reviewed atoms were
kept links. One of them, `tract-profile → [[tractometry]]`, was the most tempting
proposal in the topic (T2-41).

Never propose `part-of::`. Its target is always a topic (`_meta/schema.md`
§ Atom/Topic → Topic). Written between two atoms, lint reports it. Composition
between atoms is `extends::` or `uses::` (T2-25).

**Lens D — Unacknowledged conflict**  
Skip conflict detection here — use `memex-conflicts` instead. It handles this more precisely: it scans relation fields directly, classifies acknowledged vs. unacknowledged pairs, and drafts tension prose for you. If you haven't run `memex-conflicts` on this topic recently, note that to the user and suggest running it after this review.

**Lens E — Confidence vs. evidence (flag only)**  
Are there atoms with `confidence: medium` or `high` that only cite a single source, or cite sources still marked `stage: unread`? Flag these as potentially overconfident. Are there atoms with `confidence: low` that now have multiple independent processed sources? Flag these as upgrade candidates. Do **not** propose or apply confidence changes here — surface the list and tell the user to run `memex-trust-audit` to make the actual adjustments with full provenance checks.

**Lens F — Structural integrity**  
Does the topic's derived atom set form a coherent cluster, or does it read like a dumping ground? Is there a clear conceptual spine? If the topic seems like two separate domains merged together, suggest a split with proposed names and which atoms would go where.

**Direct atoms on a concept map with sub-topics are a structural defect.** An atom
names one concept map, and it must be a leaf (§ Topic Hierarchy). For each atom in
step 2's direct group, propose the leaf it moves to:

- **An existing sub-topic.** This is a `part-of::` repoint, applied in step 6 like
  any other move.
- **A sub-topic that does not exist yet.** This skill does not create topics. Group
  these atoms by the child they need. For each child, hand off to `memex-topic-init`
  by name, with the parent and the atom list. Its step 5a checks that no atom is left
  behind on the parent. Do not repoint an atom at a topic that does not exist. That
  is a lint section 7a dangling `part-of::`, and until the topic is created the atom
  belongs to nothing.

In trial 2 the Lens F proposal split 12 atoms three ways, and it was deferred
because nothing could create the children (T2-40). The handoff is how a proposal like
that gets done. Record it in the log (step 7) so it outlives the session.

### 4. Present findings — one lens at a time
For each lens, present findings and wait for the user to respond before moving to the next. Format:

```
## Lens [X] — [Name]

**Finding:** [What was found]
**Proposed action:** [Specific change — new link, renamed relation, atom moved, etc.]
**Confidence in this finding:** [High / Medium / Low — your epistemic confidence, not atom confidence]
```

The user can: Accept (queued, applied in step 6 once all lenses are done), Reject (skip), Defer (note it but don't act), or Discuss (explain your reasoning before deciding).

### 5. Write candidates — the whole set
After the last lens, write a candidate for **every** file the session will change,
before changing any of them (`_meta/schema.md` § Candidate Lifecycle, "Gate the whole
write set"). Each accepted proposal becomes:

- **A relation retyped (Lens C).** It becomes a replace of the atom's `related::`
  line with the target removed, plus a replace of the typed field's line with the
  target added. An empty field is a replace of its empty template line. This is the
  same form `memex-reconcile` writes.
- **An atom moved (Lens A, Lens F to an existing leaf).** This is a replace of the
  atom's `part-of::` line, and it is the whole edit. Neither topic file changes,
  because both derive membership by query. Links to projects and research questions
  on the line stay as they are.
- **Every atom above** also gets a replace of its `updated:` line with today's date.
  A relation changed with no `updated:` bump cannot be told apart, by date, from one
  written at seed time. `memex-reconcile` bumps it for the same edit (T2-41).
- **A new atom (Lens B).** This is a create candidate for a stub only, with no
  content yet: title, `description:`, tags, `confidence: low`. Run
  `find "$VAULT" -name "<slug>.md" -not -path '*/.archive/*'` first; it must print
  nothing.
- **The topic's `reviewed:` date.** This is a replace of the topic's `reviewed:`
  line with `reviewed: YYYY-MM-DD`. It is written on every completed review, even
  one that accepted nothing. It is a lightweight audit trail. It records when this
  kind of review last happened, not that the topic is complete.

Do not modify source files during topic review.

### 6. Apply
Show the candidate set and confirm it. Apply creates first, then atom edits, then
`reviewed:`. Each one goes write → **assert** → delete candidate. The assert re-reads
the target. A create's file must exist and equal the candidate body. A replace's new
line must be present and its `replaces:` line gone. On a miss, stop. Keep that
candidate and every one after it, report what landed, and do not log the rest. An
edit tool can report success on a write that did not happen (trial 1, finding 13).

### 7. Log
Last, after every assert has passed, append to `_meta/log.md`, naming only what
landed:

```markdown
## [YYYY-MM-DD] review | <topic>
url:: n/a
atoms:: [[atom-one]], [[atom-two]]
skill:: memex-review
notes: A <n>, B <n>, C <n>, D pointer, E <n>, F <n> findings; <M> accepted, <K> deferred; <R> relations retyped, <V> atoms moved, <L> stubs; handed to memex-topic-init: <child ← [[atom]], … | none>
```

`atoms::` lists every atom a write touched. A review that changed nothing still logs,
with `atoms::` empty, because `reviewed:` moved. Without an entry, a relation
retyped here is invisible to `memex-log-query` (T2-41).

### 8. Summary
Report:
- N findings surfaced across 6 lenses
- M changes accepted and applied
- K items deferred for later
- New atoms stubbed (if any)
- Direct atoms left on a concept map with sub-topics, and the `memex-topic-init`
  handoffs that would move them

---

## What This Skill Does NOT Do

- Does not evaluate the factual accuracy of source summaries — it audits structure and relationships, not content claims
- Does not touch sources or raw `sources/` files
- Does not run across all topics at once — one topic per session, by design
- Does not delete atoms — only proposes moves and adds new links
- Does not create topics — a split's new children are made by `memex-topic-init`, handed the atom list
- Does not change `confidence:` on atoms — flags candidates for `memex-trust-audit` to handle with full provenance checks
- Does not detect conflicts — delegates to `memex-conflicts` (Lens D is a pointer, not an implementation)

---

## On Frequency

Run this skill:
- Monthly for actively growing topics
- Before writing a research synthesis or project plan
- After adding 5+ new sources to a topic area
- When something "feels wrong" about how a topic has developed

This is not a routine maintenance task like lint — it's a reflective pass that benefits from a period of accumulation.

---

## Common Mistakes to Avoid
- Don't propose splitting every topic with > 10 atoms — breadth at the topic level is expected; only flag if the atoms genuinely span unrelated domains
- Don't flag `related::` as wrong just because a more specific type could technically fit — only propose replacements where the precise type is clearly correct, not marginal
- Don't confuse `contradicts::` with `contrasts-with::` — use § Choosing Between Skeptical Relations in `$VAULT/_meta/schema.md`
- Don't re-offer a `related::` link a `kept::` line in the log already settled
- Don't propose `part-of::` between two atoms — it names a topic, never an atom
- Don't review a concept map from its direct atoms alone — load its sub-topics' atoms too (step 2)
- Don't repoint an atom at a topic that does not exist yet — hand the split to `memex-topic-init`
- Don't create more than 5 atom stubs in a single review session — quality over quantity
