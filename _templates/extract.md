---
type: Extract
title: "Extract: <% tp.file.title %>"
description: 
extracted: <% tp.date.now("YYYY-MM-DD") %>
claims: 0
---

<!-- Filename is the source's with an `ext-` prefix: ext-2026-04-27-slug.md.
     The prefix is required — without it the extract and its source share a
     filename, and Obsidian resolves wikilinks by filename, so every existing
     cites:: [[2026-04-27-slug]] would silently go ambiguous.

     `extracted-from::` is the only record of which source this came from. There
     is no `source:` frontmatter field, because the filename and this link
     already say it twice, and no `medium:` for the same reason — it belongs to
     the source note, and copying it here is one more field to keep in step. -->
extracted-from:: 
mentions:: 

## Claims
<!-- One claim per bullet, each ending in a `^cNN` block id — Obsidian only accepts
     a block identifier at the end of a bullet or of a paragraph's last line.
     Sub-bullets use plain single-colon keys, NOT Dataview `::` fields: fifty
     claims' worth of `about::` would lift to page level and merge into one array,
     and each would fire a phantom graph edge before any human approved it.

     `quote:` must appear verbatim in the source's normalized `raw::` archive —
     lint section 12 greps for it. Two rules follow: a quote is single-line, and
     it contains no ellipsis. Split into two quote lines instead.

     type: is one of finding | definition | limitation | contrast | method -->

- <claim stated as a proposition> ^c01
    - type: 
    - about: `concept-slug`
    - quote: ""

## Concepts
<!-- Resolution of each mention against the vault. Backticked slugs, never
     [[wikilinks]] — a proposed concept is not yet a graph edge. -->

| Mention | Resolution | Target |
|---|---|---|
|  | matched / new (N claims) / ambiguous |  |

## Proposed Relations
<!-- Vocabulary restricted to _meta/schema.md § Valid Relation Fields. -->

| Subject | Relation | Object | Via |
|---|---|---|---|
|  |  |  | `^cNN` |

## Promotion Log
<!-- Appended by memex-deep-extract mode B, one line per promoted claim. -->
