# Local Intelligence MCP — GSD Master Plan

Status: execution specification
Branch baseline: `tools-addendum`
Scope: evolve LI MCP into a truthful, lightweight, cross-version Apple-local capability bridge while preserving macOS 13+ usefulness.

## Mission

Local Intelligence MCP (LI MCP) gives MCP clients and agents a stable set of local capabilities while selecting the best implementation actually available on the Mac. Apple-specific APIs are providers behind stable contracts; they are not the server architecture.

The product must remain useful on older systems while progressively gaining Apple Foundation Models and newer Apple Intelligence capabilities on macOS 26 and 27.

## Non-negotiable invariants

1. **No simulated success.** A side effect either occurred, failed, was denied, or is unavailable.
2. **Capability names outlive providers.** MCP clients request `local_*` capabilities rather than OS-version-specific APIs.
3. **Runtime truth beats compile-time assumption.** OS support does not imply hardware eligibility, permission, model readiness, or user enablement.
4. **Deterministic work stays deterministic.** Do not route computation, parsing, redaction, or other deterministic operations through an LLM merely because one is available.
5. **Least privilege.** Model access to tools is explicit, auditable, policy-controlled, and revocable.
6. **Older OS support is a product feature.** macOS 13+ retains the portable MCP shell and genuine capabilities supported there.
7. **Provider metadata is observable.** Results may report the provider used without leaking sensitive machine state.
8. **Tests prove side effects and fallbacks.** Mocks may test contracts but cannot substitute for platform integration tests.

## Current-state baseline

Keep and build upon:
- Swift 6 package/executable MCP server
- MCP Swift SDK integration
- tool registry and standardized tool abstraction
- policy/permission/security layers
- logging, metrics, health, validation
- system and deterministic utilities
- audio-domain tools as optional capabilities
- macOS 13+ deployment target

Correct immediately:
- Shortcuts currently models an Apple integration but returns simulated behavior.
- Voice Control currently models availability/recognition/execution without a genuine backend.
- FoundationModels is not yet integrated.
- capability reporting does not yet represent the complete runtime truth model.
- public documentation overstates some Apple integrations.

## Target architecture

```text
MCP Client / Agent
       |
       v
MCP Server + Stable Tool Contracts
       |
       v
Policy / Authorization / Audit
       |
       v
CapabilityRouter
  |        |          |            |
  v        v          v            v
Deterministic  Automation   Apple FM 26   Apple 27+
Provider       Provider     Provider      Providers
  |             |             |             |
  +-------------+-------------+-------------+
                        |
                        v
                Real local capability
```

### Core contracts

- `CapabilityID`
- `CapabilityStatus`
- `RuntimeCapabilities`
- `CapabilityRouter`
- `IntelligenceProvider`
- `GenerationRequest` / `GenerationResult`
- `StructuredGenerationRequest`
- `ModelAvailabilityReason`
- `ProviderMetadata`
- `ToolExecutionEvidence`

## Compatibility tiers

### Tier 0 — macOS 13+
MCP transport, policy/security, deterministic transforms, PII redaction, system information, health/capability inspection, logging/auditing, and only genuinely implemented Apple actions.

### Tier 1 — Apple automation
Real Shortcuts execution and enumeration; deterministic input/output, cancellation and timeouts; App Intents where genuinely exposed; Accessibility only as an explicit permissioned fallback.

### Tier 2 — macOS 26
Apple Foundation Models provider: availability, sessions, streaming, structured generation, tool adapter, transcript/session handling, and graceful fallback.

### Tier 3 — macOS 27+
Provider-neutral `LanguageModel` integration, Dynamic Profiles, multimodal input, relevant Vision/Spotlight system tools, PCC where appropriate, evaluation suites, and optional `fm`/Python interoperability.

## GSD execution model

Every plan follows:

**Discover → Contract → Implement → Prove → Integrate → Document → Gate**

A plan is complete only when its exit criteria and evidence are satisfied. Compilation alone is not completion.

## Phases

| Phase | Purpose | Plans |
|---|---|---|
| 0 | Baseline and truth | 0.1–0.4 |
| 1 | Capability kernel | 1.1–1.5 |
| 2 | Real Apple automation | 2.1–2.4 |
| 3 | macOS 26 Foundation Models | 3.1–3.6 |
| 4 | macOS 27 intelligence expansion | 4.1–4.7 |
| 5 | Security, evaluation, compatibility | 5.1–5.6 |
| 6 | Public product surface | 6.1–6.4 |

Detailed plans are in `PHASES_AND_PLANS.md`. Acceptance gates are in `ACCEPTANCE_GATES.md`. Test policy is in `TEST_STRATEGY.md`.

## Definition of done

LI MCP vNext is done when:
- no advertised side-effecting tool simulates success;
- capability discovery reports actual runtime state;
- macOS 13+ portable functionality remains operational;
- macOS 26 clients can use Apple on-device Foundation Models through stable MCP capabilities;
- macOS 27 clients gain newer features without changing the fundamental MCP contract;
- unavailable/disabled/not-ready/permission-denied states are distinguishable;
- model-to-tool execution is policy-controlled and auditable;
- compatibility, unit, integration, E2E, security, and evaluation gates pass;
- README claims match shipped behavior exactly;
- examples demonstrate both success and failure/fallback paths.
