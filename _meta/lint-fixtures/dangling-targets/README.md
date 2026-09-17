# dangling-targets

Section 7h, adopted in rc.2 from the claude-obsidian comparison (verdict 1), and
section 12e which predates it.

Before 7h, a `[[target]]` was resolved in exactly two places: `part-of::`, and a
`cites::` whose anchor was *block*-form. So `cites:: [[ghost]]` and
`cites:: [[ghost#Summary]]` both linted clean at exit 0 — and worse, writing one
into an otherwise-isolated atom **silenced** the section 4 orphan warning, because
section 6b counts `cites::[[` occurrences without resolving them. A fabricated
citation read as evidence *and* suppressed the check that would have caught the
atom.

What this fixture pins:

- a bare dangling `cites::` warns (7h)
- a section-anchored dangling `cites::` warns, reported without the anchor (7h)
- a block-anchored dangling `cites::` warns **once**, from 12e, not twice
- a dangling `related::` warns — it is not only `cites::` that is checked
- a dangling `supports::` on a *source* warns — it is not only `atoms/`
- a resolving link stays silent
- an existing note with a **missing block anchor** warns from 12e, distinctly
