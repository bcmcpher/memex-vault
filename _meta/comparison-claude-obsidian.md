# memex vs claude-obsidian — a conceptual comparison

Written 2026-09-17 for RC-2 Stage 7 (`_meta/rc-2-plan.md` § Stage 7).
Infrastructure doc — not a vault node. No frontmatter, and nothing should link to
it with a wikilink.

`claude-obsidian` (<https://github.com/AgriciDaniel/claude-obsidian>) is a widely
used vault-plus-skills system that does the same job as memex with a different
design. This file exists because RC-2 Decision 4 says every known finding is
dispositioned before the trial: an undecided difference is an issue trial 2 would
re-report as new. So every difference below carries a verdict, including the ones
that are declined.

**Pinned.** Everything here was read at commit
`32ac5a02c4e082e4a5628ca810776375e134708e` — v2.2.0, committed 2026-09-10, cloned
to `/tmp/claude-obsidian`. The project moves fast; a verdict against a later
release is a different verdict, and re-running this comparison means re-pinning.

**Scope.** Organization, evidence model and write safety. Not a feature count.
No code is ported by this stage; every **Adopt** below is a separate commit.

---

## What was actually read

Their v2.2.0 is 15 skills, a 24 KB-line Python package (`claude_obsidian/`,
17 modules), 8 helper scripts, 534 test functions across 40 test files, and one
GitHub Actions workflow. The documents that define the design are `WIKI.md` (the
vault schema), `skills/wiki/references/provenance.md` (the evidence rules), and
`config/product-contract.json` (the release gates `claude_obsidian/gates.py`
executes).

Verification of memex's side was done on a throwaway clone of `rc-2`
(`/tmp/mx7`), never on the fork. Where a row below says *demonstrated*, a minimal
vault was built and `_meta/lint.sh` was run; the observed exit code and output are
quoted.

---

## Corrections to the Stage 7 dimension table

The plan's table came from a first read of their tree on 2026-09-15 and told us
to verify every cell. Five were incomplete or wrong.

| Plan said | Actually |
|---|---|
| Note ontology: "concepts, entities, sources, questions, comparisons; `overview.md`; `hot.md`" | Nine page types, declared once in `claude_obsidian/page_schema.py`: `source`, `entity`, `concept`, `question`, `comparison`, `session`, `overview`, `meta`, `fold`. Five are *routable* (a new page can be filed there); `comparison`, `overview`, `meta` and `fold` are valid frontmatter that only a dedicated operation creates. The split matters — it is how they keep a router from inventing a synthesis page. |
| Evidence: ledgers record "`independence_key`" | The key is **declared**, not derived. Independence is computed in `ledgers.py:797` `_independent_group_count()` by **union-find over connected components** — the same shape as memex's `lint.sh:281-426` `units()` — but its identity atoms are the declared key, the canonical origin URL, and the payload SHA-256. memex derives its atoms (person keys from `authors:`/`channel:`/`tool:`, plus `cites::` reach) from data already in the note. And the count only binds in one place: `ledgers.py:1130`, high-risk **accepted** claims need two independent sources. Nothing enforces it elsewhere. |
| Write safety: "an approved SHA-256" | Five mechanisms, not one: per-path `expected_hashes` preconditions, an `approval_sha256` that binds the expanded plan **to the canonically resolved vault root** so an approval cannot be replayed against another vault, a vault-wide `MutationLock` (`transaction.py:1366-1690`, POSIX `dirfd`-confined), a durable journal with `transaction recover`, and atomic per-file replace. |
| Hosts: "Claude Code, Codex, Gemini, OpenCode, Cursor, Windsurf" | Seven surfaces. `.claude-plugin/plugin.json` (Claude Code), `AGENTS.md` (the host-neutral contract every other file defers to), `GEMINI.md`, `ZCODE.md`, `.cursor/rules`, `.windsurf/rules`, and `.github/copilot-instructions.md`. There is **no `CLAUDE.md`** at their root — the plugin manifest serves that host. |
| Egress: "`autoresearch`, `defuddle`, explicit network consent" | Also `claude_obsidian/url_safety.py`, a side-effect-free check that refuses URLs carrying credentials in userinfo or in a sensitive query parameter (including vendor forms like `X-Amz-Signature`), and `config/adapters.json` `"privacy_default": "offline"` across seven capture adapters. Consent is per-tier: `wiki-retrieve`'s contextual prefixer requires `--allow-egress` **plus** stated consent before page bodies reach an API, and explicitly refuses to infer consent from an installed binary or a present API key. |

Everything else in the plan's table verified as written.

---

## Verdicts

Method, per `_meta/rc-2-plan.md` § Stage 7: name the problem their design solves,
check whether memex has that problem *with evidence*, give one verdict. "They have
it" is not evidence.

### 1. Unresolvable link targets — **Adopt in RC-2**

**Their design.** `lint_engine.py` reports `dead_links` and `ambiguous_targets`
across every link in the vault, resolved through one `_TargetIndex` that knows
basenames, vault-relative paths, headings and block ids.

**Does memex have it? Yes, and it is worse than a hygiene issue.** Demonstrated on
`/tmp/mx7`. `lint.sh` resolves a relation target in exactly two places: `part-of::`
on atoms (7a), and a `cites::` link whose anchor is **block-form** (`#^`). Every
other shape passes silently:

```
cites:: [[ghost]]            → 0 warnings, exit 0
cites:: [[ghost#Summary]]    → 0 warnings, exit 0
cites:: [[ghost#^c07]]       → WARN "but no such note"
related:: [[does-not-exist]] → 0 warnings, exit 0
supports:: [[ghost-atom]]    (on a source) → 0 warnings, exit 0
```

The anchor check only runs once the target file resolves, so an unresolvable
target skips it. And the failure is worse than silence: writing
`cites:: [[ghost-source#Summary]]` into an otherwise-isolated atom **suppressed**
the 4/6b orphan warning that was the only thing flagging it, because 6b counts
`cites::[[` occurrences and never resolves them (`lint.sh:719`). A fabricated
citation therefore reads as evidence *and* silences the check that would have
caught the atom. At `confidence: medium` — the template default in
`_templates/atom.md` — lint's whole output for that vault was empty and the exit
code was 0. Only `confidence: high` catches it, via section 8's independent-unit
count reaching zero.

**Why this is the one clear adopt.** memex's premise is that a claim is worth what
its grounding is worth. Section 12 verifies quote text against the archive and is
excellent — but it only covers `extracts/`. The `cites::` edge from an atom to a
source is the load-bearing link of the whole graph, and for two of its three
spellings nothing checks that the far end exists.

**Fix shape.** One resolve pass over every `[[…]]` target in every `^[a-z][a-z-]*::`
field on every layer, reusing the `NOTE_PATH`/`SRC_PATH`/`TOPIC_PATH` lookup tables
Stage 3 already built at `lint.sh:190`. No new traversal, no new dependency. Keep
the existing `#^` message; add the bare and `#Section` cases. Severity: WARN, to
match 7a — a dangling link is bad bookkeeping until a human decides which way to
repair it, and `memex-reconcile` already owns that repair for `part-of::`.
Re-run § Verification for Stages 3, 4 and 6.

### 2. Duplicate and same-origin sources — **Adopt in RC-2**

**Their design.** `_independent_group_count()` unions any two sources sharing a
canonical origin URL or a payload SHA-256, and `provenance.md` spells out that
IPv6, IDN, Unicode, dot-segment, default-port and percent-encoding spellings of
one URL are one origin.

**Does memex have it? Yes.** Demonstrated: two notes in `sources/web/` with a
byte-identical `url:` and no `authors:` field. `lint.sh` exit 0, and the summary
reads:

```
Independent units:     2 of 2 sources (2 with no authors:/channel:/tool:, unchecked)
```

The hedge is doing its job — "unchecked" keeps the number from reading as a
verdict, which is exactly what M15 built it for. But the duplicate itself is never
surfaced, and `url:` is the one field that makes it trivially detectable. The only
defenses are per-skill and unenforced: `memex-save` step 1 greps `sources/` for the
URL, `memex-seed` matches on `doi`, and `memex-ingest` has a *Common Mistakes*
bullet ("Don't ingest a source that's already in `sources/` under a different
filename") with no procedural step behind it. Three skills, three different
answers, nothing in the oracle.

This one bears directly on the vault's headline metric. Two copies of one paper
inflate `Independent units` by one, and section 8 reads that number to decide
whether `confidence: high` is earned.

**Fix shape.** A section 2 or 7 check: group `sources/**` by normalized `url:`,
WARN on any group larger than one, naming both paths. Normalization stays
deliberately shallow — lowercase scheme and host, strip a trailing slash, strip a
`#fragment`. Do not attempt their full canonicalization; percent-encoding rules are
where that gets subtle, and a shallow check that fires on the real case beats a
deep one nobody can audit in bash. Then make the three capture skills cite the
lint check instead of each carrying its own rule.

### 3. Credentials in a saved URL — **Adopt in RC-2**

**Their design.** `url_safety.py` refuses a URL with userinfo credentials or a
sensitive query key, and `WIKI.md` § Source invariants states it as a rule:
"Credentials do not belong in URLs, source notes, bundles, queues, or tracked
configuration."

**Does memex have it? Yes, with nothing anywhere.** Grepping `lint.sh`,
`memex-save` and `memex-ingest` for `token|credential|secret|api_key|userinfo`
returns zero matches. Demonstrated: a source note carrying
`url: https://example.org/post?access_token=SECRET123` lints clean at exit 0.

The consequence is specific to memex's design rather than generic: **the vault is
a git repository**, and `sources/` is tracked. A URL copied out of an authenticated
session — a signed S3 link, a Notion or Google Docs share token, a
`?api_key=` on a data endpoint — is committed, and rewriting history is the only
removal. claude-obsidian keeps user data outside a tracked product repo, so the
same mistake costs them less.

**Fix shape.** A section 2 check over `url:` on every source: WARN on userinfo
(`//user:pass@`) and on a query key matching a small, explicit list. Port the list
from `url_safety.py:11-50` rather than inventing one — it is short, and it already
covers the vendor-prefixed forms. Add one line to `memex-save` and `memex-connect`:
strip the credential and save the bare URL, or ask. Not a FAIL: a legitimate URL
can contain the substring `key`, and a false FAIL on capture is worse than a WARN
the operator reads.

### 4. Source versions and content drift — **Roadmap**

**Their design.** Every source carries a payload SHA-256 and a `review_state` of
`unreviewed | active | superseded | rejected`, with `refresh_due` for staleness.
Superseding is a state change, not a rewrite; lineage is preserved.

**Does memex have it? Yes — it is already M6 and M19, with a live instance.** M19
records that Cliff et al. 2023 was re-retrieved for the RC-2 corpus and **8 of the
41 trial-1 quotes no longer matched verbatim**, though the paper had not changed:
6 were whitespace or punctuation, 2 were the ar5iv doubled-maths artefact, and
**0 were version drift** — despite the archives being arXiv v1 and v2. memex has
no way to tell those apart, because `raw::` names one archive and records nothing
about which rendering or which version it is.

**Why not RC-2.** M6's fix is a `version:` field, a second archive pointer, and a
new `memex-deep-extract-reconcile` skill; M19 adds that the reconcile comparison
must run on normalized text or it generates pure noise on the exact case it was
built for. That is a stage, not a commit, and it lands after trial 2 has produced
the drift data that would calibrate it.

**One cheap slice, named so it is not lost.** Recording the archive's SHA-256 in
the source note at capture time costs one `sha256sum` per archive and makes drift
*detectable* even before anything is done about it. It is not RC-2 work — it
touches the schema, four capture skills and `lint.sh` days before a tag, and
Stage 6 has already amended the schema once. Carry it into M6 as the first step.

### 5. Transactional multi-file writes — **Roadmap** *(architectural — see § To put to the user)*

**Their design.** One logical mutation is one bundle: preconditions, a lock, a
journal, atomic replace, and `transaction recover` after an interrupted apply.
Parallel workers never apply; they return draft packets to one orchestrator.

**Does memex have part of it? Yes, and Stage 6 demonstrated the gap.** The
interruption drill killed a `memex-seed` run after 6 of 12 notes. Result: 6 notes
on disk, 12 archives, 6 candidates under one session id, **0 log entries — and
`lint.sh` exit 0**. Nothing in the vault records that a batch was half-applied.

memex is not empty-handed here. `memex-candidates` carries per-write preconditions
already: a create candidate refuses if the target exists (`memex-candidates:87`), a
modify candidate refuses if the line it replaces no longer matches
(`:107`). That is `expected_hashes` at line granularity, arrived at independently.
What is missing is the *grouping* — nothing makes the twelve notes and the one log
append succeed or fail together, and `memex-candidates:132` says so outright: it
does not validate whether a candidate is still consistent with the vault.

**Why not RC-2.** A journal, a lock and a recover command are a runtime. memex's
entire toolchain is bash 4 plus awk/sed/grep, deliberately — `jq` appears nowhere
in the repo and no skill uses `python3`. A transaction engine in bash is either a
toy or a second language in the tree. Recorded as Roadmap and put to the user
below, per the plan's Guard.

**What RC-2 already did instead.** `memex-seed` logs *first* and reports second,
and documents the gap where a resumed session reads it. That is the cheap half of
the fix and it is shipped.

### 6. Tests and CI — **Roadmap**

**Their design.** 534 test functions, a GitHub Actions workflow, and
`config/product-contract.json` declaring release gates that `gates.py` executes,
with manual gates that stay explicitly manual and a `verified` state that a
self-check cannot promote.

**Does memex have it? Yes.** `lint.sh` is 1,500 lines of bash and the vault's only
executable oracle, and it is verified by hand-diffing fixtures. M20 is the
receipt: the provenance parser read body prose as provenance and **shipped in
`v1.0.0-rc.1`**. Stage 3 rewrote sections of the same file. The RC-2 process has
been "run it on a throwaway clone and read the output", which is what this stage
did again.

**Why not RC-2.** A fixture harness is new scope in the stage before a tag, and
Stage 8 is documentation and the release. But this is the highest-value item on
this whole list that is not being adopted, and it should be first into the ported
roadmap: a `_meta/lint-fixtures/` directory of minimal vaults with expected
output, and one `bash _meta/test-lint.sh`, would have caught M20 and would have
caught verdict 1 above.

Their `verified` rule is worth stealing verbatim into the roadmap entry:
*`configured` means prerequisites are present; `verified` requires a declared
behavioral check to pass, and a schema self-check cannot promote the state.* RC-2
has been informally applying exactly that — it is why Stage 6 ran three drills
instead of asserting the skill was correct.

### 7. Authority taxonomy — **Roadmap**

**Their design.** Every source carries `authority: official | primary | secondary
| community | synthetic | unknown`, and an accepted claim needs fresh, active,
**non-synthetic** support.

**Does memex have it?** Probably, but without evidence yet. memex derives
confidence from independent units alone, so a blog post and a peer-reviewed paper
count identically — three independent blog posts reach `confidence: high` by the
same arithmetic as three independent papers. No trial-1 finding names this, and
M15's argument is about independence rather than authority.

**Verdict.** Roadmap, explicitly *pending evidence*. Adding a field with no lint
semantics is decoration, and memex's own standard is that a field with a writer
needs a check (`lint.sh:1433`). Trial 2's corpus is twelve papers with no
authority spread, so it will not settle this either — the question needs a mixed
corpus.

The `synthetic` value is the interesting one and the part memex has no answer to
at all: a source that is itself model output. RC-2 has `generated:` on notes but
nothing marks a *source* as machine-produced.

### 8. Bounded session context (`hot.md`) — **Roadmap**

**Their design.** `wiki/hot.md` is a short, sanitized, bounded cache of recent
facts, changed pages and open threads, explicitly "not a transcript", with a rule
that it must not carry claims less qualified than the canonical page they came
from. Hooks may read it; they do not write it.

**Does memex have it? No such file, and no recorded finding.** Every memex session
starts cold and re-reads `references/vault-schema.md`. That is a real cost, but no
trial-1 evidence names it, and inventing a second place where a claim lives — with
weaker qualification than the atom it came from — is the failure mode their own
schema had to write a rule against. Roadmap, pending a trial-2 observation that
the cold start actually costs something.

### 9. Log rollup (`wiki-fold`) — **Roadmap**

**Their design.** An extractive, bounded, idempotent rollup of log entries in
powers of two, additive only, never rewriting child entries, dry-run by default.

**Does memex have it? The problem is starting, with a number.** The fork's
`_meta/log.md` is **46 KB after one trial**. `memex-log-query` reads it. Nothing
compacts it, and the rate is one entry per capture. At a 200-source vault it is
several hundred KB of context for any question about history.

Roadmap rather than RC-2: it is not binding at 46 KB, the fix is a skill, and
their design has one property worth copying when the time comes — *no
fold-of-folds, never automatic*, which is what keeps a rollup from becoming a
lossy rewrite of the record.

### 10. BM25 retrieval index — **Roadmap**

**Their design.** Contextual chunking, a stdlib BM25 index in `.vault-meta/`,
optional local reranking, with the index declared disposable, invalidated before
its chunk set changes, and sharing the vault-wide mutation lock so a busy vault
fails closed rather than serving a partial index.

**Does memex have the problem?** Not yet, and two of its causes are gone. M21 —
the flat topic layer blinding `memex-search` and `memex-compose` — was fixed by
Stage 4's D2 hierarchy. M16 — `lint.sh` at 22 seconds on 21 atoms, extrapolating
to 15-25 minutes at 200 sources — was fixed by Stage 3's lookup tables. What
remains is that `memex-search` walks the graph and greps, which is fine at 16
sources and untested at 200.

Roadmap. A derived index is state that can go stale, and memex's working principle
is that the notes are the only state — their answer (disposable, lock-guarded,
invalidate-before-change) is a good one, but it is the answer to a problem memex
should measure before it buys.

### 11. Methodology modes (LYT / PARA / Zettelkasten) — **Decline**

**Their design.** `mode_config.py` declares folder sets per mode and the router
files a new page accordingly; mode changes do not migrate old notes or change
evidence semantics.

**Principle it conflicts with.** memex has one schema and one executable oracle.
`lint.sh` section 11 checks schema conformance, section 6d fires on topic breadth,
section 7a derives membership from `part-of::` — every one of those is written
against one filing model. Four routing modes means four sets of checks, or checks
that stop meaning anything. Their own design concedes the cost: a mode change does
not migrate old notes, so a vault that switches carries two organizations at once,
and the linter has to accept both forever.

memex's variability lives in `_meta/domain.md` — the tag and medium vocabulary a
fork edits — and in `memex-init`, which builds the vault the fork wants. That is
the intended seam, and it is one a linter can still check.

### 12. Product and vault as separate checkouts — **Decline** *(with a real cost named)*

**Their design.** The plugin is installed; the vault is selected by
`CLAUDE_OBSIDIAN_VAULT`, `.claude-obsidian.json`, or one initialized ancestor. If
none is certain, `paths.py` raises `VaultSelectionError` and **nothing is written**.
Skills resolve the product root from their own location, never from the working
directory.

**Principle it conflicts with.** In memex the template *is* the vault and forking
*is* the install; `.claude/skills` is a symlink to `skills/`, so a fork carries the
code that operates on it and `git rev-parse --show-toplevel` is correct by
construction. The whole `$VAULT` convention — `VAULT="${MEMEX_VAULT:-$(git
rev-parse --show-toplevel)}"`, never hard-coded — exists so a fork runs unedited.

**The cost, stated honestly.** A memex fork cannot pull a skill fix without a git
merge, and RC-2 is the proof: this entire release is a back-port from the fork to
the template because the two diverged. claude-obsidian forks do not have that
problem. But the fix for it is not "separate the product" — it is the
interoperability work already in the roadmap's tier 4, and it does not require
giving up the property that a vault is self-contained and portable.

**One piece worth taking, and it is cheap.** memex has *no* equivalent of their
refusal-on-ambiguity: no skill checks that the resolved `$VAULT` is actually a
memex vault before writing to it. A stale `MEMEX_VAULT`, or running a skill from
an unrelated repository, writes `sources/paper/…` into that repository and the
first sign is `git status`. A one-line guard — `[ -f "$VAULT/_meta/schema.md" ] ||
{ echo "not a memex vault: $VAULT"; exit 2; }` — belongs in the invariant vault-root
block every skill already copies byte-for-byte. Small enough to be RC-2, but it is
a 21-skill edit and Stage 8 is the release; carry it as the first roadmap item
alongside verdict 6.

### 13. Stable addresses (`address: c-000001`) — **Decline**

**Their design.** `scripts/allocate-address.sh` assigns a stable id per page,
independent of filename, used as the key in the address map and in retrieval
records.

**Does memex have the problem? No.** memex identity is the filename slug, and a
duplicate basename is already a **FAIL**, not a warning — demonstrated:

```
FAIL  glossary/plasticity.md — atoms/plasticity.md has the same filename;
      [[plasticity]] is ambiguous (schema.md § Disambiguation Policy)
```

That is stricter than their `duplicate_basenames` report. Obsidian rewrites
`[[links]]` on rename, so the slug is stable in practice. Their address exists
because their transaction engine needs a key that survives a path change inside a
bundle — a requirement memex does not have. M22 (graph node labels are filenames)
is a display question and already has three recorded options, none of them an
address scheme.

### 14. Egress consent gates — **Decline**

**Their design.** Network is off by default (`adapters.json`
`"privacy_default": "offline"`), page bodies leaving the machine need
`--allow-egress` plus stated consent, and consent may never be inferred from an
installed binary or a present API key.

**Does memex have the problem? Not the same one.** The two flows differ. In memex
the operator hands over a URL and asks for it to be saved — the request *is* the
consent, and the fetch goes to the site the operator named. Their `--allow-egress`
guards something else: sending *vault contents* to a third party to compute
retrieval prefixes. memex sends note content to the Claude Code session, which is
the operator's own agent, not a service the operator did not choose.

The credential half of their egress story is a genuine gap and is adopted as
verdict 3. The consent half is declined.

### 15. Claims in a JSON ledger beside the prose — **Decline**

**Their design.** `claim-ledger.json` holds each falsifiable claim with its note
location, supporting and contradicting source ids, confidence, risk, review state
and assessment — deliberately apart from the notes, so prose and assessment do not
contaminate each other.

**Principle it conflicts with, and the evidence.** memex keeps claims as markdown
in `extracts/`, each `^cNN` a verbatim quote, and `lint.sh` section 12 greps that
quote in the source's normalized archive. A quote that is not there is a **FAIL**.
Their repo has no equivalent: grepping v2.2.0 for verbatim-quote verification
returns instructions only — `autoresearch/references/program.md:49` "Never
fabricate authors, dates, URLs, page numbers, measurements, or quotes" — with no
mechanical check behind it. Their `ledgers.py` `_markdown_anchor_sets()` verifies
that a claim's *anchor resolves*; nothing verifies what the anchor points at.

A ledger is a second place a claim lives, and keeping two representations in step
is a job. memex puts the claim where it can be checked against the bytes. This is
the single largest asymmetry in the comparison and it runs in memex's favour.

---

## The other direction

What memex has that claude-obsidian v2.2.0 does not. This is positioning rather
than work, but it says which of memex's costs buy something.

| memex has | Their nearest thing | Why it matters |
|---|---|---|
| **Quote grounding checked against the bytes.** `lint.sh` § 12 greps every extract's verbatim quote in the normalized archive; a miss is a FAIL, with no LLM in the verification loop | Prose instructions not to fabricate quotes; anchor-existence checks in `ledgers.py` | Fabrication is deep extraction's characteristic failure. An instruction is not a check |
| **Independence derived, not declared.** Person keys from `authors:`/`channel:`/`tool:` plus `cites::` reach, unioned into components (`lint.sh:281-426`) | `independence_key`, a string somebody types | A derived key cannot be forgotten. A declared one is blank by default — `frontmatter.md:46` ships it as `""` |
| **`unchecked` as a first-class state.** A source with no author field is its own unit *and is reported unchecked*, so the number never reads as a verdict | Absent — a missing `independence_key` simply does not union | Demonstrated above: `2 of 2 sources (2 …, unchecked)`. The hedge travels with the number |
| **A topic hierarchy with derived membership.** `part-of::` on the child, one parent, no cycles; the topic side is a Dataview query and so cannot drift | MOCs and catalogs that a transaction must update in step | A query has no stale state to repair. Their design needs an invariant *because* the catalog is hand-written |
| **`confidence:` tied to counted evidence.** § 8 refuses `high` without 3+ independent units and block-anchored cites | `confidence` is a ledger field; only high-risk accepted claims are checked, and only for a count of 2 | memex checks every atom, not the subset somebody flagged high-risk |
| **Normalization as a precondition of grounding.** `_meta/normalize.sh` runs on every archive, which is what makes exact quote match hold at all | Content addressing of raw bytes, no text normalization layer | M19 is the lesson: without it, re-rendering reads as revision |
| **Zero runtime dependencies.** bash 4 + awk/sed/grep; the vault needs nothing installed to be linted | Python package, 17 modules | A vault that outlives its tooling is still checkable |

---

## Not in RC-2

Carried into `_meta/roadmap.md` by Stage 8, each pointing back at this file.

| # | Item | Why deferred |
|---|---|---|
| 4 | Source version model and content SHA-256 | Already M6/M19; needs trial-2 drift data to calibrate. Cheap slice named: record the archive hash at capture |
| 5 | Transactional grouping of multi-file writes | Needs a runtime memex does not have. See § To put to the user |
| 6 | Lint fixtures and CI | New scope before a tag. **Highest-value deferred item** — would have caught M20 and verdict 1 |
| 7 | Source authority taxonomy | No evidence memex has the problem; trial 2's twelve-paper corpus cannot settle it |
| 8 | Bounded session context | No recorded finding; risks a second, less-qualified home for a claim |
| 9 | Log rollup | Not binding at 46 KB. Copy their "no fold-of-folds, never automatic" rule when it is |
| 10 | Retrieval index | M16 and M21 removed the two known causes. Measure before buying |
| 12 | `$VAULT` sanity guard before any write | One line, but a 21-skill edit in the release stage |

---

## To put to the user

The plan's Guard says a verdict that would change the architecture is recorded as
Roadmap and raised, however strong the case. Two qualify.

1. **A transaction runtime (verdict 5).** Journal, lock, recover and grouped
   preconditions are the right answer to a real gap that Stage 6 demonstrated. They
   also mean Python in the tree, which reverses the zero-dependency decision that
   makes a memex vault checkable without an install. Not RC-2 either way; the
   question is whether it ever becomes a roadmap item with intent behind it or stays
   a documented limitation.

2. **More hosts (their seven surfaces).** `AGENTS.md` as a host-neutral contract
   with thin per-host files is a clean pattern and would cost memex roughly one
   file plus a rule that skills never name a host. It is not a gap — memex targets
   Claude Code deliberately — but it is the difference with the widest reach, and
   it is cheaper before 21 skills accumulate host-specific prose than after.

Neither is scheduled. Both are recorded so trial 2 does not re-derive them.

---

## Summary

| # | Difference | Verdict |
|---|---|---|
| 1 | Unresolvable link targets | **Adopt in RC-2** |
| 2 | Duplicate / same-origin sources | **Adopt in RC-2** |
| 3 | Credentials in a saved URL | **Adopt in RC-2** |
| 4 | Source versions and content drift | Roadmap (M6/M19) |
| 5 | Transactional multi-file writes | Roadmap — architectural |
| 6 | Tests and CI | Roadmap |
| 7 | Authority taxonomy | Roadmap, pending evidence |
| 8 | Bounded session context | Roadmap, pending evidence |
| 9 | Log rollup | Roadmap |
| 10 | BM25 retrieval index | Roadmap |
| 11 | Methodology modes | Decline — one schema, one oracle |
| 12 | Product / vault separation | Decline — the fork is the install |
| 13 | Stable addresses | Decline — duplicate basenames already FAIL |
| 14 | Egress consent gates | Decline — the request is the consent |
| 15 | Claims in a JSON ledger | Decline — a claim lives where it can be checked |

Three adoptions, all in `lint.sh`, all small, all against demonstrated failures on
a throwaway clone. Seven roadmap rows, two of them flagged as pending evidence
rather than deferred work. Five declines, each naming the principle.

The shape of the difference, in one line: **claude-obsidian invests in the
apparatus around the notes — transactions, ledgers, indexes, hosts — and memex
invests in checking the notes themselves.** Their apparatus is better than
memex's and their evidence checking is weaker. The three adoptions are the places
where memex's own checking had a hole their linter happened to cover.
