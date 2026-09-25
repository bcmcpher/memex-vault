---
name: memex-candidates
description: Review and apply pending candidate files from incomplete skill sessions. Use when a previous save, ingest, connect, meeting, seed, glossary, topic-emerge, or deep-extract session ended before all proposed writes were confirmed, and you want to recover those proposals. Triggers on: "show pending candidates", "what's waiting in candidates", "review pending writes", "apply candidates", "what did I not finish", "recover my session". Also useful as a pre-compose audit: "any unresolved candidates before I compose this topic?"
---

# Memex Candidates

**Vault root:** `$VAULT`, resolved at run time as
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"` — never hard-coded, so a
fork of this vault works unedited. **Confirm it resolved to a vault before writing
anything:** `[ -f "$VAULT/_meta/schema.md" ]`. If that fails, stop and tell the
user — a stale `MEMEX_VAULT`, or this skill invoked from an unrelated repository,
otherwise writes `sources/`, `atoms/` and `_meta/log.md` into *that* repository,
and the first sign is `git status` (roadmap R14).
**Candidates dir:** `_meta/candidates/`

This skill resurfaces proposed vault writes from sessions that ended before the user confirmed them. Candidates are written by `memex-save`, `memex-ingest`, `memex-connect`, `memex-meeting`, `memex-seed`, `memex-glossary`, `memex-topic-emerge`, and `memex-deep-extract` (both modes) before each file write. Approved candidates are applied and deleted; rejected ones are discarded.

---

## When to Use This Skill

- After a session dropped mid-ingest and you want to recover the proposed atoms or source notes
- Before composing a topic, to ensure all pending writes are resolved
- Periodic housekeeping: "anything sitting in candidates?"

---

## Workflow

### 1. Scan for pending candidates

```bash
VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"
ls -t "$VAULT/_meta/candidates/" 2>/dev/null | grep -v "^\.gitkeep$"
```

A missing directory prints nothing, the same as an empty one — `memex-tend` runs
this line the same way. Report it as empty, and suggest `mkdir -p
"$VAULT/_meta/candidates"` so the next gated write has somewhere to go.

If empty, report: "No pending candidates. All proposed writes have been resolved." Stop.

### 2. Group by session

Parse the `session:` field from each candidate's frontmatter. Group candidates with the same session ID together — they came from one skill invocation.

Present a summary:

```
Pending candidates: 4 files across 2 sessions

  Session 2026-05-01-1430 (memex-ingest) — 3 candidates
    CREATE atoms/flash-attention.md
    CREATE glossary/kv-cache.md
    MODIFY atoms/attention-mechanism.md → append to ## Sources

  Session 2026-04-30-0940 (memex-connect) — 1 candidate
    MODIFY atoms/transformer-architecture.md → append to ## Sources
```

Name the change for each modify: `append to <section>`, `replace <line>`, or `rewrite`.

### 3. Review each session

Process one session at a time. For each candidate in a session:

**Show the candidate:**
```
── Candidate: CREATE atoms/flash-attention.md ──────────────────
[display the proposed file content or change description]
────────────────────────────────────────────────────────────────
```

**Ask:** `Approve / Reject / Defer / Show full content`
- **Approve** — apply the change (see Step 4), assert it landed, then delete the candidate file
- **Reject** — delete the candidate file without writing
- **Defer** — leave the candidate in place, move to the next one
- **Show full content** — display the full body if it was truncated

After all candidates in a session are resolved (or deferred), offer: "Apply all remaining deferred candidates in this session? (Yes / No)"

### 4. Apply approved candidates

**Read the file correctly first — it can hold two frontmatter blocks.** A candidate's
own fields are its first `---` block. A create candidate's body is a whole note, and
a note starts with its own `---` frontmatter, so that file holds two blocks one after
the other. Split on the **first two** `---` lines only: the candidate's fields sit
between them, and everything after the second — leading blank lines trimmed — is the
body, written verbatim. Splitting on every fence, or taking the last pair, returns
the note without its frontmatter. Before writing a create or a rewrite, check the body's
first line is `---`; an append or replace body has no frontmatter.

**Create action** — write the candidate body to `target`:
```bash
# Check target doesn't already exist
ls "$VAULT/<target>" 2>/dev/null && echo "EXISTS — resolve conflict before writing"

# Write if clear
cat > "$VAULT/<target>" << 'EOF'
[candidate body]
EOF
```

If the target already exists, show a diff and ask whether to overwrite, merge, or skip.

**Modify action** — append body to the named section in `target`:
```bash
# Find the section header in the target file
grep -n "^<section>" "$VAULT/<target>"
```

Append the candidate body content immediately after the section header's last line. If the section doesn't exist in the target, ask before appending at end of file.

**Modify action with `change: replace`** — find the line in `target` that equals the
candidate's `replaces:` value exactly, and substitute the body for it. If no line
matches, stop and show the file's current line instead: the target changed after
the candidate was written, and replacing a guessed line is how a link silently
disappears.

**Modify action with `change: rewrite`** — the body is the whole new file, frontmatter
included, split as above. It replaces the target only if the target is still the file
the candidate was written against:
```bash
now=$( ( sha256sum "$VAULT/<target>" 2>/dev/null || shasum -a 256 "$VAULT/<target>" ) | cut -d' ' -f1)
[ "$now" = "<was-sha256: value>" ] || echo "CHANGED since proposed — show the diff, do not write"
```
On a mismatch, stop and show `diff` between the target and the body. A rewrite
carries every line of the file, so applying it over a later edit reverts that edit
without a trace; the hash is the rewrite's equivalent of a replace's exact line.
`memex-refactor` uses it for a retirement stub and a revised body.

**Assert before deleting.** Re-read the target after every write, before touching
the candidate (`_meta/schema.md` § Candidate Lifecycle, write protocol step 4):

- **create** — the file exists and equals the candidate body;
- **append** — every body line is present under the named section;
- **replace** — the body line is present and the `replaces:` line is gone.
- **rewrite** — the file equals the body.

```bash
grep -nF -- '<one body line>' "$VAULT/<target>"   # must print
grep -nF -- '<replaces: value>' "$VAULT/<target>" # replace only: must print nothing
```

On a miss, stop: keep the candidate, report the target as **Failed** in the
summary, and move on. An edit tool can report success on a write that did not
happen — in trial 1 two anchored inserts into one file matched nothing and
reported success (finding 13). Deleting the candidate on that report destroys
the only copy of the change.

### 5. Session summary

After processing all sessions:

```
Candidates resolved:
  Applied:   3  (atoms/flash-attention.md, glossary/kv-cache.md, atoms/attention-mechanism.md)
  Rejected:  1  (atoms/transformer-architecture.md)
  Deferred:  0
  Failed:    0  (write did not assert; candidate kept)

_meta/candidates/ is now clean.
```

If any candidates were deferred or failed, list them explicitly and remind the user to run `memex-candidates` again to resolve them.

---

## What This Skill Does NOT Do

- Does not create new candidates — it only reviews and applies existing ones
- Does not modify `_meta/log.md` — applied candidates are not logged (the original skill would have logged the session if it completed normally)
- Does not validate whether a candidate's content is still consistent with the current vault state — if atoms or sources have changed since the session, review the diff carefully before approving

---

## Common Mistakes to Avoid

- Don't auto-approve all candidates without reading them — a session might have proposed a duplicate atom or a stale connection
- Don't apply a modify candidate without checking whether the target file still has the expected section
- Don't delete candidate files manually — use Approve/Reject so the skill can track what was resolved
- If the target already exists for a create candidate, treat it as a conflict to resolve, not an automatic overwrite
