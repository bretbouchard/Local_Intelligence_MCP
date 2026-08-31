# Local Intelligence MCP — Examples (GSD Plan 6.3)

Each script drives the real server over stdio JSON-RPC. Build first:
`swift build`, then run any script from the repo root:

```bash
examples/01_capability_discovery.sh       # what can THIS Mac do right now?
examples/02_deterministic_utility.sh      # summarize + extract (no model involved)
examples/03_shortcuts_discovery.sh        # list real Shortcuts on this Mac
examples/04_shortcuts_execution.sh        # run one, with confirm for destructive names
examples/05_on_device_generation.sh       # local_generate (macOS 26+ Apple Intelligence)
examples/06_structured_generation.sh      # model output validated against a JSON Schema
examples/07_model_tool_call.sh            # model calling an allowlisted capability
examples/08_unavailable_behavior.sh       # truthful unavailability / denial paths
```

Expected behavior highlights:

- **01** reports OS tier, Apple Intelligence/model state, permissions, and a
  per-capability status map (`available` / `unsupported` / `disabled` / …).
- **02** is fully deterministic — same input, byte-identical output, no model.
- **04** shows the safety gate: a destructive-looking name fails with
  `POLICY_DENIED` until `confirm: true` is passed.
- **06** validates model output against a JSON Schema subset and returns the
  parsed object plus `"validation": "passed"`.
- **07** lets the model call only allowlisted read-only capabilities; requesting
  side-effect tools fails with `POLICY_DENIED`.
- **08** on an ineligible Mac returns `UNSUPPORTED`/`DISABLED`/`NOT_READY` —
  never a simulated success.
