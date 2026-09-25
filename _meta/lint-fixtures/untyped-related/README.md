# untyped-related

Section 7j, new in rc.3 (T2-12). Nothing in lint reported an untyped `related::`,
so `memex-tend` could never route to `memex-reconcile`'s promotion pass.

- `only-related` — two `related::` links to atoms, nothing typed → WARN, count 2
- `typed-too` — a `related::` alongside a `uses::` → silent
- `plain` — no links → silent here (other sections may speak)
- `points-away` — `related::` to a topic and to a missing note → silent in 7j:
  only atom targets can be promoted, and the dangling one is 7h's
