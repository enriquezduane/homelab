---
name: learn
description: Teach any concept from the ground up as a scannable plain Markdown note in docs/learn/. Use when the user runs /learn <topic>.
argument-hint: <topic>
---

Teach `$ARGUMENTS` from zero. Ground it in what the user already has where that helps, but the note must make sense on its own.

## Steps
1. Look for anything relevant the user already has (repo, configs, live systems). Read-only, change nothing.
2. Write `docs/learn/<topic-slug>.md`. If it exists, update it instead of starting over.
3. Reply with the path and 2–3 lines on what's in it.

## What a good note covers
Pick and order the sections the topic needs. Skip any that don't fit.
- **TL;DR**: what it is and why it matters, in 2–3 lines.
- **What you have**: the user's current setup related to the topic, if they have one.
- **How it works**: the mechanism, step by step.
- **Terms**: table of `Term | Plain meaning | Example | Could look like`. "Example" is a concrete case (from the user's setup when there is one). "Could look like" is a variation or a bigger setup ("Ubuntu hosts would be `[ubuntu]`").
- **What if**: short examples that answer the obvious follow-up questions ("What if I added X?", "Can it be Y instead?").
- **Try it**: hands-on steps, safest first, with the result to expect.
- **Gotchas** and **Next**.

## Style
- Write like notes, not an RFC: short sentences, bold key words, one idea per bullet.
- Keep it scannable: headings, tables and lists over paragraphs. Paragraphs are 2 sentences max.
- Plain CommonMark/GFM only. No Obsidian features: no callouts (`> [!note]`), no `[[wikilinks]]`, no frontmatter, no tags.
- Keep what you verified separate from examples and hypotheticals. Label untested examples as untested.

## Formatting rule: no ASCII diagrams
Never use ASCII art, box-drawing characters (┌, ─, |, +---+, ├──), or Mermaid. Use instead:
- **Flows and sequences**: a one-line arrow summary (`A` ➔ `B` ➔ `C`), then a numbered list.
- **Interactions and state changes**: a Markdown table.
- **Layers, nesting, containment**: nested blockquotes (`>`, `> >`).
- **Hierarchies and decision trees**: nested bullets with **bold keys** and ↳ for outcomes.
