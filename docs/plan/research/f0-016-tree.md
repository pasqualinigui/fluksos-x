# RESEARCH — F0/016 · `docs/tree.md` (mapa da árvore para IA)

> **Item do plano:** 0.10 (§17 Fase 0) · **Ordem de execução:** 016/016 (ADR-011, último da Fase 0)
> **Data da verificação:** 2026-09-09 · **Papel:** Pesquisador
> **Método:** disco do repositório (P0) + docs oficiais (P1, fetch 2026-09-09) +
> padrão web llms.txt v2 (P2, analogia declarada como tal).
> Nenhum dado por memória.
> **Hierarquia de fontes (ADR-025):** P0 = registry API + executado + arquivos do repo ·
> P1 = docs oficiais + GitHub releases · P2 = padrões estáveis · P3 = comunidade (só
> com corroboração P0/P1). Versão ou comportamento externo exige ≥2 fontes
> independentes incluindo P0.
> **Insumo anterior:** `specs/013-release-automation/spec.md` › Contratos (Transferido:
> estrutura final incluindo o fluxo de release) + `specs/014-dependency-updates/spec.md`
> › Contratos (Transferido: estrutura final incluindo a config do bot) +
> `specs/015-docker-compose/spec.md` › Contratos (Transferido: árvore final incluindo
> `docker-compose.yml`, `docker/`, `.env.example`) + `docs/plan/decisions.md`
> (ADR-009, ADR-011, ADR-014, ADR-015, ADR-016, ADR-027) +
> `docs/plan/implementation_plan.md` §§15, 16 (Bônus #8), 17 +
> `specs/001-git-branching-strategy/contracts/oracle-cli.md`
> **Base:** harness 15/15 + manifest 15/15 declarados (`AGENTS.md:9`); 312 arquivos
> rastreados, ~11,8 KB de paths (P0 executado 2026-09-09); `docs/tree.md` inexistente
> (fronteira intacta); Python 3.12 stdlib + `tree` 2.x presentes (só o primeiro é
> portável ao harness).

---

## Q1 — O que `tree.md` é (e o que ele NÃO é)?

**Fontes:** plano §17 (`0.10 … Formato do mapa para IA, atualização automática`) +
§15/§16-Bônus#8 (`Tree Doc — mapa da árvore para IA`, MVP) + ADR-011 (016 por último:
"reflete a árvore real resultante").

Três candidatos com nomes parecidos e naturezas distintas:

| Candidato | Natureza | Serve à 016? |
|---|---|---|
| **Aider repo-map** (P1: `aider.chat/docs/repomap.html`) | dinâmico, gerado por execução: tree-sitter extrai símbolos, PageRank ranqueia por relevância à conversa, render cabe em budget de tokens (`--map-tokens` 1k default) | ❌ NÃO — é o item **1.5** da Fase 1 (`indexer/repo_map.py`), runtime do motor, não documento versionado |
| **llms.txt v2** (P2: `llmstxt.org`, Jeremy Howard) | convenção web: índice curado H1+resumo+listas de links p/ detalhe; detalhe atrás dos links, buscado sob demanda | ⚠️ SÓ A FORMA — a filosofia (índice pequeno e curado apontando p/ detalhe versionado) é o molde; o alvo aqui é repo, não site |
| **Mapa estático anotado** (árvore + 1 linha por diretório/artefato-chave + tabela "onde ler o quê") | documento versionado, lido inteiro no bootstrap de sessão | ✅ SIM — é o `0.10` |

**Achado:** a 016 documenta a árvore **resultante** da Fase 0 para consumo de agentes em zero-contexto (o caso de uso é o próprio bootstrap: `AGENTS.md` tem ~84 linhas e remete às fontes; `tree.md` é a planta do prédio). O mapa dinâmico por relevância chega na Fase 1 como código; confundir os dois anteciparia consumidor (princípio IV).

---

## Q2 — "Atualização automática": gerador, hook ou verificação?

**Fontes (P0):** constitution (Additional Constraints: *Ambiente sob demanda* — nada roda em segundo plano; *Escopo da máquina* — nada escreve fora do repo) + doutrina ADR-035 §5 (detecção, não prevenção) + precedente `test_audit_cadence` (portão pytest que mede, não que conserta).

| Mecanismo | Veredito | Motivo |
|---|---|---|
| Gerador que reescreve `tree.md` sozinho (hook/watcher/CI commitando) | ❌ REJEITADO | Viola *Ambiente sob demanda* (processo residente/vigilante) e converte "mapa curado" em artefato sobrescrito — julgamento (curadoria) destruído por automação; reabertura só com evidência de que curadoria deixou de ter valor |
| Script gerador determinístico (stdlib, sem dependência) rodado **à mão** + oráculo que **reprova se o commitado divergir do gerado** | ✅ ADOTADO | Forma da casa: o harness detecta, humano conserta (doutrina ADR-035 §5); `git ls-files` como fonte (índice, não disco — ignora o ignorado por construção); saída byte-idêntica 2× |
| Só curadoria manual sem verificação | ❌ REJEITADO | Apodrece em 3 specs (lição ADR-020 §1: achado sem consumidor apodrece; aqui: mapa sem verificador mente) |

**Achado:** "automática" no §17 lê-se **verificação automática, atualização assistida**: `scripts/<gerador>.py` (stdlib) emite o esqueleto (árvore completa a partir do índice + orçamento); o mantenedor/agente edita as anotações; o oráculo `f0-016` assere (a) igualdade esqueleto-gerado × commitado para a parte gerada, (b) teto de tamanho (Q3), (c) zero paths fora do índice. Geração usa `git ls-files` (nunca `find`/disco: respeita `.gitignore`, ex.: `.env`, `secrets/`).

---

## Q3 — Orçamento: qual teto para o mapa não virar segundo repo?

**Fontes (P0):** 312 paths / 11,8 KB hoje; `AGENTS.md` 84 linhas ("existe para ser lido inteiro em toda sessão — por isso é curto"); aider: budget default 1k tokens com expansão sob demanda.

**Achado:** o mapa tem dois andares com orçamentos distintos — (1) **esqueleto gerado**: todos os paths do índice (completo por construção, hoje ~12 KB; cresce com o repo); (2) **curadoria**: 1 linha por diretório de primeiro nível + tabela de ponteiros (teto fixo, ex. ≤120 linhas — número a fixar no SPECIFY). O oráculo assere o teto da parte curada (número, não julgamento) e a completude da parte gerada (todo path rastreado aparece; nenhum não-rastreado aparece). Total inicial estimado < 25 KB — cabe inteiro no bootstrap junto do `AGENTS.md`. Quando a Fase 1+ estourar o teto, quem decide o novo formato é item próprio com ADR (não esta spec).

---

## Q4 — Auditoria: quem carrega `f0-audit-013-016`?

**Fontes:** ADR-014 (auditoria-checkpoint a cada ≤4 itens) + ADR-016 (a 5ª spec desde a última auditoria herda a FR da existência do relatório) + ADR-027 (trava `test_audit_cadence`: falha quando `convergidas − cobertas ≥ 4`).

**Achado:** ao convergir a 016, `16 − 12 = 4` → DUE. Precedente 009: o relatório aterrissou **antes** da convergência e a spec nasceu verde na FR. **Obrigação herdada da 016** (a registrar na spec): oráculo `f0-016` assere a existência de `docs/plan/audit/f0-audit-013-016.md` com cabeçalhos grepeáveis (`Veredito`, `Achados`, `Destino`, formato ADR-014). A auditoria em si é checkpoint não-item (não entra no mapa ADR-011); o que entra no mapa é só a FR que a exige. Sem relatório, a 016 não converge — e o portão pytest trava qualquer tentativa de declarar verde sem ele.

---

## Q5 — Ferramentas: o que entra no TESTS e o que fica de fora?

| Ferramenta | Veredito | Motivo |
|---|---|---|
| `git ls-files` (fonte do gerador) | ✅ | índice como verdade; ignora o ignorado por construção (Lei Zero de graça) |
| Gerador em Python stdlib | ✅ | escada 001–003 do harness (oráculo da 016 só pode assumir stdlib+git+shell se quiser rodar em qualquer ponto; na prática 016 roda com tudo, mas stdlib mantém o gerador portável e sem trava) |
| `tree` (binário) | ❌ | presente nesta máquina, ausente em runners mínimos; saída varia por versão/locale — o gerador próprio é determinístico por construção (`LC_ALL=C`, ordenado) |
| ctags/tree-sitter (símbolos por arquivo) | ❌ | é o item 1.5 (Fase 1); nesta spec, granularidade = arquivo/diretório (princípio IV: sem consumidor de símbolos ainda) |
| Contador de tokens/BPE | ❌ | teto em linhas+bytes (grepeável, sem dependência); tokens variam por tokenizador — não-determinístico entre modelos (princípio I) |

---

## Decisões (D1–D5, vinculam SPECIFY/CLARIFY)

- **D1 (Q1):** `tree.md` = mapa estático anotado versionado (H1 + resumo + árvore anotada + tabela de ponteiros); aider-dinamismo é Fase 1 (1.5), llms.txt entra só como filosofia de forma.
- **D2 (Q2):** atualização = gerador stdlib à mão + oráculo que reprova divergência (detecção, não prevenção); fonte `git ls-files`; nada residente, nada que commita sozinho.
- **D3 (Q3):** dois andares (esqueleto completo gerado + curadoria com teto fixo a definir no SPECIFY, proposta ≤120 linhas); oráculo assere completude de um e teto do outro.
- **D4 (Q4):** 016 herda a FR da auditoria `f0-audit-013-016` (molde 009/ADR-016); sem relatório, sem converge.
- **D5 (Q5):** sem `tree`, sem ctags/tree-sitter, sem tokenizador; limites em linhas+bytes.

## NEEDS CLARIFICATION (para CLARIFY, antes do PLAN derivar tarefas)

1. Teto da parte curada (proposta: ≤120 linhas) e formato da anotação (1 linha por diretório vs por artefato-chave)?
2. `tree.md` mora em `docs/` (plano §15) — confirma, ou raiz junto do `AGENTS.md`?
3. O gerador vive em `scripts/` (versionado, como harness) ou em `docs/` junto do mapa?

## Evidências (E1–E6, 2026-09-09)

- **E1** P0 executado: `git ls-files | wc -l` → 312; `| wc -c` → 11778; profundidade máx. 4; `docs/tree.md` inexistente.
- **E2** P1 `aider.chat/docs/repomap.html`: mapa dinâmico (tree-sitter + PageRank + budget `--map-tokens` 1k); confirma que dinamismo é runtime, não documento.
- **E3** P2 `llmstxt.org` (v2, 2026-08): H1 + resumo em blockquote + seções H2 com listas `[nome](url)` + notas; filosofia adotada, alvo divergente (site vs repo).
- **E4** P0 plano: §17 `0.10 … atualização automática`; §16-Bônus#8 Tree Doc MVP; ADR-011/ADR-001: 016 por último ("reflete a árvore real resultante").
- **E5** P0 ambiente: Python 3.12.3 stdlib; `tree` presente mas não-portável (D5).
- **E6** P0 contratos herdados: 013 (fluxo de release), 014 (config do bot), 015 (`docker-compose.yml`, `docker/`, `.env.example`) — os três nomeiam a 016 como destino.
