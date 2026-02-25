#!/usr/bin/env bash
# =============================================================================
# cline-multi.sh — Orchestrate parallel Cline CLI agents via tmux
#
# Usage:
#   ./cline-multi.sh start                              Start preconfigured agents
#   ./cline-multi.sh run <name> <project> "<task>" [t]  Start a single custom agent
#   ./cline-multi.sh status                             Show running agents
#   ./cline-multi.sh stop                               Kill all agents
#   ./cline-multi.sh attach                             Attach to tmux session
# =============================================================================

set -euo pipefail

SESSION="cline-agents"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Preconfigured agents ─────────────────────────────────────────────────────
# Format: "window-name|project-name|task|timeout"
# Uncomment and edit to match your workflow.

AGENTS=(
  # "tests|my-app|Run npm test and fix any failures. Commit to fix/tests.|600"
  # "review|my-api|Review recent changes for security issues.|300"
  # "docs|my-frontend|Update README with current API documentation.|300"
)

# ── Functions ────────────────────────────────────────────────────────────────

usage() {
  echo "cline-multi — parallel Cline agent orchestrator"
  echo ""
  echo "Commands:"
  echo "  start                              Start preconfigured agents"
  echo "  run <name> <project> <task> [t]    Start one custom agent"
  echo "  status                             Show running agents"
  echo "  stop                               Kill all agents"
  echo "  attach                             Attach to tmux session"
}

start_preconfigured() {
  if [[ ${#AGENTS[@]} -eq 0 ]]; then
    echo "No agents configured. Edit the AGENTS array in this script,"
    echo "or use: $0 run <name> <project> \"<task>\" [timeout]"
    exit 1
  fi

  tmux kill-session -t "$SESSION" 2>/dev/null || true
  local first=true count=0

  for cfg in "${AGENTS[@]}"; do
    IFS='|' read -r name project task timeout <<< "$cfg"
    timeout="${timeout:-600}"

    if $first; then
      tmux new-session -d -s "$SESSION" -n "$name"
      first=false
    else
      tmux new-window -t "$SESSION" -n "$name"
    fi

    tmux send-keys -t "$SESSION:$name" \
      "bash \"$SCRIPT_DIR/cline-project.sh\" '$project' '$task' '$timeout'" Enter
    count=$((count + 1))
    echo "  ✓ $name → $project"
  done

  echo ""
  echo "$count agent(s) started."
  echo "  Attach:  tmux attach -t $SESSION"
  echo "  Switch:  Ctrl+B, <number>"
  echo "  Detach:  Ctrl+B, D"
}

run_custom() {
  local name="$1" project="$2" task="$3" timeout="${4:-600}"

  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -n "$name"
  else
    tmux new-window -t "$SESSION" -n "$name"
  fi

  tmux send-keys -t "$SESSION:$name" \
    "bash \"$SCRIPT_DIR/cline-project.sh\" '$project' '$task' '$timeout'" Enter
  echo "  ✓ $name → $project"
  echo "  Attach:  tmux attach -t $SESSION"
}

show_status() {
  echo "Cline agents:"
  local pids
  pids=$(pgrep -f "cline -y" 2>/dev/null || true)

  if [[ -z "$pids" ]]; then
    echo "  No agents running."
  else
    echo "$pids" | while read -r pid; do
      local dir etime
      dir=$(readlink -f /proc/$pid/cwd 2>/dev/null || echo "?")
      etime=$(ps -p "$pid" -o etime= 2>/dev/null || echo "?")
      echo "  PID $pid | uptime $etime | $dir"
    done
  fi

  echo ""
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "tmux session '$SESSION':"
    tmux list-windows -t "$SESSION" -F "  #{window_index}: #{window_name}" 2>/dev/null || true
  else
    echo "No tmux session."
  fi
}

stop_all() {
  pkill -f "cline -y" 2>/dev/null || true
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  echo "All agents stopped."
}

# ── Main ─────────────────────────────────────────────────────────────────────

case "${1:-}" in
  start)   start_preconfigured ;;
  run)
    shift
    [[ $# -lt 3 ]] && { echo "Usage: $0 run <name> <project> \"<task>\" [timeout]"; exit 1; }
    run_custom "$@" ;;
  status)  show_status ;;
  stop)    stop_all ;;
  attach)  tmux attach -t "$SESSION" 2>/dev/null || echo "No session. Use 'start' or 'run' first." ;;
  *)       usage; exit 1 ;;
esac
