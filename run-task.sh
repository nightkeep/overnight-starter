#!/bin/bash
# Run one task unattended with a fixed, narrow set of permissions.
# usage: ./run-task.sh <task-id>      (reads tasks/<task-id>.json)
#
# The permissions are passed on the command line instead of relying on
# .claude/settings.json: in our tests, project settings did not restrict an
# unattended run, and without --permission-mode dontAsk a user-level
# "auto" or "bypass" mode let the agent write anywhere. User-level settings
# are also skipped: their allow rules, hooks and MCP servers would otherwise be
# added on top of the list below.

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd -P)"
TASK="${1:-}"

case "$TASK" in
  ""|*[!A-Za-z0-9_-]*)
    echo "usage: ./run-task.sh <task-id>  (letters, digits, - and _ only)" >&2
    exit 1
    ;;
esac

if [ ! -f "$DIR/tasks/$TASK.json" ]; then
  echo "not found: tasks/$TASK.json" >&2
  exit 1
fi

mkdir -p "$DIR/work" "$DIR/results"

TOOLS="Read(/$DIR/**),Glob(/$DIR/**),Grep(/$DIR/**)"
TOOLS="$TOOLS,Edit(/$DIR/work/**),Edit(/$DIR/results/**)"
TOOLS="$TOOLS,WebSearch"

cd "$DIR"
exec claude -p "Do the task in tasks/$TASK.json. Follow CLAUDE.md. Finish by writing results/$TASK.md." \
  --setting-sources local \
  --strict-mcp-config \
  --permission-mode dontAsk \
  --disallowedTools "Bash" \
  --allowedTools "$TOOLS"
