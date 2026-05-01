---
name: memex-candidates
description: Review and apply pending candidate files from incomplete skill sessions. Use when a previous ingest, connect, meeting, or glossary session ended before all proposed writes were confirmed, and you want to recover those proposals. Triggers on: "show pending candidates", "what's waiting in candidates", "review pending writes", "apply candidates", "what did I not finish", "recover my session". Also useful as a pre-compose audit: "any unresolved candidates before I compose this topic?"
---

# Memex Candidates

**Vault root:** `/home/bcmcpher/Projects/claude/memex-vault`
**Candidates dir:** `_meta/candidates/`

This skill resurfaces proposed vault writes from sessions that ended before the user confirmed them. Candidates are written by `memex-ingest`, `memex-connect`, `memex-meeting`, and `memex-glossary` before each file write. Approved candidates are applied and deleted; rejected ones are discarded.

---

## When to Use This Skill

- After a session dropped mid-ingest and you want to recover the proposed atoms or source notes
- Before composing a topic, to ensure all pending writes are resolved
- Periodic housekeeping: "anything sitting in candidates?"

---

## Workflow

### 1. Scan for pending candidates

```bash
VAULT=/home/bcmcpher/Projects/claude/memex-vault
ls -t "$VAULT/_meta/candidates/" | grep -v "^\.gitkeep$"
```

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

### 3. Review each session

Process one session at a time. For each candidate in a session:

**Show the candidate:**
```
── Candidate: CREATE atoms/flash-attention.md ──────────────────
[display the proposed file content or change description]
────────────────────────────────────────────────────────────────
```

**Ask:** `Approve / Reject / Defer / Show full content`
- **Approve** — apply the change (see Step 4), delete the candidate file
- **Reject** — delete the candidate file without writing
- **Defer** — leave the candidate in place, move to the next one
- **Show full content** — display the full body if it was truncated

After all candidates in a session are resolved (or deferred), offer: "Apply all remaining deferred candidates in this session? (Yes / No)"

### 4. Apply approved candidates

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

### 5. Session summary

After processing all sessions:

```
Candidates resolved:
  Applied:   3  (atoms/flash-attention.md, glossary/kv-cache.md, atoms/attention-mechanism.md)
  Rejected:  1  (atoms/transformer-architecture.md)
  Deferred:  0

_meta/candidates/ is now clean.
```

If any candidates were deferred, list them explicitly and remind the user to run `memex-candidates` again to resolve them.

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
