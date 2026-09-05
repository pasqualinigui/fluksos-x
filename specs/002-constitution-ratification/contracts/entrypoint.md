# Contract: Porta de Entrada Operacional para Agentes

**Feature**: `002-constitution-ratification` · **Data**: 2026-08-30
**Artefatos**: `AGENTS.md` e `CLAUDE.md`, ambos na raiz do repositório

Contrato consumido por **todo agente de codificação** que chegue ao repositório, e
pelos itens 003–012 sempre que precisarem acrescentar orientação operacional.

---

## 1. Divisão de papéis

| Artefato | Papel | Quem lê | Quando |
|---|---|---|---|
| `.specify/memory/constitution.md` | Fonte **normativa** — princípios completos, critérios de violação, rationale | as etapas de planejamento e análise | sob demanda, dentro do ciclo |
| `AGENTS.md` | Porta de entrada **operacional** — identidade, operação, ponteiros | qualquer agente de codificação | toda sessão |
| `CLAUDE.md` | Importa `AGENTS.md` e acrescenta o que é específico do agente construtor | o agente que constrói o motor | toda sessão |

**Regra de precedência:** em divergência, a governança prevalece sobre a porta de
entrada. `AGENTS.md` declara essa subordinação em seu próprio texto — sem isso, a
divergência só apareceria por acaso.

---

## 2. Estrutura de `AGENTS.md`

Seções obrigatórias. O formato aberto **não impõe esquema** (pesquisa de domínio
Q3) — é convenção de localização, não de estrutura. As seções abaixo são escolha
deste motor.

**Cabeçalhos em inglês, prosa em português** (ADR-010): `AGENTS.md` é o formato
aberto, lido por agentes de qualquer origem — a estrutura precisa ser universal, o
conteúdo é do mantenedor.

| Seção | Conteúdo | Requisito |
|---|---|---|
| `## Identity` | O que é o motor, em poucas linhas | FR-010 |
| `## How to operate` | Comandos reais para verificar, executar o harness, iniciar um ciclo | FR-010 |
| `## Canonical cycle` | A sequência normativa, **incluindo a clarificação** | FR-015 |
| `## Rules that do not bend` | As invariantes de curto alcance, por ponteiro | FR-010 |
| `## Where the sources are` | Ponteiros para governança, plano, decisões, contratos | FR-010 |
| `## Precedence` | A governança prevalece | invariante da spec |

**Proibições**

- MUST NOT reproduzir o texto integral dos princípios — remete à governança.
- MUST NOT reproduzir o plano de implementação — remete a `docs/plan/`.
- MUST NOT duplicar prosa com `CLAUDE.md`.

---

## 3. Estrutura de `CLAUDE.md`

```
@AGENTS.md
```

mais uma seção curta com o que é específico do agente construtor e **não** cabe no
formato aberto. Nada mais.

| Restrição | Valor | Origem |
|---|---|---|
| Diretiva de importação | linha exata `@AGENTS.md` | documentação do fornecedor (pesquisa Q4) |
| Tipo do arquivo | **arquivo regular** | C5 — link simbólico exige privilégio de administrador no Windows |
| Conteúdo próprio | apenas o específico do agente construtor | FR-012 |

---

## 4. Orçamento de tamanho

| Métrica | Limite | Requisito |
|---|---|---|
| `AGENTS.md` | ≤ 150 linhas | FR-014 / C6 |
| `AGENTS.md` + `CLAUDE.md` | ≤ 175 linhas | FR-014 |
| Limite documentado de degradação de adesão | 200 linhas | pesquisa Q5 |

**O orçamento incide sobre a soma.** Repartir conteúdo entre arquivos não alivia:
o importado é carregado no início da sessão junto com o importador. A margem de 25
linhas é o espaço reservado para o crescimento dos itens 003–012 — quem a consumir
inteira precisa promover texto a ponteiro, não abrir um terceiro arquivo.

Acima do limite, o efeito não é erro: é **queda de adesão do agente ao próprio
conteúdo**. Uma porta de entrada grande demais é pior que uma pequena demais,
porque continua parecendo que está funcionando.

---

## 5. Métrica de não duplicação

Duas linhas são duplicadas quando, após normalização — espaços colapsados, caixa
baixa —, são idênticas, têm ≥ 40 caracteres e não são cabeçalho, tabela, citação,
comentário nem conteúdo de bloco de código.

Interseção não vazia entre os dois arquivos reprova `FR-012`.

Calibração em quatro pares de documentos reais do repositório: **zero** falsos
positivos; controle positivo (arquivo contra si mesmo): 37 detecções
(research E5).

---

## 6. Contrato de extensão para os itens 003–012

1. Orientação operacional nova entra em `AGENTS.md`, dentro do orçamento.
2. Regra **normativa** nova não entra aqui: entra na governança, por emenda, e
   `AGENTS.md` ganha no máximo um ponteiro.
3. Nenhum item cria um terceiro arquivo de porta de entrada. O orçamento é global
   e um terceiro arquivo apenas o esconde.
