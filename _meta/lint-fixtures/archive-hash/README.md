# archive-hash

Section 5's `archive-sha256:` checks, new in rc.3 (roadmap R2, labelling half;
`_meta/schema.md` § Source Archive Hash). `.archive/` is gitignored, so the hash
is how a restored archive is known to be the bytes its quotes were checked
against.

- `good` — `raw::` and the archive's real SHA-256 → silent
- `no-hash` — `raw::`, no hash → WARN
- `malformed` — hash `ABC123` → WARN
- `mismatched` — a well-formed hash of other bytes → WARN
- `hash-no-raw` — a hash with no `raw::` → WARN

Every note is `stage: unread` with a `related::` so that 6a stays quiet.
