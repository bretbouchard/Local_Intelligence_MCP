# LI MCP — GSD Phases and Plans

This is the executable work breakdown for the vNext Apple-local intelligence upgrade.

## Phase 0 — Establish truth

### Plan 0.1 — Freeze and inventory the current public contract
**Goal:** know exactly what clients can call today.

Tasks:
- enumerate registered MCP tools, schemas, resources, configuration and permissions;
- classify every tool as deterministic, genuine side effect, simulated/stubbed, optional, deprecated, or unknown;
- map each tool to source files and tests;
- capture current minimum OS/Swift/Xcode assumptions;
- record public README claims against implementation.

Evidence:
- checked-in capability inventory;
- tool → implementation → test matrix;
- list of documentation mismatches.

Exit: every advertised capability has an implementation status.

### Plan 0.2 — Remove false-success behavior
**Goal:** make truthfulness an invariant before adding intelligence.

Tasks:
- change simulated Shortcuts execution to explicit unavailable until real provider lands;
- remove or disable simulated Voice Control execution/recognition;
- standardize unavailable/unsupported/permission-denied errors;
- ensure health output cannot convert configured-but-unimplemented into available.

Tests:
- stubbed side effects never return success;
- errors remain machine-readable;
- existing genuine tools remain unaffected.

Exit: LI MCP never claims an external action occurred when it did not.

### Plan 0.3 — Establish compatibility build matrix
**Goal:** prevent new Apple APIs from silently raising the product floor.

Tasks:
- document supported Xcode/SDK combinations;
- create build lanes for legacy path, macOS 26 SDK, macOS 27 SDK;
- isolate SDK-specific source with availability/conditional compilation;
- establish CI policy for APIs that require physical eligible hardware.

Exit: new code cannot merge if it breaks the portable tier.

### Plan 0.4 — Baseline security and performance
Capture startup time, tool-discovery latency, representative deterministic-tool latency, memory footprint, current permission behavior and security tests. These numbers become regression baselines.

---

## Phase 1 — Capability kernel

### Plan 1.1 — RuntimeCapabilities
Implement a single authoritative runtime snapshot including:
- OS and architecture at the granularity needed for routing;
- API feature level;
- Apple Intelligence eligibility/availability where safely obtainable;
- model ready/downloading/unavailable state;
- relevant automation/accessibility permissions;
- registered providers and health;
- supported capability IDs.

Privacy rule: report only state required for capability routing; do not turn health into machine fingerprinting.

Exit: one object answers “what can this machine actually do now?”

### Plan 1.2 — CapabilityRouter
Implement routing independent of MCP presentation.

Requirements:
- stable capability IDs;
- deterministic priority rules;
- explicit provider selection metadata;
- no hidden fallback from a requested local/private provider to a remote provider;
- cancellation and deadline propagation;
- test-injectable providers.

Exit: tools no longer directly choose OS implementations.

### Plan 1.3 — Provider protocols and result envelopes
Create `IntelligenceProvider`, provider metadata, generation request/result types, structured generation contracts and normalized error taxonomy.

Error families:
- unsupported
- unavailable
- disabled
- notReady
- permissionDenied
- invalidRequest
- timeout
- cancelled
- providerFailure
- policyDenied

Exit: clients can reason about failure without parsing prose.

### Plan 1.4 — Stable `local_*` MCP tools
Introduce capability-oriented names such as:
- `local_capabilities`
- `local_generate`
- `local_summarize`
- `local_extract`
- `local_classify`
- `local_automation_list`
- `local_automation_execute`
- later `local_image_understand`

Preserve old names through compatibility aliases only where useful; document deprecation.

### Plan 1.5 — Observability
Add provider, capability, duration, outcome, fallback decision and policy result to structured logs/metrics without logging private prompt/result contents by default.

---

## Phase 2 — Real Apple automation

### Plan 2.1 — Shortcuts provider
Replace the simulated tool with genuine enumeration/execution using a supported macOS mechanism.

Requirements:
- list actual shortcuts;
- execute by stable user-visible identifier/name as platform permits;
- input/output mapping;
- cancellation/deadline;
- distinguish shortcut failure from transport failure;
- never shell-interpolate untrusted arguments;
- expose backend/provider metadata.

E2E evidence: a fixture Shortcut performs an observable reversible action and returns a known result.

### Plan 2.2 — App Intents capability investigation and adapter
Determine what useful installed-app intents can genuinely be exposed to an external MCP server under Apple platform rules. Implement only supported surfaces. If generic enumeration/invocation is not supported, document the boundary rather than inventing one.

### Plan 2.3 — Accessibility fallback
If retained, make Accessibility a separate, opt-in provider with explicit permission state, narrow actions and policy gates. Do not call generic Accessibility automation “Voice Control.”

### Plan 2.4 — Automation safety
Add allow/deny policy by capability/action, destructive-action classification, confirmation hooks where required, audit evidence, timeout/cancellation tests and injection tests.

Exit Phase 2: older Macs have useful real Apple automation without needing Foundation Models.

---

## Phase 3 — macOS 26 Foundation Models

### Plan 3.1 — AppleFoundationProvider26
Conditionally integrate FoundationModels while retaining the older deployment target.

Implement:
- system model availability mapping;
- `LanguageModelSession` lifecycle;
- basic generation;
- streaming;
- cancellation;
- normalized errors;
- provider metadata.

Exit: `local_generate` uses the Apple on-device model when genuinely available.

### Plan 3.2 — Structured generation
Implement guided/structured generation for MCP-friendly typed results. Validate generated output again at the MCP boundary even when framework guidance is used.

Target uses:
- extraction;
- classification;
- compact structured transformations;
- tool arguments.

### Plan 3.3 — Foundation Models Tool adapter
Bridge selected existing LI MCP capabilities into Apple Foundation Models tool calling.

Security requirements:
- tools are explicitly allowlisted per session/profile;
- schema is derived from authoritative tool contracts;
- policy is re-evaluated at execution time;
- model cannot bypass MCP/tool authorization by naming an internal function;
- side-effect evidence is recorded.

### Plan 3.4 — Task capabilities
Implement `local_summarize`, `local_extract`, `local_classify` and appropriate transformations using provider routing. Keep deterministic implementations preferred where they are semantically sufficient.

### Plan 3.5 — Session/context management
Define bounded session lifetime, transcript retention policy, context reset, concurrency behavior and resource limits. Do not create hidden indefinite memory.

### Plan 3.6 — macOS 26 integration suite
Test at least:
- API absent;
- hardware ineligible;
- Apple Intelligence disabled;
- model not ready/downloading;
- model available;
- cancellation;
- tool call allowed/denied;
- malformed structured request;
- concurrent clients;
- fallback behavior.

Exit Phase 3: supported macOS 26 Macs expose Apple on-device intelligence through stable MCP tools while macOS 13–25 behavior remains valid.

---

## Phase 4 — macOS 27 intelligence expansion

### Plan 4.1 — Provider-neutral LanguageModel layer
Adapt internal provider contracts to Apple's newer model abstraction without exposing it as the MCP contract. Confirm source compatibility with macOS 26 provider.

### Plan 4.2 — Dynamic Profiles
Use profiles to compose instructions, model and permitted tools for bounded tasks. Profiles must not become an ungoverned alternate tool registry.

### Plan 4.3 — Multimodal/image input
Add attachment/media request types and `local_image_understand`. Enforce file size/type limits, privacy policy, lifecycle cleanup and unsupported-state reporting.

### Plan 4.4 — Apple system tools
Evaluate and integrate relevant Vision and Spotlight/semantic-search facilities where Apple exposes supported APIs. Each capability gets a deterministic/direct provider where possible; LLM mediation is optional, not mandatory.

### Plan 4.5 — Private Cloud Compute
Treat PCC as a separate opt-in provider class, not an invisible fallback from “local.” Document privacy/availability semantics and require explicit routing policy.

### Plan 4.6 — Evaluations
Create evaluation datasets/suites for:
- structured generation validity;
- extraction/classification quality;
- tool selection;
- tool argument correctness;
- refusal/policy behavior;
- prompt regressions across model generations;
- multimodal tasks.

Evaluation thresholds must be versioned; failures block release where the capability is advertised as stable.

### Plan 4.7 — Developer interoperability
Add optional `fm` CLI examples and Foundation Models Python SDK examples where they materially improve development/testing. MCP remains the public interoperability boundary.

Exit Phase 4: macOS 27 gains richer Apple intelligence without fragmenting the MCP API or breaking older tiers.

---

## Phase 5 — Hardening, security and compatibility

### Plan 5.1 — Model/tool threat model
Review prompt injection, malicious tool arguments, confused-deputy behavior, path/URL abuse, privilege escalation, sensitive-data leakage, untrusted Shortcut names/inputs and provider fallback surprises.

### Plan 5.2 — Permission and approval contracts
Every side-effect capability declares risk class, required permission, policy check and whether interactive approval is required. Denial is a first-class result.

### Plan 5.3 — Cross-version compatibility
Run build/test matrix and physical-device integration where needed. Verify a newer SDK build still executes correctly on the oldest supported deployment target for Tier 0/1 features.

### Plan 5.4 — Reliability
Stress concurrent sessions, repeated provider availability changes, cancellation storms, provider crashes/errors, malformed MCP requests and long-running automation.

### Plan 5.5 — Performance
Benchmark startup, discovery, routing overhead, generation first-token/total latency where measurable, memory growth across sessions and deterministic-tool regression.

### Plan 5.6 — Release evidence bundle
For every release produce machine-readable/test evidence for supported tiers, known unavailable states, security suite, integration suite and documentation claim audit.

---

## Phase 6 — Public product surface

### Plan 6.1 — README rewrite
Lead with the actual product:

> Local Intelligence MCP is a lightweight Swift MCP server that gives AI agents practical access to Apple's local intelligence and automation stack, using the best capabilities available on each Mac while preserving graceful support for older systems.

Clearly distinguish shipped, OS-gated, experimental and planned features.

### Plan 6.2 — Compatibility table
Publish capability × OS tier × hardware/setting requirement × provider. Never use a checkmark where runtime eligibility can still make the capability unavailable without an explanatory qualifier.

### Plan 6.3 — Examples
Provide minimal examples for:
- capability discovery;
- deterministic utility;
- Shortcuts execution;
- macOS 26 on-device generation;
- structured extraction;
- model calling an allowed tool;
- macOS 27 multimodal task;
- graceful fallback/unavailable behavior.

### Plan 6.4 — Portfolio/release cleanup
Remove stale claims, mock terminology, placeholder text and unsupported portability claims. Add architecture diagram, security model, testing philosophy and concise “why this exists.”

Exit Phase 6: a developer can understand what LI MCP does, what their Mac supports, how privacy/permissions work, and how to use it without reading source.

## Sequencing

Critical path:

`0.1 → 0.2 → 1.1 → 1.2 → 1.3 → 2.1 + 3.1 → 3.2 → 3.3 → 3.6 → 4.x → 5.x → 6.x`

Parallelizable after Phase 1 contracts stabilize:
- automation implementation;
- macOS 26 provider;
- observability;
- documentation skeleton;
- security test construction.

Do not start PCC, multimodal, or developer interoperability before the capability kernel and truthful side-effect behavior are complete.
