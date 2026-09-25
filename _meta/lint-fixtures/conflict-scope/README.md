# conflict-scope

Section 9a, widened in rc.3 (T2-17). Until then it matched `contradicts::` and
`refutes::` in `atoms/` only. Trial 2's one real source-level dispute — two papers
reaching opposite verdicts on one concept, written as a `challenges::` on a source —
and its first `limits::` link were both invisible to it, and a bare `challenges::`
with no prose would have reported `OK`.

Pinned here:

- `bare-challenges` — atom `challenges::`, no prose → WARN (new field)
- `bare-limits` — atom `limits::`, no prose → WARN (new field)
- `2026-09-17-bare-refutes` — source `refutes::`, no prose → WARN (new root)
- `explained-challenges` — atom `challenges::` with a tension sentence → silent
- `2026-09-17-explained-source` — source `challenges::` with prose → silent
- `bare-contrasts` — bare `contrasts-with::` → silent: a distinction, not a
  disagreement, so it is exempt by design. `supersedes::` is the other exempt
  field; it is left out here because retirement (6e) changes what lint says
  about its target.

Atoms are `confidence: low` to keep section 8's confidence warnings out of the
expectation. The one §8 line left per atom — no cited source read claim by claim —
needs an extract and archive to silence, and is not what this fixture tests.
