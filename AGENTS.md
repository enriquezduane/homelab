# Operational Guidelines

- Workload restriction:
    - Target: KVM/QEMU virtual machines (`qm`) only.
    - NEVER generate, deploy, or run LXC container commands (`pct`).
- Hardware envelope:
    - Host limits defined in `docs/HARDWARE.md`.
    - Memory ceiling: 16GB total (max ~13.5GB allocated across all VMs).
    - CPU ceiling: 4 vCPUs maximum per VM.
    - Storage pool: thin LVM (`local-lvm`) for virtual disks.
- Network envelope:
    - Static IPs must fall within `192.168.1.201–192.168.1.254` (`docs/NETWORK_CONFIGURATION.md`).
    - Gateway: `192.168.1.1`.
    - Hypervisor bridge: `vmbr0`.
- State maintenance:
    - Repository docs are live state files.
    - Update `docs/` files whenever allocating IPs, altering templates, or modifying node state.
    - ALWAYS notify the user whenever a documentation file is edited.
- Surgical changes & minimal diffs:
    - Touch only files and hypervisor parameters required for the task.
    - Keep diffs minimal and focused strictly on the requested objective.
    - Never refactor working Proxmox scripts, bridges, or template configs casually.
    - Match existing bash style (`set -euo pipefail`, explicit argument parsing, `qm` CLI).
    - Clean up temporary artifacts, ISO downloads, or dangling VMs created during execution.
- Goal-driven verification:
    - Verify host reachability: run `just check`.
    - Verify VM operations: check state using `ssh proxmox-lab qm status <VMID>`.
    - Verify network assignments: probe target IP via `ping` or `nc` before and after allocation.

## Diagram Triggers

- IF task requires architecture, network, or workflow diagrams:
    - Follow specifications in `docs/DIAGRAMS.md`.
    - Save sources to `docs/diagrams/<name>.d2`.

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
