# memex-vault Skill Evaluation

**This ships empty, and that is correct.** A template has no usage to evaluate.
This file is the place a fork records how the `memex-*` skills behave on its own
notes, so that template changes are driven by observed friction rather than
recollection.

Infrastructure doc — not a vault node. No frontmatter, and nothing should link to
it with a wikilink. Companion to `_meta/roadmap.md`, which holds work that is still
open, and `_meta/roadmap-applied.md`, which holds what shipped. This file holds the
*evidence* that work is needed; the roadmap holds the work.

**Why the template's copy is empty rather than seeded with examples.** Trial
evidence belongs to the vault that produced it. The trial-1 campaign that sourced
roadmap M11–M22 ran in a brain-connectivity fork, on 16 sources by named authors in
one field, and every one of its fifteen findings is stated in terms of that
content. Shipping it here would hand a new fork a filled-in log of somebody else's
vault — findings it cannot reproduce, severities calibrated against a corpus it
does not have, and a § Session Log whose first row is a session it never ran. The
findings that generalized are already in the roadmap, where they carry the
measurement they rest on. What stays behind is the raw observation, and that is the
part a fork has to generate for itself.

---

## How to use this file

After a working session, append a row to § Session Log, then add any findings
below.

**A finding needs three things.** What was observed — the actual command, count, or
output, not a summary. The root cause, traced to a file and a line where one
exists. And a proposal, which may be "no change, record only".

**A finding without an observed trigger does not belong here.** It belongs in
`_meta/roadmap.md` as an idea. The distinction is the whole point of keeping two
files: the roadmap can hold a good idea indefinitely, and this file cannot hold
anything that did not happen.

**Check the roadmap before logging.** A finding is new only if it is not already a
row in `_meta/roadmap.md` § Open Work, or a remainder of a `Partially applied` one.
That list exists so a trial can tell a new problem from a known one, which is what
§ Release Status's promotion criterion turns on.

**Record deviations too.** A step taken differently from what a skill said is
evidence about the skill, not an error to hide. § Deviations taken is for those,
and in trial 1 it was where two real findings came from.

**Note the vault's state when it biases a finding.** A check that needs content
cannot fire on an empty vault, and a threshold calibrated on 16 sources may be an
artifact of 16 sources rather than a defect. Trial 1 marked these `[empty-vault]`
and later found that only two of five suspect thresholds were genuinely size
artifacts — so the caveat is worth writing and worth re-testing, not worth
assuming.

---

## Session Log

| Date | Skills exercised | Volume | Outcome |
|---|---|---|---|
| | | | |

---

## Findings

*None yet.*

---

## Observations that are working as designed

*None yet.* This section is for behaviour that looked like a defect and was not —
worth recording so it is not re-investigated.

---

## Deviations taken, for review

*None yet.* A step taken differently from the skill's instruction, with why.
