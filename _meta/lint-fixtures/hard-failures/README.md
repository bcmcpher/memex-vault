# hard-failures

The two checks that **FAIL** rather than warn, so this fixture is also the one
that pins `exit 1`. Phase 0 made `FAIL` a real gate; before it, `warn()` and
`error()` incremented the same counter and the script had no `exit 1` at all
(`L1`). A change that quietly demoted either of these to a warning would be
invisible without this.

- **Section 1, naming.** A source filename without a full `YYYY-MM-DD-` prefix.
  The prefix is what gives `ls sources/paper/` chronological order and what every
  slug-to-path lookup assumes.
- **Section 5, dangling `raw::`.** An archive pointer naming a file that is not
  there. This is load-bearing for section 12: a quote is verified against the
  archive, so a `raw::` that resolves to nothing means grounding cannot be
  checked — and *unverifiable* must never read as *verified*.

`has-archive.md` is the control. Its `raw::` resolves, so it must stay silent —
`.archive/` is gitignored, which is why fixture archives live in `archive/` and
the harness copies them into place.
