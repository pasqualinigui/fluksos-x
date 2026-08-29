# Phase 1 — Data Model: Fundação de Versionamento

**Feature**: `001-git-branching-strategy` · **Data**: 2026-08-29

Este item não possui persistência de aplicação. As entidades abaixo são as
**estruturas de estado do repositório** que o oráculo inspeciona e sobre as
quais as asserções são definidas.

---

## Entidade: Repositório

Raiz do versionamento do motor.

| Campo | Valor esperado | Requisito | Como é observado |
|---|---|---|---|
| `existe` | verdadeiro | FR-001 | presença de árvore de trabalho versionada na raiz |
| `linha_principal` | `main` | FR-001 | nome da linha apontada pela referência simbólica de cabeça |
| `autor.nome` | `Guilherme` | FR-003 | configuração de escopo **local** |
| `autor.email` | `pasqualini166@gmail.com` | FR-003 | configuração de escopo **local** |
| `config_global_intacta` | verdadeiro | FR-003 | escopo global não contém entradas escritas por este item |

**Invariantes**

- `linha_principal == "main"` independentemente da preferência global da máquina.
  Verificado em E8: o parâmetro de nomeação é **descartado em silêncio** ao
  reinicializar um repositório existente, portanto a checagem incide sobre o
  estado resultante, nunca sobre o comando emitido.
- A escrita de identidade ocorre exclusivamente em escopo local. O escopo global
  da máquina do mantenedor não é território do projeto.

**Transições de estado**

```
ausente ──criar com linha principal nomeada──▶ presente(main)
presente(master) ──renomear linha principal──▶ presente(main)
presente(main) ──sem ação──▶ presente(main)
```

A terceira transição garante idempotência: reexecutar a fundação sobre um estado
conforme não produz alteração.

---

## Entidade: Linha de trabalho (branch)

| Campo | Tipo | Restrição |
|---|---|---|
| `nome` | texto | ver categorias abaixo |
| `categoria` | enumeração | `estável` \| `integração` \| `funcionalidade` |
| `origem` | referência | linha da qual foi derivada |

**Categorias e regras**

| Categoria | Nome | Papel | Requisito |
|---|---|---|---|
| estável | `main` | estado publicável | FR-001, FR-007 |
| integração | `develop` | recebe linhas de funcionalidade | FR-002, FR-007 |
| funcionalidade | `feature/f<fase>-<pacote>-<funcionalidade>` | trabalho isolado | FR-006 |

**Invariantes**

- `develop` deriva de `main` e ambas existem após a fundação.
- Um nome de linha de funcionalidade revela fase, pacote e propósito sem consulta
  externa (SC-005).

**Exemplos conformes** (§18 do plano): `feature/f0-uv-workspace`,
`feature/f1-harness-engine`, `feature/f2-agent-architect`.

---

## Entidade: Registro (commit)

| Campo | Tipo | Restrição | Requisito |
|---|---|---|---|
| `tipo` | enumeração fechada | um dos 11 rótulos | FR-004 |
| `escopo` | texto, opcional | minúsculas, iniciando por letra ou dígito | FR-005 |
| `incompatível` | booleano | marcado por `!` após tipo/escopo | FR-005 |
| `descrição` | texto não vazio | segue `: ` após o cabeçalho | FR-005 |

**Conjunto fechado de tipos** (decisão Q1 — superconjunto dos 7 do §18 do plano;
`perf` e `build` exigidos pela classificação automática de releases do addendum R2):

```
feat   fix   docs   test   refactor   ci
chore  perf  build  style  revert
```

**Gramática do cabeçalho**

```
<tipo>[(<escopo>)][!]: <descrição>
```

**Regra de reconhecimento** (verificada em E10, 8/8 casos):

```
^(feat|fix|docs|test|refactor|ci|chore|perf|build|style|revert)(\([a-z0-9][a-z0-9._-]*\))?(!)?: .+
```

**Invariante**: 100% dos registros do histórico satisfazem a gramática (SC-002).
Sem isso a geração automática do registro de mudanças (addendum R2) é impossível.

---

## Entidade: Regra de exclusão

Declaração de que uma categoria de arquivo não pertence ao histórico.

| Categoria | Alcance | Requisito | Decisão |
|---|---|---|---|
| segredos e ambiente | `.env`, `.env.*` — exceto `.env.example` | FR-008, FR-009 | **D1** |
| ambientes virtuais e bytecode | herdado do template canônico | FR-010 | — |
| caches de ferramentas de qualidade | herdado do template canônico | FR-011 | — |
| efêmeros do motor | `.fluksos-x/sessions/`, `.fluksos-x/reports/`, `.tmp/`, `*.lance/` | FR-012 | **D2** |
| geridas por terceiros | não redeclaradas | FR-014 | — |
| configuração local de agente | `.claude/settings.local.json` | FR-023 | **D9** |

**Contraparte: regra de inclusão obrigatória**

| Alvo | Regra | Requisito | Decisão |
|---|---|---|---|
| trava de dependências | precisa ser comprovadamente versionável | FR-013 | **D3** |
| arquivo-modelo de ambiente | precisa ser comprovadamente versionável | FR-009 | **D1** |
| artefatos de integração de agente | precisam ser comprovadamente versionáveis | FR-023 | **D9** |

**Invariantes**

- Nenhuma regra de exclusão alcança a trava de dependências. Asserção
  **positiva**, não ausência de menção — protege contra um item futuro
  acrescentar um padrão amplo e desfazer o controle de cadeia de suprimentos em
  silêncio.
- Nenhum diretório-pai que contenha conteúdo versionável é excluído por inteiro.
  Verificado em E2: o git não desce em diretório excluído, então negar um filho
  de um pai excluído seria inoperante.

---

## Entidade: Violação

Unidade de reprovação emitida pelo oráculo.

| Campo | Tipo | Descrição |
|---|---|---|
| `requisito` | identificador | o `FR-0NN` violado — permite rastrear até a spec |
| `severidade` | enumeração | `crítica` \| `alta` \| `média` |
| `evidência` | texto | o que foi observado |

**Escala de severidade**

| Severidade | Critério | Exemplo |
|---|---|---|
| crítica | segredo alcançável a partir do histórico | arquivo de ambiente já registrado |
| alta | proteção estrutural ausente ou desfeita | trava de dependências capturada por exclusão |
| média | convenção ou documentação ausente | linha de integração inexistente |

**Distinção obrigatória** (D5): violação no **índice** se corrige removendo do
rastreamento; violação no **histórico** exige reescrita e constitui incidente.
São asserções separadas porque as respostas são diferentes.

---

## Entidade: Veredito

Resultado agregado de uma execução do oráculo.

| Campo | Tipo | Descrição |
|---|---|---|
| `conforme` | booleano | verdadeiro se nenhuma violação |
| `violações` | lista de Violação | vazia quando conforme |
| `código_saída` | inteiro | `0` conforme, `1` não conforme, `2` erro de uso |

**Invariante de determinismo** (SC-003): duas execuções consecutivas sobre o
mesmo estado produzem vereditos idênticos — mesmo código de saída, mesmas
violações, mesma ordem. Nenhuma asserção pode depender de horário, ordem de
leitura do sistema de arquivos ou identificador gerado.
