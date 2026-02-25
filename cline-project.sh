#!/usr/bin/env bash
# =============================================================================
# cline-project.sh — Run a Cline CLI agent scoped to a specific project
#
# Usage: ./cline-project.sh <project-name> "<task>" [timeout]
#
# Examples:
#   ./cline-project.sh my-app "fix the login bug in src/auth" 600
#   ./cline-project.sh my-api "run tests and fix failures"
#   ./cline-project.sh my-frontend "update README with API docs" 300
#
# Configuration:
#   Edit PROJECT_DIRS and PROJECT_PERMS below to match your projects.
#   Each project maps to a directory and a set of allowed shell commands.
# =============================================================================

set -euo pipefail

PROJECT="${1:-}"
TASK="${2:-}"
TIMEOUT="${3:-600}"

# ── Configuration ────────────────────────────────────────────────────────────
# Map project names → directories.
# Edit these to match your actual setup.

declare -A PROJECT_DIRS=(
  ["my-app"]="/projects/my-app"
  ["my-api"]="/projects/my-api"
  ["my-frontend"]="/projects/my-frontend"
  # Add your projects here:
  # ["project-name"]="/path/to/project"
)

# Map project names → allowed/denied commands (JSON).
DEFAULT_PERMS='{"allow":["npm *","npx *","git *","node *","cat *","ls *","grep *","find *","mkdir *","cp *","mv *","echo *","head *","tail *","wc *"],"deny":["rm -rf /","rm -rf ~","sudo *","chmod 777 *","git push *","curl * | bash"],"allowRedirects":true}'

declare -A PROJECT_PERMS=(
  # Override per project if needed:
  # ["my-api"]='{"allow":["npm *","git *","node *","python3 *","cat *","ls *"],"deny":["sudo *","git push *"]}'
)

# ── Validation ───────────────────────────────────────────────────────────────

if [[ -z "$PROJECT" || -z "$TASK" ]]; then
  echo "Usage: $0 <project-name> \"<task>\" [timeout]"
  echo ""
  echo "Available projects:"
  for p in "${!PROJECT_DIRS[@]}"; do
    echo "  $p  →  ${PROJECT_DIRS[$p]}"
  done
  exit 1
fi

DIR="${PROJECT_DIRS[$PROJECT]:-}"
if [[ -z "$DIR" ]]; then
  echo "Error: project '$PROJECT' not found."
  echo "Available: ${!PROJECT_DIRS[*]}"
  exit 1
fi

if [[ ! -d "$DIR" ]]; then
  echo "Error: directory '$DIR' does not exist."
  exit 1
fi

PERMS="${PROJECT_PERMS[$PROJECT]:-$DEFAULT_PERMS}"
CONFIG_DIR="$HOME/.cline-configs/$PROJECT"
mkdir -p "$CONFIG_DIR"

# ── Execute ──────────────────────────────────────────────────────────────────

echo "┌─ Cline Sub-Agent ────────────────────────────"
echo "│ Project:  $PROJECT"
echo "│ Dir:      $DIR"
echo "│ Config:   $CONFIG_DIR"
echo "│ Timeout:  ${TIMEOUT}s"
echo "│ Task:     $TASK"
echo "└──────────────────────────────────────────────"
echo ""

cd "$DIR"

CLINE_DIR="$CONFIG_DIR" \
CLINE_COMMAND_PERMISSIONS="$PERMS" \
  cline -y "$TASK" --timeout "$TIMEOUT"

EXIT_CODE=$?
echo ""
[[ $EXIT_CODE -eq 0 ]] && echo "✓ Task completed." || echo "✗ Task failed (exit $EXIT_CODE)."
exit $EXIT_CODE
