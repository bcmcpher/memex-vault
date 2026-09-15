---
type: Concept Map
title: 
description: 
tags: []
created: <% tp.date.now("YYYY-MM-DD") %>
reviewed: 
---

## Overview
<!-- What is this domain? Why does it matter?
     Condense into frontmatter `description:`. -->

## Core Concepts
<!-- Derived from each atom's part-of:: — do not maintain by hand. -->
```dataview
LIST FROM "atoms"
WHERE contains(row["part-of"], this.file.link)
```

### Via sub-topics
<!-- Atoms of every concept map that names this one as its parent, grouped by
     sub-topic. Derived; empty on a leaf. See _meta/schema.md § Topic Hierarchy. -->
```dataview
LIST rows.file.link
FROM "atoms"
FLATTEN row["part-of"] AS sub
WHERE sub AND contains(sub["part-of"], this.file.link)
GROUP BY sub
```

## Key Sources
cites:: 

## Sub-topics and Relations
<!-- part-of:: names this map's one parent concept map. Leave it empty on a root. -->
part-of:: 
related:: 
