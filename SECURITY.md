# Security Policy

## Trust Statement

This skill orchestrates Cline CLI 2.0 sub-agents with the following security model:

- **No network access by default** — sub-agents only access local files
- **Project-scoped sandboxing** — each agent is restricted to its project directory
- **Command allow/deny lists** — dangerous commands (sudo, rm -rf, git push) are denied by default
- **No credential storage** — this skill does not store or transmit any credentials
- **User approval required** for: push to remote, delete files, access other projects, system commands

## External Endpoints

This skill connects to:
- **Cline CLI OAuth** (cline.bot) — for model authentication (user-initiated only)
- **AI model providers** (OpenRouter, Anthropic, etc.) — for inference (user-configured)

No data is sent to any endpoint not explicitly configured by the user.

## Scripts

All scripts in this skill:
- Use `set -euo pipefail` for safe bash execution
- Do not interpolate raw user input into shell commands
- Do not require or request elevated permissions (sudo)
- Log actions to local files only

## Reporting Vulnerabilities

If you discover a security issue, please open a private issue on GitHub or contact the maintainers directly.
