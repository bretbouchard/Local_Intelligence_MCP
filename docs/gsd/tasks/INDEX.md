# AI-Optimized GSD Task Breakdown - Complete Index

## Document Purpose

This index provides navigation across the complete AI-optimized task breakdown for Local Intelligence MCP vNext implementation using Qwen3-Code:30B.

## Core Documents

### Planning & Strategy

| Document | Purpose | Audience |
|----------|---------|----------|
| `MASTER_PLAN.md` | Overall vision and architecture | All stakeholders |
| `PHASES_AND_PLANS.md` | Original conceptual plan breakdown | Human reviewers |
| `ACCEPTANCE_GATES.md` | Quality gates for each phase | QA, reviewers |
| `TEST_STRATEGY.md` | Testing philosophy and requirements | Developers, QA |
| `tasks/AI_EXECUTION_GUIDE.md` | **START HERE for AI agents** | AI, developers |

### Task Definitions

| Document | Phase | Tasks | Est. Time | Priority |
|----------|-------|-------|-----------|----------|
| `tasks/TASK_TEMPLATE.yaml` | Template | 1 | - | Reference |
| `tasks/PHASE_0_TASKS.yaml` | 0: Truth | 28 | 2-3 days | CRITICAL |
| `tasks/PHASE_1_TASKS.yaml` | 1: Kernel | 42 | 3-4 days | CRITICAL |
| `tasks/PHASE_2_TASKS.yaml` | 2: Automation | 32 | 2-3 days | CRITICAL |
| `tasks/PHASE_3_TASKS.yaml` | 3: macOS 15 FM | 48 | 4-5 days | CRITICAL* |
| `tasks/PHASES_4_5_6_TASKS.yaml` | 4-6: Advanced | 65 | 6-8 days | DEFERRED |

\* Blocked on task 3.0.1 (human-completed Apple API documentation)

## Quick Navigation

### For AI Agents

**First Time Setup:**
1. Read `AI_EXECUTION_GUIDE.md`
2. Review `TASK_TEMPLATE.yaml`
3. Start with task 0.1.1 in `PHASE_0_TASKS.yaml`

**During Execution:**
- Current task → Find in `PHASE_X_TASKS.yaml`
- Need context → Check `docs/ai_context/` (if referenced)
- Verification fails → Review `TEST_STRATEGY.md`
- Gate check → Review `ACCEPTANCE_GATES.md`

### For Human Reviewers

**Daily Review:**
1. Check `TASK_STATUS.json` for progress
2. Review commits for task ID tags
3. Run full test suite: `swift test`
4. Verify gate criteria in `ACCEPTANCE_GATES.md`

**Phase Completion:**
1. Review phase gate in `ACCEPTANCE_GATES.md`
2. Check all priority 1 tasks complete
3. Run compatibility builds
4. Review documentation updates

### For Project Managers

**Progress Tracking:**
- Overall status: `TASK_STATUS.json`
- Daily summaries: `docs/progress/daily_YYYYMMDD.md`
- Phase milestones: `PHASES_AND_PLANS.md`

**Risk Monitoring:**
- Critical blocker: Task 3.0.1 (Apple API docs)
- Hallucination risk: Phase 3-4 (Apple-specific APIs)
- Integration risk: Phase 5 (cross-version compatibility)

## Task Breakdown Statistics

### Total Effort

```
Phase 0:  28 tasks × ~20-30 min avg = ~10-14 hours
Phase 1:  42 tasks × ~25-35 min avg = ~18-25 hours
Phase 2:  32 tasks × ~25-35 min avg = ~13-19 hours
Phase 3:  48 tasks × ~30-40 min avg = ~24-32 hours
Phase 4:  28 tasks × ~35-45 min avg = ~16-21 hours (deferred)
Phase 5:  22 tasks × ~35-45 min avg = ~13-17 hours (deferred)
Phase 6:  15 tasks × ~25-35 min avg = ~6-9 hours (concurrent)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total:   215 tasks                  ~100-137 hours

With AI efficiency gains: 60-90 hours (17-24 days @ 4 hrs/day)
```

### Priority Distribution

```
Priority 1 (Critical path): 87 tasks (40%)
Priority 2 (Important):     98 tasks (46%)
Priority 3 (Deferred):      30 tasks (14%)
```

### Dependency Chains

**Longest Critical Path:**
```
0.1.1 → 0.1.2 → 0.2.2 → 1.1.1 → 1.1.2 → 1.1.3 → ... → 3.6.1
Approximately 35 tasks in strict sequence
```

**Parallelizable Work:**
- Phase 0: 10 tasks can run in parallel (priority 2-3)
- Phase 1: 24 tasks can run in parallel
- Phase 2: 18 tasks can run in parallel
- Phase 6: Most tasks can run concurrent with Phase 3

## Critical Milestones

### Milestone 1: Truth Established (End of Phase 0)
- **Date Target**: Day 3
- **Criteria**:
  - ✅ No simulated side-effect success
  - ✅ Tool inventory complete
  - ✅ Baseline metrics captured
  - ✅ macOS 13 build works

### Milestone 2: Capability Kernel (End of Phase 1)
- **Date Target**: Day 7
- **Criteria**:
  - ✅ RuntimeCapabilities operational
  - ✅ CapabilityRouter routes to providers
  - ✅ local_* tools registered
  - ✅ Observability logging works

### Milestone 3: Real Automation (End of Phase 2)
- **Date Target**: Day 10
- **Criteria**:
  - ✅ Shortcuts execution works (integration test)
  - ✅ Permissions enforced
  - ✅ Timeout/cancellation work
  - ✅ Examples documented

### Milestone 4: Foundation Models (End of Phase 3)
- **Date Target**: Day 15
- **Criteria**:
  - ✅ Generation works on eligible hardware
  - ✅ Structured output validates
  - ✅ Tool calling respects policy
  - ✅ macOS 13-15 compatibility maintained

### Milestone 5: Release Ready (End of Phase 5-6)
- **Date Target**: Day 20
- **Criteria**:
  - ✅ Security tests pass
  - ✅ Documentation complete
  - ✅ Examples tested
  - ✅ Evidence bundle generated

## Risk Register

### High Risk Items

| Risk | Impact | Mitigation | Owner |
|------|--------|------------|-------|
| Task 3.0.1 not completed | Phase 3 blocked | Human must complete first | Human |
| AI hallucinates Apple APIs | Wrong implementation | Require API docs in ai_context/ | AI + Human |
| Tests pass but feature broken | False confidence | Manual integration testing | Human QA |
| Breaking changes to Tier 0 | Older macOS broken | Compatibility tests in CI | AI + CI |

### Medium Risk Items

| Risk | Impact | Mitigation |
|------|--------|------------|
| Task dependencies unclear | Out-of-order execution | Explicit dependency tracking |
| Verification commands fail | Blocked progress | Clear error messages, debugging guide |
| Performance regression | User impact | Baseline metrics, benchmarking |

## Context Documents Required

### Must Create Before Phase 3 (Human Task)

```
docs/ai_context/
├── foundation_models_api.md           ⚠️ REQUIRED for Phase 3
├── foundation_models_examples.swift   ⚠️ REQUIRED for Phase 3
```

### Recommended for Phase 2

```
docs/ai_context/
├── shortcuts_api_reference.md         Recommended
├── accessibility_api_reference.md     Recommended
```

### Optional (Can Create During Implementation)

```
docs/ai_context/
├── swift_concurrency_patterns.md      Optional
├── mcp_tool_schema_examples.md        Optional
├── error_handling_patterns.md         Optional
├── testing_patterns.md                Optional
```

## Verification Commands Reference

### Build & Test

```bash
# Full build
swift build

# All tests
swift test

# Specific test
swift test --filter TestClassName

# Specific test method
swift test --filter TestClassName.testMethod

# Build for specific SDK
swift build -Xswiftc -target -Xswiftc x86_64-apple-macos13.0
```

### Linting (if configured)

```bash
swiftlint lint
swiftformat --lint .
```

### Status Checks

```bash
# Current task status
cat TASK_STATUS.json | jq '.current_task'

# Completion percentage
cat TASK_STATUS.json | jq '.overall_completion'

# Failed tasks
cat TASK_STATUS.json | jq '.tasks | to_entries | map(select(.value.status == "failed"))'
```

## File Locations

### Source Code

```
Sources/LocalIntelligenceMCP/
├── Capability/          # Phase 1
│   ├── CapabilityID.swift
│   ├── RuntimeCapabilities.swift
│   └── ...
├── Routing/             # Phase 1
│   └── CapabilityRouter.swift
├── Providers/           # Phases 1-3
│   ├── IntelligenceProvider.swift
│   ├── Shortcuts/       # Phase 2
│   └── AppleFM/         # Phase 3
├── Tools/               # Phases 1-2
│   ├── LocalCapabilitiesTool.swift
│   └── ...
├── Errors/              # Phase 0-1
│   └── CapabilityError.swift
└── main.swift           # Integration
```

### Tests

```
Tests/
├── CapabilityTests/     # Phase 1
├── RoutingTests/        # Phase 1
├── ProviderTests/       # Phases 1-3
├── ToolTests/           # Phases 1-2
├── IntegrationTests/    # All phases
└── ...
```

### Documentation

```
docs/
├── gsd/                 # This directory
├── ai_context/          # API references for AI
├── inventory/           # Phase 0 output
├── compatibility/       # Phase 0, 5
├── automation/          # Phase 2
├── examples/            # Phase 6
├── security/            # Phases 2, 5
├── testing/             # Continuous
└── progress/            # Daily updates
```

## Common Commands

### Start New Task

```bash
# Read task definition
cat docs/gsd/tasks/PHASE_0_TASKS.yaml | grep -A 50 "task_id: \"0.1.1\""

# Check dependencies complete
cat TASK_STATUS.json | jq '.tasks["0.1.1"].dependencies'
```

### Complete Task

```bash
# Verify
swift build
swift test --filter TaskRelatedTests

# Update status
jq '.tasks["0.1.1"] = {"status": "complete", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' TASK_STATUS.json > tmp && mv tmp TASK_STATUS.json

# Commit
git add -A
git commit -m "feat(component): description [task 0.1.1]"
```

### Check Phase Completion

```bash
# Count completed vs total
PHASE=0
TOTAL=$(grep "^- task_id:" docs/gsd/tasks/PHASE_${PHASE}_TASKS.yaml | wc -l)
DONE=$(cat TASK_STATUS.json | jq "[.tasks | to_entries[] | select(.key | startswith(\"${PHASE}.\")) | select(.value.status == \"complete\")] | length")
echo "Phase $PHASE: $DONE / $TOTAL tasks complete"
```

## Support & Escalation

### When AI Gets Stuck

1. **Mark task blocked** in `TASK_STATUS.json`
2. **Document issue** clearly
3. **Save work** (commit or stash)
4. **Report** to human reviewer

### Human Review Triggers

- Task marked "blocked" for >1 hour
- Verification fails 3+ times
- API documentation missing
- Acceptance criteria unclear

## Next Steps

1. **AI Agent**: Read `AI_EXECUTION_GUIDE.md`
2. **Human**: Complete task 3.0.1 before Phase 3
3. **Team**: Review this index and ask questions
4. **All**: Execute Phase 0, validate approach

---

**Document Version**: 1.0  
**Last Updated**: 2026-08-22  
**Status**: Ready for execution  
**Total Tasks**: 215  
**Estimated Duration**: 17-24 days with AI  
