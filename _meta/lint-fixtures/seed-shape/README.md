# seed-shape

Exactly what `memex-seed` step 5 writes, and nothing else: two paper source
notes at `stage: unread` with empty `## Connections`, their normalized archives
with `archive-sha256:`, and a concept-map root with two leaves copied from
`_templates/topic-concept.md`.

`memex-seed` step 6 tells the operator what lint will say after the seed —
"exit 0 with N section-6a inbox-only warnings". That sentence is a prediction,
and a new lint check that fires on a freshly seeded vault silently makes it
false (rc-3-plan § Risks). This fixture is the prediction under test: when its
expectation changes, update step 6 in the same commit.

The leaves have no member atoms, but the vault has none either, so section 6d's
empty-leaf warning stays gated off (it needs ten atoms vault-wide).
