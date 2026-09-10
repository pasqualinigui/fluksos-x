# RESEARCH — `017` (1.1) `core/harness.py`: feedforward + feedback controls

> **Data**: 2026-09-10 · **Item**: `017` (1.1, mapa ADR-040) · **Fase do ciclo**: RESEARCH
> **Hierarquia de fontes (ADR-025)**: P0 = registry API + executado + arquivos do
> repo · P1 = docs oficiais + releases · P2 = engenharia big-tech/padrões ·
> P3 = comunidade (só com corroboração P0/P1).
> **ADRs vinculantes**: ADR-001/011 (número = posição), ADR-015a (manifest +1
> linha), ADR-017 (procedimento de fronteira), ADR-019 §3 + `010` FR-010 (retry
> proibido), ADR-020 §2 (roteamento), ADR-025 (hierarquia/triangulação),
> ADR-027 §5-adendo (assunções de ambiente com prova), ADR-031 §3-caminho-1,
> ADR-035 (merge no servidor), ADR-040 (mapa F1), ADR-041 (norma prospectiva
> subprocess: primeiro consumidor é este item).

## Q-table

| # | Pergunta | Resposta (com fonte) |
|---|---|---|
| Q1 | O que são "feedforward + feedback controls" para este motor? | Vocabulário da teoria de controle (P2): **feedforward** = agir sobre condição medida **antes** da execução (validar pré-condições, recusar sem executar); **feedback** = corrigir/julgar sobre o erro **observado após** a execução (capturar saída + exit code, comparar ao esperado, evidenciar). Busca GitHub por padrão canônico com esse nome: **0 resultados** (busca controle "agent harness": 20.700 — o vazio é ausência real, não falha de ferramenta, precedente ADR-012). Definição operacional adotada: feedforward = portão pré-execução com saída `2` (erro de uso, sem executar); feedback = julgamento pós-execução com saída `0`/`1` + evidência (P0: `specs/001-…/contracts/oracle-cli.md` §§2–3; P3 corroborante: `langchain-ai/deepagents` — "harness" = o código determinístico ao redor do agente, distinto do modelo; e sua política "enforce boundaries at the tool level" corrobora o princípio I). |
| Q2 | Qual o contrato de exit codes do `harness.py`? | **Espelha o contrato do oráculo** (P0, `oracle-cli.md` §2): `0` conforme · `1` não conforme · `2` erro de uso. Triangulação: `os.EX_OK=0, EX_USAGE=64, EX_SOFTWARE=70` **executados** (P0, Python 3.12.3) + uso real de `os.EX_SOFTWARE` na indústria (`apache/airflow`, 1064 arquivos com o símbolo no GitHub — P3). Recomendação ao SPECIFY (não decisão): literais `0/1/2` para compor por construção com os 16 oráculos shell; `EX_USAGE/EX_SOFTWARE` como valores preferidos **dentro** das classes `2`/`1` se o CLARIFY quiser granularidade — nunca novos sentidos para `0/1/2` (remap silencioso, proibido pela Regra 8). |
| Q3 | Qual a forma Python de executar e julgar comandos? | `subprocess.run` (P1, CPython `Doc/library/subprocess.rst` via Context7 + P0 executado): `check=True` → `CalledProcessError` com `.returncode/.cmd/.output/.stderr`; sinal → returncode **negativo** (medido: SIGKILL → `-9`); `timeout=` → `TimeoutExpired` com kill+wait (**fail-closed**, fonte `Lib/subprocess.py`); `check=False` + `.returncode` para julgamento. Recomendação: asserts usam `check=False` + captura (caminho-1, ADR-031 §3) — **exceção não é evidência** (princípio X: falha nomeia requisito + evidência observada; traceback nomeia linha Python, não requisito). `check=True` só onde a chamada é pré-condição do próprio harness (falha = erro de uso, saída `2`). |
| Q4 | Feedback pode re-tentar (retry)? | **Não.** (P0: ADR-019 §3 — retry transforma vermelho real em verde eventual; `010` FR-010 o proíbe.) Divergência transitória é **evidência a registrar**, nunca gatilho de re-execução. Reabrir exige ADR (não releitura). |
| Q5 | O que este item assume do ambiente, e onde está a prova executada? (adendo ADR-027) | **Assunções**: (a) Python `>=3.12,<3.14` (plano §4) — prova: `python3 --version` → **3.12.3**, `uv run python` idem (P0, esta sessão); (b) **POSIX** para semântica de sinais (negativos) — prova: `Linux` + runner `ubuntu-24.04` (P0, `ci.yml:70,101,127,147,169`, matriz 3.12/3.13); **Windows fora de escopo** (limite honesto: semântica de sinais difere, sem runner para provar); (c) **stdlib puro, sem daemon, sem rede** (Escada: `subprocess/os/sys` já existem; nada a instalar). |
| Q6 | Onde mora e o que importa? | `packages/core/src/fkx_core/harness.py`, membro existente (011), **sem dependência nova** (Q5c). Superfície: tipos-base 011 (`FkxError` + taxonomia por módulo — `011` spec.md:101/FR-006: "extensão futura por módulo novo" → recomendação ao SPECIFY: `HarnessError(FkxError)`; `__init__.py` exporta, nunca import de submódulo — `011` data-model.md:35-37). |
| Q7 | Impacto de fronteira? (levantamento mecânico, molde ADR-017) | **1 ponto genuíno**: `f0-011` FR-002 (linhas 144-145) — `EXTRA` reprova qualquer módulo além dos 4 (`harness.py` incluído). `grep` por `alem dos 4\|EXTRA=` nos 16 oráculos: só `f0-011` (conteúdo de `core/`); `f0-012` FR-002 é sobre `cli/` (intocado); `f0-004/005/006/007/008` asserem diretórios, não conteúdo. Forma do ajuste (padrão ADR-018/023/026): admitir `harness.py` na whitelist **se** sob jurisdição 017. Vai ao PLAN + ADR prévia (**10ª execução** do molde ADR-017), verde aplica, manifest cita. Manifest +1 linha 17 (ADR-015a, asserida pelo oráculo novo). |
| Q8 | Roteamento ADR-020: algo a consumir? | **Nenhuma entrada roteada a 1.1.** Próximas registradas como fora de escopo com motivo: teto por run → `2.10` (sem gateway aqui); sandbox em modos → `2.6` (sem tools MCP aqui); trace-id → `3.4`; goals/compactação → `4.2`/`core/context.py`. "Emenda 3" não existe (nada a consumir). ANALYZE que ignorar este quadro sem registro = achado ≥MEDIUM (ADR-020 §2). |

## Decisões (insumo ao SPECIFY, não desenho)

| # | Decision | Rationale | Alternatives considered |
|---|---|---|---|
| D1 | `harness.py` = portão feedforward (pré) + julgamento feedback (pós), stdlib, sobre tipos 011 | Q1+Q5+Q6: é o que o item 1.1 delimita; Escada proíbe dependência nova | Reusar oráculos shell via `subprocess` (rejeitado: duplica o harness em vez de dar-lhe corpo Python; composição é por exit codes, não por invocação) |
| D2 | Exit codes espelham `oracle-cli.md` (`0/1/2`) | Q2: composição por construção com 16 oráculos; remap proibido (Regra 8) | Granularidade sysexits por classe (deferida ao CLARIFY, nunca por padrão) |
| D3 | Julgamento com `check=False` + captura; `check=True` só em pré-condição | Q3: exceção não é evidência (X); caminho-1 (ADR-031) | Tudo com `check=True` (rejeitado: traceback no lugar de `FR-XXX` + evidência) |
| D4 | Zero retry | Q4: ADR-019 §3 + `010` FR-010 (P0 normativo, não preferência) | Retry com backoff (rejeitado por governança, antes do mérito) |
| D5 | POSIX assumido e declarado; Windows fora de escopo | Q5: sem runner Windows não há prova (VIII); limite honesto, não lacuna | Abstrair sinais (rejeitado: YAGNI sem consumidor Windows) |
| D6 | `HarnessError(FkxError)` como hipótese de erro do módulo | Q6: taxonomia por módulo da 011; SPECIFY confirma o nome | Reusar `FkxError` genérico (rejeitado: perde o requisito violado em X) |
| D7 | Fronteira: 1 ponto (`f0-011` FR-002), molde ADR-017, 10ª execução | Q7: levantamento mecânico, não leitura; forma exata no PLAN + ADR prévia | Ajuste silencioso no verde (rejeitado: achado A1, `f0-audit-005-008.md`) |

## Declaração de impacto de fronteira (insumo obrigatório ao PLAN — ADR-017)

| # | Oráculo | Conflito | Ajuste (forma exata, só na Fase C verde) |
|---|---|---|---|
| 1 | `f0-011` FR-002 (l.144) | `EXTRA` lista `harness.py` como "módulos além dos 4" sobre estado correto | whitelist admite `harness.py` **se** `specs/017-*/` existe com `harness.py` sob jurisdição (jurisdição 017); resto proibido; padrão ADR-018 (legitimidade: membro `packages/core`, nunca nome estático) |

Manifest regenerado na Fase C citando a ADR prévia. Qualquer outro vermelho
herdado = conflito novo, ADR própria, nunca fix direto.

## Limites honestos (ADR-025 §3)

- Comportamento sob Windows não provado nem alegado (Q5b).
- `HarnessError` é hipótese do research (D6); o nome final é do SPECIFY/CLARIFY.
- "Feedforward/feedback" não é padrão canônico externo (busca GitHub: 0) — é
  vocabulário de controle (P2) operacionalizado sobre precedentes do repo (P0);
  a definição que vale é a deste documento (Q1), não a da literatura.
