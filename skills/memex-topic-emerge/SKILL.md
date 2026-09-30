---
name: memex-topic-emerge
description: Discover emerging topic clusters from existing atoms by scanning structural signals — shared domain tags, `part-of::` chains, and dense atom-to-atom links. Use when atoms have accumulated in an area without a topic map, or when you want the graph to suggest what domains are forming. Triggers on: "what topics are emerging", "discover clusters in my vault", "bottom-up topics", "find natural groupings", "what domains have I built up", "suggest topic maps from my atoms", "what can I form into a topic". For creating a topic map you already have in mind, use memex-topic-init.
---

# Karpathy Wiki Topic Emerge

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

This skill scans `atoms/` for structural clustering signals and proposes topic maps from the bottom up. It complements `memex-topic-init` (which is human-directed: you know the domain, you scaffold it) with graph-directed discovery: the vault tells you what's clustering, you confirm it. Run it after accumulating 10+ atoms without a covering topic, or monthly as part of graph maintenance.

---

## When to Use This Skill

- You've ingested many atoms but haven't created topic maps yet
- You want to see what domains have naturally formed in your vault
- You suspect there are orphan atoms that belong together but aren't wired
- Lint section 6 flags a concept map as broad — the clusters inside it are its candidate sub-topics

For a domain you already have in mind, use `memex-topic-init` instead — it's faster when you know what you're building.

---

## Workflow

### Step 1 — Scan clustering signals

Collect three types of signals from `atoms/`. Skip retired atoms, meaning any atom
named in some `supersedes::` (`_meta/schema.md` § Retirement). A retirement stub
is a pointer to its successor, not a member of a domain.

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"

# Retired atoms — leave them out of every signal below
grep -rhE '^supersedes::' "$VAULT/atoms" --include='*.md' | grep -oE '\[\[[^]|#]+' | sed 's/^\[\[//' | sort -u

# Domain Tags — the only tags that name a subject
sed -n '/^## Domain Tags/,/^## /p' "$VAULT/_meta/domain.md" | sed -n '/^```/,/^```/p' | grep -vE '^```|^[[:space:]]*(#|$)'

# Tags per atom
grep -rH "^tags:" "$VAULT/atoms/"

# part-of:: targets that have no topic file (count atoms per target)
grep -rh "^part-of::" "$VAULT/atoms/" | grep -oE '\[\[[^]|#]+' | sed 's/^\[\[//' | sort | uniq -c |
  while read -r n t; do
    [ -z "$(find "$VAULT/topics" -name "$t.md" -print -quit)" ] && echo "$n $t"
  done

# Atom-to-atom links: every relation field whose target is an atom
grep -rHE "^(extends|uses|contradicts|challenges|limits|contrasts-with|related)::" "$VAULT/atoms/"
```

For each atom, record: filename, title, domain tags, `part-of::` targets, and its
links to other atoms by field.

**Tags: Domain Tags only.** `_meta/domain.md` splits its vocabulary into
§ Domain Tags, which are subjects, and § Type Tags, which describe *"what kind of
thing a note is, independent of subject"*. A concept map is a subject. Drop every
tag not in the Domain Tags block. In trial 2 the unfiltered scan made clusters of
`foundational` (12 atoms) and `applied` (10), and proposed both as sub-topics
(T2-36). The filter survives a fork, because `memex-init` rewrites the Domain Tags
block and leaves the Type Tags alone.

### Step 2 — Build candidate clusters

Evaluate three signal types in order. An atom can appear in multiple candidate clusters.

**Tag clusters:** atoms sharing the same Domain Tag. Threshold: ≥ 3 atoms per tag.

**Part-of chains:** atoms pointing to the same `part-of::` target **that has no topic file**. Threshold: ≥ 3 atoms pointing to the same target. A target with a topic file is not an emerging topic — it is existing coverage, which Step 3 reads. Counted as a signal, it proposes a topic's own membership back to it, and at the merge it absorbs the real clusters inside that topic: on the first real vault every atom named one concept map and one project, so the two part-of candidates held 22 and 20 of the 22 atoms.

**Link density:** treat the links between atoms as undirected edges. If atoms A, B
and C each have an edge to two or more of the others, they form a cluster.
Threshold: ≥ 3 atoms, each with edges to ≥ 2 of the others.

- **A typed relation is an edge** in whichever direction it is written. That covers
  `extends::`, `uses::`, `contradicts::`, `challenges::`, `limits::` and
  `contrasts-with::`. Conflict fields count too. Two atoms that contradict each
  other are about the same subject.
- **A `related::` link is an edge only when reciprocal**: A lists B *and* B lists A.
  Counted in either direction, nearly every atom in a well-wired vault qualifies. On
  the first real vault that made the whole vault one candidate.

rc.2 counted `related::` alone. `memex-reconcile` Pass 3 exists to turn
`related::` into typed relations, so the more of the mesh reconcile understood, the
less this skill could see. On trial 2, Pass 3 cut the reciprocal pairs from 21 to 13,
and cut the atoms clearing the threshold from 11 to 4 (T2-39). Counting typed
relations makes it safe to run this skill after reconcile, which is when every
campaign plan schedules it.

`part-of::` is not an edge. Its target is a topic, and the part-of chain signal above
reads it. `supersedes::` is not an edge either, because its target is retired.

Merge overlapping candidates by **Jaccard similarity**, `|A ∩ B| / |A ∪ B|`: take the highest-scoring pair, and if it is ≥ 0.50 merge the two into their union; re-score the merged cluster against the rest and repeat until no pair reaches the cut. Always merge highest-first — at a tie on the cut, scanning in list order instead can chain a merge that highest-first would never make. Use the larger signal set to name it.

Do not score overlap as `|A ∩ B| / min(|A|, |B|)`. That measures *containment*: a 4-atom candidate sharing two atoms with a 9-atom one scores 0.50, and two such bridges chain a vault's real sub-domains into one blob. On the first real vault it merged ten tag candidates into a single cluster of every atom, so the skill proposed nothing (roadmap M13). Jaccard scores that pair 2/11 = 0.18. The 0.50 cut is a starting value — 0.30 gives fewer, broader clusters — so say which one you used.

If no clusters meet any threshold, skip to the report: "No clusters found — the vault may need more atoms in an area before patterns emerge. Run `memex-ingest` or `memex-connect` to add more."

### Step 3 — Check for existing topic coverage

For each candidate cluster, read which concept map each of its atoms names. Membership is derived, so read it off the atoms rather than the topic files:

```bash
grep -H "^part-of::" "$VAULT"/atoms/*.md 2>/dev/null
ls "$VAULT/topics/concepts/"
```

Count only concept maps (`topics/concepts/`). Projects and research questions sit outside the topic tree (`_meta/schema.md` § Topic Hierarchy), so a cluster that shares a project is not covered by it.

**Count through the tree, not just the atom's own map.** An atom names one leaf, and
it is a member of every ancestor of that leaf as well. Expand each atom's concept
map to itself plus its ancestors by walking `part-of::` upward through
`topics/concepts/`. This is the same walk lint section 7f does:

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
m=<the atom's concept map>
n=0
while [ -n "$m" ] && [ "$n" -lt 20 ]; do
    echo "$m"
    m=$(grep -m1 '^part-of::' "$VAULT/topics/concepts/$m.md" 2>/dev/null | grep -oE '\[\[[^]|#]+' | head -1 | sed 's/^\[\[//')
    n=$((n+1))
done
```

A map claims an atom if the map is on that atom's chain. Test each map on the
clusters' chains against 60%, and take the **deepest** map that clears it. Deeper
maps are more specific, and a map's claim can only grow toward the root.

- **The cluster is a proper part of that map's membership**, counting the map's
  descendants' atoms too → flag it as a **possible sub-topic** of that map, and show
  the map's name.
- **The cluster holds every atom the map has** → it is already covered. Report it and propose nothing, except **Extend** for any cluster atoms that name no concept map.
- **No map clears 60%** → this is the only case where **Create** is proposed.

In rc.2 this step counted direct membership only. In trial 2 a four-atom cluster
split 2/2 between `structural-connectomics` and its child, so no map reached 60% and
the skill proposed a new root map. All four atoms were already inside
`structural-connectomics`: two directly and two through the child (T2-38).

**A sub-topic of a leaf that holds atoms directly.** Once the new map exists, the
parent is not a leaf. Every live atom the parent holds directly and the cluster does
not take is stranded, and lint section 7g warns on each one. In trial 2 this
happened to `memex-topic-init` (T2-34). List those atoms with the report. Accept the
Sub-topic only if each one either joins the new map, because the user says it
belongs, or has somewhere else to go. Otherwise, do not offer **Sub-topic** for this
cluster. Report it, and route it to `memex-topic-init` with the parent named: step 5a
there can create the siblings the remaining atoms need. A parent that already has
children does not raise this. Its direct atoms already warn, and one more child does
not add to that.

### Step 4 — Report findings

Present clusters in descending size order (most atoms first):

```
## Emerging Topics — YYYY-MM-DD

Found N candidate clusters:

### Cluster 1: [proposed title] (`proposed-slug`)
Atoms (N): [[atom-a]], [[atom-b]], [[atom-c]], ...
Signals: shared domain tags [X, Y] | M atoms in part-of:: chain | K links between atoms

→ Action: (1) Create new concept map  (2) Rename proposed title  (3) Skip

### Cluster 2: [proposed title] (`proposed-slug`)
Atoms (N): [[atom-d]], [[atom-e]], ...
Signals: shared domain tags [X]
Inside: [[existing-map]] claims M/N of these atoms (directly or through a sub-topic)
Left on [[existing-map]] if split: [[atom-f]], [[atom-g]]

→ Action: (1) Sub-topic of [[existing-map]]  (2) Extend [[existing-map]] with the unclaimed atoms  (3) Skip
```

For the proposed title: infer from the dominant Domain Tag, or the most common
keyword across atom titles. Then check the slug against the whole vault before you
show it:

```bash
find "$VAULT" -name "<slug>.md" -not -path '*/.archive/*' -not -path '*/.git/*'
```

This must print nothing. A Domain Tag names a subject, and so does the most central
atom in that subject. In trial 2, three of the five domain-tag clusters had a tag that
was an atom's filename: `tractography`, `diffusion-mri` and `structural-connectivity`
(T2-37). Accepting one would write `topics/concepts/<tag>.md`. Step 7 would then write
`part-of:: [[<tag>]]` on every member, a link that resolves to whichever file
Obsidian meets first. Lint section 1 FAILs the collision. If the slug is taken, name
the map for the domain rather than the concept, for example
`tractography-methods` (`_meta/schema.md` § Disambiguation Policy). Put the slug in
the report next to the title.

### Step 5 — Collect decisions

Ask for a decision on each cluster before writing anything. Collect all decisions first, then write candidates.

Options per cluster:
- **Create** — a new concept map with no parent
- **Sub-topic** — a new concept map whose parent is the existing map; the cluster's atoms move onto it
- **Extend** — point unclaimed atoms (those naming no concept map) at an existing map
- **Skip** — no action for this cluster

### Step 6 — Write candidate files

Write a candidate for **every** file the session will change, including the Step 7
atom edits, before changing any of them (`_meta/schema.md` § Candidate Lifecycle,
"Gate the whole write set").

For each confirmed **Create** or **Sub-topic**: write a create candidate to `_meta/candidates/`.

Build the topic from `_templates/topic-concept.md`: its frontmatter, including `reviewed:` left empty, and **both** Dataview blocks — direct members, and members via sub-topics — copied verbatim. They are self-referential (`this.file.link`), so nothing needs substituting, and a hand-typed copy is how topic stubs drift from the template. Fill `title:` (Title Case), `description:` (one sentence naming what the cluster has in common) and `tags:` (the dominant tag), and add:

```yaml
generated:
  by: memex-topic-emerge/claude-opus-5
  at: YYYY-MM-DD
```

On the `## Sub-topics and Relations` line, `part-of::` names the parent map for a **Sub-topic** and stays empty for a **Create**.

The topic file carries no membership list. The cluster's atoms join it in Step 7, by having their own `part-of::` set — that is the only write that creates membership.

For each confirmed **Extend**: no change is proposed to the existing topic file at all. Step 7 writes the atoms.


### Step 7 — Back-wire atoms

An atom names one concept map, and it is a leaf (`_meta/schema.md` § Topic Hierarchy). For each atom in a confirmed cluster, write one modify candidate and confirm it:

| The atom's concept-map `part-of::` | Write |
|---|---|
| none | append `part-of:: [[new-map]]` (or the extended map) |
| the parent of a new **Sub-topic** | replace that link with `[[new-map]]` — the parent is now derived through the new map's own `part-of::` |
| a parent map's direct member that Step 3 moved onto the new map | replace that link with `[[new-map]]` |
| any other concept map, including another leaf under the same parent | nothing yet — show both maps and ask which one leaf the atom belongs on; skip it if the user is unsure |

**Never append a second concept map to an atom that already names one.** That puts the atom on two concept maps, or on a non-leaf once the new map has a parent, and lint section 7g warns on both. Links to projects and research questions are outside the tree: keep them as they are on the same line.

A replace is a modify candidate with `change: replace`, and `replaces:` holding the atom's current `part-of::` line exactly. The body is the new line:

```yaml
---
proposed: YYYY-MM-DD HH:MM
skill: memex-topic-emerge
action: modify
target: atoms/bundle-segmentation.md
section: "## Connections"
change: replace
replaces: "part-of:: [[brain-connectivity]], [[crane-method-integration]]"
session: YYYY-MM-DD-HHMM
stage: pending
---

part-of:: [[tractography-methods]], [[crane-method-integration]]
```

On an atom that names no topic, `replaces:` is the template's empty `part-of::`
line. That keeps every Step 7 edit a replace, and never an append that would leave a
second `part-of::` line.

Do not modify atoms beyond the `part-of::` line. Do not alter other relations.

### Step 8 — Apply

Show the whole candidate set and confirm it. Then apply the candidates with topics
first, so no `part-of::` names a file that does not exist yet. Each one goes write →
**assert** → delete candidate. The assert re-reads the target. A create's file must
exist and equal the candidate body. A replace's new line must be present and its
`replaces:` line gone. On a miss, stop. Keep that candidate and every one after it,
report what landed, and do not log the rest. An edit tool can report success on a
write that did not happen (trial 1, finding 13).

### Step 9 — Log

Last, after every assert has passed, append to `_meta/log.md`, naming only what landed:
```markdown
## [YYYY-MM-DD] topic-emerge | N clusters found, M created, S sub-topics, K extended
url:: n/a
atoms:: [[atom-a]], [[atom-b]], ...
skill:: memex-topic-emerge
notes: signals: <domain-tag clusters / part-of chains / link density>; cut <0.50|0.30>; <M> new topics, <S> sub-topics, <K> extensions, <skip count> skipped
```

### Step 10 — Confirm and close

Report: clusters found, topics created, sub-topics created, topics extended, clusters skipped. Suggested next steps:

- "Run `_meta/lint.sh`: section 7 should report no new topic-tree findings, and a map you split should no longer be flagged broad in section 6."
- "If section 7a reports a dangling `part-of::`, run `memex-reconcile`."

---

## What This Skill Does NOT Do

- Does not create atoms — only discovers clusters from existing atoms
- Does not infer cluster membership from semantic content — only from structural signals (Domain Tags, `part-of::`, and atom-to-atom relation fields)
- Does not decide topic type (concept vs. research vs. project) — defaults to `concept`; rename manually if needed
- Does not modify atoms beyond each atom's `part-of::` line
- Does not scan `sources/` or `glossary/`; reads `topics/` only to learn which `part-of::` targets exist, which are concept maps, and how the concept-map tree is shaped; reads `_meta/domain.md` only for the Domain Tags block
- Does not run `memex-reconcile` inline — suggests it as a follow-up

---

## Common Mistakes to Avoid

- Don't propose a cluster of fewer than 3 atoms — the signal is too weak
- Don't cluster on Type Tags (`foundational`, `applied`, …) — they are not subjects
- Don't propose a slug any note in the vault already has — a domain tag is usually its central atom's filename too
- Don't test coverage on an atom's own map alone — count its ancestors (Step 3), or a cluster under a parent looks uncovered
- Don't propose a Sub-topic that strands the parent's other direct atoms — route it to `memex-topic-init` instead
- Don't create duplicate topic maps — always check for existing coverage first (Step 3)
- Don't count a `part-of::` target that already has a topic file as an emerging cluster
- Don't append a concept map to an atom that already names one — replace it (Sub-topic) or ask (Step 7)
- Don't batch-apply candidates without user confirmation per cluster
- Don't infer topic type from keywords alone — default to `concept` and let the user correct it
- Don't write a membership list into a topic body, and don't modify an existing topic body at all — Extend and Sub-topic are edits to atoms (plus, for Sub-topic, one new topic file)
