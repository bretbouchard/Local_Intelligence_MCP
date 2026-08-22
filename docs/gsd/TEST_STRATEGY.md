# LI MCP — Test Strategy

## Policy

Critical contracts target 100% behavioral coverage of meaningful states, not vanity line coverage. Platform integrations require real integration evidence in addition to mocks.

## Coverage classes

### Class A — 100% required
- capability routing decisions
- normalized error mapping
- authorization/policy decisions
- side-effect result truthfulness
- schema/input validation
- provider fallback rules
- permission-state mapping
- secrets/sensitive-data filtering

Every branch/state in these contracts must be exercised.

### Class B — >= 90% target
- provider adapters
- session/context management
- MCP tool adapters
- automation argument/result mapping
- structured generation decoding
- observability metadata

### Class C — pragmatic coverage
- CLI/example code
- platform glue that can only be exercised on specific hardware
- UI-free developer conveniences

These still require integration smoke tests where relevant.

## Test pyramid

### Unit
Pure contracts, routing, policy, validation, state mapping, schema construction, error normalization.

### Contract
Every MCP tool schema and result envelope; backward-compatible aliases; provider protocol conformance.

### Integration
Real Shortcuts, permissions, Foundation Models availability/session/generation, Apple tool calls, multimodal/system tools.

### E2E
An MCP client discovers capability → calls tool → provider executes → evidence/result returns. Side effects must be externally verifiable and reversible in test fixtures.

### Evaluation
For nondeterministic model behavior: quality/behavior datasets rather than brittle exact-string assertions.

## Required state matrix

For Apple model features:
1. API absent
2. API present / hardware ineligible
3. eligible / feature disabled
4. enabled / model not ready
5. available
6. provider error
7. timeout
8. cancellation

For permissioned automation:
1. permission unknown/not requested
2. denied
3. granted
4. revoked during/after prior success
5. target action unavailable
6. action succeeds
7. action itself fails
8. timeout/cancel

## Side-effect proof rule

Mocks can prove routing and contracts. They cannot prove a side effect works.

Each shipped side-effect provider needs at least one real integration/E2E fixture. Example for Shortcuts:
- install/use a known test Shortcut;
- pass a deterministic input;
- Shortcut returns a known transformed result or writes a reversible fixture artifact;
- test verifies the result independently;
- cleanup executes;
- audit record identifies actual execution.

## Model evaluations

Maintain versioned fixtures for:
- summarization fidelity;
- structured extraction precision/recall where measurable;
- classification accuracy;
- schema validity rate;
- correct tool selection;
- valid tool arguments;
- policy refusal/denial behavior;
- resistance to instructions attempting unauthorized tool use;
- multimodal correctness when introduced.

Record model/OS feature level with evaluation results because Apple system model behavior may change between OS releases.

## Regression requirements

Every bug involving false success, unauthorized action, crash, data leak, provider misrouting, malformed structured output, or compatibility break receives a permanent regression test.

## Performance tests

Track:
- server startup
- MCP initialization/tool discovery
- router overhead
- deterministic tool latency
- generation first-token latency where exposed
- total generation latency
- memory before/after repeated sessions
- automation latency and timeout correctness

Performance regressions are reviewed, not automatically accepted because the feature is AI-backed.

## CI vs physical-machine tests

CI must run all portable/unit/contract tests and compile each supported SDK path. Tests requiring Apple Intelligence eligibility or macOS permissions may run on designated physical Macs and report separate integration evidence. A skipped hardware test must be visible; it must not be reported as passed.
