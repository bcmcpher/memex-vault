---
name: memex-tend
description: Decide what maintenance the vault needs right now, and run it in dependency order. Use after a batch ingest, on a periodic health pass, or whenever the user does not know which skill to reach for. Triggers on "what should I run now", "tend my vault", "vault health check", "maintain my wiki", "I just ingested a bunch, now what", "clean up my vault", "what needs attention", "weekly maintenance", "is my vault in good shape". Also triggers before publishing or sharing research, which has its own shorter sequence. Reports first and executes only with confirmation; never invokes memex-deep-extract.
---

# Memex Tend

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited.

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
| `_meta/lint.sh` | What is wrong, by section, at WARN and FAIL severity |
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

# The state oracle. Capture once; every later step reads this file, not the vault.
bash "$VAULT/_meta/lint.sh" > /tmp/tend-lint.out 2>&1; echo "lint exit=$?"

# Findings attributed to their section
awk '/^── /{s=$0; sub(/ *─+ *$/,"",s)} /WARN|FAIL/{print s "\t" $0}' /tmp/tend-lint.out

# When each maintenance skill last ran
awk '/^## \[/{d=substr($2,2,10)} /^skill:: memex-/{print $2, d}' "$VAULT/_meta/log.md" \
  | sort -k1,1 -k2,2r | awk '!seen[$1]++'
```

**Exit 2 means the linter broke**, not the vault. Stop and report it as a linter
bug; do not route findings from a truncated run, and do not read it as corruption.

An empty log is normal in a young vault. Treat "never run" as a weak signal, not an
overdue one — a skill with nothing to do has no reason to have run.

### 2. Route findings to skills

Each lint section maps to the skill that can act on it. Findings with no skill are
hand fixes; say so rather than inventing a route.

| Lint section | Finding | Route to |
|---|---|---|
| 1 | missing `YYYY-MM-DD` prefix (FAIL) | hand fix — rename the file |
| 1 | declared source type with no folder / undeclared folder | `memex-init` re-run, vocabulary only |
| 2 | missing frontmatter field | hand fix, or re-run the capture skill that wrote it |
| 3 | stale unread sources | `memex-stale` for the report; then read or drop them |
| 4 | orphan atom | `memex-connect` to wire it, `memex-refactor` merge if it is redundant |
| 5 | `raw::` pointing at a missing archive (FAIL) | hand fix — re-ingest or drop the `raw::` |
| 6 | inbox-only source | `memex-connect` |
| 6 | bloated atom | `memex-refactor` split — **recommend only** |
| 6 | broad topic map | `memex-topic-emerge`, then `memex-review` |
| 7 | orphan `part-of::`, stale `related::` | `memex-reconcile` |
| 7 | atom's newest source >18 months old | `memex-stale` |
| 7 | unknown relation field | hand fix — it is a typo or a schema question |
| 8 | over/under-confident, unvalidated, `high` with live contradictions | `memex-trust-audit` |
| 8 | under-extracted source | `memex-deep-extract` — **name it, never run it** |
| 9 | bare conflict link | `memex-conflicts` |
| 10 | unknown tag | fix the tag, or `memex-init` to extend the vocabulary |
| 11 | `type:`/`stage:`/`status:` violations (FAIL) | hand fix — schema conformance |
| 12 | claim quote absent from the archive (FAIL) | `memex-deep-extract` re-run on that source — **the user's call** |
| 13 | provenance shape, non-`human:` sign-off, stale sign-off | `memex-trust-audit` step 7 |

Skip a skill entirely when its sections are clean. "Nothing to do" is the most
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
4. **`memex-reconcile`** — repairs dangling `part-of::` and promotes aged
   `related::`. Structural repair before semantic audit.
5. **`memex-trust-audit`** — needs 3 and 4 finished to be auditing the real graph.
   Includes the sign-off pass, which asks the human separately.
6. **`memex-conflicts`** — documents bare conflict links. After trust-audit, whose
   `high`-with-contradictions finding often creates the ones worth documenting.
7. **`memex-stale`** — read-only decay report. Last because it is advisory and its
   output is a reading list, not a repair.
8. **`memex-review` / `memex-topic-emerge`** — topic-level, optional, and only when
   section 6 flagged a broad map or the user asked.

Present this as a numbered plan with the finding counts that justify each step, and
the steps with no findings marked *skipped*. Then ask to proceed.

### 4. Execute, one at a time

Invoke the first skill in the plan. Let it run under its own rules — do not
pre-empt its confirmations or answer its questions on the user's behalf.

After any skill that **wrote** to the vault, re-run lint and diff the finding counts:

```bash
bash "$VAULT/_meta/lint.sh" > /tmp/tend-lint-2.out 2>&1; echo "exit=$?"
diff <(grep -cE "WARN|FAIL" /tmp/tend-lint.out) <(grep -cE "WARN|FAIL" /tmp/tend-lint-2.out)
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

- Don't run `memex-deep-extract`, `memex-compose`, `memex-refactor`, or `memex-init`.
  The first three are the user's call; the fourth already happened.
- Don't propose a skill whose lint sections are clean, to look thorough. An
  eight-step plan on a healthy vault teaches the user to ignore this skill.
- Don't run the plan without confirming it first. The whole point is deciding
  *whether* to spend the tokens.
- Don't re-run lint after a read-only skill — `memex-stale` and `memex-search`
  change nothing, and the second pass costs as much as the first.
- Don't route a FAIL to a skill that only reads. FAILs in sections 1, 5, and 11 are
  hand fixes; naming a skill that cannot fix them wastes a step and hides the work.
- Don't treat an empty `_meta/log.md` as neglect. A vault with nothing to tend has
  nothing in the log, and that is the same reading.
- Don't summarize a skill's output in place of running it. Handing off means
  handing off; a paraphrase of what `memex-conflicts` would probably say is not a
  conflict pass.
