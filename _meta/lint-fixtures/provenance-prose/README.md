# provenance-prose

**The M20 regression.** `lint.sh`'s provenance parser read note *prose* as
provenance and shipped that way in `v1.0.0-rc.1`, because the field it parses had
never been written by anything — `verified:` gained its first writer in Phase 4,
after the tag. The fix (rc.2 Stage 1) bounds each parser with
`f&&(/^[a-z]/||/^---[[:space:]]*$/){exit}` so a block ends at the next
frontmatter key or at the closing `---`.

This is the fixture that would have caught it. **Every note here has a body whose
lines begin with lowercase words and colons** — `by:`, `at:`, `note:`, `reason:` —
which is the shape the old parser mistook for continued provenance.

`well-formed` is the one that matters: a correct `generated:` mapping, a correct
`verified:` **list**, and that body. It must be silent on provenance. If it ever
warns, the parser has stopped terminating at the closing `---` again.

Three malformed blocks pin that the check still *works* after being bounded,
because a parser bounded into uselessness is the opposite failure and just as
quiet:

- `missing-at` — `generated:` with `by:` and no `at:`
- `bad-actor` — correct list shape, actor `somebody`, which is none of the three
  legal forms (`<producer>/<version>`, `human:<id>`, `process:<id>`)
- `verified-as-mapping` — `verified:` written as a mapping. Per
  `_meta/schema.md` § `verified:` it is a **list**, appended to on each sign-off,
  and the mapping form is the mistake a writer actually makes. This case was
  found by writing it into a fixture by accident.
