# topic-tree

The D2 concept-map hierarchy, added in rc.2 Stage 4 to fix M21: on a flat topic
layer, walking down from a map returned every atom in the vault, so the top-down
entry point narrowed nothing — a domain question returned all 22 atoms whichever
map it started from.

The tree's rules are load-bearing for `memex-search`, `memex-compose` and
`memex-topic-emerge`, and all four are enforced only here, in `lint.sh`
section 7:

- `two-parents` names **two** parents (`fixture-root` and `other-leaf`). One
  maximum, or membership is ambiguous. It deliberately does *not* name
  `good-leaf`: the first draft did, which gave `good-leaf` a child and made the
  control below fire 7g — a fixture whose control is contaminated by the case it
  is controlling for tests nothing, and reading the generated expectation is what
  caught it.
- `cycle-a` and `cycle-b` name each other. Walking parents must terminate.
- `names-interior` is an atom pointing at a map that **has a child**. An atom
  names a leaf; a root's breadth is its children's, and an atom attached to an
  interior node is counted twice on any walk.
- `orphan-parent` names a parent that does not exist (7a) — the case that
  detaches a whole sub-tree from its root.

`good-leaf` and its root are the control: a well-formed two-level tree with an
atom on the leaf must stay silent on the tree checks.
