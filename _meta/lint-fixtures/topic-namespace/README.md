# topic-namespace

The naming section's namespace guard, extended to `topics/` in rc.3 (T2-37).
It FAILed an atom and a glossary entry sharing a filename, but never looked at
topics — and `memex-topic-emerge` names clusters after tags, which are usually
an atom's filename too.

- `topics/concepts/tractography.md` vs `atoms/tractography.md` → FAIL
- `topics/concepts/reeb-graph.md` vs `glossary/reeb-graph.md` → FAIL
- `topics/concepts/clean-map.md` vs `topics/projects/clean-map.md` → one FAIL,
  on the second in sorted order
