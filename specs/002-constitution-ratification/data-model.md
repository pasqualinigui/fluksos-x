# Phase 1 — Data Model: Governança e Porta de Entrada

**Feature**: `002-constitution-ratification` · **Data**: 2026-08-30

Este item não possui persistência de aplicação. As entidades abaixo são as
**estruturas normativas** que o oráculo inspeciona e sobre as quais as asserções
de `contracts/oracle-cli.md` são definidas.

A entidade central é o **Princípio**. Sua invariante governa onze ciclos: um
princípio sem critério de violação observável não é ratificável, porque a partir
da ratificação toda violação passa a ser falha crítica automática — e um critério
subjetivo transforma esse mecanismo em gerador de falso positivo com aparência de
autoridade.

---

## Entidade: Princípio

| Campo | Regra | Requisito | Como é observado |
|---|---|---|---|
| `numeral` | Romano, contínuo de `I` a `X`, sem lacuna | FR-004 | sequência dos cabeçalhos de princípio |
| `nome` | Frase nominal curta, única no conjunto | FR-004 | texto do cabeçalho |
| `enunciado` | Declarativo, com ao menos um `MUST` ou `MUST NOT` | FR-005 | presença do verbo normativo no corpo |
| `criterio_de_violacao` | Frase que descreve um **estado observável de artefato** | FR-005 | rótulo `Violação:` presente e não vazio |
| `origem` | Referência a fonte que sobrevive à remoção do material transitório | FR-006 | rótulo `Origem:` presente e não vazio |

**Invariantes**

- `criterio_de_violacao` precisa ser respondível olhando um artefato concreto do
  repositório, sem consultar a intenção de quem escreveu o princípio. Este é o
  teste operacional de `FR-005`, e o roteiro que o aplica está em `quickstart.md`.
- `origem` **transcreve** o trecho quando a fonte é o material transitório. Um
  ponteiro para `docs/AGENTS-EXAMPLE.md` seria uma referência morta no instante
  seguinte à execução de `FR-019`.
- Um princípio que falhe a invariante do critério **não é ratificado como
  princípio**: é rebaixado a orientação não normativa em seção separada
  (edge case da spec). Rebaixar é uma saída válida; ratificar o indecidível não é.

### Instâncias ratificadas

Os dez princípios abaixo são o conteúdo normativo fixado por este plano. As áreas
vêm de `FR-004`; os enunciados e critérios são a contribuição deste desenho.

| № | Nome | Enunciado (forma normativa) | Violação (estado observável) | Origem |
|---|---|---|---|---|
| **I** | Determinismo sobre probabilidade | Toda decisão expressável como regra MUST ser implementada como código determinístico. Julgamento probabilístico MUST ficar restrito ao roteamento entre regras, nunca à regra em si | Existe decisão de negócio ou de conformidade cujo resultado depende da saída de um modelo, sem regra determinística equivalente que a valide | plano §1; material transitório L3 e L41 (*"LLMs are probabilistic, whereas most business logic is deterministic"*) |
| **II** | Especificação precede código | Nenhum artefato executável MUST ser criado ou alterado antes de existir especificação aprovada que o descreva. Se a lógica muda, a especificação muda **antes** | Existe registro que altera artefato executável sem especificação correspondente, ou cuja especificação foi registrada depois | material transitório L47 (*Golden Rule*); plano §17 (SDD) |
| **III** | Teste antes da implementação | Todo requisito MUST possuir verificação executável que reprove antes da implementação e aprove depois. Ambas as execuções MUST ser preservadas como evidência versionada | Não existe par de evidências vermelho→verde para o requisito, ou o registro do verde precede o do vermelho | plano §17 (TDD); ADR-002 |
| **IV** | Definição de dados antes da implementação | Antes de implementar um componente, o formato dos seus dados de entrada e de saída MUST estar declarado em artefato de modelo de dados versionado | Existe componente cujo contrato de entrada/saída não é encontrável em `data-model.md` ou `contracts/` da sua especificação | material transitório L26 e L80–86 (*Data-First Rule*) |
| **V** | Segurança é a Lei Zero | Segredo MUST NOT existir em código, log, mensagem de registro ou histórico. A regra de exclusão MUST preceder a possibilidade de registro. Travas de dependência MUST permanecer versionadas | Arquivo de categoria proibida consta do índice ou do histórico; ou regra de exclusão cobre a trava de dependências | addendum §9 (Lei Zero); item 001, FR-008..FR-013 |
| **VI** | O harness é o oráculo | Conformidade MUST ser decidida por código de saída de verificação executável, nunca por julgamento. Nenhum item MUST modificar a verificação de um item anterior | Existe critério de aceitação sem asserção correspondente no harness; ou o diff de um item altera o oráculo de outro | plano §14; ADR-002 |
| **VII** | Auto-reparo atualiza a documentação | Ao corrigir uma falha, o ciclo MUST registrar a causa no artefato normativo correspondente, de modo que a mesma falha não possa repetir-se sem ser detectada | Existe correção de falha cujo registro não altera nenhum artefato normativo — especificação, contrato, decisão arquitetural ou harness | material transitório L88–95 (*Self-Annealing*, passo 4) |
| **VIII** | Elo verificado antes de lógica | Nenhuma lógica MUST ser construída sobre dependência externa cuja disponibilidade e contrato não tenham sido verificados por execução mínima registrada | Existe código que consome serviço, ferramenta ou versão externa sem evidência de verificação em `docs/plan/research/` | material transitório L32–35 (*Link / Handshake*); plano (*pesquisa é verificação, não memória*) |
| **IX** | Agnosticismo de stack | O motor MUST NOT assumir linguagem, framework ou ferramenta do sistema-alvo. Toda dependência de stack MUST estar isolada atrás de adaptador declarado | Existe, fora de adaptador declarado, referência a ferramenta específica do sistema-alvo | plano §1 e §6 (o motor desenvolve **qualquer** sistema) |
| **X** | Observabilidade | Toda execução do motor MUST produzir saída rastreável a um requisito identificado. Falha MUST nomear o requisito violado e a evidência observada | Existe caminho de falha que termina sem identificador de requisito ou sem evidência na saída | plano §14; contrato de interface do oráculo (item 001, §3) |

> **Quatro dos dez derivam do material transitório** — I (parcialmente), IV, VII e
> VIII. É a quitação de `FR-018`, e a razão de `origem` transcrever o trecho em vez
> de apontar para o arquivo. O registro consolidado dessa derivação vai para
> `docs/plan/decisions.md` (ADR-006), fora do alcance de qualquer remoção futura.

> **O que foi descartado do material transitório**, e por quê: as cinco fases
> B.L.A.S.T. e as três camadas A.N.T. são uma arquitetura de projeto de automação,
> não princípios de um motor; a persona *System Pilot* é identidade de agente, e
> este item ratifica governança, não identidade; a fase *Cloud Transfer* pressupõe
> destino em nuvem, o que colide com o princípio IX.

---

## Entidade: Governança

Conjunto ordenado de princípios mais as regras que os regem.

| Campo | Valor esperado | Requisito | Como é observado |
|---|---|---|---|
| `versao` | `1.0.0` — ratificação inaugural | FR-002 | linha de rodapé da governança |
| `data_ratificacao` | ISO `YYYY-MM-DD` | FR-003 | mesma linha |
| `data_ultima_emenda` | ISO, igual à ratificação nesta versão | FR-003 | mesma linha |
| `principios` | exatamente 10, numeração I–X | FR-004 | cabeçalhos de princípio |
| `campos_em_aberto` | zero | FR-001 | ausência de `[ALL_CAPS]` fora de comentário |
| `secao_restricoes` | presente | FR-007 | cabeçalho de seção |
| `secao_fluxo` | presente, declara o ciclo canônico com clarificação | FR-015 | cabeçalho + sequência do ciclo |
| `secao_governanca` | declara emenda, versionamento e revisão de conformidade | FR-007 | três subseções nomeadas |

**Transições de estado**

```
modelo em branco ──ratificação──▶ 1.0.0
1.0.0 ──esclarecimento sem mudança de regra──▶ 1.0.1
1.0.0 ──princípio acrescentado──▶ 1.1.0
1.0.0 ──princípio removido ou redefinido──▶ 2.0.0
```

A segunda execução da ratificação sobre conteúdo idêntico **não** produz versão
nova (edge case da spec): a versão acompanha mudança de conteúdo, não execução de
comando.

---

## Entidade: Registro de impacto

Sumário de uma ratificação ou emenda, embutido no topo da governança como
comentário, para viajar com o artefato que descreve.

| Campo | Requisito |
|---|---|
| `versao_anterior` | FR-008 — aqui: *modelo não ratificado* |
| `versao_nova` | FR-008 — `1.0.0` |
| `principios_acrescentados` | FR-008 — os dez, nomeados |
| `secoes_alteradas` | FR-008 |
| `pendencias_deferidas` | FR-008 — o que ficou fora e para qual item |

**Invariante:** ocorrência **única** no arquivo. Duas execuções da ratificação não
podem empilhar dois registros (edge case da spec).

---

## Entidade: Porta de entrada

| Campo | Valor esperado | Requisito |
|---|---|---|
| `local_convencional` | `AGENTS.md` na raiz | FR-009 |
| `arquivo_do_construtor` | `CLAUDE.md` na raiz, **arquivo regular** | FR-011, FR-013 |
| `diretiva_de_importacao` | `@AGENTS.md`, linha exata | FR-011 |
| `tamanho_agents` | ≤ 150 linhas | FR-014 |
| `tamanho_somado` | ≤ 175 linhas | FR-014 |
| `prosa_duplicada` | conjunto vazio | FR-012 |
| `reproducao_integral` | ausente — remete, não copia | FR-010 |

**Invariante do orçamento.** O limite documentado a partir do qual a adesão do
agente ao próprio conteúdo degrada é de 200 linhas, e **repartir em arquivos não
alivia**, porque o conteúdo importado é carregado junto. O orçamento incide sobre
a **soma**, com margem de 25 linhas para crescimento nos itens 003–012.

**Invariante de precedência.** Se a porta de entrada afirmar algo que a governança
contradiz, a governança prevalece. A porta de entrada declara essa subordinação em
seu próprio texto — caso contrário a divergência só apareceria por acaso
(edge case da spec).

---

## Entidade: Veredito de conformidade retroativa

Resultado da reavaliação de um artefato do item 001 contra a governança ratificada.

| Campo | Regra | Requisito |
|---|---|---|
| `artefato` | um dos **16** caminhos fixados (research D8) | FR-017, SC-007 |
| `principios_avaliados` | os que incidem sobre o artefato, nomeados | FR-017 |
| `veredito` | `conforme` \| `nao conforme` | FR-017 |
| `fundamentacao` | obrigatória quando `nao conforme` | FR-017 |

**Invariante de parada.** Qualquer `nao conforme` **interrompe o ciclo** e submete
a decisão ao mantenedor. O oráculo reprova e nomeia o par artefato×princípio.
Corrigir o artefato, emendar o princípio ou registrar exceção são as três saídas —
e nenhuma é aplicável automaticamente (`FR-017b`).

Este é o primeiro precedente de conflito entre governança e trabalho já entregue
no motor. A razão de ele não ter tratamento automático é que precedente
estabelecido por omissão vira jurisprudência sem ninguém ter decidido.
