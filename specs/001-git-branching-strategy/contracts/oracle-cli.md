# Contract: Oráculo de Conformidade da Fase 0

**Feature**: `001-git-branching-strategy` · **Data**: 2026-08-29
**Artefato**: `scripts/verify/f0-001-foundation.sh`

Este é o **contrato de interface** do harness do motor. Os itens 002–012 da Fase
0 acrescentam seus próprios oráculos seguindo exatamente esta interface, e o
item 007 (pytest) os promove a módulos de teste. Alterações neste contrato
afetam onze itens — trate-o como interface pública.

---

## 1. Invocação

```
scripts/verify/f0-001-foundation.sh [--quiet] [--list]
```

| Parâmetro | Efeito |
|---|---|
| *(nenhum)* | Executa todas as asserções e imprime relatório legível |
| `--quiet` | Suprime asserções aprovadas; imprime apenas violações. Para uso agregado pelos itens seguintes |
| `--list` | Lista os identificadores das asserções sem executá-las. Permite ao item 007 enumerar casos de teste sem interpretar o script |

Sem argumentos posicionais. Executável a partir de qualquer diretório de
trabalho: o script resolve a raiz do projeto a partir da própria localização,
nunca do diretório corrente — requisito de determinismo (SC-003).

---

## 2. Código de saída

| Código | Significado | Consumidor |
|---|---|---|
| `0` | Conforme — todas as asserções aprovadas | integração contínua, item 008 |
| `1` | Não conforme — ao menos uma violação | integração contínua, item 008 |
| `2` | Erro de uso — parâmetro inválido | operador humano |

O código de saída é a **única** interface obrigatória para máquinas (FR-016). A
saída em texto é para humanos e pode ser reformatada sem quebrar o contrato.

---

## 3. Formato da saída

Uma linha por asserção. Prefixo de status, identificador do requisito, descrição
e — quando reprovada — a evidência observada. O exemplo abaixo é ilustrativo; a
contagem autoritativa é a da tabela de asserções da seção 4.

```
✅ FR-001  linha principal e main
✅ FR-002  linha de integracao develop existe
🔴 FR-020  arquivo proibido ja rastreado
           evidencia: .env
              .venv/pyvenv.cfg

Resultado: 25/26 assercoes aprovadas — 1 violacao (critica: 1)
```

**Regras de formatação**

- Somente ASCII na estrutura; emoji restrito ao prefixo de status.
- Cada linha começa por `✅` (aprovada), `🔴` (reprovada) ou `⏭️` (não aplicável
  neste estágio do bootstrap).
- O identificador do requisito é sempre a segunda coluna, permitindo rastrear
  cada linha até a spec sem consultar o código.
- A linha de resultado é sempre a última e sempre presente.

---

## 4. Asserções

Numeradas pelo requisito funcional que verificam. `⏭️` marca as que ainda não
são aplicáveis neste estágio e serão ativadas por itens posteriores.

> Os sufixos `a`/`b` (por exemplo `FR-020a`, `FR-023b`) são **refinamento local
> deste contrato**: a spec define cada requisito sem decomposição, e aqui ele é
> quebrado nas asserções mecanicamente verificáveis que o compõem.

### Grupo A — Repositório e linhas de trabalho

| ID | Asserção | Severidade se reprovada |
|---|---|---|
| `FR-001` | Existe repositório na raiz e sua linha principal chama-se `main` | média |
| `FR-002` | Existe a linha de integração `develop` | média |
| `FR-003a` | Identidade de autoria definida em escopo **local** | média |
| `FR-003b` | Escopo global da máquina **não** foi alterado por este item | alta |

> `FR-021` é atendido por este grupo: na ausência de repositório, `FR-001`
> reprova com mensagem informativa em vez de erro abrupto.

### Grupo B — Convenções documentadas

| ID | Asserção | Severidade |
|---|---|---|
| `FR-004` | Documento de convenções declara os 11 tipos, todos presentes | média |
| `FR-005` | Documento declara o formato com escopo opcional e marcação de incompatibilidade | média |
| `FR-006` | Documento declara o formato de nome de linha de funcionalidade | média |
| `FR-007` | Documento declara o papel de `main` e de `develop` | média |

### Grupo C — Higiene do histórico (Lei Zero)

| ID | Asserção | Severidade |
|---|---|---|
| `FR-008a` | Arquivo de ambiente base é excluído | crítica |
| `FR-008b` | **Variantes** de arquivo de ambiente são excluídas — verificar ao menos `.local`, `.production`, `.staging` | crítica |
| `FR-009` | Arquivo-modelo de ambiente **permanece versionável** | alta |
| `FR-010` | Ambiente virtual e bytecode são excluídos | alta |
| `FR-011` | Caches das ferramentas dos itens 005–008 são excluídos | média |
| `FR-012` | Efêmeros do motor são excluídos, **e** o diretório-pai permanece versionável | alta |
| `FR-012b` | **As duas camadas concordam** — verificação hermética e verificação no repositório real produzem o mesmo veredito para cada regra | alta |
| `FR-013` | Trava de dependências **permanece versionável** — asserção positiva | alta |
| `FR-014` | Exclusões geridas pela ferramenta de especificação não são redeclaradas | média |
| `FR-023a` | Artefatos de integração de agente **permanecem versionáveis** — asserção positiva | alta |
| `FR-023b` | Configuração local de máquina do agente é excluída | alta |

> `FR-008b`, `FR-009` e `FR-013` são as asserções que a pesquisa empírica tornou
> obrigatórias. `FR-008b` corrige um vazamento presente no template canônico da
> indústria (E1/E5). `FR-013` protege contra regressão futura (E3/E6).

> **Duas camadas obrigatórias no Grupo C.** Cada regra é avaliada (1) num
> repositório descartável **hermético** — `GIT_CONFIG_GLOBAL` e
> `GIT_CONFIG_SYSTEM` neutralizados — respondendo *"o `.gitignore` do projeto,
> sozinho, está correto?"*; e (2) **no repositório real**, quando ele existe,
> respondendo *"o repositório está de fato protegido?"*. `FR-012b` reprova se as
> duas divergirem.
>
> A hermeticidade da camada 1 **não é opcional**: um repositório recém-criado
> herda `core.excludesFile` global por padrão, então um gitignore global da
> máquina excluindo `.env.local` faria `FR-008b` **aprovar com o `.gitignore` do
> projeto quebrado** — a mesma classe de falso-positivo que E7 demonstrou. Uma
> implementação sem hermeticidade está errada, ainda que aprove.

### Grupo D — Estado do histórico

| ID | Asserção | Severidade |
|---|---|---|
| `FR-015` | Existe registro inicial contendo o plano e a pesquisa | média |
| `FR-020a` | **Nenhum arquivo proibido consta do índice** | crítica |
| `FR-020b` | Nenhum arquivo proibido consta do histórico completo | crítica |
| `SC-002` | 100% dos registros satisfazem a gramática de convenção | média |

> **Mecanismo obrigatório de `FR-020a`**: listagem dos arquivos rastreados que
> casam com as regras de exclusão. Consultar as regras isoladamente produz
> **falso-negativo** — demonstrado em E7: a consulta às regras não enxerga o
> índice, e reportaria "limpo" com um segredo registrado. Uma implementação que
> use consulta às regras para esta asserção está errada, ainda que aprove.

> `FR-020b` audita o histórico completo. Distinta de `FR-020a` por severidade
> operacional: violação de índice se corrige removendo do rastreamento; violação
> de histórico exige reescrita e constitui incidente de segurança (D5).

### Grupo E — Meta

| ID | Asserção | Severidade |
|---|---|---|
| `FR-018` | Duas execuções consecutivas sobre o mesmo estado produzem saída idêntica | alta |
| `FR-019` | Nenhuma ferramenta além do interpretador de shell e do Python da máquina é invocada | alta |
| `FR-022` | Documento de decisões arquiteturais registra o mapa entre specs e itens do plano | média |

---

## 5. Restrições de implementação

| # | Restrição | Origem |
|---|---|---|
| 1 | Nenhuma dependência do projeto pode ser invocada. Apenas interpretador de shell, o versionador e Python 3.12 stdlib | FR-019 — as ferramentas chegam nos itens 005–009 |
| 2 | Nenhuma escrita fora de saída padrão e erro padrão. O oráculo **observa**, não corrige | determinismo — um oráculo que altera o estado que mede é inútil |
| 3 | Nenhuma saída dependente de horário, ordem de leitura do sistema de arquivos ou identificador gerado. Listas sempre ordenadas | FR-018, SC-003 |
| 4 | Raiz do projeto resolvida a partir da localização do próprio script | SC-003 — resultado não pode depender do diretório corrente |
| 5 | Uma asserção reprovada **não** interrompe as demais. Todas executam sempre | FR-017 — o operador precisa do quadro completo, não do primeiro erro |
| 6 | Arquivos-isca criados para teste de exclusão são removidos ao final, mesmo em caso de interrupção | restrição 2 — o oráculo não deixa resíduo |

---

## 6. Contrato de extensão para os itens 002–012

Cada item subsequente da Fase 0:

1. Acrescenta `scripts/verify/f0-NNN-<slug>.sh` seguindo **este mesmo contrato** —
   mesmos códigos de saída, mesmo formato de linha, mesmos parâmetros.
2. **Não modifica** os oráculos dos itens anteriores. Se um item invalida uma
   asserção anterior, isso é conflito de contrato entre specs e sobe para
   decisão, não para edição silenciosa.
3. Registra em `scripts/verify/README.md` o que passa a ser verificado.

O harness completo da Fase 0 é a execução de todos os oráculos em sequência,
conforme conjunto o `Verification Plan` do plano de implementação. O item 007
promove cada `f0-NNN-*.sh` a um módulo de teste equivalente; `--list` existe
para que essa promoção enumere os casos sem interpretar o script.
