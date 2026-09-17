# memex-vault Improvement Roadmap

Revised: 2026-09-17 for `v1.0.0-rc.2`. **This is the first revision to live in the
template.** It carries the 2026-09-11 revision across from the brain-connectivity
fork — M6–M22, § The RC-2 seed corpus, and the discharged verification-debt rows —
and adds a status marker to every finding, so the list can answer "what is still
open?" without reading four other sections. Before this revision the template's
copy stopped at M5 while skills in it already cited M8, M11, M13, M14 and M21.

Superseded 2026-09-11 (fork), which superseded 2026-09-02, which added § Release
Status for `v1.0.0-rc.1`; the tier 0–2 findings and phase detail are from the
2026-08-25 revision, which superseded 2026-07-09, which superseded 2026-05-07.

M11–M22 differ in kind from everything above them: they are the first findings
sourced from running the skills over real notes rather than from reading them.
Every one names the measurement it rests on.

**Reading the status markers.** Every finding carries one, in italics, directly
after its label:

| Marker | Means |
|---|---|
| *Applied* | The change shipped. Where it shipped is named |
| *Closed* | The finding was resolved without the change it proposed — the evidence refuted the proposal |
| *Partially applied* | Some of the finding shipped; what did not is stated |
| *Open* | Real, unblocked, not done |
| *Deferred* | Real, and deliberately not scheduled. The reason is stated |
| *Accepted* | Decided against fixing. The principle or trade-off is named |

A marker is not a verdict on the finding's quality. `Closed` and `Accepted` both
mean the row stays as a record so a later trial does not re-derive it.

Infrastructure doc — not a vault node. No frontmatter, and nothing should link to
it with a wikilink.

Companions: `_meta/deep-extract-design.md` holds the full design for Phase 3, and
for Phase 5 (deferred). `_meta/okf-alignment.md` holds the full design for
Phases 8–9, plus the frontmatter changes they need from Phase 2.
`_meta/forge-design.md` holds the design for a post-1.0 WikiSkill fork — design
only, nothing in it is built. `_meta/comparison-claude-obsidian.md` holds the RC-2
comparison against `claude-obsidian`, with a verdict on every difference; the seven
Roadmap verdicts in it appear below as F-numbered rows.

`_meta/rc-2-plan.md` held the execution order that produced `v1.0.0-rc.2`. It is a
working document, deleted once the tag lands — this file and `CHANGELOG.md` are the
durable record. `_meta/skill-evaluation.md` ships as an empty scaffold: trial
evidence belongs to the vault that produced it, so the trial-1 campaign that
sourced M11–M22 stays in the brain-connectivity fork. Where a finding below cites
it, the citation is to that fork's copy and is kept because it names what the
finding rests on.

`CHANGELOG.md` records what shipped in each release; this file records what has
not shipped yet. When the two disagree about a phase's status, the changelog is
the one tied to a tag.

---

## Release Status

**`v1.0.0-rc.1`, tagged 2026-09-02.** The first tagged release, cut at Phase 7.

A release *candidate* rather than a final for one reason: the verification debt
below. Four things are built and pass against fixtures but have never run over
real notes, and that cannot change inside this repository — it is a template and
ships with zero notes deliberately. The debt is discharged in the first fork that
puts real content through the skills, which is exactly what an RC is for.

**`v1.0.0-rc.2`, tagged 2026-09-17.** Cut after the RC-2 stages applied every
trial-1 finding that was going to be applied, added one skill (`memex-seed`), and
dispositioned every known open question — including the fifteen differences against
`claude-obsidian` in `_meta/comparison-claude-obsidian.md`.

What `rc.2` contains, by stage: the trial-1 back-port (M17, M18, M20); five
recalibrated thresholds (M11, M12, M13, M14); `lint.sh` correctness and cost (M15,
M16); the topic hierarchy and seed scaffold (M21); eleven per-skill verdict fixes
(M7 closed, M8 bounded); `memex-seed`; and three lint checks adopted from the
comparison. Full detail is in `CHANGELOG.md`.

**`rc.2` is not closer to `v1.0.0` than `rc.1` was in the way a version number
suggests.** It is closer in one specific way: the criterion below is now the right
one, and every input to it is written down. Whether the tag promotes depends
entirely on what trial 2 finds, and the honest expectation is that it finds
something.

**Status 2026-09-11 — the RC did its job, and the answer is "not yet".** The
brain-connectivity fork exercised all four verification-debt rows and then ran
**every one of the 20 skills**, 15 of them for the first time. All four rows are
discharged. **Twelve findings came out of it** — M11-M22 — plus a rewrite of M7
whose original proposal the evidence refuted. By this section's own criterion
those are what now gate the tag, not the rows.

The shape of the twelve is the argument for having cut an RC at all. Five are
miscalibrated thresholds or unreachable triggers in skills never run against
content. **Five more could not have been found by any fixture, because each
needed a human action to exist first:** M17 needed the vault opened in Obsidian,
M19 a second retrieval of an already-extracted paper, M20 a human `verified:`
sign-off, M7 an invocation of a skill nobody had invoked, and M22 someone looking
at the graph. M20 in particular is a parser that read note prose as provenance and
shipped that way in the tagged release, because the field it parses had never been
written. The release process worked; the code was not ready.

Full per-skill verdicts, with what changed and what each finding rests on, are in
`_meta/skill-evaluation.md` § Trial-1 Skill Campaign. Nothing was retired: the one
genuine retirement candidate was cleared by running the skill that had never run.

**What promotes it to `v1.0.0` — restated 2026-09-11, because the old criterion
was too weak.** It used to read "the four verification-debt rows exercised
against a real vault, and any bugs that surfaces fixed". `rc.1` met the first
half in full and the trial still returned twelve findings and a parser bug that
had shipped in the tag. A criterion a release can satisfy while being that wrong
is not measuring the right thing.

The criterion is now: **a full trial against the tag that surfaces nothing new
worth fixing.** Not "the fixes work" — the absence of new findings. Every trial
that produces one produces another RC instead, so `rc.3` and `rc.4` are expected
and are the process working rather than failing. The verification-debt rows are
discharged and demoted; they are no longer the gate.

*Confirmed in place for `rc.2`, 2026-09-17, with one addition.* The criterion needs
a readable open set, or "nothing new" cannot be judged: a finding trial 2 reports
is new only if it is not already a row in this file. That is why RC-2 Decision 4
required every known issue dispositioned before the trial, why the fifteen
`claude-obsidian` differences each carry a verdict, and why this revision adds a
status marker to every finding. **An unreadable roadmap makes this gate as weak as
the criterion it replaced** — the same failure one level up.

**Phase 8 is not a blocker** — it ships as `v1.1.0`. An exporter with nothing to
export and no importer to feed cannot be validated either, so holding the release
for it would trade one kind of unverified code for another.

Root `VERSION` carries the release into a fork, which GitHub's *Use this template*
otherwise strips along with the history and tags. `memex-init` logs it as
`template::`. Neither is edited by a fork.

---

## Summary Verdict

**As of 2026-08-25, seven of the ten phases are complete** — 0, 1, 2, 3, 4, 6, 7.
One remains: **Phase 8**, the OKF export layer. Two are deferred: Phase 5 (Anki,
unscheduled) and Phase 9 (OKF import, scheduled but waiting on a real consumer).
Everything a vault needs to be *used* is built; what is missing is the ability to
hand it to something that is not Obsidian.

The verdict this document opened with in May 2026 was:

> **Bones are excellent** — typed relations, candidate gating,
> schema-as-constitution, 17-skill lifecycle coverage. **Skin is missing** — no
> specialization path, no orchestrator.

Both halves of "skin is missing" are now built: `memex-init` (Phase 6) and
`memex-tend` (Phase 7). The skill count went 17 → 20 in the interval, which is
what made the orchestrator worth building rather than merely worth filing.

Three things were learned in the doing, none of which were on any list:

- **A fork was broken for a reason S3 never named.** Every skill hard-coded the
  template author's absolute vault path. The onboarding skill was the visible half
  of the problem; path portability was the half that mattered.
- **`lint.sh` was blind to any vocabulary a fork added.** It read tags and node
  types from `_meta/domain.md` but hard-coded the five source media, while the
  README claimed otherwise. A fork's new source folder got no checks at all,
  silently.
- **Lint is the vault's only executable state oracle.** `_meta/index.md` answers
  the same questions but only inside Obsidian. That constraint, discovered while
  designing Phase 7, is what determined the orchestrator's whole design.

The 2026-07 revision adds two things:

- **The vault has no evidence layer.** Four findings previously filed separately
  (P2 confidence, M3 temporal claims, M5 drift, and lint 8d's unfixable warning)
  are all downstream of that single absence.
- **`lint.sh` cannot fail.** Its `FAIL` level is cosmetic. Independent of
  everything else here, and discovered while checking the evidence-layer design.

The 2026-08 revision adds one:

- **The vault has no interchange format, and one frontmatter key collides with an
  emerging standard.** Google's Open Knowledge Format v0.2 is architecturally the
  same object this vault is. The gap is small and almost entirely additive, and
  it is cheapest to close inside Phase 2, which already touches every template
  and every writing skill.

---

## Design Decisions (Resolved)

| Decision | Choice |
|----------|--------|
| Example vault | Skip for now — leave empty, documentation is sufficient |
| `covers::` duplication | Make `covers::` Dataview-derived from `part-of::` (breaking change) |
| Onboarding | Build interactive `memex-init` skill |
| Deep-extraction output | A new `extracts/` node type — never atoms |
| Extraction ontology | Reuse `schema.md`'s closed relation vocabulary; no second ontology |
| Anki delivery | Obsidian_to_Anki plain text; a `memex-compose` mode, not a new skill |
| Atom stubs from extraction | Threshold-gated at ≥ 3 claims |
| Claim-comparison inference | Lives in deep-extract (a proposing skill), never in `memex-conflicts` |
| Orphan definition | No `cites::` **and** no inbound link from `sources/`, `atoms/`, `topics/`, or `glossary/` |
| OKF scope | In-vault: additive keys plus one rename, nothing more. Everything Obsidian needs is translated at export, never changed in place |
| `status:` collision | Rename ours to `stage:`. `status:` goes unused in-vault, so OKF's "absent ⇒ stable" default applies — safe rather than wrong |
| Node-type discriminator | One `type:` key at node granularity. `medium:` stays the source subtype; `topic-type:` retired as a redundant second discriminator |
| Exporter language | Python 3, stdlib only. No pip, no venv |
| Export output | `_okf/`, git-tracked, with a mandatory Obsidian exclusion |
| Vault root in skills | Resolved at run time — `${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}` — never hard-coded. A fork works at any path with no search-and-replace |
| Empty folders for unbuilt features | Never scaffolded. `anki/` and `_okf/` are both created by the thing that writes to them; only the `_okf` *exclusion* is written early, because it is ordering-sensitive |
| Orchestrator authority | `memex-tend` routes and reports; it never invokes `memex-deep-extract`, `memex-compose`, `memex-refactor`, or `memex-init`. Triage is its default mode |
| Vault state outside Obsidian | `_meta/lint.sh` is the only executable oracle. `_meta/index.md` answers the same questions in Dataview, which renders only in Obsidian, so no skill may depend on it |

---

## Prioritized Findings

### Tier 0 — Correctness

**L1. `lint.sh` never exits non-zero, and `FAIL` is indistinguishable from `WARN`.** *Applied — `rc.1`, Phase 0.*
`warn()` and `error()` incremented the same `issues` counter, the script had no
`exit 1`, and the summary reported both as "issue(s) found … Review warnings
above." The two genuine-corruption checks — source naming and archive mismatch —
gated nothing. Any hook or CI job shelling out to lint passed silently.

*Status: fixed in Phase 0.*

**L2. `lint.sh` and `_meta/index.md` disagreed on what an orphan atom is.** *Applied — `rc.1`, Phase 0.*
Lint section 4 used "no `cites::` and no `covers::` backlink in `topics/`." The
index query used "no `cites::` and `length(file.inlinks) = 0`." A source's
`introduces:: [[atom]]` creates an inlink, so the index cleared atoms that lint
still flagged.

Worse, and latent: `_meta/log.md` records `atoms:: [[Atom A]], [[Atom B]]` on every
ingest. Those are real wikilinks. On the first real log entry, `file.inlinks`
would become non-zero for every atom ever ingested and the index's orphan query
would return nothing, permanently, with no error.

*Status: fixed in Phase 0. Both now use the single definition in `schema.md`,
which counts inbound links only from curated folders.*

### Tier 1 — Specialization blockers

**S1. Constitution conflated with configuration in `schema.md`.** *Applied — `rc.1`, Phase 2.* Universal rules
(node types, relation types, status lifecycles) sit alongside domain-configurable
content (tag vocabulary). A historian forking this finds ML tags baked into the
constitution.

*Fix:* split into `_meta/schema.md` (constitution) + `_meta/domain.md` (tag vocab,
source subtypes, domain name). Lint reads tags from the domain config.

*Status: fixed in Phase 2.* `_meta/domain.md` holds the domain name, three tag
groups, the `medium:` vocabulary, and the folder→`type:` table; `_meta/lint.sh`
sections 10 and 11 read both from it. `README.md` § Specializing This Template is
the fork guide.

**S2. No worked example.** *Deferred — by the design decision above; no worked example ships, and none is planned.*

**S3. No specialization guide or onboarding skill.** *Applied — `rc.1`, Phase 6 (`memex-init`).* No "how to make this yours"
workflow. *Fix:* `memex-init` interactive skill.

*Status: fixed in Phase 6*, which also found the reason a fork actually broke and
the finding never named: 18 skills hard-coding the template author's absolute vault
path, on 54 lines. The onboarding skill was the visible half of S3; path
portability was the half that made a fork unusable.

### Tier 2 — Structural

**E1. No evidence layer.** *Applied — `rc.1`, Phase 3 (the evidence layer).* Sources are stored at document granularity. Nothing
records what a source said sentence by sentence. Consequences: confidence cannot
be anchored to evidence (P2), conflicts can never be *proposed* — only audited
once a human has already written the link, `lint.sh`'s "under-extracted source"
warning has no remediation path, and `.archive/` has no consumer at all.

*Fix:* an `extracts/` node type plus a `memex-deep-extract` skill. Full design in
`_meta/deep-extract-design.md`.

*Status: fixed in Phase 3.* `extracts/` holds quote-grounded claims addressable by
block reference; `_meta/lint.sh` section 12 `grep -F`s every quote against the
normalized archive, so fabrication is mechanically detectable. `.archive/` finally
has a consumer.

**P1. `covers::` / `part-of::` duplication.** *Applied — `rc.1`, Phase 1.* Same membership data in two places;
`memex-reconcile` exists solely to sync them. Make `covers::` a Dataview-generated
view from `part-of::`.

*Status: fixed in Phase 1.*

**P2. Confidence is unanchored — fix rewritten.** *Applied — `rc.1`, Phase 3; the rubric was cheapest to write while the schema was open.* Previously: "add source-type
weighting to the rubric." That treats the symptom. Source *count* is the wrong
unit no matter how it is weighted — three blog posts agreeing is not `high`. With
E1, confidence derives from **independent claims across independent sources**,
with source-type weighting as a secondary term. **P2 now depends on E1.**

*Status: fixed in Phase 3*, not Phase 4 as scheduled — extracts made the rubric
expressible and the schema was already open. `_meta/schema.md` § Confidence
Values: the unit is independent claims across independent sources, source tiers
are inferred at audit time and never stored, and an atom with no extract is capped
at `medium`.

**P3. `related::` will erode typed-relation value.** *Applied — `rc.1`, Phase 1.* No skill audits or promotes
`related::` links. *Fix:* a promotion pass in `memex-reconcile` surfacing links
older than 30 days for typed-relation assignment.

*Status: fixed in Phase 1*, which absorbed it while rewriting the relation
handling. `skills/memex-reconcile/SKILL.md` runs the promotion pass; Phase 7
routes lint section 7's stale-`related::` findings to it. The status line was
never written at the time — recorded here 2026-08-25 during roadmap revision.

**P4. No orchestration layer — now more urgent.** *Applied — `rc.1`, Phase 7 (`memex-tend`).* 17 peer skills becomes 18.
Deep-extract is the most expensive skill in the vault and must never fire
automatically. Holding Anki to a `memex-compose` mode rather than a 19th skill is
a deliberate concession to this finding. *Fix:* `memex-tend`.

*Status: fixed in Phase 7*, at 20 skills rather than 18 — the count grew through
Phases 6 and 7 while the finding sat open, which is the finding proving itself.

### Tier 3 — Missing concepts

**M1. No atom voice/claim style spec — now a hard prerequisite.** *Applied — `rc.1`, Phase 2.* "Wikipedia-stub
granularity" is a length cue, not a style cue. Deep-extract mode B writes atom
`## Detail` prose at volume; without a style spec it writes it inconsistently, at
scale, into every atom it touches.

*Status: fixed in Phase 2.* `_meta/schema.md` § Atom Writing Style — five rules,
each tied to an existing lint signal so the spec is checkable rather than
aspirational.

**M2. No disambiguation policy — promoted to blocker.** *Applied — `rc.1`, Phase 2.* `attention` (cognitive
science) vs. `attention` (transformers) collide under kebab naming. A paper cut
while a human names atoms by hand. Deep-extract's resolution pass handles dozens
of concept mentions per document and will emit `ambiguous` rows on day one with no
rule to settle them. **Must land before or with E1.**

*Status: fixed in Phase 2.* `_meta/schema.md` § Disambiguation Policy. Homonyms
get suffixed slugs and the bare slug is left permanently unused; polysemous
senses stay one atom with per-sense `##` sections and section-anchored `cites::`.
The test is whether a change to one sense obliges a change to the other.

**M3. No temporal model on claims — now tractable.** *Deferred — became cheap once Phase 3 existed, and blocks nothing.* `supersedes::` handles atom
replacement, not time-bounded claims. Claims finally have a home: Hyper-Extract
carries `t_start` / `t_end` / `t_obs` per fact, and extract claims can carry the
same without imposing decay on atoms, which `memex-stale` deliberately refuses.

**M4. No first-class open questions.** *Deferred — became cheap once Phase 3 existed, and blocks nothing.* `rq-*.md` is heavyweight. Extracts could
type an `open-question` claim, giving atom-level questions a home.

**M5. Source↔atom drift not audited — partially subsumed by E1.** *Applied — `rc.1`, Phase 3.* An extract's
claims make the source `supports::` ↔ atom `cites::` correspondence checkable
rather than merely assertable.

*Status: fixed in Phase 3*, to the extent E1 subsumes it. `memex-trust-audit`
gained an UNGROUNDED finding and an extract-existence check on G13; `memex-stale`
Check 4 surfaces processed sources that were never extracted.

**M6. No version model on sources — preprint vs version of record.** *Deferred — needs trial-2 drift data to calibrate, and M19 shows why: a reconcile step that cannot tell re-rendering from revision is noise. See F1.* A work
commonly exists as several near-identical documents (preprint, accepted
manuscript, version of record) sharing one identity and differing in wording.
`raw::` holds exactly one archive and does not say which. When only the preprint
is reachable — increasingly common, and unavoidable behind a paywall — the
grounding guarantee quietly degrades from "what the paper says" to "what a draft
says", with nothing checkable marking the difference.

Wants a `version:` field (`preprint | accepted | record`), a second archive
pointer, and a `memex-deep-extract-reconcile` skill that re-checks an extract's
existing quotes against a newly reachable version, bucketing each claim as
unchanged / reworded / removed / new, repointing `raw::` at the newer version
while preserving `^cNN` ids. Newest version always wins; the older archive is
retained so the preprint-to-record drift stays inspectable — that drift is
evidence of how much a result firmed up under peer review, which bears on
`confidence:` and is recorded nowhere else.

*Triggered by `_meta/skill-evaluation.md` finding 9 (2026-09-04).* Depends on
finding 5's `fetch-fulltext.sh`, which is the component that would discover a
version of record had appeared.

**M7. The glossary was empty because the wrong skills were looking for the wrong
thing — keep it. (Rewritten 2026-09-11; the original proposal is refuted.)** *Closed — `rc.2` Stage 5. Resolved without the change it proposed: the glossary is a disjoint set, not a lossy view of `atoms/`, and retiring it would have deleted the only place four terms can live. The original proposal is kept below because the evidence that refuted it is the finding.*

*What this entry used to say.* That `glossary/` had never held a file across two
sessions that tried to fill it, that the overlap with `atoms/` was structural
rather than incidental, and that the fix was to retire the node type and generate
`_exports/glossary.md` from every atom's `title`, `aliases:` and `description:`.
Finding 12 supplied the reasoning: a term load-bearing enough to define is
load-bearing enough to clear the 3-claim atom threshold, so the glossary can only
receive terms nobody cared enough to atomise.

*What running the skill showed.* `memex-glossary` had never been invoked. Run once
in the skill campaign over `atoms/pairwise-interaction-statistics.md` and its
extract, it proposed four terms in minutes, all written:

| term | why it is not, and should not be, an atom |
|---|---|
| `rand-index` | an instrument. Used once, to report that a clustering is robust. Will never accumulate claims |
| `spearman-correlation` | the ingredient of the empirical similarity index — definitional, load-bearing, not a claim |
| `dynamic-time-warping` | a named algorithm; held back from atomhood by the 3-claim threshold at 1 claim |
| `convergent-cross-mapping` | the same, and it appears only as the expensive method something cheaper substitutes for |

**None of the four has an atom.** That refutes the original proposal directly:
an export generated from atom frontmatter would have produced **none** of them.
The export assumed the glossary is a lossy view of `atoms/`; it is a **disjoint
set**, and retiring the node type would have deleted the only place these terms
can live.

*The diagnosis was wrong, not just the fix.* `memex-connect` and
`memex-deep-extract` mode B both search for `type: definition` **claims**. A claim
worth extracting attaches to a concept load-bearing enough to be atomised — which
is finding 10's namespace collision, restated. Those two skills were searching the
atom namespace and correctly finding it occupied. `memex-glossary` scans for
something else entirely: **undefined jargon a future reader would have to look
up**. The two populations do not overlap. Two sessions returning zero was evidence
that definition-claims collide with atoms, which is true — and it was read as
evidence that the glossary is redundant, which does not follow.

*Revised proposal.* Keep `glossary/` as an authored node type, one file per term.
Finding 10's collision does not arise for this population, because none of these
terms is an atom candidate; the atom-vs-glossary slug check proposed there is
still worth adding, but as a guard rather than as a reason to retire anything.
The action finding 12's evidence actually supports is to **run `memex-glossary`
deliberately**, which nothing had ever done.

*Also observed.* The vault's first glossary entry, `nystrom-method`, arrived
through `memex-ingest` step 7 — so the opportunistic prompts in the capture skills
work once a term genuinely fits the category. They were not broken either; they
had simply never met a qualifying term, because definition-claims reached them
first.

*One correction to the evidence.* Finding 12 named the `Kozachenko-Leonenko
estimator` as an example of this residual category, "present in this vault's
extracts". It is not — zero occurrences across `extracts/` and `atoms/`. The
category it described is real and is now populated; that particular example was
never checked.

*Status: closed. `memex-glossary` is retained; `_meta/skill-evaluation.md`
finding 12 should be read with this entry.*

**M8. Conceptual extraction from code repositories.** *Deferred — design written, not built. `rc.2` Stage 5 bounded it instead: `memex-stale` Check 4 now lists `medium: code` apart with no route, rather than recommending an operation nothing has designed.* `memex-deep-extract` assumes
prose. Pointing it at a repo would produce claims about control flow and I/O
plumbing, which is not knowledge worth graphing. But the conceptual content of a
research codebase is real; it simply does not live in the call graph:

- the **public API surface** — what operations a library claims to offer *is* its
  conceptual model, stated more precisely than any paper states it;
- **docstrings and module headers**, which state intent and often cite the paper
  being implemented;
- **defaults and parameter names**, which freeze methodological choices;
- **comments explaining why**, as opposed to what.

The strongest argument for the skill is the third. A paper says "we threshold the
matrix"; the code says `threshold=0.25`. **Code is where methodological choices
that papers leave open become concrete**, and nothing else in the vault records
that gap. Grounding transfers unchanged — a docstring greps as verbatim as a
paragraph, so `lint.sh` section 12 needs no modification.

A distinct claim-type vocabulary is the main design work, since
`finding | definition | limitation | contrast | method` does not fit:
`capability` (what it does), `default` (a choice frozen into a parameter),
`constraint` (what it requires or refuses), `implements` (this realizes method X
from paper Y). The `implements` type is the high-value output — it produces
edges from code to the atoms and papers describing the method.

Explicit non-goals, so the skill does not drift into a code-analysis tool:
control flow, call graphs, I/O plumbing, test scaffolding, dependency trees.

Note the interaction with spec-driven repos. CRANE carries 63 openspec specs plus
12 in-flight changes; there the specs are the conceptual layer and the code is
the implementation, so the interesting extraction is drift between the two. This
would also let `topics/research/method-to-crane-mapping.md` retire its own
recorded caveat that spec coverage was "judged from names not full bodies".

*Not yet triggered — the user has pointed at a repo and considered running
extraction on it, but no run has been attempted. Recorded here rather than in
`skill-evaluation.md` for that reason.*

**M9. A concurrency contract, so fan-out is planned rather than discovered.** *Applied — `rc.2` Stage 4, as `_meta/schema.md` § Concurrency. Every skill that can fan out now carries a `## Concurrency` section pointing at it.*
No skill states which of its steps may run simultaneously. The one nearby
sentence — deep-extract's "It never runs automatically or vault-wide" — governs
scope, not simultaneity: it forbids an unattended sweep and says nothing about
four attended runs at once. That gap matters now, because the retrieval backlog
is six papers and fanning out is the obvious response.

The rule that decides it, and that should live in `_meta/schema.md` so future
skills inherit it rather than re-deriving it:

> A step may run in parallel **iff** its writes are keyed to a single source slug
> and its reads do not depend on vault state another concurrent run is writing.

Under that rule deep-extract mode A qualifies — fetch, normalize, `.archive/`,
the extract file, the source's own `raw::` line, and concept resolution, which
reads `atoms/` precisely because mode A never writes `atoms/`. Mode B never
qualifies, and the disqualifying step is **confidence recomputation**, not file
contention. `_meta/schema.md` § Confidence Values counts independent claims
across independent sources, which is a whole-vault property; N concurrent
promoters each see the pre-fork state and each conclude they are adding an
independent source. Four of the six unread papers are Frässle et al. and share an
author, so that conclusion would be wrong in every run and wrong in a way each
run reports as correct. A wrong `confidence:` is the one vault output with no
second check on it, which is why this is worth fixing before it is needed rather
than after.

Two structural fixes fall out, both cheap: lift `_meta/log.md` appends out of the
workers so a coordinator writes all N serially — the alternative is a lost-update
race that finding 13 makes *silent* — and derive candidate session ids from the
worker, not the wall clock.

State the real payoff honestly in the skill: parallel mode A buys **context, not
wall time**. Each normalized archive runs 75-100 KB and the binding constraint is
fitting six of them in one window.

**M10. Zotero as the first retrieval tier, with attachment validation.** *Partially applied — the load-bearing half shipped. `_meta/validate-archive.sh` landed in `rc.2` Stage 1 and was recalibrated in Stage 3; the Zotero lookup tier did not, and no skill consults a local library. The RC-2 corpus was retrieved half by Zotero and half by `opencite` by hand.*
Retrieval, not extraction, is what gates the evidence layer: 12 of 14 sources
have no `raw::`, and of the six unread papers two are hard-blocked behind
Elsevier. The user maintains a local Zotero library with the local API enabled
and no skill consults it. `memex-ingest` and `memex-deep-extract` both reach for
the network first and have no concept of a local library.

Measured yield on the current backlog was one paper of six — Zotero unblocked
nothing that the network had blocked. Record that plainly: the case for this
milestone is that the library grows and the network route decays, not that it
clears the present backlog.

The load-bearing half is validation, not lookup. `zotero-cli get fulltext` on the
FiberNeAT item returns ~22 KB and reports success; it is the IEEE Xplore landing
page, ending in copyright boilerplate, with three total occurrences of any method
term. Normalized and archived it would look like a source. Every quote would then
either fail grounding or, worse, a few would succeed against publisher chrome.
For IEEE and Elsevier entries in any real library this is the *normal* case, not
an edge case. So: before writing `.archive/` from an attachment, require the
paper's own section structure, a length floor, and the absence of publisher
chrome; on failure report "metadata only" and fall through to the network rather
than archiving it. Record which tier won in the source note's provenance comment,
the same way preprint provenance is already recorded (M6).

Duplicates are routine here and must resolve deterministically rather than by
search rank — the library holds `10.1101/2023.08.19.553990` twice, as a Crossref
`report` and a PMC `journalArticle` with the same attached text. Prefer the entry
whose attachment passes validation, then the most recent.

*Depends on nothing; M6's provenance line is the natural place to record the
winning tier, so shipping them together is cheaper than either alone.*

*Amended 2026-09-11 — `zotero-cli search` loses roughly 40% of results and misses
specific titles entirely, so the retrieval tier must not be built on it.* Verified
against a running Zotero with the local API answering (`/api/users/0/items` and
`/connector/ping` both 200, 1,809 top-level items, `coverage --limit 5000`
reporting 1,774 scanned / 1,513 with a PDF). The client under-reports at every
query length, compared with the same `qmode=titleCreatorYear` query issued
directly to the local API:

| query | `zotero-cli` | local API |
|---|---|---|
| `Mapping` | 69 | 123 |
| `Mapping the human` | 26 | 44 |
| `Mapping the human connectome` | 6 | 9 |
| `Mapping the human connectome at multiple scales` | **0** | **2** |

The loss is proportional, not a length cutoff — and it becomes a **total miss
exactly where the true result set is small**, which is the specifically-titled
lookup a retrieval tier actually performs. Cammoun et al. 2012 is present twice in
the user library (`4F8X4FX9`, `VUMG4ST9`, both `libraryID 1`, both with a PDF
attachment) and `zotero-cli` returns zero for its exact title, with or without
`--all-libraries`. This vault deep-extracted that paper *from Zotero* on
2026-09-04, so the item is unambiguously there.

**This is the mirror of the FiberNeAT trap already recorded above.** That one is a
false positive — an attachment that is a publisher landing page reported as full
text. This one is a false negative — a paper that is present reported as absent.
A retrieval tier that can fail in both directions is worse than no tier, because
each failure silently produces a plausible outcome: fall through to the network
and record "not in library", or archive a copyright footer.

Two consequences for the implementation:

- **Query the local HTTP API directly**, not through `zotero-cli search`. The API
  returns `DOI`, `publicationTitle` and the full `creators` list — the last being
  what M15's independence test needs — and `items/<key>/children` gives the
  attachment `contentType` and `filename` for the validation step. Verified
  end-to-end.
- **`--limit` truncates silently and defaults low.** Unqualified,
  `zotero-cli coverage` scanned 196 items of 1,774 and reported an 85.7% coverage
  figure that looked entirely plausible. Any call that does not pass an explicit
  high limit is reporting on a sample without saying so.

**M11. Five of five calibrated thresholds were wrong, and only two were a
size artifact.** *Applied — `rc.2` Stage 2, all four parts.* Every threshold the 2026-09-11 skill campaign exercised failed on
a real vault of 16 sources / 21 atoms. Separating them matters, because the
obvious diagnosis — "the vault is too small" — covers only two:

| Threshold | Size artifact? | At 200 sources |
|---|---|---|
| `memex-reconcile` Pass 2, `related::` stale after 30 days | yes, pure vault age | fires |
| `memex-stale` Check 1 (90d) and `lint.sh` section 3 (30d) | yes | fires |
| `lint.sh` 6c bloated atom, `lines > 100` | **no** — writing style | still never fires |
| `memex-topic-emerge` step 2 merge, `>= 50%` over `min()` | **no** — worse at scale | more tags, more bridges |
| `memex-conflicts` step 2 reciprocity on `limits::` | **no** — category error | 11 false flags becomes ~100 |

*Fix, four parts.* Skills and `lint.sh` cite these as `M11a`–`M11d`; the
parenthesised letters below are the same labels.

**(a) `M11a` — drop the temporal thresholds.** `memex-stale` Check 1 and `lint.sh`
section 3 ask the same question with different numbers (90 vs 30 days) and
neither produced a finding. Delete both. `memex-stale` Check 4 — processed but
never deep-extracted — carries no temporal term and was the only stale check that
fired, surfacing all five code repos; keep it, and see M8 for why its
recommendation is currently wrong for `medium: code`.

**(b) `M11b` — move `related::` typing to write time.** Dropping reconcile's 30-day rule
is right, but it removes the only thing suppressing a link the user deliberately
chose to **Keep** — the skill uses `updated:` for that, and the mechanism dies
with the threshold. Have `memex-deep-extract` mode B propose a typed relation when
it *writes* the link, while the reasoning is still at hand, and leave
`memex-reconcile` as an unthresholded manual backlog tool. This also closes the
three-way coverage hole recorded in M12.

**(c) `M11c` — replace the line count with body characters, computed against the
vault.**
Lines are a 1.5x spread across this vault's atoms (38-56) while body size is a
5.0x spread (1704-8528 characters, median 3816). The threshold `lines > 100` is
unreachable because the prose is one long-wrapped line per paragraph, and the
`cites::` line alone reaches 1756 characters — 21% of the largest body. Measure
**body characters excluding the `cites::` line**, and set the trigger at **2x the
vault's running median** rather than a constant, so it self-calibrates across
forks the way tag vocabulary already reads from `domain.md`.

**(d) `M11d` — replace `min()` with Jaccard in topic-emerge step 2.** See M13.

**M12. Nothing owns the untyped-relation problem.** *Applied — `rc.2` Stage 2, by dropping the promise rather than adding the check. With no age threshold a lint check could only flag every `related::` (78 in the fork), so `memex-tend`'s routing row is gone and reconcile's Keep is a `kept::` line in `_meta/log.md`.* The vault holds **78
`related::` links**, 21 of 21 atoms carry a populated `related::`, and
`contradicts::`, `supersedes::` and `defines::` are all **0**. That is precisely
the decay `memex-reconcile` Pass 2 exists to prevent. It is unreachable from
three directions at once:

1. `lint.sh` has **no stale-`related::` check at all** — section 7 is 7a/7c/7d/7e,
   there is no 7b, and the only `related` references in the script are the 6b/6c
   link counters;
2. therefore `memex-tend` can never route to it, although its routing table
   promises exactly that ("section 7 | orphan `part-of::`, stale `related::` |
   `memex-reconcile`") — the table names a signal the linter cannot emit;
3. and reconcile's own 30-day rule excludes every link in a young vault.

The only reachable path today is `memex-review` Lens C, which is scoped to one
topic per session and explicitly described as reflective rather than routine.

*Fix:* M11b at write time, plus either a lint check that can actually fire or
the removal of the routing-table row that promises one.

**M13. `memex-topic-emerge` destroys its own best signal before using it.** *Applied — `rc.2` Stage 2. The highest-leverage single fix the campaign found.* The
tag signal works: nine clusters pass the `>= 3` threshold on 21 atoms, and they
are the domain's real sub-divisions. Step 2 then merges any two candidates sharing
`>= 50%` of their atoms, scored as `|A n B| / min(|A|,|B|)` — an asymmetric
*containment* measure — and applies it transitively. This vault's two halves are
bridged by exactly two edges at exactly 0.50:

```
network-neuroscience n effective-connectivity = 2 / min(9,4) = 0.50
network-neuroscience n fmri                   = 2 / min(9,4) = 0.50
```

Two shared atoms each, and they chain a clean two-way split into one 21-atom blob.
Step 3 then reports that blob as a 100%-covered extension of the existing topic,
so the skill proposes nothing.

*Fix:* score with Jaccard, `|A n B| / |A u B|`. On identical data that yields
**7 clusters at threshold 0.50 and 5 at 0.30**, each a recognizable sub-domain.

*This is independent of the topic-hierarchy question and does not wait on it.* The
collapse happens in step 2, before step 3 consults any topic, so repairing
`part-of::` would not fix it. It fires in any vault whose atoms carry two to four
overlapping tags — here, 9 atoms carry 3 tags, 6 carry 4, 5 carry 2.

**M14. `memex-conflicts` cannot acknowledge a directional relation.** *Applied — `rc.2` Stage 2.* Step 2 calls
a conflict acknowledged only if the *target* atom carries a reciprocal skeptical
link. Across 13 conflict pairs on 9 atoms — 2 `challenges::`, 11 `limits::`, 0
`contradicts::`, 0 `refutes::` — **all five target atoms have empty conflict
fields, so 13 of 13 classify as unacknowledged.** That includes
`streamline-smoothing challenges:: tractography-filtering`, the most carefully
documented tension in the vault, which `memex-deep-extract` wrote with a full
in-group caveat about four shared authors.

Requiring reciprocity for `limits::` is a category error: the field means "A
defines boundary conditions where B breaks down", which is directional by
construction, and `B limits:: A` asserts something different and usually false. 11
of the 13 pairs are `limits::`. The rule also contradicts the skill's own field
table, which says of `refutes::` that "asymmetric is acceptable — one side may not
yet be updated".

*Fix:* exempt `limits::` from the reciprocity condition entirely; treat asymmetry
as acceptable for `challenges::` and `refutes::`; require reciprocity only for
`contradicts::`.

*Also:* the step 3 cross-topic check cannot fire while every atom declares the
same `part-of::` targets — a third skill degraded by the flat topic layer, after
`memex-search` step 2 and M13.

**M15. The useful unit of vault size is the independent author group, not the
source.** *Applied — `rc.2` Stage 3 (`lint.sh` counts independent units) and Stage 6 (`memex-seed` reports them before writing anything).* Fitted from the trial-1 vault — 21 atoms, 5 contributing units, mean
1.476 units per atom — **each independent unit covers about 20% of the concept
pool** in its span (p = 0.196, implied pool ~32 concepts). The model reproduces
what was measured: it predicts 38% of atoms medium-eligible and 8% high-eligible
against an observed 33% and 10%.

Projecting, for units landing in the same sub-domain:

| units | ~sources | atoms | `>= 2` units | `>= 3` units |
|---|---|---|---|---|
| 3 | 8 | 15 | 21% | 2% |
| **5** | **14** | **21** | **38%** | **8%** (trial 1) |
| 8 | 22 | 26 | 59% | 24% |
| 12 | 32 | 29 | 77% | 46% |
| 16 | 43 | 31 | 88% | 65% |

**The knee is 8-12 independent units, roughly 22-32 sources.** Below about 15
sources the topic layer cannot split and `confidence:` reads `low` almost
everywhere, which is exactly the state trial 1 reached at 16 sources. The
`skill-evaluation.md` note to "re-assess after ~50 sources" was directionally
right and slightly conservative.

**The regime matters more than the count.** Read *broadly*, atoms accumulate at
about 4.2 per unit and the high-eligible fraction stays pinned near 10%
indefinitely — more sources produce a larger graph, not a better one. Read
*deeply*, atoms saturate near 31 for a given span while confidence climbs
steeply. The target is therefore not a vault-wide total but **8-12 independent
units per sub-domain worth caring about**.

Trial 1 reached only 5 units from 16 sources because the saves were correlated by
construction: four Frassle papers plus the rDCM repo are one unit, each method
paper was saved alongside its own repository, and Hagmann and Cammoun share six
authors. Nothing warns about this at save time.

*Fix:* record independent-unit count alongside source count in `lint.sh`'s
summary block, and have `memex-save` / `memex-ingest` report the author overlap
against existing sources at capture time — "this shares 4 authors with
`<source>`; it will not raise confidence in any atom they both support." The
information is already in `authors:`.

**M16. The 200-source ceiling is a constant factor in `lint.sh`, not an
architectural limit.** *Applied — `rc.2` Stage 3. Lint on the reference vault went 22 s → under 1 s; a filename-to-path map replaced the per-citation `find`.* Lint takes **22 seconds** on 21 atoms, 16 sources and 365
quotes. The driver is `backing_sources()` (`lint.sh:105-126`), which runs a
`find` over `sources/` **per citation**, and is called roughly five times per atom
(`:423`, `:433`, `:492`, `:510`, `:521`). With 272 `cites::` targets across 21
atoms, that is about 1,360 `find`/`grep` subprocess pairs per run. At 200 sources
— extrapolating 1.3 atoms per source and 20 citations per atom — it becomes
roughly 26,000 calls, each scanning 200 files instead of 16: **15 to 25 minutes**.
The quality cost is indirect and severe: a linter that takes twenty minutes stops
being run, and it is the vault's only executable state oracle.

*Fix:* compute `backing_sources()` once per atom and reuse it across sections 7c,
7d and 8; replace the per-citation `find` with a filename-to-path map built once
at startup. A 20-50x constant-factor win puts 200 sources back under a minute and
moves the practical ceiling into the thousands.

*The genuinely architectural limit is the topic layer*, and it binds far earlier:
`lint.sh` section 6d already fires at 15 atoms per topic, which is about 12
sources, not 200.

### Tier 4 — Interoperability

Measured against Open Knowledge Format v0.2. Full analysis in
`_meta/okf-alignment.md`. Lowest tier because nothing else here depends on it,
but O1 and O2 move up to Phase 2 the same way M1 and M2 did — they are cheap
only while that phase is already rewriting every template.

**O1. `status:` carries four different vocabularies, and collides with OKF.** *Applied — `rc.1`, Phase 2.*
One key means `unread|read|processed` on a source, `unprocessed|processed` on a
meeting, `active|paused|complete|abandoned` on a project, and `stub|reviewed` in
the glossary. That overload is a smell on its own terms — the field is a
*pipeline stage*, not a document lifecycle. It is also the one place where an
outside reader gets a **wrong** answer rather than a missing one: OKF §5.4 defines
`status` as a closed `draft|stable|deprecated` lifecycle, so `abandoned` should
read as `deprecated` and `stub` as `draft`, and neither does.

*Fix:* rename to `stage:` in Phase 2. Leaving `status:` unused means OKF's
"absent ⇒ stable" default applies, which is safe. The exporter synthesises the
real value.

*Status: fixed in Phase 2.* The rename is total — templates, 13 skills, eval
fixtures, `_meta/index.md`, `_meta/lint.sh`, and the candidate frontmatter the
original scope list missed. Lint 11c fails on any in-vault `status:`, and 11b
validates each `stage:` against the vocabulary for its node type.

**O2. No node-type discriminator in frontmatter.** *Applied — `rc.1`, Phase 2.* The node type is currently
implicit in the folder, plus `topic-type:` on topics and `medium:` on sources.
Nothing states it directly, so the type is unavailable to any Dataview query that
spans folders, and unavailable to any consumer that is not walking the tree. It
is also OKF's single required field (§4.1), which no template satisfies.

*Fix:* add `type:` in Phase 2; retire `topic-type:`, which it subsumes exactly.

*Status: fixed in Phase 2.* `type:` is on all seven templates and enforced by
lint 11a against `_meta/domain.md` § OKF Types. `topic-type:` is gone. The
cross-folder query O2 asks for now works — see `_meta/index.md` § Provenance.

**O3. The vault has no interchange format.** *Open — Phase 8, the only unblocked phase. Ships as `v1.1.0`, not as part of `v1.0.0`.* Wikilinks, Dataview-backed indices,
date-only timestamps, and typed relations are all load-bearing for Obsidian and
all unreadable outside it. Nothing can consume this vault but Obsidian and the
memex skills.

*Fix:* a deterministic export layer (Phase 8) that translates rather than
changes. Import (Phase 9) is the other half, deferred.

### From the claude-obsidian comparison — recorded, not scheduled

*Added 2026-09-17, `rc.2` Stage 7.* `claude-obsidian`
(<https://github.com/AgriciDaniel/claude-obsidian>) does the same job as memex with
a different design. `_meta/comparison-claude-obsidian.md` compares the two at pinned
commit `32ac5a0` (v2.2.0, 2026-09-10) and gives a verdict on each of fifteen
differences: three were adopted into `rc.2`, five were declined with the principle
named, and seven were recorded as roadmap work. Those seven are F1–F7 below. **F8 is
an eighth row and not one of the fifteen** — it is the one piece worth taking from a
difference that was otherwise declined (product/vault separation, comparison verdict
12), salvaged rather than lost.

**These deliberately carry no tier and no priority.** *(User decision, 2026-09-17:
they are to be evaluated alongside other pending plans once RC-2 is finished.)* They
are numbered `F` so they are addressable without implying they sort against
M-numbers, and they are absent from § Implementation Order on purpose. Every one
names the evidence that memex has the problem — "they have it" was not accepted as
evidence anywhere in that document.

**F1. No version model on sources, and no content hash to detect drift.**
*Deferred — this is M6 + M19, not a new finding.* Their design hashes every payload
and carries `review_state: unreviewed | active | superseded | rejected` plus
`refresh_due`; superseding is a state change that preserves lineage. memex's `raw::`
names one archive and records nothing about which rendering or which version it is.
M19 is the live instance: 8 of 41 quotes stopped matching on re-retrieval while the
paper had not changed. The one addition the comparison makes is a **cheap first
slice** — record the archive's SHA-256 at capture time, which costs one `sha256sum`
and makes drift detectable before anything is done about it. Carry it into M6 as
step one.

**F2. Multi-file writes are not transactional.** *Deferred — architectural. Put to
the user 2026-09-17; no decision recorded.* One logical mutation, in their design,
is one bundle: per-path precondition hashes, a vault-wide lock, a durable journal,
atomic per-file replace, and a `recover` command. Workers return drafts; one
orchestrator applies them. memex has the per-write half already and arrived at it
independently — `memex-candidates` refuses a create whose target exists and a modify
whose line no longer matches. What is missing is grouping, and Stage 6 demonstrated
the cost: a `memex-seed` run killed after 6 of 12 notes left 6 notes, 12 archives,
6 candidates and **0 log entries, with `lint.sh` exiting 0**. Nothing records that a
batch was half-applied. **The blocker is not difficulty, it is language:** a journal,
a lock and a recover command are a runtime, and this vault's toolchain is bash 4
plus awk/sed/grep by decision — `jq` appears nowhere in it and no skill uses
`python3`. Building this means accepting a second language in the tree, which is a
call for the user and not a refactor.

**F3. `lint.sh` has no test suite and no CI.** *Deferred — new scope in the stage
before a tag. The highest-value item in this section.* They ship 534 test functions,
a GitHub Actions workflow, and release gates declared in `config/product-contract.json`
and executed by code, with manual gates that stay explicitly manual. memex has 1,500
lines of bash that is the vault's only executable state oracle, verified by
hand-diffing fixtures. **M20 is the receipt:** the provenance parser read note prose
as provenance and shipped that way in `v1.0.0-rc.1`. So would the 7h gap adopted in
Stage 7 — `cites:: [[ghost]]` linting clean at exit 0 — which was found by reading
someone else's linter, not by testing this one. Wants `_meta/lint-fixtures/`, a set
of minimal vaults with expected output, and one `bash _meta/test-lint.sh`.

Their `verified` rule is worth taking verbatim with it: **`configured` means the
prerequisites are present; `verified` requires a declared behavioural check to pass,
and a schema self-check cannot promote the state.** RC-2 has been applying exactly
that informally — it is why Stage 6 ran three drills rather than asserting the skill
was correct.

**F4. Sources carry no authority.** *Deferred — pending evidence that memex has the
problem.* They declare `authority: official | primary | secondary | community |
synthetic | unknown`, and an accepted claim needs fresh, active, **non-synthetic**
support. memex derives confidence from independent units alone, so three independent
blog posts reach `confidence: high` by the same arithmetic as three independent
papers. No trial-1 finding names this and M15's argument is about independence rather
than authority, so the honest status is unproven: **adding a field with no lint
semantics is decoration, and this vault's own rule is that a field with a writer
needs a check.** Trial 2's corpus is twelve papers with no authority spread and
cannot settle it either; this needs a mixed-medium corpus.

The `synthetic` value is the part memex has no answer to at all. `generated:` marks
a *note* as machine-produced; nothing marks a *source* as model output.

**F5. There is no bounded session context.** *Deferred — pending evidence.* Their
`wiki/hot.md` is a short, sanitized cache of recent facts, changed pages and open
threads, explicitly "not a transcript", with a rule that it must not carry claims
less qualified than the canonical page they came from. Hooks read it and never write
it. memex has no equivalent and every session starts cold, re-reading
`references/vault-schema.md`. That is a real cost with no recorded finding behind it,
and the fix creates a second home for a claim — the failure mode their own schema had
to write a rule against. Wants a trial-2 observation that the cold start actually
costs something.

**F6. `_meta/log.md` grows without bound.** *Deferred — not binding yet.* Their
`wiki-fold` builds bounded, extractive, idempotent rollups of log entries in powers
of two: additive only, never rewriting child entries, dry-run by default. memex's log
is **46 KB after one trial**, `memex-log-query` reads it, and nothing compacts it at
a rate of one entry per capture. Two properties of their design are the ones worth
copying when this does bind: **no fold-of-folds, and never automatic.** Those are
what keep a rollup from becoming a lossy rewrite of the record.

**F7. Retrieval is a graph walk and a grep.** *Deferred — measure before buying.*
They build contextual chunks and a stdlib BM25 index in a disposable cache, with
optional local reranking, and the index is invalidated before its chunk set changes
so a partial index is never served. memex's `memex-search` walks the topic tree and
greps. **Two of the three known causes for wanting an index are already gone:** M21,
the flat topic layer that blinded search, was fixed in Stage 4, and M16, lint at 22 s
extrapolating to 15–25 minutes at 200 sources, was fixed in Stage 3. What remains is
that the grep path is untested above ~16 sources. A derived index is state that can
go stale, and this vault's working principle is that the notes are the only state —
so the cost is real and the need is unmeasured.

**F8. Nothing checks that `$VAULT` is a memex vault before writing to it.**
*Deferred — one line of logic, but a 21-skill edit, and it arrived during the release
stage.* Their `paths.py` raises `VaultSelectionError` and **writes nothing** when
vault selection is not certain, and their skills resolve the product root from their
own location rather than the working directory. memex resolves
`VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"`, which is correct by
construction when a skill runs inside its own fork — and silently wrong otherwise. A
stale `MEMEX_VAULT`, or a skill invoked from an unrelated repository, writes
`sources/paper/…` into that repository, and the first sign is `git status`. The guard
is `[ -f "$VAULT/_meta/schema.md" ] || { echo "not a memex vault: $VAULT"; exit 2; }`
in the invariant vault-root block every skill already copies byte-for-byte. **This is
the cheapest real safety gain in this section** and the one most likely to be worth
pulling forward.

---

## Implementation Order

The original Phase 1→4 sequence still holds internally. E1 slots in after the
schema work it depends on. The OKF work splits across two points: the in-vault
half rides along with Phase 2, and the export layer lands at Phase 8, once
everything it serialises exists.

| Phase | Work | Closes | Why here |
|-------|------|--------|----------|
| **0** | Lint integrity: split `fails` from `warns`, `exit 1`, one orphan definition | L1, L2 | Small. Nothing downstream can treat lint as a gate until this lands. **Done.** |
| **1** | `covers::` → Dataview migration | P1 | Breaking; all skills must be consistent first. **Done.** |
| **2** | Schema split + atom style spec + disambiguation policy + OKF frontmatter | S1, M1, M2, O1, O2 | M1 and M2 are hard prereqs for Phase 3. O1 and O2 land here because this phase already rewrites every template and writing skill — separately means touching both twice. **Done.** |
| **3** | Evidence layer: `extracts/` + `memex-deep-extract` | E1, M5 | Depends on 0 (grounding gate), 1 (`part-of::` traversal), 2 (M1, M2). Also absorbed P2 — the rubric was cheapest to write while the schema was open. **Done.** |
| **4** | `memex-trust-audit` rebuild on the claim rubric | — | Shrunk: P2's rubric landed in Phase 3, P3's `related::` promotion in Phase 1. **Done.** |
| **5** | Anki render mode on `memex-compose` | — | **Deferred** (2026-08-25) — low priority, unlikely to be revisited before more critical refactoring. Unblocked whenever it is wanted; the design is written. |
| **6** | `memex-init` onboarding skill | S3 | **Done.** Also made the 18 existing skills path-independent and taught lint to read § Source Types |
| **7** | `memex-tend` orchestrator | P4 | **Done.** Routes lint findings to skills; never invokes deep-extract, compose, refactor, or init |
| **8** | OKF export layer: `_meta/okf-export.py` + `memex-export` | O3 | Needs the schema settled (2), `extracts/` to exist (3), and `verified:` populated (4) |
| **9** | OKF import: `memex-import` | — | Scheduled but deferred — no consumer yet, and its shape depends on what real-world bundles look like |

Deferred, unscheduled: **Phase 5** (Anki), **M3** (temporal claim fields), **M4**
(typed open questions). M3 and M4 became cheap once Phase 3 existed; neither
blocks anything. Phase 9 is scheduled but deferred on the same footing.

**This table stops at the phases.** The RC-2 stages that applied M6–M22 are not
phases and are not added to it — they were one release's execution order, recorded
in `CHANGELOG.md` and in each finding's status marker, and a stage numbering that
only ever applied to `rc.2` would age badly next to phase numbers that are cited
across four other documents. **F1–F8 are absent on purpose**, per the same decision
that gave them no tier: they are evaluated alongside other pending plans before any
of them earns a place here.

Phase numbers are **not** reassigned when a phase is deferred. Phases 6–9 keep
their numbers with 5 skipped, because the numbers are referenced across
`_meta/deep-extract-design.md`, `_meta/okf-alignment.md`, several skill files,
and every commit message in the history. A tidier sequence is not worth
invalidating that.

---

## Where to Start Next

**Since `v1.0.0-rc.2`, the first move is trial 2, not a phase.** Everything RC-2
was going to apply is applied, and the only thing that can move the release now is
a full trial against the tag. It is not a build step, it needs no phase here, and
its shape is § The RC-2 seed corpus plus `memex-seed`. A trial that surfaces
nothing new promotes `v1.0.0`; a trial that surfaces something produces `rc.3`,
which is the process working.

*The open set trial 2 is judged against* is this file's `Open` and `Deferred`
rows — `O3`, `M3`, `M4`, `M6`, `M8`, `S2`, `F1`–`F8` — plus the `Partially
applied` remainders of `M10` and `M19`. A finding trial 2 reports is new only if
it is not one of those. That list is the whole reason this revision added status
markers.

**Then Phase 8, the next *build*.** The post-1.0 WikiSkill fork is written up in
`_meta/forge-design.md`, gated on `v1.0.0` final; it needs no phase here because
it happens in another repository.

**Two questions are with the user, not with this file** — F2 (a transaction
runtime, which means accepting a second language in the tree) and multi-host
support on the `AGENTS.md` pattern, which is not a gap but is the widest-reaching
difference the comparison found. Neither is scheduled. Both are recorded so a
later trial does not re-derive them.

**Phase 8 is the only unblocked phase.** Its full design is in
`_meta/okf-alignment.md`; the roadmap entry below carries three amendments made
while later phases shipped — extracts map onto OKF §5.1 footnote-keyed
attribution, the exporter must not duplicate `_meta/normalize.sh`, and it creates
`_okf/` itself because Phase 6 deliberately does not scaffold the empty folder.
It is also the first phase that is real code rather than a skill document.

Everything else outstanding is deferred: Phase 5 (Anki), Phase 9 (OKF import),
M3 (temporal claim fields), M4 (typed open questions), M6 (source versions), M8
(code extraction), S2 (a worked example), and F1–F8 from the `claude-obsidian`
comparison. None blocks anything. F3 (lint fixtures and CI) and F8 (the `$VAULT`
guard) are the two most likely to be worth pulling forward.

**M17. The Obsidian setup the README describes does not exist, and half the
graph was infrastructure.** *Applied — `rc.2` Stage 1 (the `.obsidian/` files and the README rewrite) and Stage 4.* Found while discharging the last verification-debt
row on 2026-09-11. Three separate defects, all fixed in the brain-connectivity
fork and back-ported here in `rc.2` Stage 1, and all of which every previous fork
would have hit:

- **README section 4 pointed at a menu that is not there.** It said
  `Settings → Graph view → Groups`. Obsidian has no graph section under Settings;
  the panel lives inside the graph pane, behind the sliders icon in its own
  top-left corner. The instruction was unfollowable as written.
- **`.obsidian/graph.json` shipped empty** — `search: ""`, `colorGroups: []`,
  `showOrphans: true` — so the "optional but recommended" colouring was a manual
  task every fork repeated by hand, which is the same argument `domain.md` settles
  for tag vocabulary. Now shipped configured.
- **Infrastructure outnumbered knowledge on the graph, 60 files to 49.**
  `app.json` `userIgnoreFilters` excluded only `.archive` and `_okf`; `skills/`
  (40 files), `_meta/` (10) and `_templates/` (8) rendered as a large
  disconnected cloud around the real graph. Fixed with a **graph filter**, not a
  global ignore, because those folders should stay searchable and openable — the
  two exclusion mechanisms are not interchangeable and the README did not
  distinguish them.

*Also fixed:* `_templates/topic-research.md` used `this.file.link` for its atoms
query but a Templater-baked `[[<% tp.file.title %>]]` for its sources query — an
inconsistency inside one file. It resolves at creation time, so nothing was
broken, but it is a literal snapshot that breaks on rename (Obsidian does not
rewrite links inside code blocks) and it cannot be verified by observation on a
vault where no source `supports::` a topic. Both the template and the one topic
created from it now use `this.file.link`; 9 of 9 dataview self-references in the
vault are consistent.

*Generalizable:* `.obsidian/` is configuration a fork should inherit, not
re-derive. Anything the README tells a human to click through once is a candidate
for shipping pre-configured.

**M18. `_meta/validate-archive.sh` rejects short-genre papers and misses
drop-cap headings — 4 false negatives in 12.** *Applied — `rc.2` Stage 1 (the script) and Stage 3 (its calibration table).* Measured while building the RC-2
corpus. Every one was verified by reading the archive; all four are correct full
text and the check is wrong.

| archive | check that failed | what it actually is |
|---|---|---|
| Daducci & Schiavi 2025 | 17.9 KB prose < 25 KB floor | genuine 4-page commentary, abstract + affiliations + references |
| Rheault et al. 2025 | 24.2 KB prose < 25 KB floor | genuine 5-page commentary, same |
| Shailja et al. 2023 | 1 distinct heading (< 2) | IEEE drop-caps: `pdftotext` renders them `I. I NTRODUCTION` |
| Runge 2018 | 1 distinct heading (< 2) | 97 KB prose, 113 paragraphs, full text |

Two independent defects.

**The 25 KB prose floor cannot distinguish a short paper from a landing page.**
The floor exists to catch the FiberNeAT trap — an IEEE abstract page that
returned ~22 KB and reported success (M10). A 4-page commentary is the same size.
This collides directly with the RC-2 corpus requirement for adversarial evidence:
**disagreement in this field lives in commentary and correspondence, which is
precisely the genre the floor rejects.** Aydogan et al. passed at 27.9 KB — the
genre straddles the threshold, so no single number separates them.

*Fix:* stop using length as the landing-page test and use **structure** instead.
A landing page has no references section, no numbered sections and no author
affiliations block; a 4-page commentary has all three. Those are cheap to detect
and they discriminate on the thing that actually differs.

**Heading detection breaks on PDF typography.** `pdftotext` renders a drop-cap
capital as a detached letter, so `INTRODUCTION` arrives as `I NTRODUCTION` and
the section-heading pattern misses it. Both failures here are this, in two
different publishers' layouts.

*Fix:* normalise `^([A-Z]) ([A-Z]{2,})` to `\1\2` in `pdf-clean.sh` before the
structure test runs, and count numbered section markers (`I.`, `1.`, `A.`) as
headings independently of their text.

**M19. Quote grounding is archive-format-specific, so re-grounding reports drift
that does not exist.** *Partially applied — the lesson shipped, the tool it was a lesson for did not. Normalized comparison is mandatory where grounding is checked, and `memex-seed` normalizes every archive before its note is written. The `memex-deep-extract-reconcile` step this finding constrains belongs to M6 and is deferred with it.* A live instance, not a hypothetical. Cliff et al. 2023 was
re-retrieved for the RC-2 corpus and **8 of the 41 trial-1 quotes no longer match
verbatim** — yet the paper did not change. Classifying all 8:

- **6 are whitespace or punctuation differences alone.** They are present in the
  new archive after stripping non-alphanumerics.
- **2 are the ar5iv doubled-maths artifact.** Trial 1 archived ar5iv HTML, where
  inline maths arrives duplicated: `sij=sjis\_{ij}=s\_{ji}` and `[-1,1][-1,1]`.
  `pdftotext` on the PDF renders the same sentences `sij = sji` and `[-1, 1]`.
- **0 are version drift**, despite trial 1 holding `arXiv:2201.11941` **v1** and
  the new archive holding **v2** (2023-06-26).

`_meta/skill-evaluation.md` records quoting ar5iv's maths debris verbatim as
"the whole discipline", and that is right for verifying against *that* archive.
But it makes the quote an artefact of one rendering, and the grounding guarantee
silently narrows from "this sentence is in the paper" to "this byte sequence is
in this file".

*Consequence for M6.* The proposed `memex-deep-extract-reconcile` classifies each
claim as *unchanged / reworded / removed / new* by re-checking its quote against
the newer archive. On this data it would report 8 claims as reworded or removed
and hand all 8 to a human, when the correct answer is 41 unchanged. **A reconcile
step that cannot tell re-rendering from revision generates pure noise on exactly
the case it was built for.** Step 2 must compare on normalised text —
non-alphanumerics stripped — and only report drift when the normalised forms
differ. The verbatim quote stays in the extract; the *comparison* is what
normalises.

*Consequence for the RC-2 corpus.* Trial-2 quotes on Cliff and Cammoun will not
match trial-1 quotes textually even when both are correct, so the planned
paper-by-paper diff must compare claims and concepts, never quote strings.

**M20. `lint.sh`'s provenance parser read body prose as provenance, and shipped
that way because `verified:` had never been written.** *Applied — `rc.2` Stage 1. The one finding in this list that had already shipped broken in a tagged release.* Surfaced the first time any
atom carried a real sign-off, 2026-09-11.

Section 13b captured the block with:

```awk
/^verified:/{f=1;next} f&&/^[a-z]/{exit} f{print}
```

which terminates at the next top-level key but **not at the frontmatter fence**.
`verified:` is conventionally the last key in the block, so the parser ran
**21-33 lines into the note body** on all five signed-off atoms and treated prose
as provenance. In `method-validation-without-ground-truth` it lifted
`confounded by: resolution,` out of a sentence and reported `resolution,` as an
invalid actor string.

**Four of the five were silent purely by luck** — their prose contains no second
`by:` before the first lowercase-initial line. A universal parser bug with a
data-dependent symptom is the worst shape available: it looks like a content
problem in one file.

*Why it survived to a tagged release.* `verified:` was 0 of 21 atoms until this
session, and 0 in the template by construction, so section 13b had **never
executed against a populated block** — only against files that skip the key
entirely, where it correctly does nothing. No fixture could have caught it; it
needed a human sign-off to exist first. Section 13c inherits the same block and
would have read any `at: YYYY-MM-DD` in prose as a sign-off date. Section 13a is
safe only incidentally, because it `exit`s on the first match.

*Fixed* by terminating on `/^---$/` as well as `/^[a-z]/`, applied to all three
provenance parsers. Lint returns to 7 warnings and a full diff against the
morning baseline shows the only change is the three trust-audit upgrades clearing
section 8.

*Generalizable, and worth stating as a rule:* **every optional frontmatter block
is an unexecuted code path until something writes one.** `verified:` is the only
field in the schema whose writer requires a human, which is exactly why it was
the last to be exercised and the last to be checked. Audit the other optional
blocks against a populated example before the next tag.

**M21. The flat topic layer blinds `memex-compose` and `memex-search` from
opposite directions.** *Applied — `rc.2` Stage 4 (the D2 topic hierarchy) and Stage 6 (a seeded scaffold with two branches).* Both were run for the first time in the campaign and both
degraded, but not in the same way, and the pair is more informative than either
alone.

- **`memex-search` step 1-2** is specified to flow top-down, `topics/` → `atoms/`
  → `sources/`. Starting at `topics/concepts/` returns all 22 atoms for every
  query, so it narrows nothing and every useful query short-circuits to the atom
  layer or the grep fallback. The documented entry point is dead weight.
- **`memex-compose` step 1** refuses a topic with no `part-of::` members — and
  correctly refused `topics/research/method-to-crane-mapping.md`, the vault's
  richest node: a real research question, 7 cited sources, a ranked comparison
  table, and 7 atoms referenced inline in prose. Zero atoms declare membership,
  because on 2026-09-04 the node **deliberately opted out**, reasoning in its own
  body that a third `part-of::` target on atoms already declaring
  `brain-connectivity` and `crane-method-integration` would "make the derived
  lists identical everywhere and stop discriminating."

That reasoning was right, and it is the trap. **The one topic whose membership
would carry information has no members, and the topic whose membership carries
none composes fine.** `brain-connectivity` exported 22 atoms, 241 footnotes and
16 tensions without difficulty, while being the node `lint.sh` 6d has flagged as
undifferentiated since 2026-09-04.

*Fix, two parts.* The hierarchy amendment addresses the cause. Independently,
`memex-compose` step 2 should **fall back to atoms wikilinked from the topic
body** when `part-of::` membership is empty, and state which basis it used —
a topic that relates its atoms in prose is not an empty topic, and treating it as
one discards the most considered node in the vault.

**M22. Graph node labels are filenames, and nothing in Obsidian's core settings
changes that.** *Accepted — option 3. Atom labels are already the readable ones and atoms are what a topic map is read through; the long labels are on the layer a reader arrives at last. Revisit only if a fork is willing to take a second load-bearing plugin.* Raised by the user 2026-09-11, low priority, recorded so it is not
re-derived.

Obsidian labels a graph node with the file's basename. Frontmatter `title:` and
`aliases:` are not consulted. Current label lengths in this vault:

| layer | range | note |
|---|---|---|
| `atoms/` | 11-43 chars | kebab-case, readable |
| `sources/` | 31-64 chars | 10 of them are the `YYYY-MM-DD-` prefix |
| `extracts/` | up to 66 chars | `ext-` plus the full source slug |

So every source and extract label spends 10-14 characters on a prefix that
carries no meaning at a glance — and `_meta/schema.md:567` **requires** that
prefix, so shortening the filename is a schema change, not a display tweak.
`graph.json`'s `textFadeMultiplier` controls when labels fade with zoom, not what
they contain.

*Options, none free.*

1. **Front Matter Title plugin** — substitutes `title:` across explorer, graph and
   search. This is the only thing that does what was asked. Cost: the README's
   claim that "exactly one plugin is load-bearing" stops being true, and a fork
   inherits a second hard dependency for a cosmetic gain.
2. **Shorten the slug rule** — drop the date prefix from `sources/`. Cheapest
   visually, but the prefix is what gives `ls sources/paper/` chronological order
   and what `lint.sh` section 1 checks. Not worth it.
3. **Accept it.** Atom labels are already the readable ones, and atoms are what a
   topic map is read through; source and extract nodes are the ones that are long,
   and they are the layer a reader arrives at last.

*Recommendation: 3, revisit if the graph becomes a primary reading surface.* No
action taken.

### The RC-2 seed corpus

What to read, sized from M15 and shaped by M11-M22. This supersedes the informal
"about 10 papers" figure: the count was never the binding quantity.

> **A worked example, not a specification.** This section is the RC-2 trial's own
> corpus, and its subject matter — tractography, connectomics, the specific author
> groups — belongs to the brain-connectivity fork that ran trial 1. A fork in
> another domain substitutes its own. What generalizes is everything above the
> paper titles: select on author independence rather than topic, two branches of
> asymmetric depth rather than one flat set, one medium, a deliberate disagreeing
> pair, and a floor rather than a target. Those are M15 applied, and they are
> domain-free. Kept in the template because § Release Status's criterion refers to
> "a full trial", and this is the only written account of what one is.

**Select on author independence, not on topic alone.** This is the whole finding
and it costs nothing to apply:

| 10 documents, chosen by | independent units | atoms | `>= 2` units | `>= 3` units |
|---|---|---|---|---|
| topic, read as trial 1 was | 4 | 19 | 30% | **4%** |
| topic **and** distinct author groups | 10 | 28 | 69% | **35%** |

Same ten papers, same reading cost, and `confidence:` goes from decorative to
informative. Trial 1 got 5 units from 16 documents because the saves were
correlated by construction — four Frassle papers plus the rDCM repo are one unit,
each method paper was captured alongside its own repository, and Hagmann and
Cammoun share six authors.

**Target shape: 12 documents, 12 distinct author groups, in two branches.**

| Branch | Docs | Units | `>= 3` units |
|---|---|---|---|
| Deep — one sub-domain, read to saturation | 8 | 8 | 24% |
| Shallow — a second sub-domain | 4 | 4 | 4% |

Two branches rather than one flat set, because a hierarchy with one branch is not
a hierarchy. Asymmetric depth rather than 6+6, because the test is whether the
seeded structure *earns its keep*, and a visible difference between a saturated
branch and a thin one is what makes that answerable. Pick the two sub-domains from
the seven Jaccard clusters M13 recovers — `structural-connectivity`,
`statistics`, `network-neuroscience`, `tractography`+`diffusion-mri`,
`effective-connectivity`+`fmri`, `foundational`, `software-tools`.

**Composition rules.**

- **All `medium: paper`.** The confidence rubric needs "reviewed or primary",
  which per `_meta/schema.md` is inferred from `medium: paper` with a `venue:`.
  Mixing media dilutes unit density without testing the evidence layer.
- **At least 8 of 12 carrying a `venue:`.** `high` needs two reviewed-or-primary
  units per atom; preprints alone cannot get there.
- **Two deliberate preprints**, to exercise M6's version model and force the
  preprint-provenance path rather than leaving it to chance. *As built, one:*
  Cliff (arXiv:2201.11941v2), carried over from trial 1. M6 is not in RC-2, so
  one preprint observes the provenance path; exercising a version model waits for
  the model.
- **One deliberate out-of-group pair that disagrees.** Trial 1 produced 13
  conflict pairs and 0 `contradicts::`, because a single author group rarely
  contradicts itself. M14 cannot be tested without genuine adversarial evidence.
- **Trial-1 overlap: keep Cliff, and exactly one of Hagmann or Cammoun.** They are
  one unit, so spending two of twelve slots on them buys one. Cammoun is the
  better keep — it is the multi-scale paper, and scale dependence is where the
  hierarchy question bites.
- **Untested media stay out of the corpus.** `web`, `video`, `docs` and `meeting`
  get exercised by throwaway captures during the skill campaign, where they cost
  nothing and confound nothing.

**Retrieval split.** Roughly half from the local Zotero library (exercising M10's
first-tier lookup and, more importantly, its attachment validation) and half via
`opencite` (exercising the network fallback and citation resolution). Every
archive passes `_meta/validate-archive.sh` before entering the manifest; the
manifest records which tier won per document. *As built, 8 and 4:* all eight
deep-branch documents came from Zotero, all four shallow from `opencite`, so tier
and branch are confounded.

*Corrected 2026-09-17, Stage 6.* This paragraph said the manifest carries a
`validation` field that is `null` on every row, and that 4 of 12 archives fail the
validator as M18 false negatives. Both were wrong, and the second was wrong in the
direction that matters. The manifest has no `validation` key: it has
`validate_pass` (boolean, **false on four rows**) and `validate_detail`. Both are
snapshots of the **retired pre-M18 validator**, whose `FAIL` token no longer
exists — the current failure token is `REJECT`. Re-running the current validator
over all twelve archives gives **12 PASS, 0 REJECT, exit 0**. So the four
"failures" are an artefact of a stale snapshot, not surviving false negatives.
`memex-seed` ignores both fields and re-validates at seed time, and says so in one
sentence where an operator will read it.

**Stop condition.** Twelve documents is the floor at which both branches are
testable, not a target. If the deep branch does not reach 8 genuinely independent
groups, add to that branch rather than broadening — per M15, broad reading pins
the high-eligible fraction near 10% no matter how many documents arrive.

### Verification debt

Four things were built and proven only against fixtures, because this repository
is a template and ships with 0 atoms, 0 sources and 0 extracts by design. Every
check that needs content to act on could only be verified in a fork. The
brain-connectivity fork has now done that for all four.

| What | Since | Status |
|---|---|---|
| `memex-init`'s five-question flow | Phase 6 | **Discharged** 2026-09-03, `_meta/log.md` init entries |
| `memex-deep-extract` end to end | Phase 3 | **Discharged** 2026-09-04, 8 extracts, 365 quotes grounded |
| `memex-tend`'s ordering | Phase 7 | **Discharged** 2026-09-11, triage run in the skill campaign |
| Every Dataview query in `_meta/index.md` | Phases 1–2 | **Discharged** 2026-09-11, all 19 queries verified against precomputed counts |

**All four rows are discharged by the brain-connectivity fork**, the last on
2026-09-11. The Dataview row was verified by computing every query's expected row
count from the filesystem first and comparing: sources 16, atoms 21, extracts 8,
never-verified 21, and so on for all 19. The discriminating test for the silent
`row["part-of"]` failure (`_meta/schema.md:158-159`) is that `brain-connectivity`
returns 21 atoms and `crane-method-integration` returns 20 — a broken query and a
genuinely empty topic both render as nothing, so an empty topic proves nothing
unless a populated one renders alongside it.

**Discharging the rows turned out not to be what promotes the release at all.**
The exercise that discharged them surfaced M11-M22, which is why § Release Status
now asks for a trial that surfaces *nothing new* rather than for these four rows
plus a fix list. The rows did their job — they are what got a real vault in front
of the skills — and they are retired as a gate.

This is not a defect list. Fixture-testing caught two real bugs in Phase 6 that a
content-ful vault would have caught the same way. But no amount of it substitutes
for one pass over real notes.

*Status 2026-09-17.* That pass has now happened once, and the twelve findings it
returned are M11–M22. **The section is kept as a record of a retired gate, not as
outstanding work** — every row is discharged and § Release Status no longer refers
to them. What replaced the rows is a standing obligation rather than a checklist:
each RC gets a full trial, and a trial that finds something produces the next RC.
F3 is the same argument applied one level down — fixtures are not a substitute for
a real pass, and `lint.sh` still has neither.

## Phase Detail

### Phase 0 — Lint integrity *(complete)*

1. `_meta/lint.sh` — separate `fails` from `issues`; `exit 1` when `fails > 0`;
   summary distinguishes failures from warnings.
2. `_meta/lint.sh` section 4 — orphan check now counts inbound wikilinks from
   `sources/`, `atoms/`, `topics/`, and `glossary/`, replacing the `covers::`-only
   grep. This also survives Phase 1, which removes manually-written `covers::`.
3. `_meta/index.md` — both `file.inlinks` queries filter to the same four curated
   folders, so `_meta/log.md` links no longer suppress the orphan lists.
4. `_meta/schema.md` — the orphan definition is stated once, normatively.

**Verification:** `bash _meta/lint.sh; echo $?` → `0` on a clean vault. Introduce a
source file without a date prefix → prints `FAIL`, exits `1`.

### Phase 1 — `covers::` → Dataview migration *(complete)*

Make `covers::` auto-derived from `part-of::` on atoms. Single source of truth.

1. `_meta/schema.md` — remove `covers::` from the Topic → Atoms table and from
   Valid Relation Fields; note that topic membership is derived via Dataview.
2. `_templates/topic-{concept,research,project}.md` — replace the `covers::`
   placeholder with a Dataview block; Templater injects the topic title.
3. `topics/concepts/getting-started.md` — same substitution.
4. `skills/memex-topic-init/SKILL.md` and `skills/memex-topic-emerge/SKILL.md` —
   stop writing `covers::`; keep writing `part-of::` to atoms.
5. `skills/memex-reconcile/SKILL.md` — remove the `part-of::` ↔ `covers::` drift
   check; replace with an orphan-`part-of::` check (points at a non-existent
   topic). Add the `related::` promotion pass from Phase 4.
6. `_meta/lint.sh` — 6d now counts atoms by reverse `part-of::` lookup; 7a keeps
   only the dangling-topic half; 7b retired outright (a query cannot drift).
7. `README.md` — note `covers::` is derived, not written.

**The list above under-scoped the work.** `covers::` was *written* by three skills
but *read* by eight more, and the per-skill schema reference is duplicated 13
times. The full set that had to change:

8. `skills/*/references/vault-schema.md` — 13 identical copies, all carrying the
   retired `Topic → Atoms` table. Kept byte-identical after the edit.
9. Reading skills switched to reverse lookup
   (`grep -rlE "^part-of::.*\[\[<topic>\]\]" atoms/`): `memex-compose`,
   `memex-review`, `memex-conflicts`, `memex-stale`, `memex-trust-audit`,
   `memex-search`, `memex-connect`.
10. `skills/memex-refactor/SKILL.md` — split and merge no longer rewrite any topic
    file; they carry `part-of::` onto the new atoms instead.
11. `_meta/ccm-mapping.md`, `_meta/deep-extract-design.md` — stale references.

**Phase 4 item 2 is already done.** The `related::` promotion pass landed here, as
step 5 directed. Phase 4 keeps only the confidence rubric and the trust-audit
rebuild.

**Verification:** `grep -r "covers::" skills/ _templates/ topics/` returns only
Dataview query blocks and schema notes.

**Dependency created for Phase 8.** Dataview-derived membership is invisible
outside Obsidian, so a non-Obsidian consumer would see every topic as empty. The
exporter must materialize `covers` by scanning atoms' `part-of::` — the same
traversal, done deterministically in Python. No work in this phase; recorded so it
is not discovered late.

### Phase 2 — Schema split + atom style spec + disambiguation + OKF frontmatter *(complete)*

**Schema work (S1, M1, M2):**

1. `_meta/schema.md` — replace the Tags section with a pointer to `_meta/domain.md`; add **Atom Writing Style** (3–5
   rules: present tense, hedge single-source claims, use relations not inline
   prose, one claim per atom) and a **Disambiguation Policy** (suffixed slugs for
   true homonyms, polysemous sections for related senses).
2. `_meta/domain.md` — new. Sections: *Domain Name*, *Domain Tags*, *Type Tags*,
   *Stage Tags*, *Source Types*, *OKF Types*. Each is a fenced list parsed one
   entry per line, the same shape `schema.md` § Valid Relation Fields already
   uses and lint already knows how to read.
3. `_meta/lint.sh` — read tag vocabulary from `_meta/domain.md` (section 10) and
   the folder→`type:` table from it as well (section 11).
4. `README.md` — add a "Specializing This Template" section.

**OKF frontmatter (O1, O2).** Additive except one rename. Nothing here costs
Obsidian or Dataview anything, and each item pays for itself independent of OKF.

5. **Add `type:`** to all seven templates and to
   `topics/concepts/getting-started.md`. Values: `Source`, `Atom`,
   `Glossary Term`, `Concept Map`, `Project`, `Research Question`. `medium:`
   stays the source subtype, so no fact is duplicated. The mapping lives in
   `_meta/domain.md` under `okf_types` so a fork can rename types without
   touching the exporter.
6. **Retire `topic-type:`** — `type:` subsumes it exactly. Touches
   `_templates/topic-{concept,project,research}.md`,
   `topics/concepts/getting-started.md`, `memex-topic-init`, `memex-topic-emerge`,
   `_meta/schema.md`.
7. **Rename `status:` → `stage:`.** Values unchanged; only the key moves, so no
   behaviour changes anywhere. The widest blast radius in the roadmap, so scope it
   explicitly: 4 templates (`source-digital`, `source-meeting`, `topic-project`,
   `glossary`); 13 skills at ~49 lines total — `memex-compose`, `-connect`,
   `-glossary`, `-ingest`, `-log-query`, `-meeting`, `-refactor`, `-review`,
   `-save`, `-search`, `-stale`, `-topic-init`, `-trust-audit`; `_meta/index.md`
   (6 Dataview references); `_meta/lint.sh` (22 hits); `_meta/schema.md`
   §Status Values → §Stage Values; `README.md`; the `TABLE` columns in
   `_templates/topic-research.md` and `topics/concepts/getting-started.md`; and
   the eval fixtures under `memex-ingest/evals/` and `memex-search/evals/`.
8. **Add `description:`** — optional, one sentence, all seven templates. Not
   conformance-only: it feeds Phase 8's `index.md` generator *and* lets
   `_meta/index.md` carry a summary column, which it cannot today. The existing
   `## Summary` / `## Definition` / `## Overview` prose is the drafting cue.
9. **Define `generated:` and `verified:`** in `_meta/schema.md`, with OKF's actor
   convention (`<producer>/<version>`, `human:<id>`, `process:<id>`). Writing
   skills start emitting
   `generated: { by: memex-ingest/claude-opus-5, at: <date> }`. A real gain, not
   just conformance — `skill::` currently exists only in `_meta/log.md`, so
   per-note authorship is unrecoverable. `verified:` is **defined** here and
   **written** in Phase 4. State explicitly that `confidence:` and `verified:`
   are orthogonal: confidence measures evidence strength, verified records who
   confirmed it.
10. `_meta/lint.sh` — three new checks, as section 11: `type:` present and
    matching the folder's entry in `domain.md`; `stage:` value valid for the node
    type; `status:` **absent** in-vault, since it is the exporter's output field
    and hand-writing it would diverge. Section 2 also gained the topic
    required-field checks it never had — `title` on all three topic kinds,
    `stage` on projects, `question` on research.

**Verification:** the invariant is about *frontmatter*, so match line-initial
keys — prose that names the retired fields in order to explain the retirement is
expected and desirable:

```bash
grep -rn '^topic-type:' _templates/ skills/ topics/ sources/ atoms/ glossary/
grep -rn '^status:'     _templates/ skills/ topics/ sources/ atoms/ glossary/
grep -rn 'status *='    _meta/index.md _templates/ topics/
```

All three return zero. `bash _meta/lint.sh` exits `0`. A note with `type: Nonsense`, or one carrying
`status:`, prints `FAIL` and exits `1`. In Obsidian: every `_meta/index.md`
Dataview table still renders, now with a `description` column, and a note created
from each of the seven templates shows `type` and `stage` in the property editor.

**Scope corrections found during implementation.** The step list above missed
four things, all of them found by doing the work rather than by re-reading the
plan:

11. **`_meta/candidates/` also carried `status:`.** Step 7 enumerated templates,
    skills, lint, and index, but not the candidate frontmatter documented in
    `_meta/schema.md` § Candidate Lifecycle and emitted by `memex-ingest`,
    `-connect`, and `-glossary`. Renamed there too. Keeping it would have forced
    a folder carve-out in the new lint check and made "`status:` is the
    exporter's output field" false in one place; the invariant is now total.
12. **`_meta/index.md` had the same hyphen bug Phase 1 fixed.** The
    uncategorized-atoms query read `WHERE !part-of`, which Dataview parses as
    subtraction and which therefore matched nothing — a silent empty table, not
    an error. Now `WHERE !row["part-of"]`, matching the membership query.
    `topics/concepts/getting-started.md` also still told the reader to write
    `part-of:: [[Getting Started]]`, the frontmatter title rather than the
    filename, which would never resolve. Both are the Phase 1 failure class,
    missed because Phase 1 fixed the queries it touched and not the prose.
13. **`_meta/lint.sh` aborted silently on any missing field.** Eleven
    `var=$(grep … | head -1 | sed …)` assignments run under `set -euo pipefail`,
    so `grep` finding nothing returned 1 and killed the script mid-run — a
    truncated report and `exit 1` with no failure printed. Surfaced immediately
    by the new `type:` check, since a note missing `type:` is exactly the case.
    All eleven now end `|| true`. Latent since the script was written; harmless
    only because the vault has no notes yet.
14. **Citation counts counted the empty template line.** `_templates/atom.md`
    ships a bare `cites:: ` prompt, which Dataview reads as absent — section 4
    documents this and matches `^cites::\s*\[\[`, but sections 6c, 7d, 8a, 8c,
    and 8d used `grep -c "^cites::"`. Every freshly-created atom therefore drew
    two bogus "all cited sources are unread" warnings. All counts now require a
    populated field.
15. **Relation counts counted lines, not targets** *(found 2026-09-02, after
    `v1.0.0-rc.1`)*. Item 14's fix added `\[\[` to those greps but left them as
    `grep -c`, which counts matching *lines*. § Orphans blesses
    `introduces:: [[A]], [[B]]` on one line and calls it "expected and correct",
    so every threshold check read a well-linked field as a single connection.
    Two checks were wrong in opposite directions: **8d** flagged a source with
    four atoms on one `introduces::` line as *under-extracted* — nagging exactly
    the sources the vault wants — and **6c** could only fire on six separate
    `cites::` lines, which nothing writes, so it had never fired at all. Fixed
    with a `count_links()` helper beside `backing_sources()`, which already
    parsed per-target correctly; 6c, 8d, and 8e now use it. Thresholds unchanged.

Items 13, 14, and 15 are lint defects rather than Phase 2 work, filed here
because this phase is what exposed the family and because a lint that dies
partway cannot gate anything — which was Phase 0's entire point. Item 15 was
found later, while verifying that nothing in the vault enforces one atom per
source; nothing does, and the wording that suggested otherwise
(`memex-ingest` step 6, `getting-started.md`, and the "one concept per file"
line in `README.md` / § Node Types) was corrected in the same change.

### Phase 3 — Evidence layer *(complete)*

See `_meta/deep-extract-design.md`. Summary: a new `extracts/` node type, one file
per deep-extracted source, holding quote-grounded claims addressable by Obsidian
block reference. A `memex-deep-extract` skill with `extract` and `promote` modes.
A grounding check in `lint.sh` that `grep -F`s every claim's verbatim quote
against the normalized `.archive/` text — making fabrication mechanically
detectable, which is only meaningful because Phase 0 made `FAIL` a real gate.

*OKF addendum:* `extracts/` gets `type: Extract` and a `description:`, registered
in `_meta/domain.md` with the rest. Record in `deep-extract-design.md` that
extract claims map onto OKF §5.1 footnote-keyed per-claim attribution
(`[^source-id]` joined to `sources[].id`) — the planned block-reference addressing
is the same idea, and the exporter renders one as the other. No design change;
recorded so Phase 8 does not reinvent it.

#### Design calls made during implementation (2026-08-25, confirmed with the user)

Five conflicts between `deep-extract-design.md` and this roadmap, resolved before
building. All five are reflected in the code and docs.

> The canonical write-up is now `_meta/deep-extract-design.md` § Implementation
> decisions, which carries these five plus a sixth found while testing — the lint
> section 5 clone case below. The summaries here are kept because the *conflict*
> was between the two documents, and this is the other side of it.

1. **Archive normalization gets its own script.** `memex-ingest` already wrote
   `.archive/` files with no normalization, so any extract taken from an
   ingest-written archive would have thrown false grounding FAILs. New
   `_meta/normalize.sh` (bash/awk, deterministic, idempotent); *every* skill that
   writes an archive pipes through it. Rejected: having deep-extract normalize in
   place on first use, which would leave the guarantee dependent on which skill
   saved the file.
2. **Anki is deferred entirely to Phase 5.** The design doc's change list included
   `anki/.gitkeep`, the `.obsidian/app.json` exclusion, and the `memex-compose`
   render mode; the roadmap makes Anki its own phase. Roadmap wins — Phase 3
   touches nothing Anki-related.
3. **The confidence rubric (P2) landed here, not in Phase 4.** Extracts make it
   expressible, so it was written while the schema was open. **Phase 4 therefore
   shrinks to the `memex-trust-audit` rebuild** — `related::` promotion already
   landed in Phase 1, so that phase now has one item.
4. **`grounded:` and `source:` dropped from extract frontmatter.** `grounded: true`
   is a cached lint verdict stored in the file it judges: it goes stale, and a
   fabricating writer can simply assert it. `source:` was a third copy of a fact
   the filename and `extracted-from::` already carry. `medium:` was dropped on the
   same reasoning. `claims:` survives with a lint cross-check, because Dataview
   cannot count block ids.
5. **Extract filenames take an `ext-` prefix.** The design mandated mirroring the
   source filename *exactly*, which collides head-on with Phase 2's own
   Disambiguation Policy — Obsidian resolves wikilinks by filename, so every
   `cites:: [[<source-slug>]]` already on an atom would silently go ambiguous the
   moment its extract appeared. Confirmed in a fixture: two files, one name.
   `extracts/ext-<source-slug>.md`.

#### Defect found while implementing

**`_meta/lint.sh` section 5 failed every fresh clone.** `.archive/` is gitignored,
so a clone has none of it, and the archive-mismatch check FAILed on the first
`raw::` it met — the exact trap `deep-extract-design.md` argues the *grounding*
check must avoid, already live one section earlier since Phase 0. Now split: if
`.archive/` is absent entirely that is the clone case and SKIPs; a file missing
while the folder exists is a real mismatch and still FAILs. The gate is preserved
everywhere it means anything.

#### What shipped

Branch `phase-3-evidence-layer`, merged to `main`. `bash _meta/lint.sh` exits 0.

- `_meta/normalize.sh` — new. Idempotence and folding tested against hyphenated
  line breaks, soft hyphens, ligatures, smart quotes, nested lists, code fences.
- `_templates/extract.md`, `extracts/.gitkeep` — new.
- `_meta/domain.md` — `extracts|Extract` in the OKF Types table.
- `_meta/schema.md` — Extract node type; `extracted-from::` / `mentions::`
  (also added to Valid Relation Fields); block anchors on `cites::`; new
  § Extract Claims; **rewritten § Confidence Values** (independent-claims rubric,
  inferred source tiers, `medium` cap without extracts); Archive section rewritten
  around `normalize.sh`; `ext-` in Naming Conventions; orphan definition now names
  `extracts/` as non-curated.
- `_meta/lint.sh` — section 2 extract fields; **section 5 clone fix**; section 7e
  scans `extracts/`; **new section 12** (12a `extracted-from::` resolves + filename
  matches, 12b `claims:` cross-check + duplicate ids, 12c every claim has a quote,
  12d `grep -F` grounding with ellipsis hint, 12e dangling block anchors,
  12f `high` without block-anchored `cites::`); extracts in the summary counts.
  Verified in a fixture vault: positive grounds, fabricated quote FAILs with
  exit 1, absent `.archive/` SKIPs with exit 0, missing-file-in-present-folder
  FAILs, `claims:` drift and duplicate ids fire.
- `_meta/index.md` — `## Extracts`, "extracts with unpromoted claims", "processed
  sources with no extract"; `extracts` added to the provenance and missing-`type:`
  queries; a pointer to lint 12f where Dataview cannot see block subpaths.
- `skills/memex-deep-extract/SKILL.md` — new, both modes.
- `skills/*/references/vault-schema.md` — 14 copies, byte-identical (verified:
  one md5).
- `skills/memex-ingest/SKILL.md` — archives written through `normalize.sh`.
- `skills/memex-search/SKILL.md` — extracts as a gap-finding surface only.
- `skills/memex-trust-audit/SKILL.md` — UNGROUNDED finding, independence test,
  extract-existence check on G13.
- `skills/memex-stale/SKILL.md` — Check 4, processed sources never extracted.
- `README.md` — layer diagram, folder tree, node types, `ext-` rationale, skill
  lifecycle and reference table, graph colouring, archival section.
- `_meta/deep-extract-design.md` — corrected to match what shipped, with an
  § Implementation decisions section recording all six divergences, an § OKF
  correspondence section for Phase 8, and both Open questions resolved.

**Still unverified, carried forward from Phases 1–2:** no Dataview query in
`_meta/index.md` has ever been executed — no Obsidian here, and the vault has 0
atoms and 0 extracts. The three new extract queries use the `meta(l).path` inlinks
idiom already present in the file, but they are unrun. **This is the first thing
to check when the vault is next opened in Obsidian.**

### Phase 4 — `memex-trust-audit` rebuild *(complete)*

**This phase came down to one item.** Both of its original two landed early: the
confidence rubric was written in Phase 3, where extracts first made it
expressible, and the `related::` promotion pass went in with Phase 1's
`memex-reconcile` rewrite. What was left was the skill that consumes the rubric —
and, as it turned out, five lint checks that had quietly stopped agreeing with it.

1. ~~`_meta/schema.md` — confidence derives from independent claims across
   independent sources; source-type weighting (peer-reviewed > preprint > curated
   blog > unreviewed post) as a secondary term.~~ **Done in Phase 3**, as
   `_meta/schema.md` § Confidence Values. Source tiers are *inferred* at audit
   time rather than stored — see the OKF addendum below, which is why.
2. ~~`skills/memex-reconcile/SKILL.md` — `related::` promotion pass for links
   older than 30 days.~~ **Done in Phase 1.**
3. ~~`skills/memex-trust-audit/SKILL.md` — rebuild checks on the claim-count
   rubric, and become the writer of `verified:` entries
   (`{ by: human:<id>, at: <date> }` on human sign-off), using the field defined
   in Phase 2.~~ **Done.**

#### What shipped

- `skills/memex-trust-audit/SKILL.md` — rebuilt. The six-check threshold table is
  replaced by *gather evidence → compute justified confidence → compare to
  declared*: citations are split into claims and bare sources, every block anchor
  is resolved through its extract's `extracted-from::`, sources are grouped by
  the independence test, and tiers are inferred per group. Findings fall out of
  the comparison. New: CONTRADICTED, NEVER VERIFIED, STALE SIGN-OFF.
- **The sign-off pass is new** — step 7, and the vault's only writer of
  `verified:`. Its first rule is that the skill may never write an entry on its
  own judgement: `human:<id>` asserts a named person read the atom, and inferring
  that from an audit result forges a record about a human. Sign-off is asked
  separately from `confidence:`, offered only for atoms actually examined that
  session, and never bumps `updated:`.
- `_meta/schema.md` § `verified:` — three normative rules (append-only, does not
  touch `updated:`, asked separately from `confidence:`), plus the stale-sign-off
  definition. Propagated to all 14 `skills/*/references/vault-schema.md` copies
  (verified: one md5).
- `_meta/lint.sh` — new **section 13** (13a `generated:` shape and actor form,
  13b `verified:` list shape and `human:` requirement, 13c stale sign-off); new
  **8e**, `high` with a live `contradicts::`/`refutes::`, which is the rubric's
  third requirement for `high` and had gone unchecked since Phase 3.
- `_meta/index.md` — a stale-sign-off query beside the never-verified one.
- `README.md` — `verified:` semantics, skill map, and trigger table.

#### Defect found while implementing

**Four lint checks could not see through an extract citation.** 7c, 7d, 8b and 8c
each resolved `cites::` targets straight against `sources/`, which was correct
until Phase 3 made `cites:: [[ext-slug#^cNN]]` the *preferred* form for
well-grounded atoms. On any atom citing an extract they resolved nothing: 7d and
8c then reported "all cited sources are stage: unread" on atoms whose sources
were processed — a false positive aimed squarely at the best-cited notes in the
vault — while 7c and 8b silently under-reported. 8a had the mirror problem: it
counted `cites::` *lines*, so three anchors into one extract read as three
sources and let a `low`-grade atom sit at `high`.

All five now share one `backing_sources()` helper that resolves anchors through
`extracted-from::` and deduplicates. Independence is deliberately *not* tested
there — it is a judgement, `memex-trust-audit` owns it, and the lint count is
an upper bound that can only under-report.

**`lint.sh` could exit 1 without reaching a verdict.** An unguarded `grep` inside
a command substitution in the new section 13 tripped `pipefail` and `set -e`; the
script died mid-section and returned 1 — which since Phase 0 means "this vault
has a FAIL." A linter bug was indistinguishable from vault corruption, and the
fixture that caught it looked exactly like a genuine failure. Fixed, and guarded:
an early exit now returns **2** with a message saying it is a bug in the linter,
so exit 1 keeps meaning what Phase 0 made it mean.

*OKF addendum:* the source-type weighting in step 1 is this vault's credibility
signal. OKF §5.1 stores exactly that — objective per-source signals (`author`,
`usage_count`, `last_modified`) — and explicitly refuses to store a score, on the
grounds that a score is subjective, unportable, and goes stale. That is P2's own
conclusion reached independently, so name the frontmatter fields to match rather
than inventing parallel ones.

### Phase 5 — Anki *(deferred, unscheduled)*

**Deferred 2026-08-25 at the user's call:** a low-priority idea, unlikely to be
revisited before more critical components are refactored. Nothing is lost by
waiting — the design below is complete, and its one real dependency (extract
claims to make cards from) landed in Phase 3, so this can be picked up whenever
it is wanted rather than needing to be re-derived.

Two notes for whoever resumes it. The **glossary half has no dependency at all**
— Basic cards from `stage: reviewed` terms work against today's vault — so it is
shippable on its own if the claim half still looks like too much. And Phase 6 no
longer scaffolds `anki/`; if this lands, `memex-init` needs that folder and its
`.obsidian/app.json` exclusion added back.

The design, unchanged:

`memex-compose` gains an `anki` render mode writing Obsidian_to_Anki plain text to
a versioned top-level `anki/`. Cloze cards from extract claims, Basic cards from
`stage: reviewed` glossary terms. Every card back carries the source link and the
verbatim quote. Card identity keys off the extract block id, so the plugin's
`<!--ID:-->` writeback makes re-export an update rather than a duplicate.

`_exports/` is unsuitable: `.gitignore` excludes the directory, so a
`!_exports/anki/` negation cannot re-include anything, and the note IDs are
durable state rather than an ephemeral render.

### Phase 6 — `memex-init` *(complete)*

Interactive one-time specialization skill. Five questions (domain name, source
types, projects?, research questions?, initial tags) → write `_meta/domain.md`,
create a first topic stub, scaffold `extracts/`, update `getting-started.md`,
log the run.

`anki/` was on that scaffold list until Phase 5 was deferred. Scaffolding a
folder for a feature that may never ship leaves every generated vault with an
empty directory nothing writes to — add it back if and when Phase 5 lands.

*Phase 3 addendum:* scaffolding `extracts/` is not just the folder. A generated
vault also needs `_templates/extract.md`, the `extracts|Extract` row in the
generated `_meta/domain.md` § OKF Types, and the **`ext-<source-slug>` naming
rule** stated in the onboarding text — the prefix exists to keep extracts from
colliding with their own sources under Obsidian's filename-based wikilink
resolution, so a fork that drops it breaks every `cites::` the first time an
extract appears. See `_meta/deep-extract-design.md` § Implementation decisions 5.

Constraints: does not delete unused folders, does not modify `schema.md`,
re-runnable without overwriting the topic stub.

*OKF addendum:* also scaffolds the `okf_types` block in the generated
`_meta/domain.md` and adds `_okf/` to Obsidian's excluded-files list (see the
warning in Phase 8). ~~creates `_okf/`~~ — **superseded during implementation**:
the exclusion is written, the folder is not. See *Decisions* below.

*Plugin addendum (audit, 2026-08-25):* the onboarding text must state the
corrected plugin contract, not the pre-Phase-4 one. **Dataview is the only hard
requirement**, and core **Bases** does not replace it — Bases reads YAML
frontmatter, while every typed relation in this schema is a Dataview inline field
in the note body. Core **Canvas** matters only if the fork keeps `canvas/`.
**Templater is optional**: the shipped templates use only `tp.date.now` and
`tp.file.title`, both of which have core-Templates equivalents, and the skills
replace the placeholders themselves rather than invoking either plugin.
`memex-init` must **not** tell a fork to install **Folder Notes** or **Graph
Analysis** — both were listed as required through Phase 4 with zero dependents
anywhere in `_meta/`, `_templates/`, or the skills, and Graph Analysis has had no
release since January 2022. A fork that installs the old list pays four plugin
dependencies for one real one. See `README.md` § Obsidian Plugins.


**What shipped.**

1. `skills/memex-init/SKILL.md` — five questions (domain name, source types,
   projects?, research questions?, initial tags), then: rewrite the four
   instance-specific fenced blocks of `_meta/domain.md` **in place**, scaffold one
   `sources/<medium>/` per declared type, seed one concept map, rewrite
   `getting-started.md`, add the `_okf` exclusion, run lint, log. No
   `references/` directory and no fifteenth `vault-schema.md` copy — the skill
   writes vocabulary, not typed nodes, and the sync burden is real.
2. **All 18 pre-existing skills made path-independent.** They hard-coded
   `/home/bcmcpher/Projects/claude/memex-vault` on 54 lines, so a fork's skills
   pointed at the template author's vault — the actual thing that broke a fork,
   and not on any list. Now `VAULT="${MEMEX_VAULT:-$(git rev-parse --show-toplevel)}"`,
   with the header of each skill saying so. `README.md`'s "editing **one file**"
   promise is true as of this phase; it was not before.
3. `_meta/lint.sh` sections 1 and 2 read § Source Types from `_meta/domain.md`
   instead of the literal `web video paper docs meeting`. A fork adding
   `sources/hearing/` got **zero** filename or frontmatter checking, silently,
   while `README.md` claimed lint reads all vocabulary from `domain.md`. Two new
   WARNs close both halves of the mismatch: a declared type with no folder, and a
   folder under `sources/` that § Source Types never declares. Falls back to the
   shipped five if the block is missing, so a half-edited `domain.md` degrades to
   the old behaviour rather than checking nothing.
4. `topics/concepts/getting-started.md` — the "Creating a new source" list named
   five templates (`source-web`, `source-video`, `source-paper`, `source-docs`,
   `source-meeting`). Four of them have never existed: there are two source
   templates and `medium:` is per note. Fixed, since `memex-init` step 10 rewrites
   this section and would have propagated the error into every fork.
5. `_meta/domain.md` § Source Types — documents the contract lint now enforces,
   and records that **`meeting` is the one reserved medium name** (checked for
   `date:` rather than `url:`/`saved:`).

**Decisions.**

- **`_okf/` is not scaffolded, only excluded.** The roadmap said create it; that
  contradicts the reasoning used to drop `anki/` one commit earlier. The
  *exclusion* is what is ordering-sensitive — it has to exist before the first
  export, or every note appears twice in search and graph. The folder is the
  exporter's to create. Same argument, same answer, now applied consistently.
- **`memex-init` does not call `memex-topic-init`.** That skill's value is
  searching existing atoms and sources; a fresh fork has none, so it would run
  five searches over empty folders to produce the same stub. Delegation would cost
  tokens and return less.
- **Nothing is ever deleted.** A dropped source type keeps its folder and earns a
  WARN. Deleting an empty folder is free; deleting one that turned out to hold
  notes is not, and the skill cannot tell the difference under `.gitignore`.
- **`_meta/schema.md` is off limits**, stated twice in the skill. A fork that edits
  the constitution has forked the format, not the domain.

**Still unverified:** no fork has been run end to end. The skill's steps are
individually exercised — lint's new source-media path was fixture-tested against a
vault declaring `web`/`hearing` — but the five-question flow has never been walked
by a user. First real fork is the test.

### Phase 7 — `memex-tend` *(complete)*

Orchestration meta-skill. Sequences the maintenance skills after a batch ingest
and answers "what should I run now?" Must explicitly never auto-invoke
`memex-deep-extract`.

*OKF addendum:* sequences `memex-export` as a terminal step, and never before
`_meta/lint.sh` passes.

**What shipped.**

`skills/memex-tend/SKILL.md` — a router, not an author. It writes exactly one
thing, its own `_meta/log.md` entry; every vault change is made by the skill it
hands off to, under that skill's own confirmation rules.

1. **State comes from three executable sources**, not from `_meta/index.md`. The
   index is Dataview, which renders only inside Obsidian, and this skill runs where
   there is none. So: `_meta/lint.sh` for what is wrong, `_meta/candidates/` for
   what a previous session left unfinished, and `_meta/log.md` for when each skill
   last ran. One lint pass produces every signal, which is the efficiency argument
   for having an orchestrator at all — the alternative is five skills each scanning
   the vault to discover they have nothing to do.
2. **A routing table from lint section to skill**, covering all 13 sections.
   Findings with no skill are named as hand fixes rather than routed to a skill that
   cannot fix them — sections 1, 5, and 11 are mostly this.
3. **The order is a dependency chain, not a calendar.** `memex-candidates` first
   (unapplied proposals make every other skill read an incomplete vault), FAILs
   before any skill runs (a claim quoting text its source never contained makes
   trust-audit's evidence wrong, not merely incomplete), then connect → reconcile →
   trust-audit → conflicts → stale. Each step changes what the next one sees.
4. **Four modes**: triage (the default — report and stop), full pass, post-ingest,
   pre-share. Pre-share is the sequence `README.md` already recommended by hand.
5. **Re-lint after every writing skill**, and report the delta. A step that
   *increases* the finding count is a result, not an error: reconcile promoting
   `related::` to typed relations surfaces conflicts that were previously
   invisible.

**Decisions.**

- **Four skills are never invoked**, and the reasons differ. `memex-deep-extract` is
  the expensive one and the one lint 8 actively tempts an orchestrator toward — the
  under-extracted-source WARN is exactly the signal that would justify firing it, so
  the prohibition had to be written where that signal is routed, not only in a
  preamble. `memex-compose` is publishing, not maintenance. `memex-refactor` makes
  irreversible judgement calls about what a concept *is*. `memex-init` already ran.
- **Triage is the default mode.** "What should I run now?" is answered with a plan
  and a stop, not with a plan and a chain. The value of an orchestrator is deciding
  whether to spend the tokens, which it cannot do by spending them.
- **Proposing nothing is a valid outcome.** Skills whose lint sections are clean are
  marked skipped and not proposed. An eight-step plan on a healthy vault teaches the
  user to ignore the skill.

**Still unverified:** the routing table is written against lint's current 13
sections and was checked against real output on a fixture vault, but no tend pass
has been run on a vault with enough findings to exercise the ordering. The vault has
0 atoms.

### Phase 8 — OKF export layer

Full design in `_meta/okf-alignment.md`. Summary: `_meta/okf-export.py`, Python 3
stdlib only, no LLM, deterministic — same invocation ergonomics and same `exit 1`
discipline as `lint.sh`.

```
python3 _meta/okf-export.py [--out _okf] [--include-archive]
```

Every OKF field is computed from what the vault already holds; nothing is
hand-maintained and nothing is duplicated into frontmatter. The four things
Obsidian needs — wikilinks, date-only timestamps, Dataview indices, typed
relations — are *translated* here rather than changed in place: wikilinks become
bundle-relative markdown links, dates gain `T00:00:00Z`, `index.md` is generated
per directory from `title` + `description`, and typed relations render as labelled
bullets under a `# Relations` heading. `sources[]` is derived from `cites::`,
`rebuts::`, and `raw::`; duplicating it into frontmatter would recreate exactly
the P1 sync problem Phase 1 exists to remove.

*Phase 3 addendum, two items.* **(a)** `extracts/` now exists and the exporter
must carry it: extract claims map onto OKF §5.1 footnote-keyed per-claim
attribution — `^c07` becomes the footnote key, `extracted-from::` resolves to the
`sources[].id`, and the claim's `quote:` sub-bullet becomes the footnote body.
Block-reference addressing and footnote attribution are the same idea, so this is
a rendering, not a redesign; the correspondence is written up in
`_meta/deep-extract-design.md` § OKF correspondence. **(b)** `_meta/normalize.sh`
already exists and is the vault's canonical text-folding implementation. The
exporter must call it or leave normalization alone entirely — a second,
Python-side copy of the folding rules would drift from the one lint greps
against, and the grounding guarantee is only worth what that agreement is worth.

Then a thin `skills/memex-export/SKILL.md` wrapping the script: run `lint.sh`
first, refuse to export a failing vault, run the exporter, write a `_meta/log.md`
entry. No generative work — the skill is a guard rail, not an author.

> **Hard requirement.** `_okf/` is a full second copy of every note and **must**
> be added to Obsidian's *Settings → Files & Links → Excluded files*, or every
> note appears twice in search, quick-switcher, graph view, and every Dataview
> query. This is the one way the OKF work could regress Obsidian functionality.
>
> *Phase 6 status:* `memex-init` now writes that exclusion into
> `.obsidian/app.json` at fork time, before anything can export. **The exporter
> creates `_okf/` itself on first run** — Phase 6 deliberately does not scaffold
> the empty folder. The exporter must therefore `mkdir -p` its own output, and
> must also verify the exclusion is present in a vault that predates `memex-init`,
> refusing to export rather than silently doubling the vault.

**Verification:** export, then assert §11's three MUSTs mechanically — every
non-reserved `.md` under `_okf/` has parseable frontmatter with a non-empty
`type:`; the root `index.md` carries `okf_version: "0.2"` and no other
frontmatter; `log.md` headings all match `^## \d{4}-\d{2}-\d{2}$`. Then: zero
`[[...]]` remain anywhere under `_okf/`; every markdown link target resolves in
the bundle or is an absolute URL; and exporting twice to separate directories
gives a clean `diff -r`, which is what proves determinism.

### Phase 9 — OKF import *(deferred)*

The other half of the IO layer. A `memex-import` skill consuming a third-party
OKF bundle: each concept becomes a source note under `sources/`, `sources[]`
entries become `cites::`, and `type:` routes to the right folder.

Deferred because it has no consumer yet and its shape depends on what real-world
OKF bundles look like once the format has adoption. Blocks nothing.
