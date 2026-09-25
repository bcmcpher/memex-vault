# inbox-only

Section 6a. A source is inbox-only when it is unread and none of its own relation
fields names a target. Until rc.3 the check counted five of the nine source fields,
so an unread source wired only by `challenges::`, `refutes::`, `rebuts::` or
`defines::` was sent to `memex-connect`, whose discovery counts all nine and
skipped it — the T2-9 contradiction, from the other side.

- `unwired-paper` — nothing wired → WARN
- `challenging-paper` — only `challenges:: [[disputed-atom]]` → silent
- `defining-paper` — only `defines:: [[a-term]]` → silent
