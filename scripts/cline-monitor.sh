#!/usr/bin/env bash
# =============================================================================
# cline-monitor.sh — Usage monitor for Cline CLI sub-agents
#
# Scans task_metadata.json and api_conversation_history.json across all
# CLINE_DIR configs. Reports daily/total usage and warns on thresholds.
#
# Usage: bash cline-monitor.sh [--json] [--quiet]
#
# Requires: Python 3 with json/glob/os (stdlib only)
# =============================================================================

set -euo pipefail

JSON_ONLY=false
QUIET=false
for arg in "$@"; do
  case "$arg" in
    --json) JSON_ONLY=true ;;
    --quiet) QUIET=true ;;
  esac
done

# Find a working Python (prefer venv, fallback to system)
PY=""
for candidate in \
  "$HOME/instagram-automation/venv/bin/python3" \
  "$HOME/.venv/bin/python3" \
  "$(which python3 2>/dev/null)" \
  "$(which python 2>/dev/null)"; do
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    PY="$candidate"
    break
  fi
done

if [[ -z "$PY" ]]; then
  echo "Error: No Python found" >&2
  exit 1
fi

# Configurable thresholds via env vars
DAILY_TASK_WARN="${CLINE_DAILY_TASK_WARN:-50}"
DAILY_TOKEN_WARN="${CLINE_DAILY_TOKEN_WARN:-500000}"
TOTAL_COST_WARN="${CLINE_TOTAL_COST_WARN:-5.0}"
OUTPUT_JSON="${CLINE_MONITOR_JSON:-$HOME/.cline-usage.json}"

$PY - "$JSON_ONLY" "$QUIET" "$DAILY_TASK_WARN" "$DAILY_TOKEN_WARN" "$TOTAL_COST_WARN" "$OUTPUT_JSON" << 'PYEOF'
import json, os, glob, sys
from datetime import datetime, timezone
from collections import defaultdict

json_only = sys.argv[1] == "True"
quiet = sys.argv[2] == "True"
DAILY_TASK_WARN = int(sys.argv[3])
DAILY_TOKEN_WARN = int(sys.argv[4])
TOTAL_COST_WARN = float(sys.argv[5])
OUTPUT_JSON = sys.argv[6]

# Auto-discover cline config dirs
config_dirs = []
main = os.path.expanduser("~/.cline")
if os.path.isdir(main):
    config_dirs.append(("main", main))

configs_base = os.path.expanduser("~/.cline-configs")
if os.path.isdir(configs_base):
    for d in sorted(os.listdir(configs_base)):
        p = os.path.join(configs_base, d)
        if os.path.isdir(p):
            config_dirs.append((d, p))

today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
daily = {"tasks": 0, "prompt": 0, "completion": 0, "cached": 0, "cost": 0.0}
total = {"tasks": 0, "prompt": 0, "completion": 0, "cached": 0, "cost": 0.0}
models_used = defaultdict(int)
per_config = {}
task_log = []

seen_tasks = set()

for name, base in config_dirs:
    ct, ctok = 0, 0
    patterns = [
        os.path.join(base, "tasks/*/api_conversation_history.json"),
        os.path.join(base, "data/tasks/*/api_conversation_history.json"),
    ]
    for pattern in patterns:
        for f in glob.glob(pattern):
            task_dir = os.path.basename(os.path.dirname(f))
            task_key = f"{task_dir}"
            if task_key in seen_tasks:
                continue
            seen_tasks.add(task_key)
            try:
                task_ts = int(task_dir) / 1000
                task_date = datetime.fromtimestamp(task_ts, tz=timezone.utc).strftime("%Y-%m-%d")
                is_today = (task_date == today)
                with open(f) as fh:
                    msgs = json.load(fh)
                tp, tc, tca, tcost = 0, 0, 0, 0.0
                model = "unknown"
                task_text = ""
                for msg in msgs:
                    if msg.get("role") == "user" and not task_text:
                        c = msg.get("content", "")
                        if isinstance(c, list):
                            for x in c:
                                if isinstance(x, dict) and x.get("type") == "text":
                                    task_text = x.get("text", "")[:100]
                                    break
                        elif isinstance(c, str):
                            task_text = c[:100]
                    m = msg.get("metrics", {})
                    t = m.get("tokens", {})
                    mi = msg.get("modelInfo", {})
                    p = t.get("prompt", 0) or 0
                    co = t.get("completion", 0) or 0
                    ca = t.get("cached", 0) or 0
                    cost = m.get("cost", 0) or 0
                    if p > 0 or co > 0:
                        tp += p; tc += co; tca += ca; tcost += cost
                        mid = mi.get("modelId", "unknown")
                        models_used[mid] += 1
                        model = mid
                total["tasks"] += 1; total["prompt"] += tp; total["completion"] += tc
                total["cached"] += tca; total["cost"] += tcost
                ct += 1; ctok += tp + tc
                if is_today:
                    daily["tasks"] += 1; daily["prompt"] += tp; daily["completion"] += tc
                    daily["cached"] += tca; daily["cost"] += tcost
                task_log.append({"ts": task_ts, "date": task_date, "config": name,
                    "model": model, "tokens": tp+tc, "cost": tcost, "task": task_text})
            except:
                continue
    if ct > 0:
        per_config[name] = {"tasks": ct, "tokens": ctok}

# Warnings
warnings = []
dt = daily["prompt"] + daily["completion"]
tt = total["prompt"] + total["completion"]
if daily["tasks"] > DAILY_TASK_WARN:
    warnings.append(f"Daily tasks ({daily['tasks']}) > {DAILY_TASK_WARN}")
if dt > DAILY_TOKEN_WARN:
    warnings.append(f"Daily tokens ({dt:,}) > {DAILY_TOKEN_WARN:,}")
if total["cost"] > TOTAL_COST_WARN:
    warnings.append(f"Total cost (${total['cost']:.2f}) > ${TOTAL_COST_WARN}")

report = {
    "date": today,
    "daily": {"tasks": daily["tasks"], "tokens": dt, "cached": daily["cached"], "cost": daily["cost"]},
    "total": {"tasks": total["tasks"], "tokens": tt, "cached": total["cached"], "cost": total["cost"]},
    "models": dict(models_used),
    "per_config": per_config,
    "warnings": warnings,
    "has_warnings": len(warnings) > 0
}

# Save JSON
os.makedirs(os.path.dirname(OUTPUT_JSON) if os.path.dirname(OUTPUT_JSON) else ".", exist_ok=True)
with open(OUTPUT_JSON, "w") as f:
    json.dump(report, f, indent=2)

if json_only:
    print(json.dumps(report, indent=2))
    sys.exit(0)

if not quiet:
    print(f"\n{'='*55}")
    print(f" 📊 CLINE CLI USAGE REPORT — {today}")
    print(f"{'='*55}")
    print(f"\n📅 TODAY:  {daily['tasks']} tasks | {dt:,} tokens | ${daily['cost']:.4f}")
    print(f"📈 TOTAL:  {total['tasks']} tasks | {tt:,} tokens | ${total['cost']:.4f}")
    print(f"\n🤖 MODELS:")
    for m, c in sorted(models_used.items(), key=lambda x: -x[1]):
        print(f"  {m}: {c} calls")
    print(f"\n📂 CONFIGS:")
    for n, i in per_config.items():
        print(f"  {n}: {i['tasks']} tasks, {i['tokens']:,} tokens")
    print(f"\n{'='*55}")
    if warnings:
        print(f" ⚠️  WARNINGS:")
        for w in warnings:
            print(f"  • {w}")
    else:
        print(f" ✅ All within limits")
    print(f"{'='*55}\n")

# Exit code: 1 if warnings
sys.exit(1 if warnings else 0)
PYEOF
