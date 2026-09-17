# memex-vault Improvement Roadmap

Revised: 2026-09-17 for `v1.0.0-rc.2`. **This is the first revision to live in the
template**, and it does three things. It carries the 2026-09-11 revision across from
the brain-connectivity fork — M6–M22, § The RC-2 seed corpus, and the discharged
verification-debt rows; before this, the template's copy stopped at M5 while skills
in it already cited M8, M11, M13, M14 and M21. It gives every finding a status
marker. And it **splits the file in two**, so that what is open is separable from
what shipped.

Superseded 2026-09-11 (fork), which superseded 2026-09-02, which added § Release
Status for `v1.0.0-rc.1`; the tier 0–2 findings and phase detail are from the
2026-08-25 revision, which superseded 2026-07-09, which superseded 2026-05-07.

M11–M22 differ in kind from everything above them: they are the first findings
sourced from running the skills over real notes rather than from reading them.
Every one names the measurement it rests on.

**Two files.** This one holds what is **open**: sixteen `R` rows in § Open Work,
plus the release state, the phase sequence, and what trial 2 is for.
`_meta/roadmap-applied.md` holds what **shipped**: 25 applied findings under their
original labels, the seven completed phases, and the retired verification-debt
rows. The split happened at `rc.2` because 25 of 43 findings were applied and they
were most of the file's length, so the one question it gets opened for — *what is
still open?* — was the hardest to answer from it. § Renumbering carries the full
old→new mapping, and explains the one deliberate inconsistency: applied labels kept
their names.

**A bare label inside prose is the original numbering.** Both files argue by
cross-reference — `M19` explains why `M6`'s proposed fix would misfire, `M11a`
points at `M8`, `E1` absorbed `P2` — and rewriting every one of those sentences
into `R` numbers would have meant re-editing arguments to change a name. So
`L S E P M O` labels appearing mid-sentence mean what they always meant.
§ Renumbering says which of the two files each one now lives in; the rule of thumb
is that anything not in that table is applied.

**Reading the status markers.** Every finding in either file carries one, in
italics, directly after its label:

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
comparison against `claude-obsidian`, with a verdict on every difference. Its seven
Roadmap verdicts are `R8`–`R13` and `R2` below; `R14` is salvaged from a difference
that was otherwise declined.

`_meta/rc-2-plan.md` holds the execution order that produced `v1.0.0-rc.2`. It is a
working document, to be deleted once the tag has landed **and** trial 2 has started
— its § Verification is what trial 2 checks the tag against, so it outlives the tag
by one step. This file and `CHANGELOG.md` are the durable record. `_meta/skill-evaluation.md` ships as an empty scaffold: trial
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
recorded in `_meta/roadmap-applied.md` § Verification debt — retired. Four things
were built and passed against fixtures but had never run over real notes, and that
could not change inside this repository — it is a template and ships with zero notes
deliberately. The debt was discharged in the first fork that put real content
through the skills, which is exactly what an RC is for.

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

## Open Work

Sixteen rows. This is everything that is not done, plus two rows kept as a record
of a decision so a later trial does not re-derive it. Applied findings are in
`_meta/roadmap-applied.md` — 25 of them, with their full arguments and their
original labels.

**`R` numbers are identifiers, not an order.** They group by where the work came
from: `R1` is the one scheduled build; `R2`–`R7` come from this vault's own history,
the trial-1 campaign and the earlier design reviews; `R8`–`R14` come from the
`claude-obsidian` comparison and are *recorded, not scheduled* — the user evaluates
them alongside other pending plans once RC-2 is finished; `R15`–`R16` are decided
and closed. Nothing here is ranked, and none of it is in § Implementation Order,
which stops at the phases.

Status markers are defined in the header. Every row names the evidence that the
problem is real — for the comparison rows, "claude-obsidian has it" was not
accepted as evidence anywhere in that document.

### R1 — the one scheduled build

**R1. The vault has no interchange format.** *Open — Phase 8, the only unblocked phase. Ships as `v1.1.0`, not as part of `v1.0.0`.* Wikilinks, Dataview-backed indices,
date-only timestamps, and typed relations are all load-bearing for Obsidian and
all unreadable outside it. Nothing can consume this vault but Obsidian and the
memex skills.

*Fix:* a deterministic export layer (Phase 8) that translates rather than
changes. Import (Phase 9) is the other half, deferred.

### R2–R7 — from this vault's own history

**R2. A source has no version model, re-rendering is indistinguishable from
revision, and no content hash exists to tell them apart.** *Deferred — needs
trial-2 drift data to calibrate. Was `M6` + `M19` + comparison verdict 1 (`F1`).*

**These were three rows for one problem**, which is the clearest example of what
the old numbering could not express. `M6` said a work exists as several
near-identical documents and `raw::` does not say which. `M19` said the quotes
`M6`'s proposed reconcile step would compare are archive-format-specific, so that
step generates noise on exactly the case it was built for. The `claude-obsidian`
comparison then said the missing primitive underneath both is a content hash. Read
as one finding: **memex cannot distinguish a paper that changed from an archive
that was re-rendered, and has no field that would let it.**

*The cheapest first step*, from the comparison: record the archive's SHA-256 at
capture time. One `sha256sum` per archive, and drift becomes detectable before
anything is done about it. It is not free — it touches the schema, four capture
skills and `lint.sh` — which is why it did not land in `rc.2` Stage 8.

The three original statements follow unchanged, because each carries evidence the
others do not.

#### (a) No version model on sources — preprint vs version of record

*Originally M6.* No version model on sources — preprint vs version of record.** *Deferred — needs trial-2 drift data to calibrate, and M19 shows why: a reconcile step that cannot tell re-rendering from revision is noise. See F1.* A work
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

#### (b) Quote grounding is archive-format-specific

*Originally M19.* Quote grounding is archive-format-specific, so re-grounding reports drift
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

#### (c) The missing primitive: a content hash

*Originally F1.* No version model on sources, and no content hash to detect drift.**
*Deferred — this is M6 + M19, not a new finding.* Their design hashes every payload
and carries `review_state: unreviewed | active | superseded | rejected` plus
`refresh_due`; superseding is a state change that preserves lineage. memex's `raw::`
names one archive and records nothing about which rendering or which version it is.
M19 is the live instance: 8 of 41 quotes stopped matching on re-retrieval while the
paper had not changed. The one addition the comparison makes is a **cheap first
slice** — record the archive's SHA-256 at capture time, which costs one `sha256sum`
and makes drift detectable before anything is done about it. Carry it into M6 as
step one.

**R3. Conceptual extraction from code repositories.** *Deferred — design written, not built. `rc.2` Stage 5 bounded it instead: `memex-stale` Check 4 now lists `medium: code` apart with no route, rather than recommending an operation nothing has designed.* `memex-deep-extract` assumes
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

**R4. Zotero as the first retrieval tier, with attachment validation.** *Partially applied — the load-bearing half shipped. `_meta/validate-archive.sh` landed in `rc.2` Stage 1 and was recalibrated in Stage 3; the Zotero lookup tier did not, and no skill consults a local library. The RC-2 corpus was retrieved half by Zotero and half by `opencite` by hand.*
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

**R5. No temporal model on claims — now tractable.** *Deferred — became cheap once Phase 3 existed, and blocks nothing.* `supersedes::` handles atom
replacement, not time-bounded claims. Claims finally have a home: Hyper-Extract
carries `t_start` / `t_end` / `t_obs` per fact, and extract claims can carry the
same without imposing decay on atoms, which `memex-stale` deliberately refuses.

**R6. No first-class open questions.** *Deferred — became cheap once Phase 3 existed, and blocks nothing.* `rq-*.md` is heavyweight. Extracts could
type an `open-question` claim, giving atom-level questions a home.

**R7. No worked example.** *Deferred — by the design decision above; no worked example ships, and none is planned.*

### R8–R14 — from the claude-obsidian comparison, recorded not scheduled

*Added 2026-09-17, `rc.2` Stage 7.* `claude-obsidian`
(<https://github.com/AgriciDaniel/claude-obsidian>) does the same job as memex with
a different design. `_meta/comparison-claude-obsidian.md` compares the two at pinned
commit `32ac5a0` (v2.2.0, 2026-09-10) and gives a verdict on each of fifteen
differences: **3 were adopted into `rc.2`, 5 were declined with the principle named,
and 7 were recorded as roadmap work.** Those seven are `R8`–`R13`, plus `R2`, which
turned out to be M6 and M19 restated. `R14` is not one of the fifteen — it is the one
piece worth taking from a difference that was otherwise declined (product and vault
as separate checkouts, comparison verdict 12), salvaged rather than lost.

*"They" below is claude-obsidian at that commit.* Every row names the evidence that
**memex** has the problem; "they have it" was not accepted as evidence anywhere in
that document, which is why five of the fifteen are declines and not rows here.

**R8. Multi-file writes are not transactional.** *Deferred — architectural. Put to
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

**R9. `lint.sh` has no test suite and no CI.** *Deferred — new scope in the stage
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

**R10. Sources carry no authority.** *Deferred — pending evidence that memex has the
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

**R11. There is no bounded session context.** *Deferred — pending evidence.* Their
`wiki/hot.md` is a short, sanitized cache of recent facts, changed pages and open
threads, explicitly "not a transcript", with a rule that it must not carry claims
less qualified than the canonical page they came from. Hooks read it and never write
it. memex has no equivalent and every session starts cold, re-reading
`references/vault-schema.md`. That is a real cost with no recorded finding behind it,
and the fix creates a second home for a claim — the failure mode their own schema had
to write a rule against. Wants a trial-2 observation that the cold start actually
costs something.

**R12. `_meta/log.md` grows without bound.** *Deferred — not binding yet.* Their
`wiki-fold` builds bounded, extractive, idempotent rollups of log entries in powers
of two: additive only, never rewriting child entries, dry-run by default. memex's log
is **46 KB after one trial**, `memex-log-query` reads it, and nothing compacts it at
a rate of one entry per capture. Two properties of their design are the ones worth
copying when this does bind: **no fold-of-folds, and never automatic.** Those are
what keep a rollup from becoming a lossy rewrite of the record.

**R13. Retrieval is a graph walk and a grep.** *Deferred — measure before buying.*
They build contextual chunks and a stdlib BM25 index in a disposable cache, with
optional local reranking, and the index is invalidated before its chunk set changes
so a partial index is never served. memex's `memex-search` walks the topic tree and
greps. **Two of the three known causes for wanting an index are already gone:** M21,
the flat topic layer that blinded search, was fixed in Stage 4, and M16, lint at 22 s
extrapolating to 15–25 minutes at 200 sources, was fixed in Stage 3. What remains is
that the grep path is untested above ~16 sources. A derived index is state that can
go stale, and this vault's working principle is that the notes are the only state —
so the cost is real and the need is unmeasured.

**R14. Nothing checks that `$VAULT` is a memex vault before writing to it.**
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

### R15–R16 — decided, kept as a record

**R15. The glossary was empty because the wrong skills were looking for the wrong
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

**R16. Graph node labels are filenames, and nothing in Obsidian's core settings
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

---

## Renumbering

*2026-09-17.* The findings convention was six prefixes — `L S E P M O F` — whose
meanings appeared nowhere, with `M` spanning two tiers, numbers ordered by
discovery rather than anything useful, ad-hoc sub-letters, no status field, and no
way to say that two findings were one. It is now one prefix for open work and one
file for applied work.

| New | Was | Status |
|---|---|---|
| `R1` | `O3` | Open |
| `R2` | `M6` + `M19` + `F1` | Deferred |
| `R3` | `M8` | Deferred |
| `R4` | `M10` | Partially applied |
| `R5` | `M3` | Deferred |
| `R6` | `M4` | Deferred |
| `R7` | `S2` | Deferred |
| `R8` | `F2` | Deferred — architectural |
| `R9` | `F3` | Deferred |
| `R10` | `F4` | Deferred — pending evidence |
| `R11` | `F5` | Deferred — pending evidence |
| `R12` | `F6` | Deferred |
| `R13` | `F7` | Deferred |
| `R14` | `F8` | Deferred |
| `R15` | `M7` | Closed |
| `R16` | `M22` | Accepted |

Everything not in that table is applied and lives in `_meta/roadmap-applied.md`
under its original label: `L1 L2 S1 S3 E1 P1 P2 P3 P4 M1 M2 M5 M9 M11 M12 M13 M14
M15 M16 M17 M18 M20 M21 O1 O2`.

**Applied labels were not renumbered**, and that is the one deliberate
inconsistency here. Nine of the ten labels cited from code are applied ones —
`lint.sh` alone cites `M11a`, `M11c`, `M16`, `M18` and `M20` in comments that
explain why the code is shaped as it is. Renaming them would have meant editing
sixteen citation sites to point at a file whose entries say less than the comments
already do. The cost of the inconsistency is one sentence of explanation; the cost
of the alternative was losing the reason the citations exist.

**Phase numbers are unaffected** and are not reassigned, for the reason
§ Implementation Order already gives: they are cited across
`_meta/deep-extract-design.md`, `_meta/okf-alignment.md`, several skill files and
every commit message in the history.

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


## Phase Detail

Only the phases that have not shipped. Phases 0–4, 6 and 7 are complete and their
detail is in `_meta/roadmap-applied.md` § Completed phases; § Implementation Order
above keeps the whole table, including those, so the sequence stays readable in one
place. Phase numbers are never reassigned.


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
