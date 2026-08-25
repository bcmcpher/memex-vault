---
title: 
topic-type: research
question: 
tags: []
created: <% tp.date.now("YYYY-MM-DD") %>
reviewed: 
---

## Research Question

## Current Understanding
cites:: 

### Atoms in This Question
<!-- Derived from each atom's part-of:: — do not maintain by hand. -->
```dataview
LIST FROM "atoms"
WHERE contains(row["part-of"], this.file.link)
```

## Evidence For
- 

## Evidence Against / Gaps
- 

## Synthesis

## Dataview: Supporting Sources
```dataview
TABLE medium, saved, status FROM "sources"
WHERE contains(supports, [[<% tp.file.title %>]])
SORT saved DESC
```
