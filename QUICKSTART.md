# ⚡ Quickstart (5 minutes)

## 1. Install

```bash
npm install -g cline
cline auth    # Sign in with Cline (free models)

git clone https://github.com/ericmil87/cline-cli-2-orchestration-openclaw-skill.git
cd cline-cli-2-orchestration-openclaw-skill
bash install.sh
```

## 2. Test

```bash
cd /your/project
cline -y "echo hello from cline" --timeout 30
```

If it works, you're ready.

## 3. Run Your First Agent

```bash
# Single agent — fix a bug
cd /your/project
cline -y "Find and fix bugs in src/. Create branch fix/bugs. Run tests. Commit." --timeout 600

# Review code changes
git diff main...feature | cline -y "Review for security and quality issues" --timeout 300
```

## 4. Run Parallel Agents

```bash
# Security audit (4 agents)
bash scripts/cline-cron.sh examples/security-audit.conf
```

## 5. Monitor Usage

```bash
bash scripts/cline-monitor.sh
```

## ⚠️ Don't Forget

1. **Create `.clineignore`** in your project root:
   ```
   node_modules/
   .next/
   dist/
   venv/
   ```

2. **Copy auth** to isolated configs:
   ```bash
   mkdir -p ~/.cline-configs/my-project
   cp -r ~/.cline/* ~/.cline-configs/my-project/
   ```

## Next Steps

- Read [SKILL.md](SKILL.md) for the full orchestration guide
- Check [examples/](examples/) for configs and templates
- See [reports/how-it-was-built.md](reports/how-it-was-built.md) for the full story
