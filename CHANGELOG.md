# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-02-25

### Added
- `scripts/cline-monitor.sh` — Usage monitoring with token/cost tracking and threshold alerts
- `scripts/cline-cron.sh` — Config-driven scheduled multi-agent task runner
- `scripts/cline-summarize.sh` — Aggregate multi-agent reports into executive summary
- `.clineignore` template for common ignore patterns
- `examples/security-audit.conf` — 4-agent parallel security audit config
- `examples/periodic-review.conf` — 2.5h periodic code review config
- `examples/clinerules-templates/` — Project-specific agent instruction templates
- `examples/github-actions/` — CI/CD workflow examples (review, test-fix, audit)
- `references/mcp-integration.md` — MCP tools integration guide
- `references/openclaw-cron-setup.md` — Complete cron scheduling guide
- `SECURITY.md` — Trust statement and security policy
- `CHANGELOG.md` — This file

### Changed
- SKILL.md updated with field-tested critical lessons (`.clineignore`, auth copy, frontend scoping)
- README.md rewritten with current status, results, and roadmap

### Fixed
- Documentation for auth credential copying to isolated CLINE_DIRs
- Frontend scan instructions to exclude node_modules explicitly

## [0.1.0] - 2026-02-25

### Added
- Initial release
- SKILL.md with Cline CLI 2.0 orchestration instructions
- `cline-project.sh` — Single-project agent wrapper
- `cline-multi.sh` — Interactive multi-agent tmux orchestrator
- `install.sh` — Automated setup script
- MIT License
