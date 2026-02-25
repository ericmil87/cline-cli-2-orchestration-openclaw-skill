# 🦞 cline-subagents-skill

> An [OpenClaw](https://openclaw.ai) skill that lets your AI agent orchestrate [Cline CLI 2.0](https://cline.bot/cli) sub-agents for autonomous coding tasks.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Cline CLI](https://img.shields.io/badge/Cline_CLI-2.0-orange)](https://cline.bot/cli)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-Compatible-green)](https://openclaw.ai)

## What is this?

This skill teaches an OpenClaw bot (or any compatible AI agent) to delegate coding tasks to **Cline CLI 2.0** sub-agents running in headless mode. Each sub-agent is sandboxed to a specific project directory with scoped permissions.

**Key capabilities:**
- 🔧 Bug fixing, refactoring, and feature development
- 🧪 Test execution with automatic failure repair
- 📝 Code review via piped git diffs
- 📦 Dependency audits and updates
- 🌐 Browser-based research (API docs, library changes)
- 🔀 Git workflow management (branching, commits)
- ⚡ Parallel multi-agent execution via tmux
- 🔒 Project-scoped sandboxing with command allow/deny lists

## Architecture

```
OpenClaw Bot (orchestrator)
  │
  ├── cline -y "task" → /projects/app-a/     [sandboxed, isolated config]
  ├── cline -y "task" → /projects/app-b/     [sandboxed, isolated config]
  └── cline -y "task" → /projects/app-c/     [sandboxed, isolated config]
```

Each Cline sub-agent:
- Runs in headless mode (`-y` / YOLO)
- Has its own isolated configuration directory (`CLINE_DIR`)
- Is restricted to allowed commands via `CLINE_COMMAND_PERMISSIONS`
- Cannot push to remotes, run sudo, or access system files without explicit approval

## Installation

### Prerequisites

- **Node.js 20+** (22 recommended)
- **npm**
- **git**
- **tmux** (optional, for parallel agents)
- **Cline CLI 2.0**: `npm install -g cline`

### Quick Install

```bash
# Clone the skill
git clone https://github.com/ericmil87/cline-subagents-skill.git

# Run the setup script
cd cline-subagents-skill
bash setup/install.sh
```

### Manual Install

```bash
# 1. Install Cline CLI
npm install -g cline

# 2. Authenticate (see Authentication section below)
cline auth

# 3. Copy skill to OpenClaw
cp SKILL.md ~/.openclaw/skills/cline-subagents/SKILL.md

# 4. Restart OpenClaw
openclaw gateway restart
```

## Authentication

Cline CLI needs authentication to access AI models. This is the trickiest part on headless servers / Docker containers.

### Method A: SSH Tunnel (Recommended — enables free models)

This gives you access to free models like Kimi K2.5 and MiniMax M2.5 via Cline's OAuth provider.

```bash
# From your LOCAL machine (with a browser):
ssh -L 48801:localhost:48801 \
    -L 48802:localhost:48802 \
    user@your-server.com

# On the server (inside that SSH session):
cline auth
# → Choose "Sign in with Cline"
# → Copy the URL shown in terminal
# → Paste in your local browser
# → OAuth callback tunnels back through SSH → done!
```

### Method B: Auth Locally, Copy Credentials

```bash
# On your local machine:
npm install -g cline
cline auth                    # complete in browser
scp -r ~/.cline/data/ user@your-server.com:~/.cline/data/
```

### Method C: API Key (No browser needed)

```bash
# Headless-friendly, no OAuth required:
cline auth -p openrouter -k sk-or-v1-YOUR_KEY
cline auth -p anthropic  -k sk-ant-YOUR_KEY -m claude-sonnet-4-5-20250929
```

### Docker: Copy Credentials to Containers

After authenticating on the host:

```bash
# Option A: docker cp
docker cp ~/.cline/data/. my-container:/home/node/.cline/data/

# Option B: Volume mount (recommended — add to docker-compose.yml)
volumes:
  - ~/.cline/data:/home/node/.cline/data:ro
```

## Usage

Once installed, your OpenClaw bot can use the skill automatically. Example interactions:

```
User: "fix the login bug in my-app"
Bot:  → Spawns Cline sub-agent in /projects/my-app
      → Creates branch fix/login-bug
      → Fixes the bug, runs tests, commits
      → Reports results

User: "run tests on my-app and review the PR on my-api at the same time"
Bot:  → Spawns 2 parallel Cline agents via tmux
      → Reports combined results

User: "push the fix to GitHub"
Bot:  → "⚠️ Push requires approval. Confirm?"
```

### Helper Scripts

The `setup/scripts/` directory includes utility scripts:

| Script | Purpose |
|--------|---------|
| `cline-project.sh` | Run a Cline agent scoped to a project with safety defaults |
| `cline-multi.sh` | Orchestrate parallel agents via tmux |

```bash
# Run a task in a specific project
./setup/scripts/cline-project.sh my-app "run tests and fix failures" 600

# Start parallel agents
./setup/scripts/cline-multi.sh start

# Check status
./setup/scripts/cline-multi.sh status
```

## Free Models (as of Feb 2026)

| Model | Provider | Free? | Best For |
|-------|----------|-------|----------|
| Kimi K2.5 | Cline (OAuth) | ✅ Limited time | Complex reasoning, frontend |
| MiniMax M2.5 | Cline (OAuth) | ✅ Limited time | Multi-agent, speed (100 tok/s) |
| Arcee Trinity Large | Cline (OAuth) | ✅ Yes | General coding |
| DeepSeek V3 | OpenRouter | ✅ Free tier | Refactoring, debugging |
| Qwen 3 | OpenRouter | ✅ Free tier | Multilingual |
| Llama 3.3 70B | OpenRouter | ✅ Free tier | General purpose |

> **Note:** Free model promotions are temporary. Check [cline.bot/blog](https://cline.bot/blog) for current availability.

## Configuration

### Project Permissions

Each project gets scoped command permissions:

```bash
export CLINE_COMMAND_PERMISSIONS='{
  "allow": ["npm *", "git *", "node *", "cat *", "ls *", "grep *"],
  "deny": ["rm -rf /", "sudo *", "git push *"],
  "allowRedirects": true
}'
```

### Isolated Configs

```bash
# Each project has its own Cline config
export CLINE_DIR=~/.cline-configs/my-app
```

### Security Model

| Action | Default | Override |
|--------|---------|----------|
| Read files in project | ✅ Allowed | — |
| Edit files in project | ✅ Allowed | — |
| Run npm/node/git | ✅ Allowed | Configurable |
| Delete files | ⚠️ Restricted | User approval |
| Push to remote | 🚫 Denied | User approval |
| System commands (sudo) | 🚫 Denied | Never in sub-agent |
| Access other projects | 🚫 Denied | User approval |

## Project Structure

```
cline-subagents-skill/
├── SKILL.md                    # Runtime skill (goes in bot's skills dir)
├── README.md                   # This file
├── LICENSE                     # MIT License
└── setup/
    ├── install.sh              # Automated setup script
    └── scripts/
        ├── cline-project.sh    # Single-project agent wrapper
        └── cline-multi.sh      # Multi-agent tmux orchestrator
```

## Contributing

Contributions welcome! Please open an issue or PR on GitHub.

Areas where help is appreciated:
- Additional model provider configurations
- CI/CD pipeline examples
- Better token refresh automation
- Windows support improvements

## License

MIT — see [LICENSE](LICENSE) for details.

## Author

**Eric Milfont** — [@ericmil87](https://github.com/ericmil87) — [eric.milfont.net](https://eric.milfont.net)

---

*Built for the [OpenClaw](https://openclaw.ai) ecosystem. Powered by [Cline CLI 2.0](https://cline.bot/cli).*
