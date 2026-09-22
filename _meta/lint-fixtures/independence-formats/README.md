# independence-formats

**Every way a person list can be written must key the same people.** Section 8
reads independent units to decide whether `confidence: high` is earned, and a
missed author overlap can only ever *overstate* independence — the direction that
inflates `high`. Four shapes were missed before rc.3:

- **`attendees:` on meeting notes** (T2-23). `reading-one` (flow list) and
  `reading-two` (block list) share Charles Babbage, so two sessions of one reading
  group are **one** unit. rc.2 read no `attendees:` at all: both were unchecked
  and counted separately.
- **Quoted "Last, First" in a flow list.** `last-first` holds
  `"Turing, Alan M."` and `"Church, Alonzo"`; rc.2 split on every comma and keyed
  `alonzo` and `a.m` instead of `a.church` and `a.turing`.
- **A flow list wrapped across lines.** `wrapped` opens `[Alonzo Church,` and
  closes on the next line; rc.2 read only the first line and lost Kleene.
- **"Last, First" in a block list and as a scalar.** `block-last-first` has
  `- "Kleene, S. C."`; `scalar-last-first` has `authors: Hopper, Grace`, which
  must match `scalar-plain`'s `Grace Hopper`.

Expected: **3 units of 7 sources**, none unchecked — the reading group; Turing,
Church, Kleene and Post (chained through Church and Kleene); and Hopper.
