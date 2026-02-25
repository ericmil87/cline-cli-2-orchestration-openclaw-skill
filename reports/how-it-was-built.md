# How This Project Was Built

> A technical report on building an AI-orchestrated multi-agent coding skill using LLMs, Cline CLI 2.0, and OpenClaw.

**Date:** February 25, 2026  
**Duration:** ~4 hours (01:00 → 05:00 GMT-3)  
**Authors:** Eric Milfont (human), Cláudio Milfont (AI agent)

---

## Executive Summary

This project demonstrates a novel workflow: **an AI agent (Claude) orchestrating other AI agents (Cline CLI) to perform autonomous coding tasks**. The entire skill — from installation to field testing to documentation to publishing — was built in a single session through human-AI collaboration via Telegram.

**Key achievement:** A 4-agent parallel security audit of a production codebase, running on free models, coordinated by an AI orchestrator, producing 1,935 lines of detailed reports at $0.00 inference cost.

---

## Architecture: The AI Stack

```
┌─────────────────────────────────────┐
│         Eric (Human)                │
│         Telegram Chat               │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      OpenClaw Gateway               │
│      (Session Management)           │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Cláudio (Claude Opus 4)        │
│      Orchestrator Agent             │
│      - Plans tasks                  │
│      - Launches sub-agents          │
│      - Monitors progress            │
│      - Aggregates results           │
│      - Writes code & docs           │
└──────────────┬──────────────────────┘
               │ tmux / exec
    ┌──────────┼──────────┐
    │          │          │
┌───▼───┐ ┌───▼───┐ ┌───▼───┐
│Cline 1│ │Cline 2│ │Cline N│
│glm-5  │ │glm-5  │ │glm-5  │
│Agent   │ │Agent  │ │Agent  │
└───────┘ └───────┘ └───────┘
```

### Layer 1: Human (Eric)
- **Role:** Strategic direction, approval, quality control
- **Interface:** Telegram (text + voice messages)
- **Decisions:** What to build, when to proceed, what to merge

### Layer 2: OpenClaw
- **Role:** Session management, message routing, tool access
- **Platform:** Self-hosted on Oracle Cloud ARM VPS (Ubuntu)
- **Features used:** exec, web_search, web_fetch, tts, memory, file I/O

### Layer 3: Cláudio (Claude Opus 4)
- **Role:** Orchestrator — the "brain" that plans, codes, and coordinates
- **Provider:** Anthropic (via OpenClaw)
- **Model:** claude-opus-4-6
- **Capabilities used:**
  - Shell command execution (tmux, git, cline CLI)
  - File creation and editing
  - Web research (Brave Search + Perplexity Sonar Pro)
  - Text-to-speech for voice reports
  - GitHub operations (clone, commit, push, PR creation)
  - Memory management (MEMORY.md, daily notes)

### Layer 4: Cline CLI Sub-Agents
- **Role:** Autonomous coding agents for specific tasks
- **CLI:** Cline CLI v2.5.0
- **Model:** kwaipilot/kat-coder-pro (routes to z-ai/glm-5)
- **Provider:** Cline OAuth (free tier)
- **Mode:** Headless (-y / YOLO) with timeouts
- **Isolation:** Per-project CLINE_DIR with command permissions

---

## LLMs Used

| Model | Provider | Role | Cost | Tokens |
|-------|----------|------|------|--------|
| **Claude Opus 4** | Anthropic | Orchestrator (Cláudio) | Per Eric's plan | ~50k+ |
| **glm-5** (via kat-coder-pro) | Cline OAuth / z-ai | Sub-agents (coding tasks) | **$0.00** | ~1.5M |
| **Perplexity Sonar Pro** | OpenRouter | Web research | ~$0.15 | ~5k |
| **Arcee Trinity Large** | Cline OAuth | Initial test | $0.00 | ~10k |

### Model Selection Rationale

**Orchestrator (Claude Opus 4):**
- Chosen for complex reasoning, multi-step planning, and tool orchestration
- Handles the "CEO" role: deciding what tasks to delegate, monitoring progress, synthesizing results
- Only model that reliably handles the full orchestration loop

**Sub-agents (glm-5 via kat-coder-pro):**
- Free model available through Cline OAuth
- Sufficient for file scanning, code analysis, report generation
- 256k context window handles large codebases
- Rate limits manageable with 2s stagger between parallel agents

**Research (Perplexity Sonar Pro):**
- Used for deep web research when Brave Search results were insufficient
- Queries: Cline pricing, free tier limits, best practices, ClawHub publishing

---

## Timeline of Events

### Phase 1: Installation (01:00 - 01:30)
1. Cloned skill repo from GitHub
2. Read SKILL.md and install.sh (security review)
3. Installed to `~/clawd/skills/cline-subagents/`
4. Created isolated config dirs (~/.cline-configs/)
5. **Issue found:** Auth not copied to isolated dirs → fixed by copying ~/.cline/* to each config

### Phase 2: Field Testing — Security Audit (01:30 - 02:15)
1. Launched 4 parallel agents via tmux for UpBro security audit
2. **Issue found:** All agents failed ("Not authenticated") → fixed by copying auth credentials
3. Relaunched all 4 agents successfully
4. **Issue found:** Agent 2 (frontend) hung on node_modules → fixed with explicit .clineignore
5. Agents 1, 3, 4 completed; Agent 2 relaunched with directory scoping → completed
6. Results: 46 findings across 4 reports (1,935 lines total)

### Phase 3: Monitoring & Research (02:15 - 02:45)
1. Created cline-monitor.sh (usage tracking, token counting, cost alerts)
2. Researched Cline pricing via Perplexity (free tier, Teams plan, rate limits)
3. Verified all configs using correct model (kwaipilot/kat-coder-pro)
4. Generated usage log showing all task history

### Phase 4: Improvements & PRs (02:45 - 03:15)
1. Researched best practices (ClawHub publishing, .clinerules, MCP, CI/CD)
2. Created 4 feature branches with improvements:
   - PR #1: .clinerules templates + MCP integration guide
   - PR #2: GitHub Actions CI/CD workflows
   - PR #3: OpenClaw cron integration + result aggregation
   - PR #4: ClawHub publishing readiness
3. Found and fixed merge conflict (SKILL.md between PR #1 and #3)
4. Fixed trailing whitespace in YAML files
5. Verified all 4 PRs merge cleanly in sequence
6. Pushed all branches, created PRs with descriptions

### Phase 5: Merge & Persistence (03:15 - 04:00)
1. Merged all 4 PRs in correct order (1→3→2→4)
2. Created STATE.md (persistent source of truth)
3. Updated MEMORY.md, HEARTBEAT.md, daily memory
4. Verified all persistence survives compact
5. Comprehensive CHANGELOG covering all versions

---

## Costs

| Item | Cost |
|------|------|
| Cline sub-agents (glm-5) | $0.00 |
| Perplexity research (~5 queries) | ~$0.15 |
| Claude Opus 4 (orchestrator) | Per user's Anthropic plan |
| **Infrastructure** | Oracle Cloud free tier |
| **Total incremental cost** | **~$0.15** |

The entire multi-agent security audit (4 agents, 1.5M tokens, 1,935 lines of reports) cost **$0.00** in inference — all on free models.

---

## Challenges & Solutions

| Challenge | Solution | Lesson |
|-----------|----------|--------|
| Agents failed "Not authenticated" | Copy ~/.cline/* to each CLINE_DIR | Auth doesn't inherit to isolated configs |
| Frontend agent hung (15+ min) | Add .clineignore, scope to specific dirs | node_modules kills agents |
| Parallel agents hit rate limits | Stagger launches by 2 seconds | Don't launch all at once |
| SKILL.md merge conflict between PRs | Rebase PR #3 on PR #1 | Plan branch dependencies |
| Exec commands getting SIGTERM | Use tmux for long-running cline tasks | OpenClaw exec has timeout limits |
| No usage/quota API from Cline | Built local monitoring from task_metadata.json | Parse local files for tracking |

---

## What We Proved

1. **AI orchestrating AI works.** Claude successfully planned, launched, monitored, and aggregated results from multiple Cline sub-agents.

2. **Free models are viable for real work.** A production security audit with 46 findings at $0.00 inference cost.

3. **Parallel execution scales.** 4 agents running simultaneously via tmux, each isolated with its own config.

4. **The full development cycle can be AI-driven.** From installation → testing → debugging → documentation → PR creation → merge — all coordinated by an AI agent through Telegram.

5. **Persistence is solvable.** STATE.md + MEMORY.md + daily notes ensure continuity across session compacts.

---

## Tools & Technologies

| Category | Tool | Version |
|----------|------|---------|
| Orchestrator LLM | Claude Opus 4 | claude-opus-4-6 |
| Sub-agent LLM | glm-5 (kat-coder-pro) | via Cline CLI |
| Research LLM | Perplexity Sonar Pro | via OpenRouter |
| Agent Platform | OpenClaw | Latest |
| Sub-agent CLI | Cline CLI | 2.5.0 |
| Parallel Execution | tmux | System |
| Version Control | git + GitHub | gh CLI |
| Search | Brave Search API | via OpenClaw |
| TTS | ElevenLabs (via OpenClaw) | For voice reports |
| Server | Oracle Cloud ARM | Ubuntu 22.04 |
| Communication | Telegram Bot API | via OpenClaw |

---

## Conclusion

This project demonstrates that **multi-layer AI orchestration** is practical and cost-effective today. An AI agent (Claude) can successfully act as a "team lead" — planning work, delegating to specialized sub-agents (Cline), monitoring progress, handling failures, and delivering results — all while communicating naturally with a human via chat.

The key insight: **the orchestrator doesn't need to do the coding itself.** By delegating to cheaper/free specialized agents and focusing on planning, coordination, and communication, the system achieves more than any single agent could alone.

**Total time:** ~4 hours  
**Total additional cost:** ~$0.15  
**Lines of code/docs produced:** 5,000+  
**Security findings discovered:** 46  
**Human effort:** Strategic direction + approvals  

---

*This report was written by Cláudio Milfont (Claude Opus 4), the AI orchestrator that built this project.*
