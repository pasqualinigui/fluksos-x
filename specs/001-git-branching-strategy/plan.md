# Implementation Plan: Fundação de Versionamento e Convenções do Motor

**Branch**: `001-git-branching-strategy` | **Date**: 2026-08-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-git-branching-strategy/spec.md`

---

## Summary

Estabelecer o repositório do motor com linha principal `main` e linha de
integração `develop`, regras de exclusão que impeçam segredos e artefatos
descartáveis de entrarem no histórico, convenções normativas de registro e de
nomeação de linhas de trabalho, e um **oráculo de conformidade** executável que
avalie tudo isso por código de saída.

A abordagem técnica é ditada por dois achados da pesquisa empírica (Phase 0):
o template canônico do GitHub **deixa variantes de arquivo de ambiente
passarem** (E1), e `git check-ignore` **não enxerga arquivos já rastreados**
(E7). O plano corrige ambos explicitamente, em vez de herdar o padrão da
indústria sem verificação.

O oráculo nasce aqui como script único e cresce por acréscimo nos itens 002–012,
até ser promovido a suíte de testes automatizados no item 007.

---

## Technical Context

**Language/Version**: Bash (POSIX-compatible) + Python 3.12.3 — **exclusivamente
stdlib**. Verificado presente na máquina alvo.

**Primary Dependencies**: Nenhuma. Restrição dura de FR-019: neste ponto do
bootstrap, `pytest`, `ruff`, `mypy`, `lefthook`, `trivy` e `gitleaks` estão
todos ausentes por design — chegam nos itens 005 a 009. O gerenciador de
pacotes está instalado mas **não é usado** neste item (é o item 003).

**Storage**: Sistema de arquivos e banco de objetos do git. Sem base de dados.

**Testing**: Oráculo em script, contrato de código de saída (`0` conforme,
`1` não conforme, `2` erro de uso). Promovido a `pytest` no item 007 — o
contrato de interface foi desenhado para tornar essa promoção mecânica.

**Target Platform**: Linux (Ubuntu, kernel 7.0.0), git 2.55.0.

**Project Type**: Infraestrutura de repositório — raiz do monorepo. Não é
aplicação; não há código de produção neste item.

**Performance Goals**: Oráculo conclui em < 5 s (SC-003). Estimativa: dezenas de
milissegundos, dominadas por invocações do git.

**Constraints**:
- Nenhuma escrita em configuração de escopo global da máquina (FR-003).
- Nenhuma dependência instalada (FR-019).
- Ordem de execução normativa: exclusões vigentes **antes** do registro inicial;
  oráculo reprovando **antes** da implementação.

**Scale/Scope**: Um repositório, ~5 arquivos criados, 23 requisitos funcionais.
Consome contrato de nenhum item anterior e entrega contrato a 5 itens
nomeados (003, 005, 006, 007, 012), transferindo responsabilidade a outros
3 (002, 008, 009), conforme a seção Contratos da spec.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Estado da constitution**: `.specify/memory/constitution.md` contém **18
placeholders não substituídos** — é o modelo em branco. A ratificação é o item
**002**, o próximo da fila.

**Consequência**: não existem princípios ratificados contra os quais avaliar
este portão formalmente. Aplicar o portão contra um modelo vazio seria teatro.

**Portão substituto aplicado** — princípios normativos vigentes conforme
`docs/plan/implementation_plan.md` e `docs/plan/addendum_v3.md`:

| Princípio vigente | Origem | Avaliação |
|---|---|---|
| **Segurança é Lei Zero** — nunca segredos em código, log ou commit | addendum §9, itens 1–2 | ✅ FR-008..FR-012 e FR-020. A pesquisa E1 **encontrou e corrigiu** um vazamento que o padrão da indústria deixaria passar |
| **Supply chain: hash-pinning no lockfile** | addendum §9, item 10 | ✅ FR-013 + asserção positiva (D3), protegendo contra regressão futura |
| **Test-First** | plano §17, ciclo determinístico | ✅ Oráculo escrito e executado reprovando antes da implementação (Fase C antes da Fase D). Único mecanismo de prova disponível antes do item 007 |
| **O harness é o oráculo** | plano §14 | ✅ Veredito por código de saída, não por julgamento. Extensível pelos itens 002–012 |
| **Determinismo** | plano §1 | ✅ SC-003: execuções repetidas produzem resultado idêntico; asserção explícita no oráculo |
| **Spec precede código** | Golden Rule | ✅ spec.md e research.md concluídos e revisados antes deste plano |
| **Não invadir escopo alheio** | ordem acordada dos 12 itens | ✅ D8: constitution e `AGENTS.md` deixados intactos para o item 002 |

**Veredito**: **PASS**, com a ressalva registrada de que o portão formal só
existirá a partir do item 002. Nenhuma violação a justificar.

**Re-avaliação pós-Phase 1**: **PASS**. O desenho não introduziu dependência,
não escreveu em escopo global e não antecipou artefatos do item 002. A adição
do `CONTRIBUTING.md` (D8) usa um local já previsto no §15 do plano.

---

## Project Structure

### Documentation (this feature)

```text
specs/001-git-branching-strategy/
├── spec.md              # Concluído (/speckit-specify)
├── plan.md              # Este arquivo
├── research.md          # Phase 0 — E1..E10, decisões D1..D8 (D9 em spec.md/Clarifications)
├── data-model.md        # Phase 1 — entidades e invariantes
├── quickstart.md        # Phase 1 — roteiro de validação
├── contracts/
│   └── oracle-cli.md    # Phase 1 — contrato de interface do oráculo
├── checklists/
│   └── requirements.md  # Concluído (/speckit-specify)
└── tasks.md             # Phase 2 (/speckit-tasks — NÃO criado aqui)
```

### Source Code (repository root)

Este item não produz código de aplicação. Produz a fundação do repositório e a
semente do harness.

```text
fluksos-x/
├── .gitignore                    # NOVO — regras de exclusão (D1, D2, D3, D9)
├── CONTRIBUTING.md               # NOVO — convenções normativas (D8)
├── scripts/
│   └── verify/
│       ├── README.md             # NOVO — como o oráculo cresce nos itens 002-012
│       └── f0-001-foundation.sh  # NOVO — oráculo deste item
├── docs/                         # EXISTENTE
│   └── plan/
│       ├── implementation_plan.md
│       ├── addendum_v3.md
│       ├── decisions.md          # NOVO — ADR-001: mapa 001..012 <-> itens 0.x
│       └── research/
│           └── f0-001-git-branching.md
├── specs/                        # EXISTENTE
├── .claude/skills/               # EXISTENTE — versionado (D9)
└── .specify/                     # EXISTENTE — intocado
```

**Structure Decision**: `scripts/verify/` já consta do §15 do plano como
`scripts/`; a subpasta `verify/` isola os oráculos das ferramentas operacionais
(`setup.sh`, `dev.sh`) previstas para o mesmo diretório. Um arquivo por item da
Fase 0, nomeado `f0-NNN-<slug>.sh`, para que cada item acrescente o seu sem
tocar nos anteriores e para que o item 007 possa promovê-los individualmente a
módulos de teste. `CONTRIBUTING.md` e `.gitignore` vão à raiz por convenção
universal — é onde pessoas e ferramentas os procuram.

---

## Fases de execução

> A ordem abaixo é **normativa**. Duas restrições a governam, ambas levantadas na
> validação da spec: (1) exclusões vigentes antes do registro inicial, porque o
> histórico é irreversível; (2) oráculo reprovando antes da implementação, porque
> é a única prova de test-first disponível antes do item 007.

### Fase A — Preparação (sem repositório ainda)

1. Criar `docs/plan/decisions.md` com **ADR-001**, registrando o mapa entre a
   numeração sequencial das specs (`001`..`012`) e os itens do plano (`0.9`,
   `0.11`, `0.1`, ...), mais a ordem de dependência acordada. Sem isso a
   rastreabilidade entre spec e plano depende de memória de conversa.
2. Criar `scripts/verify/README.md` documentando o contrato de crescimento do
   harness pelos itens 002–012.

### Fase B — Regras de exclusão **antes** de qualquer registro

Criar `.gitignore` na raiz:

1. Herdar o template canônico do GitHub para Python (220 linhas, já obtido na
   pesquisa) como base.
2. **Substituir** o bloco de ambiente pelo trio corrigido (D1):
   `.env` + `.env.*` + `!.env.example`.
3. Acrescentar o bloco fluksos-x (D2): `.fluksos-x/sessions/`,
   `.fluksos-x/reports/`, `.tmp/`, `*.lance/`.
4. Acrescentar `.claude/settings.local.json` (D9), mantendo `.claude/skills/`
   versionável.
5. **Não** acrescentar padrão algum de lockfile (D3).
6. **Não** repetir as exclusões que `.specify/.gitignore` já gerencia (FR-014).

> Nada é registrado nesta fase. O objetivo é que a regra exista antes de existir
> a possibilidade de registrar.

### Fase C — Oráculo em estado de reprovação 🔴

1. Escrever `scripts/verify/f0-001-foundation.sh` implementando todas as
   asserções do contrato (ver `contracts/oracle-cli.md`).
2. **Executar o oráculo e registrar a saída.** Ele deve reprovar — o repositório
   ainda não existe (FR-021), não há `develop`, não há `CONTRIBUTING.md`, não há
   registro inicial.
3. Preservar essa saída como evidência do vermelho (SC-004).

> Esta fase é a prova de test-first. Pular direto para a Fase D satisfaz todos os
> FR e ainda assim **falha SC-004**, porque a evidência do vermelho não existiria.

### Fase D — Implementação até o verde 🟢

> **Ordem interna revisada** após `/speckit-analyze` (achado I1): as convenções
> precedem a criação do repositório, para que o commit inicial já as contenha e
> obedeça sem exigir um segundo commit corretivo. Esta é a ordem materializada em
> `tasks.md` (Phases 4–6); as duas ordens satisfazem os requisitos, mas manter
> duas ordens distintas nos artefatos criava divergência sem propósito.

1. Escrever `CONTRIBUTING.md` com as convenções normativas (D8): os 11 tipos, o
   formato com escopo e marcação de incompatibilidade, o formato de nome de linha
   de trabalho, e o papel de `main` e `develop`.
2. **Fundação do repositório** (D6): detectar se já existe repositório.
   Ausente → criar com linha principal `main`. Presente → verificar o nome da
   linha principal e renomear se necessário. Nunca reinicializar às cegas, porque
   o parâmetro de nome é descartado em silêncio no re-init.
3. Fixar identidade de autoria **no escopo local** do repositório
   (`Guilherme <pasqualini166@gmail.com>`) e a preferência de linha principal
   também em escopo local. Nenhuma escrita em escopo global (FR-003).
4. Inspecionar o que será registrado antes de registrar, confirmando que nenhum
   arquivo de categoria proibida aparece.
5. Registrar o commit inicial contendo `docs/`, `specs/`, `.gitignore`,
   `CONTRIBUTING.md`, `scripts/`, `.specify/` e `.claude/skills/` (D9) —
   mensagem conforme a própria convenção recém-definida.
6. Criar a linha `develop` a partir de `main`.

### Fase E — Verde e convergência 🟢

1. Executar o oráculo novamente. Todas as asserções aprovam.
2. Registrar a saída como evidência do verde (SC-004).
3. Confirmar SC-003 executando duas vezes seguidas e comparando os resultados.

---

## Decisões técnicas herdadas da pesquisa

| ID | Decisão | Requisito atendido |
|---|---|---|
| D1 | `.env` + `.env.*` + `!.env.example` | FR-008, FR-009 |
| D2 | Excluir subdiretórios de `.fluksos-x/`, nunca o diretório-pai | FR-012 |
| D3 | Herdar template canônico; asserção positiva sobre a trava | FR-013 |
| D4 | Arquivo já rastreado detectado por listagem do índice, não por consulta às regras | FR-020 |
| D5 | Índice e histórico auditados como asserções separadas, severidades distintas | FR-020 |
| D6 | Fundação detecta repositório preexistente antes de agir | FR-001, edge case |
| D7 | Convenção validada por expressão regular na stdlib | FR-004, FR-005, SC-002 |
| D8 | Convenção normativa em `CONTRIBUTING.md`; constitution intocada | FR-004..FR-007 |
| D9 | Artefatos de integração de agente versionados; configuração local excluída | FR-023 |

---

## Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| Um item futuro acrescenta `*.lock` ao `.gitignore` e desfaz o controle de cadeia de suprimentos em silêncio | Alto — perda de hash-pinning sem aviso | Asserção **positiva** no oráculo (D3): a trava precisa ser comprovadamente versionável, não apenas não mencionada |
| Oráculo construído sobre consulta às regras dá falso-negativo com segredo já no índice | Crítico — Lei Zero violada com o oráculo aprovando | D4: listagem do índice. Demonstrado empiricamente em E7 |
| Variante de arquivo de ambiente escapa da exclusão | Crítico — segredo permanente no histórico | D1, verificado em E5 sobre 5 variantes |
| Registro inicial criado antes das exclusões | Crítico — irreversível | Fase B precede a Fase D por construção |
| Fase C pulada, perdendo a prova de test-first | Médio — SC-004 falha silenciosamente | Fase C produz artefato de evidência; sua ausência é detectável |
| Habilidades do motor de especificação derivam sem registro entre itens da Fase 0 | Alto — o processo derivaria junto, invalidando a comparabilidade entre os 12 itens | D9: artefatos de integração versionados, tornando qualquer deriva visível no diff |
| Oráculo cresce em arquivo único e vira monólito ao chegar no item 012 | Médio — manutenção | Um arquivo por item, `f0-NNN-<slug>.sh`; `README.md` documenta a convenção de crescimento |

---

## Complexity Tracking

> Preenchido apenas se o portão constitucional apresentar violações a justificar.

Nenhuma violação. Tabela não aplicável.
