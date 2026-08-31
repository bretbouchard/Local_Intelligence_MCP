# 🐛 Bug Reports | 🌟 Feature Requests | 📝 Development Notes

## Quick Start

### Create New Issue

```bash
# Using script (recommended)
./scripts/new-issue.sh bug "Short description"
./scripts/new-issue.sh feature "Streaming support"
./scripts/new-issue.sh note "API design decision"

# Manually
cp docs/tracking/bugs/BUG-20260822-001-example.md docs/tracking/bugs/BUG-$(date +%Y%m%d)-001-my-bug.md
```

### List Issues

```bash
# All open issues
grep -r "Status: open" docs/tracking/

# By priority
grep -r "Priority: P0" docs/tracking/

# By type
ls docs/tracking/bugs/
ls docs/tracking/features/
ls docs/tracking/notes/
```

## Directory Structure

```
docs/tracking/
├── bugs/           # 🐛 Bug reports
├── features/       # 🌟 Feature requests  
├── notes/          # 📝 Dev notes & decisions
└── TRACKING.md     # Full documentation
```

## File Format

Each issue is a markdown file:

```
[TYPE]-YYYYMMDD-NNN-short-description.md
```

Examples:
- `BUG-20260822-001-shortcuts-timeout.md`
- `FEATURE-20260822-002-streaming.md`
- `NOTE-20260822-003-api-hallucination.md`

## Integration with GSD

Issues link to GSD tasks:

```markdown
## Linked Items

- GSD Task: 2.3.2 (where discovered)
- Blocking Tasks: 2.3.3, 2.3.4
```

TASK_STATUS.json tracks blockers:

```json
{
  "tasks": {
    "2.3.3": {
      "status": "blocked",
      "blocked_by": "BUG-20260822-001"
    }
  }
}
```

## Examples

See example files:
- [Bug Example](bugs/BUG-20260822-001-example.md)
- [Feature Example](features/FEATURE-20260822-001-example.md)
- [Note Example](notes/NOTE-20260822-001-example.md)

## GitHub Integration

GitHub issue templates are in `.github/ISSUE_TEMPLATE/`:
- `bug.yml` - Bug report template
- `feature.yml` - Feature request template
- `note.yml` - Development note template

Create GitHub issue → reference local tracking file

## Quick Reference

### Status Values
- `open` - Identified, not started
- `in-progress` - Actively working
- `blocked` - Waiting on dependency
- `resolved` - Fixed/completed
- `wontfix` - Decided not to address

### Priority Levels
- `P0-critical` - Blocks release
- `P1-high` - Important, current phase
- `P2-medium` - Should do, next phase ok
- `P3-low` - Nice to have, backlog

### Common Commands

```bash
# Create bug
./scripts/new-issue.sh bug "Description"

# Find P0 issues
grep -r "Priority: P0" docs/tracking/

# List by date
ls -lt docs/tracking/bugs/

# Count open issues
grep -r "Status: open" docs/tracking/ | wc -l

# Mark as resolved
sed -i '' 's/Status: open/Status: resolved/' docs/tracking/bugs/BUG-*.md
```

## For AI Agents

When encountering issues:

```markdown
**Bug found during task X.Y.Z**

Creating: docs/tracking/bugs/BUG-YYYYMMDD-NNN-description.md
Priority: P1 (blocks current phase) 
Action: [fix now | defer | needs discussion]
```

## Documentation

Full documentation: [TRACKING.md](TRACKING.md)

---

**Total Issues**: `find docs/tracking -name "*.md" -not -name "*example*" | wc -l`  
**Open Issues**: `grep -r "Status: open" docs/tracking/ | wc -l`  
**Last Updated**: Run `date`  
