# LI MCP — Acceptance Gates

These gates prevent “implemented” from meaning “code exists.” A phase closes only with evidence.

## Gate A — Truth
- zero side-effecting tools return success without performing the action;
- every advertised capability maps to a real provider or explicit unavailable state;
- documentation distinguishes shipped from planned;
- configured != available in runtime reporting.

## Gate B — Compatibility
- Tier 0 builds and tests with the supported legacy deployment path;
- macOS 26-only source cannot make the base executable unloadable on older supported systems;
- macOS 27-only source is isolated and availability guarded;
- tool schemas remain stable across OS tiers unless versioned deliberately.

## Gate C — Capability routing
- provider choice is deterministic and testable;
- provider used is observable;
- no silent local → remote/PCC fallback;
- cancellation/deadline propagates through router and provider;
- unavailable states are normalized.

## Gate D — Side-effect safety
For every side-effecting tool:
- permission requirements are explicit;
- policy is checked immediately before execution;
- untrusted arguments are validated;
- timeout and cancellation are tested;
- action result includes enough evidence to distinguish execution from proposal;
- destructive/high-risk actions follow configured approval policy.

## Gate E — Foundation Models 26
- model availability states are correctly distinguished;
- generation and streaming work on eligible hardware;
- structured output is schema-valid;
- selected tool calling obeys allowlist/policy;
- tool arguments are validated after generation;
- macOS 13–25 behavior remains functional.

## Gate F — Foundation Models 27
- new model abstraction does not leak into stable MCP contracts;
- multimodal limits and lifecycle are enforced;
- Dynamic Profiles cannot expand tool authority beyond policy;
- PCC, if enabled, is explicit and opt-in;
- evaluations cover changed model behavior and tool use.

## Gate G — Security
- prompt/tool injection suite passes;
- path/URL/input validation suite passes;
- privilege and permission-denial paths pass;
- logs do not contain prompt/result payloads by default unless explicitly configured;
- secrets/credentials are never returned through capability inspection;
- threat model reviewed for each new provider class.

## Gate H — Reliability
- concurrent-client tests pass;
- cancellation and timeout stress tests pass;
- provider unavailability transitions do not crash server;
- malformed MCP requests cannot corrupt provider/session state;
- repeated session creation does not show unbounded memory growth.

## Gate I — Documentation
Before release, sample every README capability claim and prove it against code/tests. Compatibility table and examples must match current behavior. Planned work is labeled planned.

## Release rule

A capability may be marked **stable** only when its relevant gates pass. Otherwise label it **experimental**, **unavailable on this tier**, or **planned**. Never use “supported” to mean merely “the SDK contains the API.”
