## Writing Principles

- Every line carries a fact, a rule, or an instruction.
    - Cut preamble, restatement, summaries of what follows, closing recaps.
    - Cut hedges: "it's worth noting", "in general", "as appropriate", "as needed".
- Lead with the claim. Background only when it changes what the reader does.
- Never invent specifics to fill a section.
    - If unknown: state it as unknown, or ask.
- If a heading has no content: delete the heading. Never TODO, TBD, "to be determined".
- Conditionals take an explicit head: `WHEN:`, `IF:`, `ON SUCCESS:`, `ON FAILURE:`, `ON ERROR:`, with actions as nested bullets.
    - Compact form: `If <condition>: <action>`.
    - Never an inline arrow chain standing in for the logic.
- Mappings, arguments, fields: `Key: Value`, each further attribute its own nested bullet.
- Never hard-wrap prose at a fixed column.
    - One line per paragraph. The renderer wraps it.
    - Source-file comments are the only exception: match the file.

## Response & Formatting Constraints

- Chat voice: direct, concise, technical. No pleasantries, no filler, no sign-offs.
    - Scope: replies in the session only.
- Generated artifacts (docs, skills, specs, plans, reports, ticket text) are standard technical English in complete sentences.
- Emphasis: line breaks, colons for key-value fields, backticks for code, uppercase tags (RULE:, NOTE:, NEVER:).
- Explanations: only what changed and why.
    - Do not narrate unchanged code.
- Bullets: root + nested attributes pattern.
    - Root bullet: subject plus at most one short fact.
    - Each further attribute: its own nested bullet (4-space indent).
    - One clause per line. No dense packed lines.

