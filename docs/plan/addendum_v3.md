# FLUKSOS-X: Addendum v3 — Respostas Finais e Ajustes

> **Referência:** Este documento complementa o `implementation_plan.md` v2.
> **Data:** 2026-08-29 03:56

---

## Resposta 1: ORM no Motor?

**Veredicto: NÃO precisamos de ORM no motor. Mas está disponível como skill para projetos.**

| Camada | Tecnologia | Por quê |
|--------|-----------|---------|
| **LangGraph State** (checkpoints) | `langgraph-checkpoint-postgres` | Pacote oficial. NÃO usar ORM — ele gerencia serialização/recovery internamente |
| **Memória global** (learnings, etc) | SQLite direto + Pydantic models | Leve, sem servidor, queries simples |
| **Knowledge Graph** (AST/code index) | SQLite direto | Grafos com queries SQL nativas |
| **Vector Store** | LanceDB | API própria, sem ORM |

**Para projetos gerados pelo motor:**
- Se o projeto precisar de ORM Python → skill `database-postgres` carrega SQLModel ou SQLAlchemy
- Se for JS/TS → skill carrega Drizzle ORM (como no seu fluksos)
- A escolha de ORM é do **projeto**, não do motor

> [!NOTE]
> A best practice de 2026 é clara: **não "over-ORM" o grafo**. Manter o estado do LangGraph slim, usar PostgresSaver oficial, e separar storage de aplicação do storage do grafo.

---

## Resposta 2: Changelog + Update Notifier

**Sim! Incluído como feature MVP.**

### Comportamento

```
╭──────────────────────────────────────────────────╮
│  🚀 fkx v0.3.0 disponível (você está na v0.2.1) │
│                                                   │
│  Novidades:                                       │
│  • Fix: QA agent loop infinito em projetos Rust   │
│  • Feat: Novo tema "aurora"                       │
│  • Perf: 40% menos tokens no Pesquisador          │
│                                                   │
│  Atualize com: uv tool upgrade fkx               │
│  Changelog: https://github.com/.../CHANGELOG.md   │
╰──────────────────────────────────────────────────╯
```

### Implementação

```python
# packages/cli/src/fkx_cli/update_checker.py

# Verifica atualizações uma vez por dia (cache em ~/.fkx/last_update_check)
# Fonte: PyPI API (GET https://pypi.org/pypi/fkx/json)
# Exibe banner Rich ao iniciar CLI se versão nova disponível
# Configurável: fkx config set update_check false  (desativar)
```

### Arquivo CHANGELOG.md
- Formato: [Keep a Changelog](https://keepachangelog.com/) 
- Gerado automaticamente com `python-semantic-release` baseado nos conventional commits
- Guardião monitora o changelog e gera summaries para o notifier

---

## Resposta 3: Impeccable — Skill para Projetos, NÃO no Core

**Veredicto: Impeccable como skill carregável, não embutido no motor.**

| Aspecto | Decisão |
|---------|---------|
| **No core do motor?** | ❌ Não — o motor é backend/CLI, Impeccable é frontend/UX |
| **Como skill carregável?** | ✅ Sim — `skills/frontend-polish/` com referência ao Impeccable |
| **Quando é ativado?** | Quando o Desenvolvedor gera código frontend (React, Next.js, Vue, etc.) |
| **Como integra?** | O agente Desenvolvedor, ao gerar UI, carrega a skill que inclui os padrões do Impeccable |

### Skill: `skills/frontend-polish/SKILL.md`

```markdown
# Frontend Polish (Impeccable-Inspired)

## Quando Ativar
- Projetos com frontend (React, Next.js, Vue, Svelte, etc.)
- Ao gerar componentes UI, páginas, layouts

## Regras
- Referência: https://github.com/pbakaus/impeccable
- Anti-patterns: Evitar "AI slop" (Inter genérico, gradientes roxos,
  cards aninhados sem hierarquia, etc.)
- Comandos disponíveis no projeto: /polish, /audit, /critique, /typeset
- Instalar Impeccable no projeto gerado: npx impeccable install

## Integração
- O CLI pode sugerir `npx impeccable install` durante `fkx init`
  quando detecta projeto frontend
- O agente QA pode rodar checks do Impeccable como parte da validação
```

**Benefício:** Mantém o motor limpo e agnóstico. Impeccable é ativado apenas quando faz sentido (projetos frontend).

---

## Resposta 4: Onde Colocar o Implementation Plan

**O plano fica dentro do próprio projeto do motor, acessível aos agentes.**

```
fluksos-x/
├── docs/
│   ├── plan/                              # 📋 Plano de implementação
│   │   ├── implementation_plan.md         # Plano principal (este documento)
│   │   ├── addendum_v3.md                # Adendos e ajustes
│   │   ├── decisions.md                   # ADR (Architecture Decision Records)
│   │   └── research/                     # Pesquisas que fundamentam decisões
│   │       ├── pesquisa-profunda-harness.md
│   │       └── ...
│   ├── tree.md                            # Mapa da árvore (para IA)
│   ├── architecture/                      # ADRs por componente
│   └── guides/                            # Guias de uso
```

### Como a IA acessa durante specify

1. **No `AGENTS.md` (constitution do motor)** teremos uma seção:
   ```markdown
   ## Documentação do Plano
   - Plano principal: docs/plan/implementation_plan.md
   - Árvore do projeto: docs/tree.md
   - Decisões arquiteturais: docs/plan/decisions.md
   
   REGRA: Antes de qualquer spec, consulte o plano para contexto.
   ```

2. **O Spec-Kit** já suporta isso nativamente — o `speckit-constitution` pode referenciar docs auxiliares

3. **Cada fase** terá sua pasta de specs dentro de `.fluksos-x/specs/fase-N/`

---

## Resposta 5: Confirmar — Motor Cria Qualquer Sistema

**Sim. Confirmação absoluta:**

```
Motor fkx (Python)
    ↓ gera/opera
    ├── Projeto Next.js (TypeScript)
    ├── Projeto FastAPI (Python)
    ├── Projeto NestJS (TypeScript)
    ├── Projeto Rust CLI
    ├── Projeto Go Microservice
    ├── App React Native (Mobile)
    ├── Automação Python (n8n, scripts)
    ├── SaaS full-stack (qualquer stack)
    ├── Projeto C# (.NET)
    ├── Projeto Java (Spring)
    └── Literalmente qualquer coisa com código
```

**Todo projeto segue o mesmo ciclo determinístico:**
```
INTERVIEW → CONSTITUTION → RESEARCH → SPEC → PLAN → TASKS → TESTS → IMPLEMENT → HARNESS → QA → DEVOPS → COMMIT → CONVERGE
```

O motor não "sabe" todas as linguagens de antemão — ele **pesquisa** (via Agente Pesquisador), **aprende** (via skills + RAG), e **valida** (via harness + LSP + testes). O determinismo vem do **processo**, não do conhecimento prévio.

---

## Resposta 6: Scaffold Padrão no `fkx init`

**Sim! `fkx init` cria uma estrutura base INDEPENDENTE do tipo de projeto.**

### `fkx init` (projeto novo)

```bash
$ fkx init
# Resultado:
meu-projeto/
├── .fluksos-x/                    # Pasta do motor (isolada)
│   ├── constitution.md            # AGENTS.md do projeto (template)
│   ├── config.toml                # Configuração local
│   ├── specs/                     # Especificações futuras
│   ├── plans/                     # Planos futuros
│   ├── tasks/                     # Tarefas futuras
│   ├── sessions/                  # Histórico de sessões
│   └── reports/                   # Relatórios futuros
├── docs/                          # Documentação do projeto
│   └── tree.md                    # Mapa da árvore (auto-gerado)
├── .gitignore                     # Gitignore inteligente (detecta stack depois)
├── .env.example                   # Template de variáveis de ambiente
├── README.md                      # README template
└── .git/                          # Git inicializado + primeiro commit
```

### O que acontece automaticamente:

| Ação | Detalhe |
|------|---------|
| `git init` | Repositório local criado |
| Primeiro commit | `chore: initialize project with fkx` |
| `.gitignore` | Template base (`.env`, `node_modules/`, `__pycache__/`, `.fluksos-x/sessions/`, etc.) |
| `docs/tree.md` | Auto-gerado com a estrutura atual |
| `constitution.md` | Template base que será customizado no `fkx interview` |
| `config.toml` | Defaults herdados do global (`~/.fkx/config.toml`) |

### `fkx init --legacy` (projeto existente)

```bash
$ cd projeto-legado/
$ fkx init --legacy
# Resultado:
# 1. NÃO altera nada existente
# 2. Cria apenas .fluksos-x/ com configs
# 3. Indexa o projeto (Tree-sitter)
# 4. Gera relatório de saúde:
#    - Vulnerabilidades encontradas
#    - Debt técnica estimada
#    - Padrões fora do padrão sênior
#    - Sugestão de modernização
# 5. Gera docs/tree.md com a árvore atual
```

---

## Resposta 7: Minha Opinião — Estamos Prontos?

**Sim, o plano está sólido e completo.** Aqui minha análise:

### ✅ O que temos coberto (e que nos coloca na vanguarda)

| Dimensão | Status | Nível |
|----------|--------|-------|
| **Harness Engineering** | Completo (feedforward + feedback) | 🟢 State-of-the-art |
| **SDD** | Spec-Kit (GitHub, 132k⭐) integrado | 🟢 Padrão da indústria |
| **TDD** | Tests-first enforçado pelo ciclo | 🟢 Determinístico |
| **ADD** | LangGraph + 7 agentes especializados | 🟢 Arquitetura sênior |
| **Multi-linguagem** | Tree-sitter (66+ langs) + LSP | 🟢 Agnóstico |
| **Observabilidade** | LGTM + Langfuse + Promptfoo | 🟢 Enterprise-grade |
| **Memória** | Shadow + RAG + Knowledge Graph | 🟢 Compounding dreams |
| **Segurança** | pip-audit + Trivy + hardening | 🟢 DevSecOps |
| **CLI/UX** | Typer + Rich + Textual + temas | 🟢 Premium |
| **Auto-melhoria** | Agente Guardião | 🟢 Self-evolving |

### ⚡ O que nos diferencia de TUDO que existe hoje

1. **Nenhuma CLI existente** (Claude Code, Aider, OpenCode) tem orquestração multi-agente com SDD + TDD integrado
2. **Nenhuma** tem Harness Engineering formalizado com feedforward + feedback
3. **Nenhuma** tem Shadow Memory + Knowledge Graph + RAG híbrido
4. **Nenhuma** tem Spec-Kit integrado como engine SDD
5. **Nenhuma** é multi-provider com observabilidade completa self-hosted

### 🔮 Sugestão final: coisas para considerar PÓS-MVP

| Item | Prioridade | Quando |
|------|-----------|--------|
| **Plugin marketplace** | Média | v0.5+ |
| **fkx cloud** (execução remota) | Baixa | v1.0+ |
| **Modo "pair programming"** (streaming visual) | Média | v0.4+ |
| **Geração de testes visuais** (Playwright/Cypress) | Média | v0.3+ |
| **Integração com GitHub Issues/PRs** | Alta | v0.3+ |
| **fkx migrate** (migração entre stacks) | Alta | v0.3+ |

**Não falta pesquisar nada.** Temos todas as versões pinadas, todas as decisões tomadas, todos os patterns definidos. O que falta é **executar**.

---

## Resposta 8: MCP no Motor

**Sim! O motor DEVE suportar MCP. É configurável via terminal.**

### Arquitetura MCP do Motor

```
fkx Motor
  ├── MCP Client (MultiServerMCPClient)     # Consome tools de MCP servers
  │   ├── Servers built-in                   # filesystem, shell, git, web_search
  │   └── Servers configuráveis              # Qualquer MCP server externo
  │
  └── MCP Server (opcional, futuro)          # Expõe o MOTOR como MCP server
      └── Outros agentes podem usar fkx      # Ex: Copilot → fkx via MCP
```

### Configuração via CLI

```bash
# Adicionar MCP server ao motor
fkx config mcp add github \
  --transport stdio \
  --command "npx" \
  --args "-y @modelcontextprotocol/server-github"

# Adicionar MCP server a um projeto específico
fkx config mcp add postgres \
  --transport stdio \
  --command "npx" \
  --args "-y @modelcontextprotocol/server-postgres" \
  --project  # flag para config local

# Listar MCP servers configurados
fkx config mcp list

# Remover
fkx config mcp remove github

# Testar conexão
fkx config mcp test github
```

### Arquivo de configuração

```toml
# .fluksos-x/config.toml (por projeto) ou ~/.fkx/config.toml (global)

[mcp.servers.github]
transport = "stdio"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-github"]
env = { GITHUB_TOKEN = "${GITHUB_TOKEN}" }

[mcp.servers.filesystem]
transport = "stdio"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "."]

[mcp.servers.postgres]
transport = "stdio"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-postgres"]
env = { DATABASE_URL = "${DATABASE_URL}" }
project_only = true  # Apenas neste projeto
```

### Tools Built-in do Motor (sempre disponíveis)

Estes NÃO precisam de MCP server externo — são tools Python nativas do motor:

| Tool | Descrição |
|------|-----------|
| `fkx_filesystem` | Ler/escrever arquivos |
| `fkx_shell` | Executar comandos (sandboxed) |
| `fkx_git` | Operações git |
| `fkx_web_search` | Tavily/Exa search |
| `fkx_web_scrape` | Crawl4AI scraping |
| `fkx_lsp` | Bridge com LSP servers |
| `fkx_treesitter` | AST queries |
| `fkx_speckit` | Spec-Kit CLI |

MCP servers externos são **complementares** — expandem as capacidades dos agentes conforme o projeto precisa.

---

## Resposta 9: Segurança — Princípios Fundamentais

**Segurança é LEI ZERO do motor. Aqui está o hardening completo.**

### Security Hardening Checklist do Motor

| # | Área | Medida | Implementação |
|---|------|--------|---------------|
| 1 | **Secrets** | NUNCA em código, NUNCA em logs, NUNCA em commits | `.env` + `.gitignore` + `git-secrets` pre-commit hook |
| 2 | **Secrets rotation** | Variáveis de ambiente, NUNCA hardcoded | Pydantic Settings com `SecretStr` (mascara em logs) |
| 3 | **Dependency audit** | Scan contínuo de vulnerabilidades | `pip-audit` no pre-commit + Guardião monitora |
| 4 | **Container security** | Imagens Alpine, read-only, cap_drop ALL | docker-compose hardening (já no plano) |
| 5 | **Network isolation** | Rede interna Docker, mínimo de portas expostas | `internal: true` na rede Docker |
| 6 | **LLM API keys** | Centralizados no LiteLLM, nunca nos agentes | LiteLLM proxy é o único com acesso às keys |
| 7 | **Sandbox execution** | Comandos shell dos agentes em sandbox | Whitelist de comandos, timeout, sem sudo |
| 8 | **Git secrets scan** | Detectar leaks antes do commit | `git-secrets` ou `gitleaks` no Lefthook |
| 9 | **SBOM** | Software Bill of Materials | `cyclonedx-py` para gerar SBOM |
| 10 | **Supply chain** | Hash-pinning em lockfile | UV lockfile nativo (hash verification) |

### Security Checklist para Projetos Gerados

Quando o motor gera um projeto, o agente DevOps **obrigatoriamente** aplica:

| # | Medida | Detalhes |
|---|--------|---------|
| 1 | **CSP Headers** | Content-Security-Policy strict |
| 2 | **HSTS** | HTTP Strict Transport Security |
| 3 | **Rate Limiting** | Por IP, por rota, por user |
| 4 | **CORS** | Whitelist explícita de origins |
| 5 | **Auth** | better-auth ou equivalente sênior (NUNCA auth caseira) |
| 6 | **JWT** | Rotation, short-lived access tokens, refresh tokens |
| 7 | **SQL Injection** | ORM parameterized queries (NUNCA string concat) |
| 8 | **XSS** | Output encoding, CSP, sanitização |
| 9 | **DAST** | OWASP ZAP scans automatizados |
| 10 | **SCA** | Trivy + pip-audit/npm audit |
| 11 | **Secrets** | `.env` + vault + zero trust |
| 12 | **SSH** | Porta alterada, sem root, sem password, only keys |
| 13 | **Firewall** | UFW + fail2ban (como você faz na VPS) |
| 14 | **Proxy** | Traefik/Cloudflare (borda, DDoS, WAF) |
| 15 | **Zero Trust** | Cloudflare Access / Tunnels |
| 16 | **Backup** | R2/S3 com encryption at rest |
| 17 | **Logging** | Audit logs, sem PII nos logs |
| 18 | **Docker** | Non-root user, read-only fs, resource limits |

### Skill: `skills/security/SKILL.md`

Esta skill será carregada **automaticamente** em TODOS os projetos (nunca desativável):

```markdown
# Security (Always-On Skill)

## REGRAS INQUEBRAVEIS
1. NUNCA armazenar secrets em código-fonte
2. NUNCA logar secrets, tokens, passwords, PII
3. NUNCA confiar em input do usuário sem validação
4. NUNCA usar auth caseira — usar bibliotecas auditadas
5. NUNCA expor portas desnecessárias
6. NUNCA usar root em containers
7. NUNCA usar HTTP em produção — SEMPRE HTTPS
8. SEMPRE validar input (Pydantic/Valibot/Zod)
9. SEMPRE usar parameterized queries
10. SEMPRE aplicar rate limiting
11. SEMPRE configurar CORS restritivo
12. SEMPRE usar CSP headers
```

### Sua VPS como referência (skill `infra-hardening`)

O que você faz na VPS será codificado como skill `infra-hardening`:

```markdown
# Infrastructure Hardening

## SSH
- Remover acesso root: PermitRootLogin no
- Desabilitar password: PasswordAuthentication no
- Porta custom: Port 6622 (ou outra não-padrão)

## Firewall
- UFW: allow 6622/tcp, allow from Cloudflare IPs only on 80,443
- fail2ban: max 3 tentativas, ban 24h

## Cloudflare
- Full-Strict SSL
- Zero Trust Access
- R2 para backups
- WAF rules ativas
- DDoS protection

## Sistema
- swap configurado
- unattended-upgrades
- audit logging
```

---

## Resumo das Atualizações no Plano

| # | Mudança | Onde |
|---|---------|-----|
| 1 | ORM: Não no motor, sim como skill para projetos | Nova seção |
| 2 | Changelog + Update Notifier | `packages/cli/src/fkx_cli/update_checker.py` |
| 3 | Impeccable como skill carregável | `skills/frontend-polish/` |
| 4 | Implementation plan em `docs/plan/` | Estrutura de docs atualizada |
| 5 | Confirmação: motor é universalmente agnóstico | Seção explícita |
| 6 | Scaffold padrão no `fkx init` | Nova seção detalhada |
| 7 | Análise: plano é state-of-the-art, pronto para execução | Opinião fundamentada |
| 8 | MCP configurável no motor | `fkx config mcp add/remove/list/test` |
| 9 | Security como skill always-on + hardening checklist | `skills/security/` + `skills/infra-hardening/` |

---

> [!CAUTION]
> **O plano está COMPLETO.** Todas as dúvidas respondidas, todos os ajustes feitos.
> 
> **Próximo passo após aprovação final:**
> 1. Copiar `implementation_plan.md` + este addendum para `fluksos-x/docs/plan/`
> 2. Executar `specify init --here` no diretório `fluksos-x/`
> 3. Criar `AGENTS.md` (constitution do motor) referenciando o plano
> 4. Iniciar Fase 0.1: UV workspace com o ciclo specify completo
