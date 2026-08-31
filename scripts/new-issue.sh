#!/bin/bash
# new-issue.sh - Create a new bug/feature/note tracking file

set -euo pipefail

TYPE="${1:-}"
DESCRIPTION="${2:-}"

if [[ -z "$TYPE" ]] || [[ -z "$DESCRIPTION" ]]; then
    echo "Usage: $0 <bug|feature|note> \"Short description\""
    exit 1
fi

TYPE_UPPER=$(echo "$TYPE" | tr '[:lower:]' '[:upper:]')
case "$TYPE_UPPER" in
    BUG) DIR="docs/tracking/bugs"; PRIORITY="P2-medium" ;;
    FEATURE) DIR="docs/tracking/features"; PRIORITY="P3-low" ;;
    NOTE) DIR="docs/tracking/notes"; PRIORITY="P2-medium" ;;
    *) echo "Error: TYPE must be bug, feature, or note"; exit 1 ;;
esac

DATE=$(date +%Y%m%d)
COUNT=$(find "$DIR" -name "${TYPE_UPPER}-${DATE}-*.md" 2>/dev/null | wc -l | tr -d ' ')
NUM=$(printf "%03d" $((COUNT + 1)))
SLUG=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g')

ID="${TYPE_UPPER}-${DATE}-${NUM}"
FILENAME="${DIR}/${ID}-${SLUG}.md"
mkdir -p "$DIR"

cat > "$FILENAME" << EOF
# ${TYPE_UPPER}: ${DESCRIPTION}

**ID**: ${ID}  
**Status**: open  
**Priority**: ${PRIORITY}  
**Created**: $(date +%Y-%m-%d)  
**Updated**: $(date +%Y-%m-%d)  
**Assignee**: unassigned  

## Description

${DESCRIPTION}

## Context

*(Add context here)*

## Linked Items

- GSD Task: *(if applicable)*
- Related Issues: *(if any)*

## Tags

#${TYPE} #untagged
EOF

echo "Created: $FILENAME"
