# Data Model: CI completo + branch protection — portão servidor

## Entidades

### 1. Workflow CI (`.github/workflows/ci.yml`)

| Campo | Tipo | Regra |
|---|---|---|
| jobs | mapa nome→definição | nomes únicos entre workflows, estáveis (`verify` preservado da 003); 8 jobs (FR-005) |
| `uses:` | SHA + comentário | todo action pinado imutável; tag major proibida |
| `runs-on` | string fixa | `ubuntu-24.04`; `latest` proibido |
| `strategy.matrix` | `["3.12","3.13"]` + `fail-fast: false` | intervalo exato; sinal total |
| `timeout-minutes` | inteiro por job | teto explícito (quarentena ADR-019) |
| proibidos | — | `continue-on-error`, retry mascarador, segredos literais |

### 2. Required check (config de servidor, fora do repo)

| Campo | Tipo | Regra |
|---|---|---|
| nome do job | string | 1:1 com job do workflow; renomear job exige ADR (quebra checks nominais) |
| modo | frouxo | sem exigência de branch atualizada (decisão CLARIFY) |
| bypass | negado | inclusive admin ("Do not allow bypassing") |
| reviews | não exigidos | deadlock com 1 mantenedor; reavaliar com 2º colaborador |

### 3. Portão de cobertura

| Campo | Tipo | Regra |
|---|---|---|
| ferramenta | `pytest-cov==7.1.0` em dev | hash `uv.lock` |
| limiar | `--fail-under=90` | medido 95% (2026-09-04); elevar só por spec/ADR |

### 4. Gramática de commit

11 tipos (CONTRIBUTING) aceitos pelo preset commitlint; mensagem fora reprova com regra nomeada; validação no intervalo do push/PR, nunca retroativa.

### 5. Linha de manifest + índice

10ª linha `sha256sum` de `f0-010` (acréscimo); `specs/README.md` `010 ✅` + hash do commit verde.

## Relações

- Workflow 1:N jobs; job 1:1 required check (nome é a chave estrangeira entre repo e servidor).
- Oráculo observa workflow (grep estrutural) + documenta procedimento; nunca toca servidor.
- Índice aponta commit verde; verde aponta manifest; manifest aponta oráculo.

## Ciclo de vida

Ausente (vermelho 🔴) → presente + verde local (🟢) → convergido (índice + cenário 🧑 registrado ou divergência declarada) → validado em servidor (Fase E, fecha B3).

## Volume / escala

1 workflow, 8 jobs, matriz 2 versões; 13 FRs → 13 asserções; 0 segredos.
