# GSD + Beads Integration Guide

## Critical Understanding

**GSD (Get Shit Done)** = Execution methodology and task decomposition  
**Beads (`bd`)** = Work tracking, issue state, and dependency management

## The Relationship

```
┌─────────────────────────────────────────────────────────────┐
│                  GSD + Beads Together                       │
└─────────────────────────────────────────────────────────────┘

GSD defines HOW:
├── Task breakdown (215 atomic tasks)
├── Verification commands
├── Acceptance criteria
├── Dependencies between tasks
└── Quality gates

Beads (`bd`) tracks STATE:
├── Which tasks are in progress
├── Which are blocked
├── Who's assigned
├── Comments and notes
├── Real-time status
└── Dependency chain
```

## Beads in This Repository

Beads is already initialized and actively used:

```bash
Location:     .beads/
Database:     .beads/local_intelligence_mcp.db
Socket:       .beads/bd.sock
Issues file:  .beads/issues.jsonl
```

Existing issues:
- `local_intelligence_mcp-1`: Initialize project infrastructure
- `local_intelligence_mcp-2`: Design Book Intelligence (closed)
- `local_intelligence_mcp-5`: Architectural Review (open)
- More...

## Integration Workflow

### Phase 1: Create Beads Issues from GSD Tasks

```bash
# For each GSD phase, create a parent bead
cd /Users/bretbouchard/apps/local_intelligence_mcp

# Create Phase 0 parent
bd create --type=task \
  --title="[GSD] Phase 0: Establish Truth Baseline" \
  --description="Complete all 28 tasks in Phase 0 to establish accurate system inventory"

# Create child issues for each task
bd create --type=task \
  --title="[GSD 0.1.1] Enumerate all registered MCP tools" \
  --description="Map all tools to source files, create inventory JSON"

# Link as dependency
bd link <phase-0-id> depends-on <task-0.1.1-id>
```

### Phase 2: Execute with Beads Tracking

```bash
# AI working on a task

# 1. Check Beads for next task
bd list --status=open --type=task | grep "\[GSD"

# 2. Assign to self (AI)
bd assign <issue-id> ai

# 3. Add note when starting
bd note <issue-id> "Starting implementation: reading task definition from PHASE_0_TASKS.yaml"

# 4. Execute GSD task steps
# (follow AI_EXECUTION_GUIDE.md)

# 5. Run verification
swift build
swift test

# 6. If bug found, create Bead
bd create --type=bug \
  --title="Shortcuts timeout hardcoded at 5s" \
  --description="Found during task 2.3.2: timeout needs to be configurable"

# 7. Link bug to task
bd link <bug-id> blocks <task-id>

# 8. Update task status
bd set-state <task-id> blocked

# 9. When task complete
bd close <task-id> --comment="All verification passed, code committed"
```

### Phase 3: Query Status

```bash
# Human checks progress
bd list --status=open --type=task | wc -l     # Open tasks
bd list --status=blocked                       # Blocked tasks
bd query 'status:open AND label:P0'          # Critical issues

# Check GSD phase progress
bd list --title="[GSD] Phase 0" --children    # All Phase 0 tasks

# Find blockers
bd query 'label:blocker'
bd children <phase-id> --status=blocked
```

## Beads Commands for GSD

### Creating Issues

```bash
# Task (from GSD task list)
bd create --type=task --priority=1 \
  --title="[GSD 1.2.3] Implement CapabilityRouter" \
  --description="Create routing logic per GSD Phase 1 plan"

# Bug (found during execution)
bd create --type=bug --priority=2 \
  --title="RuntimeCapabilities crashes on macOS 13" \
  --description="Found during task 1.1.3"

# Feature (enhancement idea)
bd create --type=feature --priority=3 \
  --title="Add streaming support to local_generate" \
  --description="Defer to Phase 4"

# Note (design decision)
bd create --type=note --priority=1 \
  --title="Apple FM API needs human research" \
  --description="BLOCKS Phase 3 - AI cannot proceed without real API docs"
```

### Linking Dependencies

```bash
# Task blocks task
bd link <task-id-2> depends-on <task-id-1>

# Bug blocks task
bd link <bug-id> blocks <task-id>

# Feature depends on phase completion
bd link <feature-id> depends-on <phase-3-complete-id>

# View dependency chain
bd children <parent-id>
bd dependencies <issue-id>
```

### State Management

```bash
# Start work
bd assign <issue-id> ai
bd set-state <issue-id> in-progress

# Block on dependency
bd set-state <issue-id> blocked
bd note <issue-id> "Blocked by BUG-123: need API docs"

# Complete
bd close <issue-id> --comment="Task verified and committed"

# Reopen if needed
bd reopen <issue-id> --comment="Test regression found"
```

### Querying

```bash
# GSD-specific queries
bd query 'title:~"[GSD" AND status:open'       # All open GSD tasks
bd query 'label:phase-0 AND status:open'       # Phase 0 tasks
bd query 'label:P0 AND type:bug'               # Critical bugs
bd query 'assignee:ai AND status:in-progress'  # What AI is working on

# Dependencies
bd query 'is:blocked'                          # All blocked issues
bd query 'has:blockers'                        # Issues blocking others

# By time
bd list --created-after="2026-08-22"           # Today's issues
bd stale --days=7                              # Stale issues
```

## GSD Task → Beads Mapping

### Example: Phase 0, Task 0.1.1

**In GSD** (`docs/gsd/tasks/PHASE_0_TASKS.yaml`):
```yaml
task_id: "0.1.1"
name: "Enumerate all registered MCP tools"
estimated_time: "30 minutes"
priority: 1
dependencies: []
verification:
  commands:
    - cmd: "swift build"
      expected_exit: 0
```

**In Beads**:
```bash
# Create issue
ID=$(bd create --type=task --priority=1 \
  --title="[GSD 0.1.1] Enumerate all registered MCP tools" \
  --description="Create tool inventory with classification and source mapping" \
  --output-id)

# Add labels
bd label $ID add phase-0 gsd-task P1

# Add note with GSD reference
bd note $ID "GSD Task Definition: docs/gsd/tasks/PHASE_0_TASKS.yaml:0.1.1"

# Execute...
# When complete:
bd close $ID --comment="Tool inventory created at docs/inventory/tools.json. All verification passed."
```

## Labels to Use

Suggested label scheme:

```
# Phase
phase-0, phase-1, phase-2, phase-3, phase-4, phase-5, phase-6

# Priority (GSD)
P0-critical, P1-high, P2-medium, P3-low

# Type markers
gsd-task          # Created from GSD task breakdown
blocker           # Blocking other work
needs-human       # Requires human intervention
api-research      # Needs API documentation

# Status markers
verified          # Verification commands passed
committed         # Code committed
documented        # Documentation updated
```

## Daily Workflow

### AI Agent Morning Routine

```bash
cd /Users/bretbouchard/apps/local_intelligence_mcp

# 1. What am I working on?
bd list --assignee=ai --status=in-progress

# 2. What's next?
bd list --status=open --type=task --label=gsd-task | head -5

# 3. Any blockers to resolve?
bd query 'status:blocked AND assignee:ai'

# 4. Start next task
NEXT=$(bd list --status=open --label=phase-0 --output-format=json | jq -r '.[0].id')
bd assign $NEXT ai
bd set-state $NEXT in-progress
bd note $NEXT "Starting: reading GSD task definition"
```

### Human Review Routine

```bash
# 1. Overall status
bd status

# 2. What's AI working on?
bd list --assignee=ai --status=in-progress

# 3. Critical issues
bd query 'label:P0-critical AND status:open'

# 4. Blocked tasks
bd query 'status:blocked'

# 5. Tasks needing human
bd query 'label:needs-human'
```

## Integration Points

### GSD Files Reference Beads

In `docs/gsd/tasks/AI_EXECUTION_GUIDE.md`, add:

```markdown
## Before Starting

1. Check Beads for your next assignment:
   ```bash
   bd list --assignee=ai --status=open --label=gsd-task
   ```

2. When starting a task:
   ```bash
   bd assign <issue-id> ai
   bd set-state <issue-id> in-progress
   ```

3. Found an issue? Create a Bead immediately.
```

### Beads Issues Reference GSD

In each Bead description:

```markdown
GSD Task: 0.1.1 (see docs/gsd/tasks/PHASE_0_TASKS.yaml)
Verification: swift build && swift test --filter ToolInventoryTests
Acceptance: docs/gsd/ACCEPTANCE_GATES.md Phase 0
```

## Migration Plan

### Step 1: Create Phase Parent Issues

```bash
for phase in 0 1 2 3 4 5 6; do
  bd create --type=task \
    --title="[GSD] Phase $phase" \
    --description="See docs/gsd/PHASES_AND_PLANS.md for details" \
    --label=phase-$phase --label=gsd-parent
done
```

### Step 2: Import Tasks as Children

```bash
# Script to parse PHASE_X_TASKS.yaml and create Beads
# For each task in YAML:
#   bd create --type=task --title="[GSD X.Y.Z] ..." --label=phase-X
#   bd link <phase-parent-id> has-child <task-id>
```

### Step 3: Use Going Forward

All new work goes through Beads:
- AI checks `bd list` for next task
- AI creates Beads for bugs/features/notes
- Human reviews through `bd query`
- Status tracked in Beads, methodology in GSD

## Key Points

✅ **Beads is authoritative** for work state  
✅ **GSD is authoritative** for how to execute  
✅ **Both work together** for complete workflow  
✅ **Don't duplicate**: GSD tasks → Beads issues  
✅ **Link liberally**: Dependencies make blockers visible  
✅ **Query often**: `bd list` shows what's next  
✅ **Comment always**: Every state change gets a note  

---

**Remember**: When I say "check bd", I mean Beads. When I say "work the GSD plan", execute using the Beads-tracked tasks from the GSD methodology.
