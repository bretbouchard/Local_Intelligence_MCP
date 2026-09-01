# Security Notes

The authoritative security documentation is
[`docs/gsd/SECURITY_MODEL.md`](gsd/SECURITY_MODEL.md) (threat model, per-capability
permission and approval contracts, cross-version compatibility matrix), reviewed by
the Council of Ricks in [`docs/gsd/reviews/COUNCIL_REVIEW_2026_08_31.md`](gsd/reviews/COUNCIL_REVIEW_2026_08_31.md).

## What is actually enforced

- **Automation safety policy** — allow/deny shortcut-name lists via environment,
  destructive-name classification requiring explicit `confirm: true`, timeout
  clamping, and audit-logged allow/deny decisions.
- **Real permission verification** at the registry boundary — Accessibility via the
  AX API, Shortcuts CLI presence; permission types with no verifiable mechanism
  deny by default rather than pretending to be checked.
- **Injection resistance** — shortcut names are passed as direct `Process`
  arguments (no shell); option-prefixed and control-character names are rejected.
- **Structured-output validation** — model results must satisfy the requested
  JSON Schema subset; unsupported schema constructs are rejected explicitly,
  never silently ignored.
- **PII redaction** — default-on for summarization flows; hash mode uses real
  SHA-256 (CryptoKit).
- **Malformed-input hardening** — all JSON deserialization is validated before
  use; hostile numeric values (negative/overflowing timeouts) are rejected.

## Privacy

- All default processing is on-device. Private Cloud Compute exists only as an
  explicit opt-in provider class (`LI_ALLOW_PCC=1` plus per-request pinning) and
  is never used as an invisible fallback.
- Deterministic tools are pure computation and never persist user content.
- Capability reports contain no identifiers and cannot fingerprint the machine.

## Reporting

Please use [GitHub Issues](https://github.com/bretbouchard/Local_Intelligence_MCP/issues).
