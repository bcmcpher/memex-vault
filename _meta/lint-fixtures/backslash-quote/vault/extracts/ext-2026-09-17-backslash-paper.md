---
type: Extract
title: "Extract: A Backslash Paper"
description: one grounded quote with backslashes, one absent quote with backslashes
extracted: 2026-09-17
claims: 2
---

extracted-from:: [[2026-09-17-backslash-paper]]
mentions:: 

## Claims

- The loader reads a Windows path first. ^c01
    - type: finding
    - about: `loader-order`
    - quote: "The loader reads C:\new\table before it reads anything else."
- The manual prints escapes as tabs. ^c02
    - type: finding
    - about: `escape-rendering`
    - quote: "Escapes such as \t and \n are rendered as a tab and a newline."

## Concepts

| Mention | Resolution | Target |
|---|---|---|
| loader-order | new (1 claims) | |

## Proposed Relations

| Subject | Relation | Object | Via |
|---|---|---|---|
|  |  |  | `^c01` |

## Promotion Log
