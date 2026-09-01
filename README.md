# 🧠 Local Intelligence MCP

[![CI](https://github.com/bretbouchard/Local_Intelligence_MCP/actions/workflows/ci.yml/badge.svg)](https://github.com/bretbouchard/Local_Intelligence_MCP/actions/workflows/ci.yml)

A lightweight Swift Model Context Protocol (MCP) server that gives AI agents practical access to Apple's local intelligence and automation stack, using the best capabilities available on each Mac while preserving graceful support for older systems.

Local Intelligence MCP reports what your Mac can actually do at runtime, then routes work to genuine providers: Apple's on-device Foundation Model on macOS 26+, real Shortcuts automation, deterministic text analysis and OCR everywhere else — with Private Cloud Compute available only as an explicit opt-in. Unavailable capabilities return distinguishable machine-readable errors — nothing simulates success. Not developed, endorsed, or affiliated with Apple Inc.

## ✅ Key Points

- **Built independently** using Apple's public frameworks and Model Context Protocol support
- **Apple on-device generation** through Foundation Models on macOS 26+ (verified on Apple Silicon); `local_generate` never falls back to remote services
- **Image understanding** — deterministic Vision OCR by default; Apple multimodal analysis opt-in on macOS 27+
- **Real Shortcuts automation** — enumerate and execute the Shortcuts actually installed on the Mac, with truthful `didRun` reporting and a safety gate for destructive-looking names
- **Runtime capability discovery** — `local_capabilities` reports OS tier, Apple Intelligence/model state, permissions, and per-capability statuses; distinct states for unsupported / unavailable / disabled / not ready / permission denied
- **Deterministic by default** — summarization, extraction, and classification are pure computation unless you explicitly opt into the Apple model
- **Private Cloud Compute** — a separate opt-in provider class (`apple_pcc`, `LI_ALLOW_PCC=1`), pinned-only: never an invisible fallback from "local"
- **Privacy-first architecture**: all default processing runs locally

## ✨ Features

- **🔧 MCP Protocol**: stdio transport via the official MCP Swift SDK (34 registered tools)
- **🧩 Capability kernel**: stable `local_*` tool contracts over swappable providers (router, error taxonomy, deadlines, cancellation)
- **📝 Deterministic text tools**: `local_summarize`, `local_extract`, `local_classify` — reproducible, no model mediation needed
- **⚡ On-device generation**: `local_generate` on macOS 26+ Apple Intelligence Macs
- **🖼️ Image understanding**: `local_image_understand` — Vision OCR (deterministic, macOS 13+) or Apple multimodal analysis (macOS 27+)
- **🧾 Structured output**: optional JSON Schema validation of model output at the MCP boundary (`responseSchema`), with explicit rejection of unsupported schema constructs
- **🎛️ Generation profiles**: bounded, code-defined compositions of instructions, permitted tools and sampling (`profile`: default, precise, summarizer, support_triage)
- **🛠️ Model-callable tools**: opt-in allowlist (`tools`) letting the model invoke read-only capabilities through the same policy-checked router
- **🤖 Apple automation**: `local_automation_list`, `local_automation_execute` via the supported `shortcuts` CLI, wrapped in an audit-logged safety policy
- **📚 Book Intelligence**: PDF analysis and knowledge extraction for technical documents
- **🛡️ Privacy preserving**: PII redaction (real SHA-256 hash mode); capability reports never fingerprint the machine
- **📱 Offline capable**: deterministic tools and automation work without network connectivity
- **📦 Evidence bundle**: `LocalIntelligenceMCP evidence` emits machine-readable runtime truth for a release
- **🖥️ Reference consumer**: `LocalIntelligenceConsumer` — a working MCP client that spawns the server over stdio (the integration pattern for any app)

## Requirements

- **Swift**: 6.0 or later (Xcode 26+ toolchain for the Foundation Models provider)
- **Platforms**: macOS 13+ (portable tier); Apple Intelligence features require macOS 26+ with eligible hardware; Apple multimodal engine and PCC require macOS 27+
- **Automation**: macOS 12+ for the `shortcuts` CLI

## Capability availability

| Capability | macOS 13–25 | macOS 26+ (eligible) | macOS 26+ (ineligible/disabled) |
|------------|-------------|----------------------|---------------------------------|
| `local_capabilities` | ✅ | ✅ | ✅ |
| `local_summarize` / `local_extract` / `local_classify` | ✅ deterministic | ✅ deterministic (Apple model opt-in) | ✅ deterministic |
| `local_generate` | ❌ `UNSUPPORTED` | ✅ Apple on-device model | `UNSUPPORTED` / `DISABLED` / `NOT_READY` (distinguishable) |
| `local_image_understand` | ✅ Vision OCR | ✅ Vision OCR (+ Apple engine on macOS 27+) | ✅ Vision OCR |
| `local_automation_list` / `local_automation_execute` | ✅ (macOS 12+) | ✅ | ✅ |
| `voice_command` | ❌ `UNSUPPORTED` (no supported external API; never simulated) | ❌ | ❌ |

A ✅ still means the runtime check can refuse per-execution: a named Shortcut that doesn't exist fails with `PROVIDER_FAILURE` and the shortcut's own error message — never a fake success.

## Installation

### Build from Source

```bash
git clone https://github.com/bretbouchard/Local_Intelligence_MCP.git
cd Local_Intelligence_MCP
swift build -c release
```

### Run

The server communicates over **stdio** — an MCP client (Claude Desktop, your app, or the bundled consumer) spawns it as a child process:

```bash
.build/debug/LocalIntelligenceMCP start-command --mcp-mode
```

### Reference consumer

A bundled reference MCP client spawns the server and exercises it end-to-end:

```bash
swift build
.build/debug/LocalIntelligenceConsumer demo                                # full journey
.build/debug/LocalIntelligenceConsumer tools                               # tools/list
.build/debug/LocalIntelligenceConsumer call --name local_capabilities --args '{}'
.build/debug/LocalIntelligenceConsumer generate "Explain local-first AI in one line"
```

### Configuration (environment)

There is no server-side config file; behavior is configured through the environment:

```bash
export LI_AUTOMATION_ALLOWLIST="Alpha,Beta"   # only these shortcuts may execute (optional)
export LI_AUTOMATION_DENYLIST="Danger"        # these shortcuts may never execute
export LI_ALLOW_PCC=1                         # opt in to Private Cloud Compute (default off)
```

### Claude Desktop / any MCP client

```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "/absolute/path/to/.build/release/LocalIntelligenceMCP",
      "args": ["start-command", "--mcp-mode"]
    }
  }
}
```

## 🛠️ Available MCP Tools

Run `tools/list` for the authoritative list (34 tools) with real input schemas. Headline tools:

| Tool | Purpose | Key parameters |
|------|---------|----------------|
| `local_capabilities` | Runtime truth: OS tier, model state, permissions, per-capability statuses, providers | — |
| `local_generate` | On-device generation (macOS 26+); bounded `profile`; `responseSchema` validation; model-callable `tools` allowlist | `prompt` (required), `input`, `profile`, `responseSchema`, `tools`, `timeout` |
| `local_summarize` / `local_extract` / `local_classify` | Deterministic text pipeline; Apple engine opt-in (`engine: "apple"`) | `text` (required), `sentenceLimit` / `engine` |
| `local_image_understand` | Vision OCR (deterministic) or Apple image analysis (macOS 27+) | `imagePath` (required), `question`, `engine` |
| `local_automation_list` | List the Shortcuts actually installed | — |
| `local_automation_execute` | Execute a real Shortcut; `didRun` is truthful | `name` (required), `input`, `timeout`, `confirm` |
| `book.analyze` | PDF knowledge extraction | `content`, `domain`, `extractionTypes` |
| `apple_summarize`, `apple_text_rewrite`, `apple_text_normalize`, `apple_text_redact`, … | Deterministic audio/text processing suite (21 tools) | `text`/`content` + tool options |
| `system_info`, `health_ping`, `capabilities_list`, `model_info` | System introspection | — |

Full parameter contracts ship in every `tools/list` response. Runnable examples for every documented scenario live in [`examples/`](examples/README.md).

## 🔐 Security

Detailed model: [`docs/gsd/SECURITY_MODEL.md`](docs/gsd/SECURITY_MODEL.md).

- **Automation safety policy** (`SafetyGatedAutomationProvider`): allow/deny name lists via environment, destructive-name classification requiring explicit `confirm: true`, timeout clamping, audit-logged decisions
- **Real permission verification** at the registry boundary: Accessibility (AX API), Shortcuts CLI presence; unverifiable permission types deny by default
- **Injection resistance on automation**: shortcut names are passed as direct `Process` arguments (no shell), option-prefixed and control-character names rejected
- **Schema-validated structured output**: model results must satisfy the requested JSON Schema subset or the call fails; unsupported schema constructs are rejected explicitly
- **Private Cloud Compute is opt-in and pinned-only**: a normal request can never route to it, and it reports `DISABLED` until enabled
- **Truthful capability reporting**: `local_capabilities` exposes runtime state only — no machine fingerprinting

## 🧪 Testing

`swift test` runs the shipped suites — capability kernel, routing behavior, automation safety, structured-output validation, wire-boundary contract tests, image understanding, PCC gating, deterministic evaluation thresholds, reliability/performance, audio/text tools, book intelligence, and RuntimeCapabilities feature scenarios:

- **141 LocalIntelligenceMCPTests + 13 BDSTests, 0 failures** — including true end-to-end tests that spawn the real server process (discover, list, call, denial paths, restart, concurrent clients)
- [`examples/01–08`](examples/README.md) — scripted end-to-end stdio scenarios
- [`scripts/run_model_evals.sh`](scripts/run_model_evals.sh) — live-model evaluations (manual; all 4 pass on Apple Intelligence Macs)

## 📚 Documentation

- [**Examples**](examples/README.md) — runnable scenarios + reference consumer
- [**Capability Inventory**](docs/gsd/inventory/CAPABILITY_INVENTORY.md) — per-tool implementation status and truth baseline
- [**Security Model**](docs/gsd/SECURITY_MODEL.md) — threat model, permission contracts, compatibility matrix
- [**Master Plan / Phases**](docs/gsd/MASTER_PLAN.md) — the GSD execution specification and [phase plans](docs/gsd/PHASES_AND_PLANS.md)
- [**Council Review**](docs/gsd/reviews/COUNCIL_REVIEW_2026_08_31.md) — multi-perspective security/quality review (APPROVE) with remediation records
- [**Automation Boundaries**](docs/gsd/AUTOMATION_BOUNDARIES.md) — App Intents / Accessibility decisions
- [**MCP 2026-07-28 Gap Matrix**](docs/gsd/protocol/M0_PROTOCOL_INVENTORY.md) — protocol reconciliation status
- [**Constitution**](specs/constitution.md) — core principles and technical constraints
- [**Security Notes**](SECURITY.md) · [**CHANGELOG**](CHANGELOG.md)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the constitution and the truthfulness invariants (no simulated success, distinguishable failure states)
4. Add tests for new functionality
5. Ensure `swift test` passes
6. Submit a pull request

## License

MIT License - see [LICENSE](./LICENSE) file for details.

## Support

- [Issues](https://github.com/bretbouchard/Local_Intelligence_MCP/issues)
- [Discussions](https://github.com/bretbouchard/Local_Intelligence_MCP/discussions)

<p align="center">
  <a href="https://ko-fi.com/bretbouchard" target="_blank">
    <img src="https://cdn.ko-fi.com/cdn/kofi3.png?v=3" alt="Support me on Ko-fi" height="45" style="margin-right:10px;">
  </a>
  <a href="https://buymeacoffee.com/bretbouchard" target="_blank">
    <img src="https://www.buymeacoffee.com/assets/img/custom_images/yellow_img.png" alt="Buy Me a Coffee" height="45">
  </a>
</p>
