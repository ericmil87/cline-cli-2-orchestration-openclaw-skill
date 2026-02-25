---
name: cline-subagents
description: >
  Orchestrate Cline CLI 2.0 sub-agents in headless mode for coding tasks.
  Use when the user requests: coding, refactoring, debugging, testing, code review,
  git commits, browser research, file creation, dependency updates, or any task
  involving code manipulation in repositories. Each sub-agent is sandboxed to a
  specific project directory with scoped permissions. Supports parallel multi-agent
  execution via tmux for complex workflows.
---

# Cline Sub-Agents

Orchestrate headless Cline CLI 2.0 agents as sub-agents for coding tasks.

## When to Use This Skill

Use Cline sub-agents when the user asks you to:

- Fix bugs, refactor code, or add features in a project
- Run tests and auto-fix failures
- Review code changes (diffs, PRs)
- Generate documentation, release notes, or changelogs
- Research with browser (API docs, library changes, etc.)
- Commit, branch, or manage git workflows
- Run linters, formatters, or dependency updates
- Any multi-step coding task that benefits from an isolated agent

Do NOT use Cline sub-agents for:

- Simple questions about code (answer directly)
- Tasks that don't involve file changes
- System administration (sudo, apt, systemctl) — inform the user instead
- Anything outside the user's configured project directories

## Architecture

```
You (OpenClaw) — the orchestrator
  │
  ├── cline -y "task" (Agent A) → /projects/my-app/        [sandboxed]
  ├── cline -y "task" (Agent B) → /projects/my-api/        [sandboxed]
  └── cline -y "task" (Agent C) → /projects/my-frontend/   [sandboxed]
       │
       └── Each agent has isolated config via CLINE_DIR
           and scoped command permissions via CLINE_COMMAND_PERMISSIONS
```

## Security Rules (MANDATORY)

### Rule 1: Project Scope Lock

Each sub-agent MUST only operate within its assigned project directory.
Never grant access to home directories, root, or system paths.

```bash
# CORRECT — scoped to project
cd /projects/my-app && cline -y "fix the login bug"

# WRONG — never do this
cd / && cline -y "fix something somewhere"
```

### Rule 2: Permission Escalation

ALWAYS ask the user for explicit permission before:

- Modifying files outside the project directory
- Running `sudo`, `rm -rf`, or destructive commands
- Pushing to remote repositories (`git push`)
- Accessing credentials, secrets, or environment files
- Installing global packages
- Any task that affects the broader system

### Rule 3: Safe Branching

Always create a new branch before making changes.
Never commit directly to main/master without explicit user approval.

```bash
# Always branch first
cline -y "Create branch fix/login-bug, then fix the authentication issue in src/auth/"
```

### Rule 4: Timeouts

Always set `--timeout` to prevent runaway agents. Defaults:

| Task Type | Timeout |
|-----------|---------|
| Quick fix / review | 120-300s |
| Test + fix cycle | 600s |
| Large refactoring | 900s |
| Documentation gen | 300s |

### Rule 5: Cost Awareness

Prefer free models for simple tasks. Reserve paid models for complex work.
See Model Selection below.

---

## How to Execute Tasks

### Single Agent — Basic Pattern

```bash
cd /projects/my-app

CLINE_DIR=~/.cline-configs/my-app \
CLINE_COMMAND_PERMISSIONS='{"allow":["npm *","git *","node *","cat *","ls *","grep *","find *","mkdir *"],"deny":["rm -rf /","sudo *","git push *"],"allowRedirects":true}' \
  cline -y "TASK DESCRIPTION HERE" \
  --timeout 600
```

### Single Agent — Common Tasks

**Fix a bug:**
```bash
cline -y "There is a bug in src/api/auth.ts where JWT tokens are not refreshed on expiry. Create branch fix/jwt-refresh, fix the bug, add a test, and commit." --timeout 600
```

**Run tests and auto-fix:**
```bash
cline -y "Run 'npm test'. Analyze any failures. Fix the code. Re-run until all tests pass. Commit to branch fix/failing-tests." --timeout 600
```

**Code review via pipe:**
```bash
git diff main...feature-branch | cline -y "Review these changes for: security issues, performance problems, missing error handling. Be specific." --timeout 300
```

**Generate release notes:**
```bash
git log --oneline v1.0..HEAD | cline -y "Write release notes grouped by: features, fixes, breaking changes." --timeout 120
```

**Structured JSON output:**
```bash
cline --json "List all TODO and FIXME comments in the codebase" | jq '.text'
```

**Dependency audit:**
```bash
cline -y "Check for outdated dependencies with known vulnerabilities. Update safe ones. Create branch chore/dep-updates and commit." --timeout 600
```

### Parallel Multi-Agent — via tmux

Use parallel agents when the user has multiple independent tasks, or when
a complex workflow can be decomposed into parallel streams.

```bash
SESSION="cline-agents"
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Agent 1: Fix tests in project A
tmux new-session -d -s "$SESSION" -n "tests"
tmux send-keys -t "$SESSION:tests" "
cd /projects/my-app && \\
CLINE_DIR=~/.cline-configs/my-app \\
CLINE_COMMAND_PERMISSIONS='{\"allow\":[\"npm *\",\"git *\",\"node *\",\"cat *\",\"ls *\"]}' \\
  cline -y 'Run tests and fix failures' --timeout 600
" Enter

# Agent 2: Code review in project B
tmux new-window -t "$SESSION" -n "review"
tmux send-keys -t "$SESSION:review" "
cd /projects/my-api && \\
git diff main...develop | \\
CLINE_DIR=~/.cline-configs/my-api \\
  cline -y 'Review for security and performance issues' --timeout 300
" Enter

# Agent 3: Update docs in project C
tmux new-window -t "$SESSION" -n "docs"
tmux send-keys -t "$SESSION:docs" "
cd /projects/my-frontend && \\
CLINE_DIR=~/.cline-configs/my-frontend \\
CLINE_COMMAND_PERMISSIONS='{\"allow\":[\"npm *\",\"git *\",\"node *\",\"cat *\",\"ls *\"]}' \\
  cline -y 'Update README.md with current API docs' --timeout 300
" Enter
```

**Monitor parallel agents:**
```bash
tmux attach -t cline-agents    # connect to session
# Ctrl+B, 0/1/2 → switch windows
# Ctrl+B, D → detach without killing
```

### When to Use Multi-Agent vs Single Agent

| Scenario | Approach |
|----------|----------|
| One task in one project | Single agent |
| Multiple independent tasks | Parallel multi-agent |
| Task depends on another task's output | Sequential chain (pipe) |
| Large refactoring across files | Single agent (needs full context) |
| Test project A + review project B simultaneously | Parallel multi-agent |

---

## Model Selection

### Available Free Models (check current availability)

| Model | Via | Best For | Speed |
|-------|-----|----------|-------|
| Kimi K2.5 | Cline provider | Complex reasoning, frontend, vision | Medium |
| MiniMax M2.5 | Cline provider | Multi-agent, rapid iteration | Fast (100 tok/s) |
| Arcee Trinity Large | Cline provider | General coding, tool calling | Medium |
| DeepSeek V3 | OpenRouter free | Refactoring, debugging | Medium |
| Qwen 3 | OpenRouter free | Multilingual, docs | Medium |
| Llama 3.3 70B | OpenRouter free | General purpose | Medium |
| Gemini 2.0 Flash | Google AI free | Quick reviews, simple tasks | Fast |

### Selection Strategy

```
Simple tasks (lint, format, quick fix):
  → MiniMax M2.5 or Gemini Flash (fast + free)

Medium tasks (bug fix, test fix, small refactor):
  → Kimi K2.5 or DeepSeek (good reasoning)

Complex tasks (architecture, large refactor):
  → Kimi K2.5 (best free reasoning)

Parallel sub-agents:
  → MiniMax M2.5 (designed for multi-agent, very fast)

Fallback if free models unavailable:
  → OpenRouter free tier models
  → Then: ask user if paid model is acceptable
```

Free model promotions are temporary. If a model stops working, 
switch to the next available free option or inform the user.

---

## Interaction Patterns

### Pattern: User requests a coding task

```
User: "fix the authentication bug in my-app"

You (internally):
  1. Identify project → my-app ✓
  2. Check scope → bug fix within project ✓ (no permission needed)
  3. Select model → MiniMax M2.5 (quick fix)
  4. Execute:
     cd /projects/my-app
     CLINE_DIR=~/.cline-configs/my-app \
       cline -y "Find and fix authentication bugs in src/auth/. Branch: fix/auth-bug. Run tests. Commit." --timeout 600
  5. Report results to user

You (to user):
  "✅ Found the issue — JWT refresh was missing in the middleware.
   Fixed in branch fix/auth-bug. Tests passing. Want me to push?"
```

### Pattern: Task requires permission

```
User: "push the fix branch to GitHub"

You:
  "⚠️ Pushing to remote requires explicit approval.
   Push fix/auth-bug to origin? [Confirm]"

User: "yes"

You:
  → Execute with temporary push permission
  "✅ Pushed fix/auth-bug to origin."
```

### Pattern: Task outside project scope

```
User: "install Docker on the server"

You:
  "🚫 That requires system-level access (sudo) which is outside
   my sub-agent scope. Here are the commands you can run manually:
   ..."
```

### Pattern: Multiple tasks, different projects

```
User: "run tests on my-app and review the PR on my-api"

You (internally):
  → Two independent tasks, different projects → parallel multi-agent
  → Spawn Agent A for tests, Agent B for review
  → Wait for both, report combined results

You (to user):
  "Running both in parallel...
   
   my-app tests: ✅ All 47 tests passing
   my-api review: Found 2 potential issues — [details]"
```

---

## Reference

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `CLINE_DIR` | Isolated config directory per project |
| `CLINE_COMMAND_PERMISSIONS` | JSON allow/deny for shell commands |

### CLI Flags

| Flag | Purpose |
|------|---------|
| `-y` / `--yolo` | Headless mode, auto-approve all actions |
| `--json` | Structured JSON output for scripting |
| `--timeout N` | Kill agent after N seconds |
| `--config PATH` | Alternative config directory |

### Command Permission Template

```json
{
  "allow": [
    "npm *", "npx *", "node *", "git *",
    "cat *", "ls *", "grep *", "find *",
    "mkdir *", "cp *", "mv *", "echo *",
    "head *", "tail *", "wc *"
  ],
  "deny": [
    "rm -rf /", "rm -rf ~", "sudo *",
    "chmod 777 *", "git push *",
    "curl * | bash", "wget * | bash"
  ],
  "allowRedirects": true
}
```

### Troubleshooting

| Problem | Solution |
|---------|----------|
| "No API key found" | Credentials missing — check `~/.cline/data/` exists |
| "Command not permitted" | Add command to `CLINE_COMMAND_PERMISSIONS` allow list |
| Agent hangs / no output | Kill with `pkill -f "cline -y"`, reduce timeout |
| Model unavailable | Free promo may have ended — switch to OpenRouter free tier |
| Token expired | Re-authenticate on host, copy credentials to container |
