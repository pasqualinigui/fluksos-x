# Contribuindo com o fluksos-x

Este documento é **normativo**. As convenções abaixo não são estilo — são
contrato de máquina: o registro de mudanças e o versionamento semântico do motor
são gerados automaticamente a partir do histórico, e o harness de verificação
reprova o que não as obedecer.

> Verificado por `scripts/verify/f0-001-foundation.sh` (asserções `FR-004` a
> `FR-007`). Origem das decisões:
> [`specs/001-git-branching-strategy/`](specs/001-git-branching-strategy/) ·
> [ADR-003](docs/plan/decisions.md)

---

## 1. Mensagens de commit

Baseadas em [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

### Gramática

```
<tipo>[(<escopo>)][!]: <descrição>

[corpo opcional]

[rodapé opcional]
```

Expressão que a define, usada pelo harness e validada sobre 8 casos no
experimento E10 da pesquisa:

```
^(feat|fix|docs|test|refactor|ci|chore|perf|build|style|revert)(\([a-z0-9][a-z0-9._-]*\))?(!)?: .+
```

### Os 11 tipos — conjunto fechado

| Tipo | Quando usar | Efeito no versionamento |
|---|---|---|
| `feat` | Nova funcionalidade | MINOR |
| `fix` | Correção de defeito | PATCH |
| `perf` | Melhoria de desempenho sem mudança de comportamento | PATCH |
| `refactor` | Reestruturação sem mudança de comportamento nem de desempenho | — |
| `docs` | Apenas documentação | — |
| `test` | Apenas testes | — |
| `build` | Sistema de build, dependências, lockfile | — |
| `ci` | Pipeline de integração contínua | — |
| `style` | Formatação que não altera semântica | — |
| `chore` | Manutenção que não se encaixa nas anteriores | — |
| `revert` | Reversão de um commit anterior | — |

> **Por que 11 e não 7.** O §18 do plano de implementação lista sete tipos. O
> conjunto canônico da convenção acrescenta `perf`, `build`, `style` e `revert`.
> Adotamos o superconjunto porque `perf` e `build` são necessários para a
> classificação automática de releases exigida pela Resposta 2 do addendum —
> sem eles, melhorias de desempenho e mudanças de dependência cairiam em `chore`
> e desapareceriam do registro de mudanças. Decisão Q1 da pesquisa.

### Escopo — opcional

Entre parênteses, após o tipo. Minúsculas, iniciando por letra ou dígito. Nomeia
o pacote ou a área afetada.

```
feat(core): adiciona parser de constitution
fix(indexer): corrige travessia de AST em arquivos vazios
build(deps): fixa uv em 0.12.7
```

Escopos usuais: `core`, `agents`, `indexer`, `memory`, `cli`, `observability`,
`guardian`, `deps`, `docker`, `harness`.

### Mudança incompatível

Marcada por `!` **antes** dos dois-pontos, e opcionalmente detalhada num rodapé
`BREAKING CHANGE:`. Qualquer uma das duas formas dispara MAJOR.

```
feat(cli)!: remove a flag --legacy

BREAKING CHANGE: `fkx init --legacy` foi substituído por `fkx init --analyze`.
Projetos que usavam a flag antiga precisam atualizar seus scripts.
```

### Regras adicionais

- Descrição no **imperativo presente**: "adiciona", não "adicionado" nem "adiciona-se".
- Sem ponto final na descrição.
- Primeira linha com no máximo 72 caracteres.
- Um commit, uma mudança lógica. Se a descrição precisa de "e", provavelmente são dois commits.

### Exemplos rejeitados pelo harness

| Mensagem | Motivo |
|---|---|
| `Adiciona coisas` | Sem tipo |
| `feature: novo comando` | `feature` não pertence ao conjunto fechado — o tipo é `feat` |
| `fix:sem espaco` | Falta o espaço após os dois-pontos |
| `FIX: maiusculo` | Tipos são minúsculos |

---

## 2. Linhas de trabalho

### Papéis

| Linha | Papel |
|---|---|
| `main` | Linha de integração única, estável e publicável. Recebe as linhas de funcionalidade por proposta de mudança, com os 10 checks obrigatórios verdes |
| `develop` | Espelho protegido de `main`. Existe porque o oráculo `f0-001` FR-002 exige a linha; é sincronizada a partir de `main` e não recebe `feature/*` diretamente |
| `feature/*` | Trabalho isolado. Deriva de `main` e retorna a `main` |
| `hotfix/*` | Correção urgente. Deriva de `main` e retorna a `main`, com `develop` re-sincronizada em seguida |

> Os papéis acima valem desde **ADR-032**, que fechou a pergunta deixada em
> aberto pela ADR-028: `develop` nunca foi linha de integração de nada (70
> commits atrás, 0 à frente), e a norma passou a declarar o que a prática faz.
> Reabertura prevista: segundo colaborador com escrita, ou necessidade de linha
> de estabilização para release.

### Nome de linha de funcionalidade

```
feature/f<fase>-<pacote>-<funcionalidade>
```

O nome precisa revelar **fase, pacote e propósito** sem consulta a outra fonte.

| Exemplo | Fase | Pacote | Propósito |
|---|---|---|---|
| `feature/f0-uv-workspace` | 0 | — (raiz) | Workspace UV do monorepo |
| `feature/f1-harness-engine` | 1 | harness | Motor do harness |
| `feature/f1-treesitter-indexer` | 1 | indexer | Indexação via Tree-sitter |
| `feature/f2-agent-architect` | 2 | agents | Agente Arquiteto |
| `feature/f3-memory-shadow` | 3 | memory | Shadow memory |
| `feature/f4-cli-commands` | 4 | cli | Comandos da CLI |

---

## 3. O que nunca entra no histórico

Lei Zero do motor. O `.gitignore` da raiz impede por categoria, e o harness
reprova qualquer regressão.

| Categoria | Exemplos |
|---|---|
| Segredos | `.env` e **todas** as variantes: `.env.local`, `.env.production`, `.env.staging` |
| Ambientes e bytecode | `.venv/`, `venv/`, `__pycache__/` |
| Caches de ferramentas | `.ruff_cache/`, `.mypy_cache/`, `.pytest_cache/`, `htmlcov/`, `.coverage` |
| Efêmeros do motor | `.fluksos-x/sessions/`, `.fluksos-x/reports/`, `.tmp/`, `*.lance/` |
| Configuração de máquina | `.claude/settings.local.json` |

### O que **precisa** entrar

| Arquivo | Motivo |
|---|---|
| `uv.lock` | Controle de cadeia de suprimentos — o lockfile fixa hashes. **Nunca** adicione `*.lock` ao `.gitignore` |
| `.env.example` | Modelo público, sem valores reais |
| `.claude/skills/` | Fixa o protocolo de especificação com que o motor foi construído |

> Estas duas listas são asserções positivas **e** negativas do harness. Um item
> futuro que quebre qualquer uma reprova imediatamente, com o requisito nomeado.

---

## 4. Antes de abrir uma contribuição

```bash
# harness completo da Fase 0
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done
```

Saída `0` é obrigatória. O harness não é sugestão: é o oráculo que substitui
julgamento por veredito.

A partir do item `004` acrescentam-se as ferramentas de qualidade
(`pytest`, `ruff`, `mypy`, `pip-audit`); até lá, o harness usa apenas
interpretador de shell, git e Python 3.12 stdlib — por design, porque as
ferramentas ainda não existem neste ponto do bootstrap.

---

## 5. Ciclo de desenvolvimento

Todo trabalho no motor segue o ciclo determinístico, sem atalho:

```
RESEARCH → SPECIFY → CLARIFY → PLAN → TASKS → ANALYZE → TESTS 🔴 → IMPLEMENT 🟢 → CONVERGE
```

> A etapa **CLARIFY** entrou no ciclo a partir do item `002`. Ela existe para
> fechar ambiguidade **antes** de o planejamento derivar tarefas dela: uma decisão
> tomada por omissão no plano já nasceu embutida em código, e desfazê-la custa o
> ciclo inteiro. Na sua estreia ela pegou um limiar de desempenho que havia sido
> inventado sem fonte — exatamente o tipo de defeito que passa despercebido por
> parecer preciso.

Regras que sustentam o ciclo:

1. **Spec precede código.** Se a lógica muda, a especificação muda antes.
2. **Teste antes da implementação.** O par de commits vermelho→verde é a prova
   auditável de que o teste veio primeiro. Não há como recuperá-la depois.
3. **Pesquisa é verificação, não memória.** Toda versão de dependência é
   conferida contra o registro oficial e a evidência fica em
   `docs/plan/research/`.
4. **O harness é o oráculo.** Sem saída `0`, não convergiu.
5. **A spec é insumo do planejamento, nunca sua saída.** Achado descoberto no
   plano volta à etapa de análise, que o formaliza. Um plano que corrige a spec
   sozinho faz o defeito desaparecer sem rastro, e a spec passa a concordar com o
   plano por construção.

> A partir do item `002` a governança em `.specify/memory/constitution.md` está
> ratificada: as etapas de planejamento e análise julgam contra ela, e violação de
> princípio é falha **crítica automática**.
