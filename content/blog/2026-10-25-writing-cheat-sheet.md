---
title: Writing cheat sheet
description: Every kind of formatting a post can use, in one place. A draft, so only you can see it.
tags: [Guide]
emoji: ✏️
color: butter
draft: true   # drafts only show while running the site on your computer
---

This post is a cheat sheet for writing on the blog. It's a **draft**, so it never shows on the live site. Open `content/blog/2026-10-25-writing-cheat-sheet.md` next to this page to see how each part is written.

<!-- truncate -->

## Text

Write normally. Leave an empty line between paragraphs. Use **bold** for the important bits, *italics* for a softer touch, and [links](https://www.osym.gov.tr) to send people elsewhere. Links to [another post](/blog/welcome-to-meowdical-notes) or a [roadmap subject](/roadmap/anatomy) work too.

## Headings

Lines starting with `##` become headings with a paw in front. `###` makes a smaller one.

### Like this

## Lists

- Paw bullets for plain lists
- Indent with two spaces for a sub-list
  - like this

1. Numbered lists
2. count up on their own

## Checklists

These get paw checkboxes. Put a date at the end of a finished item:

- [x] A finished item (2026-10-25)
- [/] Something in progress
- [ ] Something to do

## Callouts

:::note
A note: `:::note`, then your text, then `:::` on its own line.
:::

:::tip A tip with its own title
Write the title after the type: `:::tip A tip with its own title`.
:::

:::info
For good-to-know things.
:::

:::warning
For mistakes that are easy to make.
:::

:::danger
For things that must never be mixed up.
:::

## Tables

| Drug | Antidote |
| --- | --- |
| Paracetamol | N-acetylcysteine |
| Opioids | Naloxone |

## Quotes

> Make a quote by starting the line with `>`.

## Images

Make the post a folder (`content/blog/2026-11-02-my-post/index.md`) and put the picture next to it, then write `![What's in the picture](photo.jpg)`. The text in the brackets shows as a caption.
