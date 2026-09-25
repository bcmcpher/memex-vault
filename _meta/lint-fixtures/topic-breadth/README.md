# topic-breadth

Section 6d, made relative in rc.3 (T2-19) and given a lower bound (T2-32).

Until rc.3 it warned at more than 15 members, an absolute count: a leaf holding
15 of 18 atoms was silent, and a split's retirement stub, which keeps its
`part-of::`, raised the count on retirement alone. No check reported a leaf that
was created and never filled.

The vault: 11 atoms, one retired (`old-concept`, named by `s2`'s `supersedes::`),
so 10 live. The live atoms form a `uses::` ring so section 4 stays quiet.

- `broad-leaf` — 8 of 10 live atoms → WARN. Under rc.2, silent (8 ≤ 15).
- `small-leaf` — 2 live atoms → silent.
- `empty-leaf` — no members → WARN (new).
- `tomb-leaf` — its only member is the retired stub → WARN as empty. This is
  the line that proves retired atoms are not counted.
  The stub keeping its `part-of::` is itself the rc.2 shape, so section 7i
  also warns on `old-concept` (added with 7i in 6e).
- `fixture-root` — has children, so it is not a leaf and is never measured.
