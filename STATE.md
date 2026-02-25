# 🦞 Cline Sub-Agents Skill — Estado Atual

> Este arquivo é a fonte de verdade do projeto. Leia antes de qualquer ação.
> Última atualização: 2026-02-25 03:30 GMT-3

## Status: ✅ OPERACIONAL

### Infraestrutura
- **Cline CLI:** v2.5.0 instalado (`npm install -g cline`)
- **Auth:** OAuth via Cline provider (não expira, refresh automático)
- **Modelo:** `kwaipilot/kat-coder-pro` → roteia para `glm-5` (grátis, $0)
- **Configs isolados:** `~/.cline-configs/{default,project-a,project-b,project-c}`
- **Skill local:** `~/clawd/skills/cline-subagents/`
- **Repo:** https://github.com/ericmil87/cline-cli-2-orchestration-openclaw-skill
- **Colaboradores:** ericmil87 (owner), claudiomil87 (collaborator)

### Scripts Disponíveis
| Script | Função | Uso |
|--------|--------|-----|
| `scripts/cline-monitor.sh` | Monitorar uso/tokens/custo | `bash scripts/cline-monitor.sh` |
| `scripts/cline-cron.sh` | Rodar tasks agendadas | `bash scripts/cline-cron.sh <config>` |
| `scripts/cline-summarize.sh` | Agregar reports | `bash scripts/cline-summarize.sh <dir>` |
| `cline-project.sh` | Agent único por projeto | `bash cline-project.sh <name> "<task>"` |
| `cline-multi.sh` | Multi-agent via tmux | `bash cline-multi.sh start` |

### Regras Críticas (NÃO VIOLAR)
1. **SEMPRE** criar `.clineignore` antes de rodar agents em projetos com node_modules
2. **SEMPRE** copiar auth de `~/.cline/` para CLINE_DIR isolados antes de usar
3. **SEMPRE** especificar diretórios explícitos para frontend scans
4. **SEMPRE** stagger 2s entre agents paralelos
5. **NUNCA** rodar agents sem `--timeout` (default: 600s)

## O Que Já Foi Feito
- [x] Skill instalada e testada com 4 agents paralelos
- [x] Security audit do UpBro (46 findings, reports em ~/upbro/security-audit/)
- [x] Monitor de uso criado e funcionando
- [x] 4 PRs merged: clinerules, CI/CD, cron, clawhub
- [x] .clineignore no UpBro

## Próximos Passos (Roadmap)
1. **Configurar cron OpenClaw** — review a cada 2.5h (periodic-review.conf)
2. **Corrigir achados críticos UpBro** — CORS, python-jose, tenant auth
3. **Publicar no ClawHub** — skill pronta com SECURITY.md e CHANGELOG
4. **Testar GitHub Actions** — code review e auto-fix em repo real
5. **Token budget por agent** — kill se exceder limite
6. **Agent retry com fallback** — trocar modelo se rate limit

## Achados de Segurança UpBro (Pendentes)
| # | Severidade | Issue | Arquivo | Status |
|---|---|---|---|---|
| 1 | 🔴 CRITICAL | CORS wildcard | api/main.py | ⏳ Pendente |
| 2 | 🔴 CRITICAL | python-jose CVEs | requirements.txt | ⏳ Pendente |
| 3 | 🔴 CRITICAL | Tenant creation sem auth | api/routers/tenants.py | ⏳ Pendente |
| 4 | 🟠 HIGH | Widget sem auth | api/routers/chat_widget.py | ⏳ Pendente |
| 5 | 🟠 HIGH | Next.js 14.2.0 desatualizado | web/package.json | ⏳ Pendente |
| 6 | 🟠 HIGH | JWT em localStorage | web/lib/auth.tsx | ⏳ Pendente |
