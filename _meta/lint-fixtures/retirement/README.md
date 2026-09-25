# retirement

`_meta/schema.md` § Retirement, landed in rc.3 (T2-33, T2-25).
`B supersedes:: [[A]]` retires A. rc.2's `memex-refactor` wrote the field on the
stub, naming its successors, which retired the live atoms and left the tombstone
live — and every counting check graded the tombstone as a concept.

Pinned here:

- `successor-a` → `old-a` — the correct shape. `old-a` is `confidence: high`,
  cites nothing and has no relations, yet 4 (orphan), 6b (isolated), 8a and 12f
  are all silent: retired atoms are not counted.
- `stub-b` → `child-b1`, `child-b2` — rc.2's inverted shape. 7i warns twice
  that the named atoms are newer, and warns on each child for still carrying
  `part-of::` (and `cites::` on `child-b1`) while retired.
- `mutual-one` ↔ `mutual-two` — each supersedes the other → one 7i WARN each.
- `composite` — `part-of:: [[successor-a]]`, an existing atom → 7a says
  `part-of::` is topic-only instead of "no matching topic file found".
