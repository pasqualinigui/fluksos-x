# Phase 0 — Research: Fundação de Versionamento e Convenções

**Feature**: `001-git-branching-strategy` · **Data**: 2026-08-29
**Método**: verificação empírica na máquina alvo. Nenhuma decisão por memória.
**Insumo anterior**: `docs/plan/research/f0-001-git-branching.md` (Q1–Q5, vinculante, não reaberto)

Esta pesquisa resolve apenas os desconhecidos **técnicos** que a spec deixou em
aberto por serem detalhes de implementação. Cinco experimentos executados em
repositórios descartáveis; nenhum tocou o diretório do projeto.

---

## E1/E5 — Semântica de exclusão de arquivos de ambiente

### Experimento

Repositório descartável, regra `.env` isolada, arquivos-isca criados:

```
.env           IGNORADO
.env.example   versionável
.env.local     versionável      <-- VAZAMENTO
```

### 🔴 Achado crítico

O template canônico do GitHub (linha 153) traz apenas `.env`. Padrões do git sem
curinga casam **exatamente**, então `.env.local`, `.env.production` e
`.env.staging` **passariam direto para o histórico**. Esse é precisamente o modo
de falha que a Lei Zero (addendum §9, itens 1 e 2) existe para impedir, e o
template canônico **não** o cobre.

Confirmado também que a negação `!.env.example` seria **desnecessária** com a
regra `.env` isolada — o que dá falsa sensação de proteção: quem lê
`.env` + `!.env.example` conclui que variantes estão cobertas, e não estão.

### Verificação da correção

```
regra: .env  +  .env.*  +  !.env.example

.env               IGNORADO ✅
.env.local         IGNORADO ✅
.env.production    IGNORADO ✅
.env.staging       IGNORADO ✅
.env.example       versionável ✅
```

**Decision**: adotar o trio `.env` / `.env.*` / `!.env.example`.
**Rationale**: cobre toda a família de variantes preservando o arquivo-modelo
(FR-008 + FR-009). Com `.env.*` presente, a negação passa a ser funcionalmente
necessária, não decorativa.
**Alternatives rejected**: `.env` sozinho (template canônico) — reprovado por
deixar variantes passarem. `.env*` sem ponto — casaria um diretório chamado
`.environment/`, exclusão ampla demais.

---

## E2 — Exclusão parcial de `.fluksos-x/`

### Experimento

```
regra: .fluksos-x/sessions/  +  .fluksos-x/reports/

.fluksos-x/config.toml        versionável ✅
.fluksos-x/specs/keep.md      versionável ✅
.fluksos-x/sessions/s1.json   IGNORADO ✅
.fluksos-x/reports/r1.md      IGNORADO ✅
```

**Decision**: excluir os subdiretórios diretamente; **não** excluir
`.fluksos-x/` com posterior negação.
**Rationale**: a preocupação levantada no briefing — o git não descer em
diretório já excluído — **não se aplica** aqui, porque o diretório-pai nunca é
excluído. A armadilha só existiria no desenho alternativo.
**Alternatives rejected**: `.fluksos-x/` + `!.fluksos-x/specs/` — inoperante. O
git não desce em diretório excluído, então a negação de um filho jamais seria
avaliada. Este é o desenho que a pesquisa preveniu.

---

## E3/E6 — A trava de dependências sobrevive ao template completo?

### Experimento

Template canônico integral (220 linhas) aplicado a um repositório descartável:

```
uv.lock        versionável ✅
poetry.lock    versionável ✅
Pipfile.lock   versionável ✅
pdm.lock       versionável ✅
```

Inspeção direta dos padrões de lockfile no template:

```
96:  # Pipfile.lock
102: # uv.lock
109: # poetry.lock
116: # pdm.lock
123: # pixi.lock
```

**Achado**: todos os padrões de lockfile no template estão **comentados**, e não
existe nenhum padrão amplo `*.lock`. A trava sobrevive.

**Decision**: herdar o template canônico sem alteração nessa área, e adicionar
uma **asserção positiva** no oráculo verificando que a trava é versionável.
**Rationale**: FR-013 exige garantia, não ausência de menção. Um item futuro
poderia acrescentar `*.lock` por engano e desfazer o controle de cadeia de
suprimentos em silêncio; a asserção positiva detecta isso na hora.
**Alternatives rejected**: confiar na inspeção visual do template — não protege
contra regressão futura, que é o risco real.

---

## E7 — Detecção de arquivo proibido **já rastreado** (FR-020)

### Experimento

Cenário do modo de falha real: segredo entra no histórico **antes** de a regra
existir; regra criada depois.

```
$ git check-ignore -q .env
  -> NAO reporta          🔴

$ git ls-files -i -c --exclude-standard
  -> .env
  -> .venv/pyvenv.cfg     ✅
```

### 🔴 Achado crítico

`git check-ignore` **ignora o índice** — ele consulta apenas as regras. Um
oráculo construído sobre `check-ignore` reportaria "tudo limpo" com um segredo
sentado no índice. É exatamente o falso-negativo que FR-020 foi escrito para
impedir, e é o erro que um oráculo escrito de memória cometeria.

**Decision**: FR-020 usa `git ls-files -i -c --exclude-standard`. `check-ignore`
fica restrito à verificação das **regras** (FR-008..FR-013), nunca do estado.
**Rationale**: são duas perguntas diferentes — "a regra existe?" e "o histórico
está limpo?". Só a segunda protege de fato.
**Alternatives rejected**: `check-ignore` isolado — falso-negativo demonstrado.

### Distinção adicional: índice vs. histórico

```
$ git log --all --pretty=format: --name-only --diff-filter=A | sort -u
  -> .env, .gitignore, legit.md, .venv/pyvenv.cfg
```

Violação no **índice** se corrige com um `rm --cached`. Violação no **histórico**
exige reescrita — incidente de segurança, severidade distinta.

**Decision**: o oráculo reporta as duas condições como asserções separadas, com
severidades distintas.

---

## E8 — Idempotência sobre repositório preexistente

### Experimento

```
$ git init -q -b main .            (sobre repo existente)
warning: re-init: ignored --initial-branch=main
HEAD preservado ✅
```

### Achado

A reinicialização é **não-destrutiva** — nenhum histórico se perde. Porém o
`-b main` é **silenciosamente ignorado**. Um plano que confie em `-b` para
garantir FR-001 falharia sem aviso num diretório que já contivesse um
repositório em `master`.

**Decision**: o passo de fundação **detecta** a presença de repositório antes de
agir. Ausente → cria com `-b main`. Presente → verifica o nome da linha
principal e renomeia se necessário, em vez de reinicializar.
**Rationale**: cobre o edge case "diretório já contém repositório" da spec sem
depender de um parâmetro que o git descarta em silêncio.
**Alternatives rejected**: `git init -b main` incondicional — falha silenciosa
demonstrada.

---

## E10 — Validação de convenção de registro com stdlib

### Experimento

```
^(feat|fix|docs|test|refactor|ci|chore|perf|build|style|revert)(\([a-z0-9][a-z0-9._-]*\))?(!)?: .+

✅ aceita  | feat(core): adiciona parser de constitution
✅ aceita  | chore: bootstrap do repositorio
✅ aceita  | feat(cli)!: remove flag --legacy
✅ aceita  | build(deps): pina uv 0.12.7
✅ rejeita | Adiciona coisas
✅ rejeita | feature: tipo invalido
✅ rejeita | fix:sem espaco
✅ rejeita | FIX: maiusculo

8/8 conforme
```

**Decision**: validação por expressão regular na stdlib do Python 3.12; os 11
tipos da decisão Q1 embutidos no padrão.
**Rationale**: satisfaz FR-019 (sem dependências) e SC-002 (100% classificável).
Cobre escopo opcional e a marcação `!` de incompatibilidade (FR-005).
**Alternatives rejected**: `commitlint` — exige Node e instalação, viola FR-019
neste ponto do bootstrap. Fica como opção do item 008.

---

## Estado da governança no momento do planejamento

```
$ grep -cE '\[[A-Z_0-9]+\]' .specify/memory/constitution.md
18 placeholders não substituídos
```

**Achado**: `.specify/memory/constitution.md` continua sendo o modelo em branco.
Não há princípios ratificados contra os quais avaliar o portão constitucional.

**Decision**: os princípios normativos vigentes para este item são os expressos
em `docs/plan/implementation_plan.md` e `docs/plan/addendum_v3.md`. A convenção
de registro e de nomes de linha de trabalho será documentada em `CONTRIBUTING.md`
na raiz, que é o local convencional e independente da ferramenta de
especificação.
**Rationale**: `AGENTS.md` e a constitution ratificada são o item **002**, o
próximo da fila. Antecipá-los aqui inverteria a ordem acordada e criaria
conteúdo que o item 002 teria de reescrever. `CONTRIBUTING.md` já consta da
estrutura final prevista no §15 do plano.
**Alternatives rejected**: preencher a constitution agora — invade o escopo do
item 002. Documentar só na spec — a spec não é fonte normativa de processo
corrente, e desenvolvedores não a leem para saber como escrever um commit.

---

## Resumo das decisões

| # | Decisão | Fonte |
|---|---|---|
| D1 | Exclusão de ambiente: `.env` + `.env.*` + `!.env.example` | E1/E5 — corrige vazamento do template canônico |
| D2 | Excluir subdiretórios de `.fluksos-x/`, nunca o pai | E2 — evita armadilha de descida |
| D3 | Herdar template canônico; asserção positiva sobre a trava | E3/E6 — protege contra regressão futura |
| D4 | FR-020 via `git ls-files -i -c --exclude-standard` | E7 — `check-ignore` dá falso-negativo |
| D5 | Índice e histórico auditados como asserções separadas | E7 — severidades diferentes |
| D6 | Fundação detecta repo preexistente antes de agir | E8 — `-b` é descartado em silêncio no re-init |
| D7 | Convenção validada por regex na stdlib | E10 — 8/8 casos |
| D8 | Convenção normativa documentada em `CONTRIBUTING.md` | Governança — constitution é o item 002 |
| D9 | Artefatos de integração de agente versionados; configuração local de máquina excluída | **Governança — emenda pós-plano**, não experimento |

> **Sobre a origem de D9.** D1–D8 derivam dos experimentos E1–E10 desta pesquisa.
> D9 **não** tem experimento associado: é decisão de governança, tomada após a
> conclusão de `plan.md`, durante a varredura de cobertura descrita em
> `spec.md` › Clarifications. Está registrada aqui para que este documento
> permaneça o registro completo das decisões vinculantes do item — a assimetria
> de origem é deliberada e explícita, não uma lacuna.

**Nenhum `NEEDS CLARIFICATION` remanescente.**
