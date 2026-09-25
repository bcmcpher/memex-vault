# under-extracted

Section 8d, rebuilt in rc.3 (T2-28, and trial 1's Not-in-RC-2 row). It counted
the source *note's* lines against 100; a note is a template-shaped summary of
34-65 lines, so the check never fired. It now measures the `raw::` archive
(>= 15,000 bytes) and covers `stage: read` as well as `processed`.

- `long-read` — read, ~16.7 KB, no extract, no atoms → WARN (was silent: wrong stage)
- `long-processed` — processed, ~16.7 KB, no extract, no atoms → WARN (was silent:
  the note is ~33 lines)
- `long-extracted` — processed, ~16.7 KB, has an extract → silent: it was read
  claim by claim, and promotion is mode B's job
- `long-wired` — processed, ~16.7 KB, introduces two atoms → silent
- `long-unread` — unread → silent in 8d (6a speaks)
- `short-read` — read, 3 KB → silent
- `no-raw` — read, no `raw::` → silent: nothing archived, nothing to measure
