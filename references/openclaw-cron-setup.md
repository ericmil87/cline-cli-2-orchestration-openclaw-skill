# OpenClaw Cron Integration

## Overview

OpenClaw supports three scheduling mechanisms for Cline sub-agent tasks:

1. **Heartbeat** — Batched periodic checks (every ~30min)
2. **Cron (main session)** — Enqueues event for next heartbeat
3. **Cron (isolated)** — Runs dedicated agent turn, delivers to channel

## Quick Setup: Every 2.5 Hours Review

### Option A: OpenClaw Cron (Recommended)

```bash
# Isolated job — runs independently, delivers to Telegram
openclaw cron add \
  --name "cline-periodic-review" \
  --every 150m \
  --session isolated \
  --message "Run: bash ~/clawd/skills/cline-subagents/scripts/cline-cron.sh ~/clawd/skills/cline-subagents/examples/periodic-review.conf — then summarize results from /tmp/cline-results/*.md and report findings." \
  --announce \
  --channel telegram
```

### Option B: System Crontab

```bash
# Add to crontab -e
# Runs every 2.5h (0, 2:30, 5, 7:30, 10, 12:30, 15, 17:30, 20, 22:30)
0 0,5,10,15,20 * * * bash ~/clawd/skills/cline-subagents/scripts/cline-cron.sh ~/clawd/skills/cline-subagents/examples/periodic-review.conf >> ~/.cline-cron.log 2>&1
30 2,7,12,17,22 * * * bash ~/clawd/skills/cline-subagents/scripts/cline-cron.sh ~/clawd/skills/cline-subagents/examples/periodic-review.conf >> ~/.cline-cron.log 2>&1
```

### Option C: Heartbeat Integration

Add to your `HEARTBEAT.md`:

```markdown
### Cline Periodic Review (every 2.5h)
- Check if last cline review was >2.5h ago (see ~/clawd/memory/cline-cron-state.json)
- If due: run `bash ~/clawd/skills/cline-subagents/scripts/cline-cron.sh ~/clawd/skills/cline-subagents/examples/periodic-review.conf`
- Check results in /tmp/cline-results/*.md
- If critical issues found, notify user
- Update cline-cron-state.json with timestamp
```

## Usage Monitoring Cron

```bash
# Daily usage report at 9am
openclaw cron add \
  --name "cline-usage-report" \
  --cron "0 9 * * *" \
  --tz "America/Sao_Paulo" \
  --session isolated \
  --message "Run: bash ~/clawd/skills/cline-subagents/scripts/cline-monitor.sh — report the results. If warnings, alert user." \
  --announce \
  --channel telegram
```

## Managing Cron Jobs

```bash
# List all jobs
openclaw cron list

# Remove a job
openclaw cron remove --name "cline-periodic-review"

# Pause/resume
openclaw cron pause --name "cline-periodic-review"
openclaw cron resume --name "cline-periodic-review"
```

## Best Practices

1. **Use isolated sessions** for Cline tasks — they're heavy and shouldn't clutter main session
2. **Set reasonable intervals** — 2.5h is good for review, daily for audits
3. **Monitor costs** — even free models have rate limits
4. **Stagger jobs** — don't schedule multiple Cline jobs at the same time
5. **Log everything** — use `CLINE_CRON_LOG` env var for debugging
6. **Night quiet hours** — skip 23:00-07:00 unless critical
