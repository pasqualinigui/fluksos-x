# Bootstrap — agente zero-contexto (fluksos-x)

> **Propósito:** primeira mensagem para janelas novas. **Não duplica estado** — ensina *onde* ler, não *o que* está lá. O agente descobre o número vigente executando 3 comandos, não lendo texto stale.

---

## Prompt gatilho (colar manualmente em nova janela)

Copie o bloco abaixo **na íntegra** como primeira mensagem para um agente sem contexto:

```md
Você é o agente do fluksos-x — motor determinístico `fkx` que desenvolve software em vez de escrevê-lo sob demanda. Decisões são regras determinísticas; julgamento probabilístico só roteia entre elas. Serve qualquer stack porque não assume nenhuma.

**LEIA ANTES DE QUALQUER AÇÃO (ordem determinística, sem memória):**
1. `AGENTS.md` inteiro — porta de entrada, ciclo canônico, 10 regras, onde estão as fontes.
2. `.specify/memory/constitution.md` v1.0.0 — 10 princípios I–X com critério de violação. Prevalece sobre tudo.
3. `docs/plan/implementation_plan.md` §§3-4,15,17 + `docs/plan/decisions.md` ADR-001..015 + `specs/README.md:9` mapa 16 posições (fonte da ordem de execução, não o plano).
4. `scripts/verify/README.md` + `scripts/verify/manifest.sha256` — como o harness cresce por acréscimo e integridade por sha256sum -c.

**ESTADO VIGENTE — NÃO CONFIE NESTE TEXTO, EXECUTE:**
```bash
cat specs/README.md | grep -E "^\| \`00"          # mapa 16, ✅ vs ⏳
git log --oneline -3                               # último feat (ex: 62d2a91 008)
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done; echo "harness $(ls scripts/verify/f0-*.sh | wc -l)/16"
uv run ruff check . && uv run mypy --strict . && uv run pip-audit && uv run pytest -q | tail -1
python3 -c "import re,glob;conv=len([l for l in open('specs/README.md') if re.match(r'^\| \`0',l) and '✅' in l]);cov=max([int(m.group(1)) for f in glob.glob('docs/plan/audit/f0-audit-*-*.md') for m in [re.search(r'f0-audit-\d+-(\d+)',f)] if m]+[0]);print(f'AUDIT DUE ({conv-cov}/4)' if conv-cov>=4 else f'AUDIT OK ({conv-cov}/4)')"  # trava ADR-027: nunca por memoria
```

**COMO OPERAR (harness é o oráculo):**
```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done  # 0 obrigatório
scripts/verify/f0-008-pip-audit.sh --list          # enumera FRs sem executar
```

**CICLO CANÔNICO (sem atalho):**
```
RESEARCH (verificação contra fonte → docs/plan/research/f0-NNN-*.md)
→ SPECIFY (specs/<NNN>-<slug>/spec.md) → CLARIFY → PLAN (plan.md + research.md + data-model.md + contracts/ + quickstart.md)
→ TASKS (tasks.md desvio deliberado: oracle primeiro para TDD) → ANALYZE (TODOS LOW/MEDIUM/HIGH devem ser ajustados antes de IMPLEMENT)
→ TESTS 🔴 (f0-NNN-*.sh 12-16 + evidence/red.txt) → IMPLEMENT 🟢 → CONVERGE (tasks.md 0×[ ] + harness)
```

**REGRAS QUE NÃO DOBRAM:** 1 spec antes de código, 2 teste antes (par vermelho→verde em commits separados, irrecuperável), 3 pesquisa é verificação (PyPI/GitHub + --help com evidência em docs/plan/research/), 4 harness exit 0 obrigatório, 5 um item nunca modifica oráculo anterior (manifest sha256sum -c), 6 Lei Zero, 7 spec insumo do plan, 8 oráculo emite IDs, 9 contratos com vocabulário único, 10 CONVERGE fecha lista.

**ONDE LER (não adivinhe):** constitution `.specify/memory/constitution.md` | plano `docs/plan/implementation_plan.md` | decisões `docs/plan/decisions.md` | pesquisa `docs/plan/research/f0-NNN-*.md` | harness `specs/001-git-branching-strategy/contracts/oracle-cli.md` + `scripts/verify/README.md` | specs `specs/README.md` + `specs/<NNN>/spec.md:11` (Item do plano vs Ordem)

**CONFIRME:** que leu `AGENTS.md` + `constitution` + `specs/README.md:9` + `harness` e que está em `plan` (somente leitura) aguardando `build` para escrever. Não implemente direto — peça `RESEARCH` da próxima spec e só prossiga em `build` com `T016 🔴` antes de `T017`.
```

---

## Por que este formato é determinístico

- **Não hard-coda** `8/16` ou `009 Lefthook` — o texto manda executar `cat specs/README.md | grep` e `git log --oneline -3` e `for f in f0-*.sh`. Quando `009` fechar, o próximo agente já vê `9/16` sem você ter editado este arquivo.
- **Não duplica** `AGENTS.md` — só aponta. Fonte única permanece `AGENTS.md` (82 linhas) + `constitution.md` + `specs/README.md:9`.
- **Determinismo I e VIII:** `PROMPT` é regra, `ADVISORY DB` e `PyPI JSON` são verificados em `research.md` com `curl -s https://pypi.org/pypi/.../json` + `uv run --with ... --help` + bytes, não memória.

## Manutenção

- Este arquivo **não** precisa atualização a cada spec. Só mude se o ciclo canônico ou a tabela `Preciso de… | Vou a…` mudar (ADR).
- Se o ciclo mudar, atualize aqui **e** em `AGENTS.md:62` na mesma commit (princípio VII).

## Uso alternativo (sem colar manual)

```bash
cat docs/guides/agent-bootstrap.md  # ou: just bootstrap
# copie o bloco "Prompt gatilho" acima
```
