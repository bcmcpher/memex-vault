# source-url

Sections 2b and 2c, adopted in rc.2 (comparison verdicts 2 and 3).

`url:` is the only field identifying a source independently of who wrote it, and
nothing read it before rc.2.

**2b — two sources at one URL.** A duplicate adds no evidence, and when neither
note carries `authors:`/`channel:`/`tool:` it adds a phantom unit to the
independent-source count that section 8 reads. The two `dup-*` notes differ in
case, trailing slash and `#fragment`, which is exactly the normalization 2b is
supposed to see through — and no further, since percent-encoding can name a
different resource.

**2c — a credential in a saved URL.** `sources/` is tracked by git, so a signed
link or share token pasted once is committed and rewriting history is the only
removal. Both forms are pinned: userinfo before the host, and a sensitive query
key. `x-amz-signature` is here because the vendor-prefixed forms are the ones a
hand-written key list misses.

**The controls matter as much as the positives.** A DOI, an arXiv id, `?v=` and
`?sortkey=` must stay silent, or the check is noise at capture time — which is
worse than the gap it closes.
