---
name: memex-tend
description: Decide what maintenance the vault needs right now, and run it in dependency order. Use after a batch ingest, on a periodic health pass, or whenever the user does not know which skill to reach for. Triggers on "what should I run now", "tend my vault", "vault health check", "maintain my wiki", "I just ingested a bunch, now what", "clean up my vault", "what needs attention", "weekly maintenance", "is my vault in good shape". Also triggers before publishing or sharing research, which has its own shorter sequence. Reports first and executes only with confirmation; never invokes memex-deep-extract.
---

# Memex Tend

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).

Nineteen skills is more than anyone should have to choose between. This one reads
the vault's actual state, decides which of them have work to do, and orders them so
that each runs on a graph the previous one has already corrected.

**It is a router, not an author.** It writes exactly one thing: its own `_meta/log.md`
entry. Every vault change is made by the skill it hands off to, under that skill's
own confirmation rules.

---

## What it reads

Three sources, all executable from a terminal. **Not `_meta/index.md`** — those are
Dataview queries that only render inside Obsidian, and this skill runs where there
is no Obsidian. Everything below is the plain-text half of the same signals.

| Source | Answers |
|--------|---------|
| `_meta/lint.sh` | What is wrong, at WARN and FAIL severity, one message per finding |
| `_meta/candidates/` | What a previous session proposed and never finished |
| `_meta/log.md` | When each maintenance skill last ran |

The lint run is the expensive part and the reason this skill exists: one pass
produces every signal, instead of five skills each scanning the vault to discover
they have nothing to do.

---

## What it never does

- **Never invokes `memex-deep-extract`.** It is the most expensive skill in the
  vault — it reads a full source claim by claim and writes an extract. Lint 8's
  "under-extracted source" WARN is exactly the signal that would justify it, so the
  temptation is real. Report the candidates, name the cost, and let the user decide.
  A tend pass that silently deep-extracts four papers is a bill, not a favour.
- **Never invokes `memex-compose`.** Composing is publishing, not maintenance.
- **Never invokes `memex-refactor`.** Split and merge are irreversible judgement
  calls about what a concept *is*. Surface the candidates; let the user run it.
- **Never invokes `memex-init`.** It runs once, before there is anything to tend.
- **Never invokes `memex-seed`.** It runs once, at bootstrap, from a manifest
  path outside the vault that tend cannot see.
- **Never chains without confirmation.** Present the plan, then run one skill at a
  time, reporting after each.

---

## Modes

Pick from what the user asked; if it is ambiguous, ask which.

| Mode | Trigger | Scope |
|------|---------|-------|
| **Triage** | "what should I run now?" | Steps 1–3. Report and stop. No skill is invoked. This is the default. |
| **Full pass** | "tend my vault", "weekly maintenance" | Steps 1–6. The whole ordered plan, confirmed step by step. |
| **Post-ingest** | "I just ingested a bunch, now what" | `memex-candidates` → `memex-connect` → re-lint. Stops there: confidence and conflict work is worthless until the new sources are wired. |
| **Pre-share** | "before I share this", "publishing my notes on X" | `memex-reconcile` → `memex-trust-audit` → `memex-conflicts` → `memex-compose`, scoped to one topic. The last step is the user's to run. |

---

## Workflow

### 1. Gather state

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"

# Pending writes from an interrupted session
ls -t "$VAULT/_meta/candidates/" 2>/dev/null | grep -v "^\.gitkeep$" | wc -l

# Scratch for this pass. A fixed /tmp name collides with a second pass (T2-6);
# print the path, and set TEND to it in every later block of this pass.
TEND="$(mktemp -d -t memex-tend.XXXXXX)"; echo "tend scratch: $TEND"

# The state oracle. Capture once; every later step reads this file, not the vault.
bash "$VAULT/_meta/lint.sh" > "$TEND/lint.out" 2>&1; echo "lint exit=$?"

# Findings per section, for the report; step 2 routes by text
while IFS= read -r line; do
    case "$line" in
        "── "*)          sect="${line%% ─*}" ;;
        *WARN*|*FAIL*)  echo "$sect" ;;
    esac
done < "$TEND/lint.out" | sort | uniq -c

# When each maintenance skill last ran: newest date per skill
sed -n -e 's/^## \[\([0-9-]\{10\}\)\].*/D \1/p' \
       -e 's/^skill:: \(memex-[a-z-]*\).*/S \1/p' "$VAULT/_meta/log.md" \
  | while read -r kind val; do
        if [ "$kind" = D ]; then day="$val"; else echo "$val $day"; fi
    done | sort -k1,1 -k2,2r | sort -s -u -k1,1
```

**Exit 2 means the linter broke**, not the vault. Stop and report it as a linter
bug; do not route findings from a truncated run, and do not read it as corruption.

An empty log is normal in a young vault. Treat "never run" as a weak signal, not an
overdue one — a skill with nothing to do has no reason to have run.

### 2. Route findings to skills

Route each finding by its **text**, not its section number. The WARN and FAIL strings
are stable and distinct, and one section holds findings for several skills. Keyed by
section, rc.2's table could route 1 of trial 2's 16 end-of-campaign warnings. An
evidence check filed under section 7 matched no row, and section 7's "atom on a map
with sub-topics" row sent the atom back to the step that had stranded it (T2-43).

The table is a file, so the matching is done by `grep`, not by reading. Each line
is `fragment|route`, where the fragment is a piece of one lint message that no other
message contains. Lines starting `#` name the section they came from.

```bash
TEND=<the scratch path step 1 printed>
cat > "$TEND/routes" <<'EOF'
# 1. Naming
missing YYYY-MM-DD prefix|hand fix (FAIL) — rename the source file
declares source type '|memex-init re-run, vocabulary only
is not declared in _meta/domain.md § Source Types|memex-init re-run, vocabulary only
atom has a date prefix|hand fix — rename the atom and its inbound links
is ambiguous (schema.md § Disambiguation Policy)|hand fix (FAIL) — rename one note (schema.md § Disambiguation Policy)
matches an alias of|memex-refactor merge if one concept — recommend only; else rename the entry
# 2. Frontmatter
missing field:|hand fix, or re-run the capture skill that wrote the note
empty field:|hand fix, or re-run the capture skill that wrote the note
(duplicate source;|hand fix — keep one source note, repoint the other's inbound links
keep the credential out of the vault|hand fix NOW — strip the credential; it is also in git history
# 4. Orphans
no cites:: and no inbound links|memex-connect to wire it; memex-refactor merge if redundant — recommend only
# 5. Archives
raw:: with no archive-sha256:|hand fix — sha256sum the archive, add archive-sha256:
archive-sha256: with no raw::|hand fix — drop archive-sha256:, or restore raw::
is not 64 lowercase hex digits|hand fix — recompute archive-sha256:
archive-sha256: does not match|the user's call — restore the archive from git, or memex-deep-extract re-grounds it; never run it
raw:: points to missing file|hand fix (FAIL) — restore the archive, or re-ingest
# 6. Graph health
inbox-only; run memex-connect|memex-connect
(fully isolated)|memex-connect
may cover multiple concepts|memex-refactor split — recommend only
consider splitting into sub-topics|memex-topic-emerge, then memex-review
leaf concept map with no live member atoms|memex-connect to wire the sources behind it; or delete the map by hand
no note carries defines::|hand fix — add defines:: to the note that uses the term
# 7. Structure
names an atom; part-of:: is topic-only|memex-reconcile Pass 1
but no matching topic file found|memex-reconcile Pass 1
only concept maps have a parent|hand fix — edit the topic's part-of:: (schema.md § Topic Hierarchy)
a concept map's parent must be one|hand fix — edit the topic's part-of:: (schema.md § Topic Hierarchy)
; a concept map has at most one|hand fix — edit the topic's part-of:: (schema.md § Topic Hierarchy)
is on a part-of:: cycle|hand fix — edit the topic's part-of:: (schema.md § Topic Hierarchy)
an atom names one leaf, and its ancestors derive|memex-review Lens A on either map
has sub-topics; name the leaf this atom belongs to|memex-review Lens F on that map; it hands missing leaves to memex-topic-init
may be stale|report only — the user's call whether newer sources exist (memex-save, memex-ingest)
unknown relation field:|hand fix — a typo or a schema question
but no such note|memex-reconcile Pass 2
the successor holds supersedes::|hand fix — move supersedes:: to the successor (schema.md § Retirement)
only the successor holds the field|hand fix — move supersedes:: to the successor (schema.md § Retirement)
a retirement stub keeps only its body|hand fix — strip the stub's relation fields (schema.md § Retirement)
untyped related:: link(s)|memex-reconcile Pass 3
# 8. Confidence and coverage
(needs 3+ independent for high)|memex-trust-audit
(upgrade candidate)|memex-trust-audit
but no cited source has been read claim by claim|memex-trust-audit
may be under-extracted|memex-deep-extract — name it, never run it
(high requires none unaddressed)|memex-trust-audit, then memex-conflicts
and no cited source has an extract)|memex-deep-extract on its most-cited source — name it, never run it
# 9. Conflicts
(bare conflict link)|memex-conflicts
# 10. Tags
unknown tag:|fix the tag, or memex-init to extend the vocabulary
# 11. Schema conformance
carries status:; the vault field is stage:|hand fix (FAIL) — schema conformance
missing required field: type:|hand fix (FAIL) — schema conformance
declares "|hand fix (FAIL) — schema conformance
not valid for|hand fix (FAIL) — schema conformance
# 12. Extract grounding
no extracted-from::|memex-deep-extract re-run on that source — the user's call (FAIL)
but no such file in sources/|hand fix (FAIL) — repoint extracted-from::
filename should be ext-|hand fix — rename the extract
block ids in the body|hand fix — correct claims: in the extract
duplicate claim ids|hand fix (FAIL) — renumber, then repoint cites
claims but only|memex-deep-extract re-run on that source — the user's call (FAIL)
empty quote: line|memex-deep-extract re-run on that source — the user's call (FAIL)
quote not found in|memex-deep-extract re-run on that source — the user's call (FAIL)
has no block|hand fix — repoint the cite to an existing claim
capped at medium without claim-level grounding|memex-trust-audit
Promotion Log has no row|hand fix — append the missing Promotion Log row
# 13. Provenance
generated: is missing by: or at:|hand fix — provenance shape
generated.by '|hand fix — provenance shape
generated.at '|hand fix — provenance shape
verified: is present but has no list entries|memex-trust-audit step 7
entr(ies) but|memex-trust-audit step 7
verified.by '|memex-trust-audit step 7
sign-off predates the current content|memex-trust-audit step 7 — re-sign or leave unsigned
but never signed off (no verified:)|memex-trust-audit step 7
EOF

grep -E 'WARN|FAIL' "$TEND/lint.out" > "$TEND/findings"
# Count per row. A row with no hits is dropped.
grep -vE '^(#|$)' "$TEND/routes" | while IFS='|' read -r frag route; do
    n=$(grep -cF -- "$frag" "$TEND/findings")
    [ "$n" -gt 0 ] && printf '%s\t%s\t%s\n' "$n" "$route" "$frag"
done
# Findings no row matches. Report each one; never drop it.
grep -vE '^(#|$)' "$TEND/routes" | cut -d'|' -f1 > "$TEND/fragments"
grep -vF -f "$TEND/fragments" "$TEND/findings"
```

Any line the last command prints is a lint message this table does not know. It
means lint gained a check since this skill was written. Report it verbatim, as
*unrouted*, and do not guess a route. A new lint WARN needs a new row here in the
same change.

Three routes need more than a skill name:

- **`has sub-topics; name the leaf`** (lint 7g). The atom sits on a map that has been
  split, and the leaf it belongs to may not exist yet. rc.2 routed it to a hand edit
  of `part-of::`, which was the step that stranded it. Group these by map and
  schedule one `memex-review` per map. Lens F moves each atom to an existing child,
  and hands the rest to `memex-topic-init`, one new leaf per group, with the atom
  list. In trial 2 this was 12 of 16 warnings.
- **`untyped related:: link(s)`** (lint 7j). This routes to `memex-reconcile` Pass 3.
  7j names only atoms with no typed relation at all, so the backlog Pass 3 finds is
  larger than the count here (T2-12).
- **`never signed off`** (lint 13d). This routes to the sign-off pass. It is the one
  step where the human does the work, so say so when it is scheduled (T2-13).

Skip a skill entirely when none of its rows matched. "Nothing to do" is the most
useful thing this skill can say, and the reason it reads state before proposing.

### 3. Order the plan

The order is a dependency chain, not a calendar. Each step changes what the next
one sees, so running them out of order produces findings that were already fixed or
misses ones that were not yet visible.

1. **`memex-candidates`** — first, always, if `_meta/candidates/` is non-empty.
   Unapplied proposals mean every other skill is reading an incomplete vault and
   may re-propose work already queued.
2. **FAIL-level lint findings** — before any skill runs. FAILs are corruption: a
   claim quoting text its source never contained makes trust-audit's evidence
   wrong, not just incomplete. Fix or escalate them, then re-run lint.
3. **`memex-connect`** — wires inbox-only sources. Wiring changes orphan counts and
   confidence inputs, so it precedes everything that reads them.
4. **`memex-reconcile`** — repairs dangling `part-of::` and other dangling targets,
   then works the `related::` backlog when 7j fired. Structural repair before
   semantic audit.
5. **`memex-topic-emerge`, then `memex-review`, then `memex-topic-init`** — when
   section 6 flagged a broad concept map, 7g flagged atoms on a split map, or the
   user asked. Emerge proposes the split; review Lens F moves atoms to existing
   leaves; topic-init creates the leaves Lens F handed off. Topic structure comes before the audits
   because they read it: `memex-trust-audit` runs one topic at a time, and
   `memex-conflicts` looks for cross-topic pairs, which a map holding every atom
   cannot have. Splitting the map afterwards leaves both audited against topics that
   no longer exist. On the first real vault this order was backwards — the plan put
   trust-audit on nine section 8 findings while section 6 flagged the one map every
   atom sat in.
6. **`memex-trust-audit`** — needs 3–5 finished to be auditing the real graph.
   Includes the sign-off pass, which asks the human separately.
7. **`memex-conflicts`** — documents bare conflict links. After trust-audit, whose
   `high`-with-contradictions finding often creates the ones worth documenting.
8. **`memex-stale`** — read-only decay report. Last because it is advisory and its
   output is a reading list, not a repair.

Present this as a numbered plan with the finding counts that justify each step, and
the steps with no findings marked *skipped*. Then ask to proceed.

### 4. Execute, one at a time

Invoke the first skill in the plan. Let it run under its own rules — do not
pre-empt its confirmations or answer its questions on the user's behalf.

After any skill that **wrote** to the vault, re-run lint and diff the finding counts:

```bash
TEND=<the scratch path step 1 printed>
bash "$VAULT/_meta/lint.sh" > "$TEND/lint-2.out" 2>&1; echo "exit=$?"
diff <(grep -cE "WARN|FAIL" "$TEND/lint.out") <(grep -cE "WARN|FAIL" "$TEND/lint-2.out")
```

Report the delta before moving on. **A step that increased the finding count is a
result, not an error** — reconcile promoting `related::` to typed relations can
surface conflicts that were previously invisible. Say which section grew and why,
and re-route if the plan should change.

Stop the whole pass if a skill reports a FAIL it could not fix, and hand back with
the remaining plan intact so it can be resumed.

### 5. Export (terminal, optional)

Only after everything else, and only if the user asked to export:

```bash
bash "$VAULT/_meta/lint.sh" > /dev/null 2>&1; echo "exit=$?"
```

**Exit must be 0.** `memex-export` refuses a failing vault by its own rule; this
step exists so the refusal is not the first the user hears of it.

If `skills/memex-export/` does not exist, say the export layer is not built yet and
skip the step. Do not attempt to run `_meta/okf-export.py` directly.

### 6. Log

```markdown
## [YYYY-MM-DD] tend | <mode>
url:: n/a
atoms:: 
skill:: memex-tend
notes: lint W<before>/F<before> → W<after>/F<after>; ran <skills>; skipped <skills>; deferred <deep-extract candidates>
```

`atoms::` stays empty — this skill modifies no atoms. The skills it invoked write
their own entries; this one records the pass that sequenced them.

Log a triage-only run too. "Looked, found nothing" is the entry that stops the next
pass from re-deriving the same conclusion an hour later.

### 7. Report

1. **What the vault needs**, as the ordered plan, with counts
2. **What ran**, and the finding delta for each
3. **What was skipped**, and why — clean sections are the good outcome
4. **What is deferred to the user**: every `memex-deep-extract` candidate by name,
   every `memex-refactor` split or merge, and every hand fix with its file path
5. **Sign-off**: if trust-audit ran, whether any atom is still waiting on a human
   `verified:` entry — that is the one thing no skill can do on the user's behalf

---

## Common Mistakes to Avoid

- Don't run `memex-deep-extract`, `memex-compose`, `memex-refactor`, `memex-init`,
  or `memex-seed`. The first three are the user's call; the last two already
  happened, and seed needs a manifest path tend was never given.
- Don't route by section number. Match the message text against step 2's table; a
  section holds findings for several skills (T2-43).
- Don't drop a finding step 2 could not match. Report it as unrouted; the table is
  missing a row.
- Don't route lint 7g to a hand edit of `part-of::`. There may be no leaf to move
  the atom to; `memex-review` Lens F decides, and `memex-topic-init` creates it.
- Don't propose a skill none of whose rows matched, to look thorough. An
  eight-step plan on a healthy vault teaches the user to ignore this skill.
- Don't run the plan without confirming it first. The whole point is deciding
  *whether* to spend the tokens.
- Don't re-run lint after a read-only skill — `memex-stale` and `memex-search`
  change nothing, and the second pass costs as much as the first.
- Don't route a FAIL to a skill that only reads. FAILs in sections 1, 5, 11 and most
  of 12 are hand fixes; naming a skill that cannot fix them wastes a step and hides the work.
- Don't treat an empty `_meta/log.md` as neglect. A vault with nothing to tend has
  nothing in the log, and that is the same reading.
- Don't summarize a skill's output in place of running it. Handing off means
  handing off; a paraphrase of what `memex-conflicts` would probably say is not a
  conflict pass.
