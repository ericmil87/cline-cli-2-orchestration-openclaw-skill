# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.3.3] - 2026-02-25

### Added
- `QUICKSTART.md` — 5-minute getting started guide
- `examples/clinerules-templates/.clinerules-security-audit` — Rules for audit agents (read-only, report format)
- `examples/auto-approve-configs/safe-readonly.json` — Locked-down permissions for audit/review agents
- `examples/auto-approve-configs/dev-standard.json` — Standard dev permissions (edit + build, no push)
- `examples/auto-approve-configs/ci-full.json` — Broader CI/CD permissions (includes push and docker)

### Changed
- `README.md` — Added quickstart link

## [0.3.2] - 2026-02-25

### Changed
- `reports/how-it-was-built.md` — Enhanced with mermaid diagrams, badges, industry context, benchmarks
- `README.md` — Enhanced with mermaid diagram and additional badges

## [0.3.1] - 2026-02-25

### Added
- `reports/how-it-was-built.md` — Technical report on how this project was built (LLMs, tools, architecture, costs)

### Changed
- Local skill synced with latest repo state

## [0.3.0] - 2026-02-25

### Added
- `STATE.md` — Persistent project state file (source of truth for agent sessions)

## [0.2.4] - 2026-02-25

### Added
- `SECURITY.md` — Trust statement, external endpoints, script safety policy
- `CHANGELOG.md` — Versioned release notes

### Purpose
- ClawHub marketplace publishing readiness
- Community trust and moderation compliance

## [0.2.3] - 2026-02-25

### Added
- `examples/github-actions/cline-review.yml` — Automated PR code review
- `examples/github-actions/cline-test-fix.yml` — Auto-fix failing tests, create fix PR
- `examples/github-actions/cline-security-audit.yml` — Weekly security audit with GitHub issue creation

### Fixed
- Trailing whitespace in YAML files

### Notes
- All workflows use free model (kat-coder-pro) by default
- Sequential execution for CI environments (no tmux needed)

## [0.2.2] - 2026-02-25

### Added
- `references/openclaw-cron-setup.md` — Complete cron scheduling guide (OpenClaw cron, system crontab, heartbeat)
- `scripts/cline-summarize.sh` — Aggregate multi-agent reports into executive summary

### Changed
- `SKILL.md` — Added cron and summarization documentation

### Notes
- Supports 2.5h periodic review cycles
- Three scheduling options documented (OpenClaw, crontab, heartbeat)

## [0.2.1] - 2026-02-25

### Added
- `examples/clinerules-templates/.clinerules-python` — Python/FastAPI project rules
- `examples/clinerules-templates/.clinerules-nextjs` — Next.js/React project rules
- `examples/clinerules-templates/.clinerules-general` — General project rules
- `references/mcp-integration.md` — MCP tools integration guide for sub-agents

### Changed
- `SKILL.md` — Added .clinerules and MCP documentation sections

### Notes
- .clinerules are appended to agent system prompt for project-specific conventions
- MCP tools extend agent capabilities (web search, APIs, databases)

## [0.2.0] - 2026-02-25

### Added
- `scripts/cline-monitor.sh` — Usage monitoring with token/cost tracking and threshold alerts
  - Supports `--json` and `--quiet` flags
  - Auto-discovers all CLINE_DIR configs
  - Configurable thresholds via env vars
- `scripts/cline-cron.sh` — Config-driven scheduled multi-agent task runner
  - Supports parallel (tmux) and sequential execution
  - YAML-like config format with per-task settings
- `.clineignore` — Template ignore file (node_modules, .next, dist, venv, etc.)
- `examples/security-audit.conf` — 4-agent parallel security audit configuration
- `examples/periodic-review.conf` — 2.5h periodic code review configuration

### Changed
- `SKILL.md` — Added "Critical Lessons" section with field-tested knowledge:
  - `.clineignore` is mandatory for Node.js projects (agents hang on node_modules)
  - Auth credentials must be copied to isolated CLINE_DIRs
  - Frontend scans need explicit directory scoping
  - Stagger parallel agent launches by 2 seconds
- `README.md` — Complete rewrite with:
  - Current status table with field-tested results
  - Critical setup notes (lessons learned the hard way)
  - Monitoring and cron documentation
  - Free model pricing info (Feb 2026)
  - Roadmap (done/next steps)
  - Added Cláudio Milfont as AI collaborator

### Field Test Results
- Ran 4-agent parallel security audit on production project (FastAPI + Next.js)
- Agent 1 (API): 25 findings, 807 lines, ~8 min
- Agent 2 (Frontend): 3 findings, 290 lines, ~6 min
- Agent 3 (Dependencies): Critical CVEs found, 360 lines, ~5 min
- Agent 4 (Infrastructure): 12 findings, 478 lines, ~7 min
- Total cost: $0.00 (free model via Cline OAuth)

## [0.1.0] - 2026-02-25

### Added
- Initial release
- `SKILL.md` — Runtime skill with Cline CLI 2.0 orchestration instructions
  - Single agent and parallel multi-agent patterns
  - Security rules (project scope, permissions, branching, timeouts)
  - Model selection strategy (free vs paid)
  - Interaction patterns (task execution, permission requests, multi-project)
- `cline-project.sh` — Single-project agent wrapper with configurable permissions
- `cline-multi.sh` — Interactive multi-agent tmux orchestrator (start/run/status/stop/attach)
- `install.sh` — Automated setup script (prerequisites, Cline install, config dirs, auth guide)
- `LICENSE` — MIT License
- `README.md` — Documentation with architecture, installation, authentication, usage examples

### Architecture
```
OpenClaw Bot (orchestrator)
  ├── cline -y "task" → project-a [CLINE_DIR isolated]
  ├── cline -y "task" → project-b [CLINE_DIR isolated]
  └── cline -y "task" → project-c [CLINE_DIR isolated]
```

---

## Contributors
- **Eric Milfont** — [@ericmil87](https://github.com/ericmil87) — Creator
- **Cláudio Milfont** — [@claudiomil87](https://github.com/claudiomil87) — AI Collaborator
