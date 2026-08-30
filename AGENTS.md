# fluksos-x

## Identity

CLI `fkx`. Um motor que desenvolve software em vez de escrevê-lo sob demanda: as
decisões são regras determinísticas, e o julgamento probabilístico só roteia entre
elas. Serve qualquer stack, porque não assume nenhuma.

**Estado**: Fase 0 (bootstrap), item 002 de 012. As ferramentas de qualidade
chegam nos itens 004–009 — até lá, só shell, git e Python 3.12 stdlib.

## How to operate

```bash
# harness completo — o oráculo do projeto
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done

# um item isolado, com relatório legível
scripts/verify/f0-001-foundation.sh
scripts/verify/f0-002-constitution.sh

# enumerar asserções sem executar
scripts/verify/f0-002-constitution.sh --list
```

Saída `0` é obrigatória antes de qualquer entrega. Sem ela, não convergiu.

## Canonical cycle

```
RESEARCH → SPECIFY → CLARIFY → PLAN → TASKS → ANALYZE → TESTS 🔴 → IMPLEMENT 🟢 → CONVERGE
```

Cada etapa produz artefato versionado em `specs/<NNN>-<slug>/`. A etapa de
clarificação fecha ambiguidade **antes** de o planejamento derivar tarefas dela.

## Rules that do not bend

1. **Especificação antes de código.** Mudou a lógica, muda a especificação antes.
2. **Teste antes da implementação.** O par vermelho→verde vive em commits
   separados. É a única prova auditável, e não é recuperável depois.
3. **Pesquisa é verificação, não memória.** Toda versão e todo comportamento
   externo são conferidos contra a fonte, com a evidência em `docs/plan/research/`.
4. **O harness é o oráculo.** Conformidade é código de saída, não opinião.
5. **Um item nunca modifica o oráculo de um item anterior.** A integridade é
   asserida por resumo criptográfico (ADR-006); divergência sobe para decisão.
6. **Segredo nunca entra no histórico.** Lei Zero. A exclusão precede o registro.
7. **A especificação é insumo do planejamento, nunca sua saída.** Achado de plano
   volta à etapa de análise; um plano que corrige a spec apaga o próprio defeito.

## Environment

Nada roda em segundo plano. Docker é ligado sob demanda e desligado após uso;
`restart: always` é proibido. Nenhuma escrita em configuração de escopo global da
máquina — identidade de autoria vive em escopo local do repositório.

## Where the sources are

| Preciso de… | Vou a… |
|---|---|
| Os dez princípios, com critério de violação e origem | `.specify/memory/constitution.md` |
| Convenções de registro, linhas de trabalho e o que nunca entra | `CONTRIBUTING.md` |
| Plano geral das 5 fases e a estrutura final | `docs/plan/implementation_plan.md` |
| Por que uma decisão foi tomada | `docs/plan/decisions.md` (ADR-001..006) |
| Evidência de pesquisa por item | `docs/plan/research/f0-NNN-*.md` |
| Contrato de interface do harness | `specs/001-git-branching-strategy/contracts/oracle-cli.md` |
| Como o harness cresce pelos itens | `scripts/verify/README.md` |

## Precedence

A governança em `.specify/memory/constitution.md` **prevalece** sobre este
arquivo, sobre os planos e sobre a documentação de contribuição. Divergência entre
eles é defeito a corrigir, não ambiguidade a tolerar.

Este arquivo é porta de entrada operacional: remete às fontes normativas e não as
reproduz. Ele existe para ser lido inteiro em toda sessão — por isso é curto.
