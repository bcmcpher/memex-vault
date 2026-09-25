# sign-off

Section 13d, new in rc.3 (T2-13). Section 13 audited `verified:` blocks that
exist and said nothing when none did, so a vault with zero sign-offs linted
like a clean one and `memex-tend` could never route to the sign-off pass.

- `high-unsigned` — `confidence: high`, no `verified:` → WARN
- `high-signed` — `high`, signed off after its last `updated:` → silent in 13
- `medium-unsigned` — never signed off, but not `high` → silent

The section also prints `INFO  1 of 3 live atom(s) signed off`, which the
harness does not record. Sections 8a and 12f speak on both `high` atoms, since
neither rests on real sources; that is not under test.
