# backslash-quote

**Findings print their message verbatim.** Lint's `warn`/`error` helpers used
`echo -e`, which interprets backslash escapes in the whole string — including the
quote excerpt a section 12 FAIL prints. A quote containing `\t` or `\n` came out
with a real tab or line break in the middle of its own finding, and a line break
split one finding across two output lines, which `test-lint.sh` and `memex-tend`
then read as two lines, one of them unlabelled.

Pinned here:

- `^c01` — a quote containing `C:\new\table`, present in the archive → grounded,
  silent. `grep -F` has no escapes; this proves the quote reaches it intact.
- `^c02` — a quote containing `\t` and `\n`, absent → one FAIL line, with both
  backslash sequences printed as two literal characters each.
