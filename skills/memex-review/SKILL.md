---
name: memex-review
description: Evaluate the semantic validity and structural coherence of topic-level nodes in the vault. Use when the user wants to audit a concept map, research note, or project for correctness, coverage gaps, mislabeled relationships, and implicit contradictions. Triggers on: "review this topic", "validate my concept map", "audit [topic]", "check coherence of [topic]", "LLM review", "review my wiki topics", "are these connections right". Not for routine source ingestion or searching — run occasionally (monthly or after major new sources are processed).
---

# Karpathy Wiki Review

**Vault root:** `/home/bcmcpher/Projects/claude/memex-llm-obsidian-template`

This skill performs a semantic audit of topic-level nodes. It reads a topic map alongside all its linked atoms and sources, then evaluates whether the knowledge structure makes sense — flagging misclassified relationships, surface-level contradictions that haven't been acknowledged, atoms that belong in a different topic, atoms missing from this topic, and relationship types that could be made more precise.

This is an LLM-assisted synthesis task, not a mechanical check. Run it occasionally — after accumulating new sources, before writing a research synthesis, or when a topic feels muddled.

For the relationship taxonomy, read: `references/vault-schema.md`

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
ls /home/bcmcpher/Projects/claude/memex-llm-obsidian-template/topics/concepts/
ls /home/bcmcpher/Projects/claude/memex-llm-obsidian-template/topics/research/
ls /home/bcmcpher/Projects/claude/memex-llm-obsidian-template/topics/projects/
```

One topic per session — each audit is deep work. For multiple topics, run the skill again. If the named topic doesn't exist yet, say so and offer to list what's available.

### 2. Load the topic graph
Read the topic file in full. Then collect all linked content:

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-llm-obsidian-template

# List atoms covered by this topic
grep "^covers::" "$VAULT/topics/concepts/<topic>.md"

# List sources cited by the topic itself
grep "^cites::" "$VAULT/topics/concepts/<topic>.md"
```

If `covers::` is empty (no atoms linked yet), skip lenses A, C, D, and E — they require atoms to exist. Run only Lens B (coverage gaps) to surface candidates, and Lens F (structural integrity) to assess whether the topic definition makes sense. Note to the user that the topic hasn't been populated yet.

For each atom in `covers::`:
- Read the atom file
- Note its `confidence:`, `cites::`, and all relation fields (`extends::`, `uses::`, `contradicts::`, `challenges::`, `supersedes::`, `limits::`, `contrasts-with::`, `part-of::`)

For each source cited by atoms, read its Summary and Key Points sections. Do not read sources the user marks as too numerous — ask for a cap if the source count exceeds ~10.

### 3. Evaluate coherence — six lenses

Work through each lens and collect findings before presenting them:

**Lens A — Scope fit**  
Does each atom actually belong in this topic? Flag atoms that seem like they belong in a different domain or are only weakly related to the topic's stated overview. Propose a new `covers::` home for each misfit.

**Lens B — Coverage gaps**  
Based on the atoms present and the sources they cite, are there obvious concepts central to this domain that have no atom? List up to 5 candidate atoms worth creating. Don't invent — only propose gaps that the existing sources clearly point to.

**Lens C — Relationship precision**  
Are `related::` links between atoms that could be made more specific? Look for pairs where a more precise type (`extends::`, `uses::`, `part-of::`, `contradicts::`, `contrasts-with::`) clearly fits. Flag each with the proposed replacement.

**Lens D — Unacknowledged conflict**  
Do any atoms in this topic make claims that are in tension with each other, without a `contradicts::`, `challenges::`, or `limits::` link between them? Surface these pairs and describe the tension. Propose which skeptical relation fits best.

**Lens E — Confidence vs. evidence**  
Are there atoms with `confidence: medium` or `high` that only cite a single source, or cite sources still marked `status: unread`? Flag these as overconfident. Conversely, are there atoms with `confidence: low` that now have multiple independent sources (suggesting an upgrade)?

**Lens F — Structural integrity**  
Does the topic map's `covers::` list form a coherent cluster, or does it read like a dumping ground? Is there a clear conceptual spine? If the topic seems like two separate domains merged together, suggest a split with proposed names and which atoms would go where.

### 4. Present findings — one lens at a time
For each lens, present findings and wait for the user to respond before moving to the next. Format:

```
## Lens [X] — [Name]

**Finding:** [What was found]
**Proposed action:** [Specific change — new link, renamed relation, atom moved, etc.]
**Confidence in this finding:** [High / Medium / Low — your epistemic confidence, not atom confidence]
```

The user can: Accept (you make the change), Reject (skip), Defer (note it but don't act), or Discuss (explain your reasoning before deciding).

### 5. Apply accepted changes
For each accepted proposal:
- Write the specific Dataview field change to the relevant atom or topic file
- If a new atom is proposed and accepted: create a stub only (no content yet — capture the title and tags, `confidence: low`)
- If an atom is being moved to a different topic: update `covers::` in both topic files; update `part-of::` in the atom if present
- Do not modify source files during topic review

### 6. Update the topic file
After all lenses are complete, add or update a `reviewed:` date field in the topic's frontmatter:

```yaml
reviewed: YYYY-MM-DD
```

This is a lightweight audit trail. It does not mean the topic is "complete" — it records when this kind of review last happened.

### 7. Summary
Report:
- N findings surfaced across 6 lenses
- M changes accepted and applied
- K items deferred for later
- New atoms stubbed (if any)

---

## What This Skill Does NOT Do

- Does not evaluate the factual accuracy of source summaries — it audits structure and relationships, not content claims
- Does not touch sources or raw `sources/` files
- Does not run across all topics at once — one topic per session, by design
- Does not delete atoms — only proposes moves and adds new links
- Does not change `confidence:` on atoms automatically — proposes upgrades/downgrades; user confirms

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
- Don't confuse `contradicts::` with `contrasts-with::` — use the decision tree in `references/vault-schema.md`
- Don't create more than 5 atom stubs in a single review session — quality over quantity
