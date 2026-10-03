# Diagramming Standards

- Format: D2 text format compiled to SVG.
- File placement:
    - Source: `docs/diagrams/<name>.d2`
    - Output: `docs/diagrams/<name>.svg`

## Configuration Block
- Every `.d2` file MUST start with this exact header block:
```d2
vars: {
  d2-config: {
    layout-engine: elk
    theme-id: 8
    sketch: true
    center: true
    pad: 20
  }
}
```

## Diagram Scope Limits
- One concern per diagram: NEVER combine hardware, storage, and networking into a single diagram.
- Node budget: Target 4 to 8 nodes per diagram (hard ceiling: 10). Split larger topics into multiple files.
- Container threshold:
    - ONLY create a container if it holds 2 or more distinct child nodes.
    - NEVER put a single node inside a container just to hold notes or attributes.
    - Container nesting limit: Maximum 1 level deep.
- Plain labels:
    - Use functional names (e.g., `Router`, `Bridge (vmbr0)`, `VM 101`).
    - Use multi-line text (`"...\n..."`) on shapes to provide capacity/role context without creating sub-containers.
    - NEVER put raw CLI flags, hardware spec dumps, or full CIDR pools in node labels.
- Layout gap settings:
    - NEVER use `horizontal-gap` or `vertical-gap` in `d2-config` (unsupported in D2 v0.9).

## Canonical Baseline Diagrams
- `network-topology.d2`: Gateway -> Host NIC -> `vmbr0` -> VMs.
- `storage-layout.d2`: SSD -> `local` (ISOs/templates) vs `local-lvm` (VM disks) -> VMs.
- `vm-flow.d2`: Debian Cloud Image -> Template 9000 -> Cloned VM (`just deploy`).
- New diagrams: Permitted for specific features (e.g., DNS flow, backup jobs) provided they respect the 4-8 node budget.

## Syntax & Connection Rules
- Arrows:
    - Directed: `->`
    - Bidirectional: `<->`
    - NEVER use Mermaid syntax (`-->`, `==>`, `-.->`).
- Direction:
    - Pipelines & data flow: `direction: right`
    - Infrastructure hierarchy & parent-child: `direction: down`
- Edge labels & Collision Prevention:
    - Edge text: 1 to 4 words maximum.
    - Multi-word labels on parallel edges MUST use `\n` to prevent horizontal text collision (e.g., `"boot\nmedia"`).
    - When 2 or more parallel links merge into one target, prefer `direction: right` or short 1-word labels.
- Styling:
    - Rely entirely on `theme-id: 8` (Colorblind Clear).
    - NEVER introduce hardcoded hex colors or inline style overrides.

## Compilation Workflow
1. Create or edit `docs/diagrams/<name>.d2`.
2. Compile to SVG:
    - Shell command: `just diagram <name>`
3. On compiler error: inspect `stderr`, correct syntax, and re-run.
