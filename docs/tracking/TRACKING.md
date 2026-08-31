# Issue Tracking & GSD Integration

## Overview

This repo uses a simple but effective issue tracking system integrated with the GSD (Get Shit Done) task workflow.

## Directory Structure

```
docs/tracking/
├── bugs/           # Bug reports
├── features/       # Feature requests
├── notes/          # Development notes & decisions
└── TRACKING.md     # This file

.github/ISSUE_TEMPLATE/  # GitHub issue templates
├── bug.yml
├── feature.yml
└── note.yml
```

## Issue Naming Convention

All tracked items use this format:

```
[TYPE]-YYYYMMDD-NNN-short-description.md

Examples:
BUG-20260822-001-shortcuts-timeout.md
FEATURE-20260822-002-voice-input.md
NOTE-20260822-003-api-hallucination-risk.md
```

### Types

- **BUG**: Something broken or not working as intended
- **FEATURE**: New capability or enhancement request
- **NOTE**: Design decision, observation, or reminder

## File Template

Each tracking file contains:

```markdown
# [TYPE] Short Description

**ID**: TYPE-YYYYMMDD-NNN
**Status**: [open | in-progress | blocked | resolved | wontfix]
**Priority**: [P0-critical | P1-high | P2-medium | P3-low]
**Created**: YYYY-MM-DD
**Updated**: YYYY-MM-DD
**Assignee**: [human | ai | unassigned]

## Description

[Clear description of the issue/feature/note]

## Context

[Background information, why this matters]

## Linked Items

- GSD Task: [task_id if applicable]
- Related Issues: [other issue IDs]
- PR/Commit: [if resolved]

## Acceptance Criteria (for features/bugs)

- [ ] Criterion 1
- [ ] Criterion 2

## Resolution (when resolved)

[How it was resolved, what was learned]

## Tags

#tag1 #tag2 #phase0
```

## Integration with GSD Tasks

### Bug Found During Task Execution

```bash
# AI finds bug while working on task 1.2.3
1. Create bug file: docs/tracking/bugs/BUG-20260822-001-router-crash.md
2. Link to task: "Found during: GSD Task 1.2.3"
3. Update TASK_STATUS.json: task 1.2.3 blocked by BUG-20260822-001
4. Continue with next task or fix bug
```

### Feature Request

```bash
# User or AI identifies feature need
1. Create feature file: docs/tracking/features/FEATURE-20260822-002-streaming.md
2. Assess priority and complexity
3. If needed, create GSD tasks for implementation
4. Link feature to tasks
```

### Development Notes

```bash
# AI encounters important decision or observation
1. Create note: docs/tracking/notes/NOTE-20260822-003-cache-strategy.md
2. Document decision and rationale
3. Link to relevant code/tasks
```

## Quick Commands

### Create New Issue

```bash
# Bug
./scripts/new-issue.sh bug "Shortcuts timeout after 5s"

# Feature
./scripts/new-issue.sh feature "Add streaming support"

# Note
./scripts/new-issue.sh note "API cache invalidation strategy"
```

### List Issues

```bash
# All open issues
find docs/tracking -name "*.md" -exec grep -l "Status: open" {} \;

# P0 critical bugs
find docs/tracking/bugs -name "*.md" -exec grep -l "Priority: P0" {} \;

# Issues from today
find docs/tracking -name "*-20260822-*.md"
```

### Update Issue Status

```bash
# Mark as resolved
sed -i '' 's/Status: open/Status: resolved/' docs/tracking/bugs/BUG-20260822-001-*.md
```

## Status Workflow

```
open → in-progress → resolved
  ↓         ↓
blocked   wontfix
```

- **open**: Identified but not started
- **in-progress**: Actively being worked on
- **blocked**: Waiting on dependency
- **resolved**: Fixed/implemented
- **wontfix**: Decided not to address

## Priority Levels

- **P0-critical**: Blocks release, immediate attention
- **P1-high**: Important, address in current phase
- **P2-medium**: Should do, next phase acceptable
- **P3-low**: Nice to have, backlog

## Integration with TASK_STATUS.json

```json
{
  "tasks": {
    "1.2.3": {
      "status": "blocked",
      "blocked_by": "BUG-20260822-001",
      "blocked_since": "2026-08-22T14:30:00Z"
    }
  },
  "issues": {
    "BUG-20260822-001": {
      "type": "bug",
      "status": "in-progress",
      "priority": "P1-high",
      "blocking_tasks": ["1.2.3"]
    }
  }
}
```

## GitHub Integration

If using GitHub Issues:

1. Create issue using template
2. Reference local tracking file
3. Use labels: bug, feature, note, P0, P1, etc.
4. Link to GSD tasks in description

## AI Agent Guidelines

### When to Create Bug

- Code doesn't compile after task
- Test fails unexpectedly
- Verification command fails
- Discovered existing broken functionality

### When to Create Feature

- Enhancement idea emerges
- Better approach identified
- User need discovered

### When to Create Note

- Important design decision made
- API limitation discovered
- Temporary workaround applied
- Future refactoring needed

### Template for AI

```markdown
I encountered [bug|feature|note] while working on task X.Y.Z:

Creating tracking file: docs/tracking/[type]/[ID]-[description].md

Priority: [P0|P1|P2|P3]
Impact: [what breaks or what improves]
Recommendation: [fix now | defer | needs discussion]
```

## Maintenance

### Weekly Review

```bash
# Count open issues by priority
for p in P0 P1 P2 P3; do
  echo "$p: $(find docs/tracking -name '*.md' -exec grep -l "Priority: $p" {} \; | wc -l)"
done

# Age of open issues
find docs/tracking -name "*.md" -exec grep -l "Status: open" {} \; | sort
```

### Cleanup Resolved

```bash
# Archive resolved issues older than 30 days
mkdir -p docs/tracking/archive/$(date +%Y-%m)
find docs/tracking -name "*.md" -mtime +30 -exec grep -l "Status: resolved" {} \; -exec mv {} docs/tracking/archive/$(date +%Y-%m)/ \;
```

## Examples

See:
- `docs/tracking/bugs/BUG-20260822-001-example.md`
- `docs/tracking/features/FEATURE-20260822-001-example.md`
- `docs/tracking/notes/NOTE-20260822-001-example.md`

## Migration from GitHub Issues

```bash
# Export GitHub issues to local tracking
gh issue list --json number,title,state,labels,createdAt --jq '.[] | 
  "docs/tracking/" + 
  (if (.labels | map(.name) | contains(["bug"])) then "bugs/BUG" 
   elif (.labels | map(.name) | contains(["enhancement"])) then "features/FEATURE" 
   else "notes/NOTE" end) + 
  "-" + (.createdAt | split("T")[0] | gsub("-";"")) + 
  "-" + (.number | tostring | tonumber | tostring | .[0:3]) + 
  "-" + (.title | gsub(" ";"-") | ascii_downcase) + ".md"'
```

---

**Version**: 1.0  
**Last Updated**: 2026-08-22  
**Maintainer**: AI + Human collaborative  
