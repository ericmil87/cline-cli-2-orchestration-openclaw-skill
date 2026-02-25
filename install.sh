#!/usr/bin/env bash
# =============================================================================
# cline-subagents-skill installer
# Installs Cline CLI 2.0 and configures it as a sub-agent system for OpenClaw.
#
# Usage: bash install.sh
#
# Run on the HOST machine (not inside Docker containers).
# After auth, copy credentials to containers via docker cp or volume mount.
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo -e "${BOLD}${BLUE}┌──────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${BLUE}│  cline-subagents-skill — installer           │${NC}"
echo -e "${BOLD}${BLUE}└──────────────────────────────────────────────┘${NC}"
echo ""

# ── Prerequisites ────────────────────────────────────────────────────────────

echo -e "${BLUE}[1/5] Checking prerequisites...${NC}"
errors=0

if command -v node &>/dev/null; then
  NODE_V=$(node -v | sed 's/v//' | cut -d. -f1)
  if [[ "$NODE_V" -ge 20 ]]; then
    echo -e "  ${GREEN}✓${NC} Node.js $(node -v)"
  else
    echo -e "  ${RED}✗${NC} Node.js $(node -v) — need 20+ (recommend 22)"
    errors=$((errors + 1))
  fi
else
  echo -e "  ${RED}✗${NC} Node.js not found"
  errors=$((errors + 1))
fi

command -v npm  &>/dev/null && echo -e "  ${GREEN}✓${NC} npm $(npm -v)"   || { echo -e "  ${RED}✗${NC} npm not found"; errors=$((errors + 1)); }
command -v git  &>/dev/null && echo -e "  ${GREEN}✓${NC} git"             || { echo -e "  ${RED}✗${NC} git not found"; errors=$((errors + 1)); }
command -v tmux &>/dev/null && echo -e "  ${GREEN}✓${NC} tmux"            || echo -e "  ${YELLOW}~${NC} tmux not found (optional — needed for parallel agents)"

[[ $errors -gt 0 ]] && { echo -e "\n${RED}Fix $errors issue(s) above and re-run.${NC}"; exit 1; }
echo ""

# ── Install / Update Cline CLI ───────────────────────────────────────────────

echo -e "${BLUE}[2/5] Installing Cline CLI 2.0...${NC}"
if command -v cline &>/dev/null; then
  echo -e "  Already installed — updating..."
  npm update -g cline 2>/dev/null || npm install -g cline
else
  npm install -g cline
fi
echo -e "  ${GREEN}✓${NC} cline $(cline --version 2>/dev/null || echo 'installed')"
echo ""

# ── Create isolated config dirs ──────────────────────────────────────────────

echo -e "${BLUE}[3/5] Creating isolated config directories...${NC}"
for name in default project-a project-b project-c; do
  mkdir -p "$HOME/.cline-configs/$name"
  echo -e "  ${GREEN}✓${NC} ~/.cline-configs/$name/"
done
echo -e "  ${YELLOW}Tip:${NC} Rename these to match your actual projects."
echo ""

# ── Install skill into OpenClaw ──────────────────────────────────────────────

echo -e "${BLUE}[4/5] Installing skill...${NC}"
DEST="$HOME/.openclaw/skills/cline-subagents"

if [[ -d "$HOME/.openclaw" ]]; then
  mkdir -p "$DEST/scripts"
  cp "$SKILL_DIR/SKILL.md" "$DEST/SKILL.md"
  
  for f in "$SCRIPT_DIR/scripts/"*.sh; do
    [[ -f "$f" ]] && { cp "$f" "$DEST/scripts/"; chmod +x "$DEST/scripts/$(basename "$f")"; }
  done
  
  echo -e "  ${GREEN}✓${NC} Installed to $DEST"
else
  echo -e "  ${YELLOW}~${NC} ~/.openclaw not found — copy manually later:"
  echo -e "    mkdir -p ~/.openclaw/skills/cline-subagents"
  echo -e "    cp SKILL.md ~/.openclaw/skills/cline-subagents/"
fi
echo ""

# ── Authentication guide ─────────────────────────────────────────────────────

echo -e "${BLUE}[5/5] Authentication${NC}"
echo ""
echo -e "${BOLD}Choose an authentication method:${NC}"
echo ""
echo -e "  ${BOLD}A) SSH Tunnel${NC} — access free Kimi K2.5 & MiniMax M2.5"
echo -e "     From your local machine:"
echo -e "       ssh -L 48801:localhost:48801 -L 48802:localhost:48802 user@this-server"
echo -e "     Then on the server: ${BOLD}cline auth${NC}"
echo -e "     Copy the URL → paste in your local browser"
echo ""
echo -e "  ${BOLD}B) Auth locally, copy credentials${NC}"
echo -e "     On your local machine: npm install -g cline && cline auth"
echo -e "     Then: scp -r ~/.cline/data/ user@this-server:~/.cline/data/"
echo ""
echo -e "  ${BOLD}C) API key (no browser)${NC}"
echo -e "     cline auth -p openrouter -k sk-or-v1-YOUR_KEY"
echo -e "     cline auth -p anthropic  -k sk-ant-YOUR_KEY"
echo ""

# ── Done ─────────────────────────────────────────────────────────────────────

echo -e "${BOLD}${GREEN}┌──────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${GREEN}│  ✓ Installation complete                     │${NC}"
echo -e "${BOLD}${GREEN}└──────────────────────────────────────────────┘${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Authenticate:  cline auth"
echo -e "  2. Test:          cline -y 'echo hello from cline' --timeout 30"
echo -e "  3. Restart:       openclaw gateway restart"
echo ""
echo -e "For Docker containers, copy credentials after auth:"
echo -e "  docker cp ~/.cline/data/. CONTAINER:/home/node/.cline/data/"
echo -e "  ${YELLOW}or${NC} mount as volume:  -v ~/.cline/data:/home/node/.cline/data:ro"
echo ""
