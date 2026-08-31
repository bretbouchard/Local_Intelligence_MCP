# 🚀 Dev Team Handoff: GSD + Beads Work System

**Project**: Local Intelligence MCP  
**Date**: 2026-08-22  
**Status**: Ready for AI execution with Beads tracking  

---

## 📋 Quick Start

Your AI agent (Qwen3-Code:30B or similar) can now execute structured work using:

1. **Beads (`bd`)** - Work tracking system (already in your repo)
2. **GSD (Get Shit Done)** - 215 pre-broken-down tasks ready to execute

### First Steps

```bash
cd /Users/bretbouchard/apps/local_intelligence_mcp

# 1. Check what's tracked in Beads
bd list --status=open

# 2. Read the integration guide
cat docs/GSD_BEADS_INTEGRATION.md

# 3. Start AI on first GSD task
# AI will read: docs/gsd/tasks/AI_EXECUTION_GUIDE.md
```

---

## 🗂️ File Locations

### Beads (Work Tracking)

```
.beads/
├── local_intelligence_mcp.db    # SQLite database (already initialized)
├── issues.jsonl                 # Issue journal
├── bd.sock                      # Daemon socket
└── daemon.log                   # Activity log

Command: bd (already installed at /Users/bretbouchard/go/bin/bd)
```

**Existing Beads issues**:
- `local_intelligence_mcp-1`: Initialize project infrastructure (open)
- `local_intelligence_mcp-5`: Architectural Review (open)
- Others: See `bd list`

### GSD Plans (Execution Methodology)

```
docs/gsd/
├── MASTER_PLAN.md              # Overall vision & approach
├── PHASES_AND_PLANS.md         # Phase descriptions
├── ACCEPTANCE_GATES.md         # Quality gates per phase
├── TEST_STRATEGY.md            # Testing requirements
└── tasks/                      # ⭐ AI starts here
    ├── AI_EXECUTION_GUIDE.md   # How AI should execute
    ├── INDEX.md                # Task navigation
    ├── TASK_TEMPLATE.yaml      # Task structure reference
    ├── PHASE_0_TASKS.yaml      # 28 tasks (Baseline Truth)
    ├── PHASE_1_TASKS.yaml      # 42 tasks (Capability Detection)
    ├── PHASE_2_TASKS.yaml      # 32 tasks (Local Automation)
    ├── PHASE_3_TASKS.yaml      # 48 tasks (Foundation Models)
    └── PHASES_4_5_6_TASKS.yaml # 65 tasks (Future - deferred)
```

### Integration Documentation

```
docs/
├── GSD_BEADS_INTEGRATION.md    # ⭐ How they work together
└── SYSTEM_OVERVIEW.md          # Complete system reference
```

### Governance

```
docs/governance/
└── CONSTITUTION.md             # "ALL work must be tracked in bd issues"
```

---

## 🎯 How It Works

### The Two-System Approach

```
┌─────────────────────┐         ┌─────────────────────┐
│   GSD (Method)      │         │   Beads (State)     │
│                     │         │                     │
│ • 215 tasks         │────────▶│ • bd create         │
│ • Verification      │         │ • bd assign         │
│ • Dependencies      │         │ • bd set-state      │
│ • Acceptance        │         │ • bd close          │
│ • AI instructions   │         │ • bd query          │
└─────────────────────┘         └─────────────────────┘
       ↓                                 ↓
   WHAT & HOW                        WHO & WHEN
```

### Workflow Example

```bash
# 1. AI reads GSD task definition
cat docs/gsd/tasks/PHASE_0_TASKS.yaml | grep -A 30 "task_id: \"0.1.1\""

# 2. AI creates Beads issue from task
bd create --type=task --priority=1 \
  --title="[GSD 0.1.1] Enumerate all registered MCP tools" \
  --description="Create tool inventory per Phase 0 plan"

# 3. AI assigns and starts work
bd assign local_intelligence_mcp-8 ai
bd set-state local_intelligence_mcp-8 in-progress

# 4. AI executes (follows GSD task steps)
# ... implementation work ...

# 5. AI runs GSD verification
swift build
swift test --filter ToolInventoryTests

# 6. AI closes on success
bd close local_intelligence_mcp-8 --comment="Verified and committed"
```

---

## 📊 Current State

### GSD Phases

| Phase | Tasks | Status | Duration | Description |
|-------|-------|--------|----------|-------------|
| 0 | 28 | Ready | 2-3 days | Establish Truth Baseline |
| 1 | 42 | Ready | 3-4 days | Capability Detection System |
| 2 | 32 | Ready | 2-3 days | Local Automation (Shortcuts) |
| 3 | 48 | Ready* | 4-5 days | Foundation Models Integration |
| 4-6 | 65 | Deferred | TBD | Advanced features |

**Total**: 215 tasks defined and ready for execution

\* **Phase 3 Note**: Requires human research of Apple Foundation Models API before AI can start (see task 3.0.1)

### Beads Database

- **Location**: `.beads/local_intelligence_mcp.db`
- **Status**: Initialized and active
- **Existing issues**: 7+ (see `bd list`)
- **Daemon**: Running (bd.sock exists)

---

## 🚀 How to Start

### Option 1: Have AI Start Phase 0

```bash
# AI reads execution guide
cat docs/gsd/tasks/AI_EXECUTION_GUIDE.md

# AI creates Beads issues for Phase 0 tasks
# (or you can batch-create them)

# AI starts executing task-by-task
bd list --status=open --label=phase-0
```

### Option 2: Review First

```bash
# Read the master plan
cat docs/gsd/MASTER_PLAN.md

# Review Phase 0 tasks
cat docs/gsd/tasks/PHASE_0_TASKS.yaml

# Check current Beads state
bd status
bd list
```

### Option 3: Batch Import Tasks

```bash
# Parse YAML files and create all Beads issues upfront
# (Custom script needed - or AI can create them as it goes)

# Example for Phase 0:
for task in 0.1.1 0.1.2 0.1.3 ...; do
  bd create --type=task \
    --title="[GSD $task] Task name" \
    --label=phase-0 --label=gsd-task
done
```

---

## 📖 Key Documents to Read

### For Humans

1. **docs/GSD_BEADS_INTEGRATION.md** (5 min)
   - Complete integration guide
   - Command examples
   - Daily workflow

2. **docs/gsd/MASTER_PLAN.md** (10 min)
   - Vision and approach
   - Phase overview
   - Success criteria

3. **docs/gsd/PHASES_AND_PLANS.md** (15 min)
   - Detailed phase descriptions
   - What each phase accomplishes

### For AI Agents

1. **docs/gsd/tasks/AI_EXECUTION_GUIDE.md** ⭐ START HERE
   - How to execute tasks
   - Verification process
   - Error handling

2. **docs/gsd/tasks/PHASE_0_TASKS.yaml**
   - 28 concrete tasks
   - Step-by-step instructions
   - Verification commands

3. **docs/GSD_BEADS_INTEGRATION.md**
   - How to use `bd` commands
   - Creating and closing issues
   - Linking dependencies

---

## 🔧 Beads Commands Reference

### Viewing Work

```bash
# What's open?
bd list --status=open

# What's AI working on?
bd list --assignee=ai --status=in-progress

# Show details
bd show local_intelligence_mcp-1

# Query with filters
bd query 'status:open AND type:task'
bd query 'label:phase-0'
```

### Creating Issues

```bash
# Task
bd create --type=task --priority=1 \
  --title="Task name" \
  --description="Details"

# Bug
bd create --type=bug --priority=2 \
  --title="Bug description"

# Feature
bd create --type=feature --priority=3 \
  --title="Feature idea"
```

### Managing Work

```bash
# Assign
bd assign <issue-id> ai
bd assign <issue-id> human

# Update state
bd set-state <issue-id> in-progress
bd set-state <issue-id> blocked

# Add notes
bd note <issue-id> "Progress update"

# Close
bd close <issue-id> --comment="Completed"
```

### Dependencies

```bash
# Link dependencies
bd link <issue-2> depends-on <issue-1>
bd link <bug> blocks <task>

# View dependencies
bd dependencies <issue-id>
bd children <parent-id>
```

---

## ⚠️ Important Notes

### 1. Beads is Authoritative

All work **must** be tracked in Beads (`bd`) issues per `docs/governance/CONSTITUTION.md`:

> **Task Management**: ALL work must be tracked in bd issues

Don't use:
- ❌ GitHub Issues (Beads is primary)
- ❌ Markdown TODO files
- ❌ External trackers

### 2. GSD Provides Methodology

GSD doesn't replace Beads - it provides:
- Task breakdown
- Execution steps
- Verification commands
- Acceptance criteria

### 3. AI Should Self-Track

The AI agent should:
- Create Beads issues from GSD tasks
- Update status as it works
- Comment on progress
- Close on completion

### 4. Phase 3 Blocker

**Phase 3 cannot start until human completes task 3.0.1**:
- Research Apple Foundation Models API
- Create docs with real API signatures
- Prevent AI hallucination of non-existent APIs

See `docs/gsd/tasks/PHASE_3_TASKS.yaml` for details.

---

## 🎯 Success Criteria

You'll know it's working when:

1. ✅ AI creates Beads issues from GSD tasks
2. ✅ AI updates status as work progresses
3. ✅ `bd list` shows accurate work state
4. ✅ GSD verification commands all pass
5. ✅ Phase acceptance gates are met
6. ✅ No "lost" work - everything tracked

---

## 📞 Questions?

### Check These First

- **Integration**: `docs/GSD_BEADS_INTEGRATION.md`
- **GSD Overview**: `docs/gsd/MASTER_PLAN.md`
- **Beads Help**: `bd --help`
- **Constitution**: `docs/governance/CONSTITUTION.md`

### Common Questions

**Q: Should we use GitHub Issues?**  
A: No. Beads (`bd`) is the authoritative tracker per project constitution.

**Q: Where do we start?**  
A: AI reads `docs/gsd/tasks/AI_EXECUTION_GUIDE.md` and starts Phase 0.

**Q: How do we track AI progress?**  
A: `bd list --assignee=ai --status=in-progress`

**Q: What if a task is blocked?**  
A: AI creates a bug/blocker Bead and links it: `bd link <bug> blocks <task>`

**Q: Can we modify GSD tasks?**  
A: Yes, but update the YAML files and corresponding Beads issues.

---

## 📦 Deliverables

### What You're Getting

1. **215 GSD tasks** - Fully broken down, AI-executable
2. **Beads integration** - Already initialized and documented
3. **Execution guide** - Step-by-step for AI agent
4. **Quality gates** - Phase acceptance criteria
5. **Test strategy** - Comprehensive testing approach

### File Checklist

- [x] `.beads/` - Database initialized
- [x] `docs/gsd/MASTER_PLAN.md` - Vision
- [x] `docs/gsd/PHASES_AND_PLANS.md` - Phase details
- [x] `docs/gsd/ACCEPTANCE_GATES.md` - Quality gates
- [x] `docs/gsd/TEST_STRATEGY.md` - Testing
- [x] `docs/gsd/tasks/PHASE_0_TASKS.yaml` - 28 tasks
- [x] `docs/gsd/tasks/PHASE_1_TASKS.yaml` - 42 tasks
- [x] `docs/gsd/tasks/PHASE_2_TASKS.yaml` - 32 tasks
- [x] `docs/gsd/tasks/PHASE_3_TASKS.yaml` - 48 tasks
- [x] `docs/gsd/tasks/PHASES_4_5_6_TASKS.yaml` - 65 tasks
- [x] `docs/gsd/tasks/AI_EXECUTION_GUIDE.md` - AI start here
- [x] `docs/GSD_BEADS_INTEGRATION.md` - Integration guide
- [x] `docs/SYSTEM_OVERVIEW.md` - System reference

---

## 🎉 Ready to Start

The system is fully set up and ready for AI execution:

```bash
cd /Users/bretbouchard/apps/local_intelligence_mcp

# Let AI read the guide
cat docs/gsd/tasks/AI_EXECUTION_GUIDE.md

# Check Beads status
bd status
bd list

# Start Phase 0!
```

**Estimated completion**: 15-20 days for Phases 0-3 (150 tasks)

---

**Version**: 1.0  
**Last Updated**: 2026-08-22  
**Location**: `/Users/bretbouchard/apps/local_intelligence_mcp`  
**Prepared By**: GitHub Copilot CLI  
