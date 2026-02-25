#!/usr/bin/env bash
# =============================================================================
# cline-cron.sh — Run scheduled multi-agent tasks via cron/OpenClaw heartbeat
#
# Reads task definitions from a YAML-like config and dispatches Cline agents.
# Designed for periodic automated work (code review, tests, audits).
#
# Usage:
#   bash cline-cron.sh <config-file>
#   bash cline-cron.sh tasks.conf
#
# Config format (one task per block, separated by ---):
#   name: audit-api
#   project: /home/ubuntu/upbro
#   task: Run security audit on api/ directory
#   timeout: 600
#   output: /tmp/cline-results/audit-api.md
#   model: kwaipilot/kat-coder-pro
#   parallel: true
#   clineignore: node_modules/,.next/,dist/,venv/
#
# Set CLINE_CRON_LOG to customize log path (default: ~/.cline-cron.log)
# =============================================================================

set -euo pipefail

CONFIG="${1:-}"
LOG="${CLINE_CRON_LOG:-$HOME/.cline-cron.log}"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
SESSION="cline-cron-$$"

if [[ -z "$CONFIG" || ! -f "$CONFIG" ]]; then
  echo "Usage: $0 <config-file>"
  exit 1
fi

log() { echo "[$TIMESTAMP] $*" | tee -a "$LOG"; }

# Parse config into arrays
declare -a NAMES PROJECTS TASKS TIMEOUTS OUTPUTS MODELS PARALLEL CLINEIGNORES
idx=0

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"  # strip comments
  [[ -z "${line// /}" ]] && continue
  
  if [[ "$line" == "---" ]]; then
    idx=$((idx + 1))
    continue
  fi
  
  key="${line%%:*}"
  val="${line#*: }"
  key="$(echo "$key" | tr -d ' ')"
  
  case "$key" in
    name)        NAMES[$idx]="$val" ;;
    project)     PROJECTS[$idx]="$val" ;;
    task)        TASKS[$idx]="$val" ;;
    timeout)     TIMEOUTS[$idx]="$val" ;;
    output)      OUTPUTS[$idx]="$val" ;;
    model)       MODELS[$idx]="$val" ;;
    parallel)    PARALLEL[$idx]="$val" ;;
    clineignore) CLINEIGNORES[$idx]="$val" ;;
  esac
done < "$CONFIG"

TOTAL=${#NAMES[@]}
log "Starting cline-cron with $TOTAL task(s)"

# Default permissions
DEFAULT_PERMS='{"allow":["cat *","ls *","grep *","find *","head *","tail *","wc *","echo *","node *","npm *","npx *","git *","python3 *"],"deny":["rm -rf /","rm -rf ~","sudo *","git push *"],"allowRedirects":true}'

# Check for parallel mode
HAS_PARALLEL=false
for i in $(seq 0 $((TOTAL - 1))); do
  [[ "${PARALLEL[$i]:-false}" == "true" ]] && HAS_PARALLEL=true
done

run_agent() {
  local i=$1
  local name="${NAMES[$i]}"
  local project="${PROJECTS[$i]}"
  local task="${TASKS[$i]}"
  local timeout="${TIMEOUTS[$i]:-600}"
  local output="${OUTPUTS[$i]:-}"
  local model="${MODELS[$i]:-}"
  local clineignore="${CLINEIGNORES[$i]:-}"
  
  log "  Agent '$name' → $project (timeout: ${timeout}s)"
  
  # Create .clineignore if specified
  if [[ -n "$clineignore" ]]; then
    local ignore_file="$project/.clineignore"
    if [[ ! -f "$ignore_file" ]]; then
      echo "$clineignore" | tr ',' '\n' > "$ignore_file"
      log "  Created .clineignore in $project"
    fi
  fi
  
  # Build task with output instruction
  local full_task="$task"
  if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    full_task="$task. Write results to $output in Markdown format."
  fi
  
  # Build cline command
  local cmd="cd '$project'"
  cmd+=" && CLINE_DIR=\$HOME/.cline-configs/${name}"
  cmd+=" CLINE_COMMAND_PERMISSIONS='$DEFAULT_PERMS'"
  
  if [[ -n "$model" ]]; then
    cmd+=" cline -y -m '$model' '$full_task' --timeout $timeout"
  else
    cmd+=" cline -y '$full_task' --timeout $timeout"
  fi
  
  # Ensure config dir exists with auth
  mkdir -p "$HOME/.cline-configs/$name"
  if [[ -d "$HOME/.cline/data" && ! -d "$HOME/.cline-configs/$name/data" ]]; then
    cp -r "$HOME/.cline/"* "$HOME/.cline-configs/$name/" 2>/dev/null || true
  fi
  
  echo "$cmd"
}

if $HAS_PARALLEL; then
  # Parallel execution via tmux
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  FIRST=true
  
  for i in $(seq 0 $((TOTAL - 1))); do
    name="${NAMES[$i]}"
    cmd=$(run_agent "$i")
    
    if $FIRST; then
      tmux new-session -d -s "$SESSION" -n "$name"
      FIRST=false
    else
      tmux new-window -t "$SESSION" -n "$name"
    fi
    
    tmux send-keys -t "$SESSION:$name" "$cmd" Enter
    sleep 2  # stagger launches to avoid rate limits
  done
  
  log "All $TOTAL agents launched in parallel (tmux session: $SESSION)"
  log "Monitor with: tmux attach -t $SESSION"
  
else
  # Sequential execution
  for i in $(seq 0 $((TOTAL - 1))); do
    name="${NAMES[$i]}"
    cmd=$(run_agent "$i")
    log "Running agent '$name'..."
    eval "$cmd" 2>&1 | tee -a "$LOG" || log "  Agent '$name' failed"
    log "  Agent '$name' done"
  done
fi

log "cline-cron finished"
