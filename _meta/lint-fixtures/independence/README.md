# independence

**M15 — the useful unit of vault size is the independent author group, not the
source count.** In trial 1, 16 documents yielded **5** independent units and
nothing warned, which pinned the vault at 8% high-eligible atoms. Section 8 reads
this number to decide whether `confidence: high` is earned, so a regression here
silently inflates every confidence verdict in the vault.

Two properties are easy to break and both are pinned:

- **Dependence is transitive, and a unit is a connected component.** `hagmann`
  and `cammoun` share `l.cammoun`; `cammoun` and `sporns` share `o.sporns`;
  `hagmann` and `sporns` share **nothing**. So no pairwise test finds the A–B–C
  chain, and the three must collapse to **one** unit rather than two. The expected
  total is 4 units of 6 sources: this component, the two `Do` papers separately,
  and `no-authors`.
- **A person key is first initial + surname.** `Klaas E. Stephan` matches
  `K. Stephan`, but `Cao T. Do` must **not** match `Kim Q. Do` — surname alone
  chained two unrelated author groups into one through exactly that pair.
  `do-one` and `do-two` are that case, and must stay **two** units.

`no-authors` carries no `authors:`/`channel:`/`tool:`, so it is its own unit *and*
reported **unchecked** — the hedge that keeps the number from reading as a
verdict. Losing the hedge is as bad as losing the count.
