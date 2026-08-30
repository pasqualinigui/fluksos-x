# Harness de verificação — Fase 0

Oráculos de conformidade do bootstrap do motor. Cada item da Fase 0 contribui com
um script, e o harness completo é a execução de todos em sequência.

> Contrato de interface normativo:
> [`specs/001-git-branching-strategy/contracts/oracle-cli.md`](../../specs/001-git-branching-strategy/contracts/oracle-cli.md)
> Decisão que originou este mecanismo: [ADR-002](../../docs/plan/decisions.md)

---

## Por que existe

O plano define o harness como o oráculo determinístico do motor (§14), mas as
ferramentas que o comporiam — pytest, Ruff, MyPy, pip-audit — só chegam nos itens
`004` a `007`. Sem este mecanismo, os três primeiros itens do bootstrap seriam
verificados por julgamento humano, e "está pronto" voltaria a ser opinião.

A resposta precisa ser **binária, repetível e rastreável a um requisito**.

---

## Convenção

Um arquivo por item, nomeado pela posição na ordem de execução:

```
scripts/verify/
├── README.md                  # este arquivo
├── f0-001-foundation.sh       # item 001 (0.9) — git, exclusões, convenções
├── f0-002-constitution.sh     # item 002 (0.11) — governança, porta de entrada
├── f0-003-ci-minimo.sh        # item 003 (0.13) — CI mínimo — harness Fase 0 em runner limpo
├── f0-004-uv-workspace.sh     # item 004 (0.1) — UV workspace — base física (pyproject.toml + uv.lock + .venv + .python-version)
└── ...                        # até f0-016
```

## Contrato de interface

Todo oráculo obedece ao mesmo contrato:

| Aspecto | Regra |
|---|---|
| Invocação | `f0-NNN-<slug>.sh [--quiet] [--list]` |
| Saída `0` | Conforme — todas as asserções aprovadas |
| Saída `1` | Não conforme — ao menos uma violação |
| Saída `2` | Erro de uso |
| Formato | Uma linha por asserção: `<status> <REQ-ID> <descrição>` |
| `--quiet` | Só violações. Para agregação pelos itens seguintes |
| `--list` | Enumera identificadores sem executar. Para o item `004` promover a pytest |
| Raiz | Resolvida pela localização do próprio script, nunca pelo diretório corrente |
| Efeitos | Somente leitura. Escreve apenas em saída padrão e erro padrão |
| Determinismo | Duas execuções sobre o mesmo estado produzem saída idêntica |

## Três regras que não se quebram

**1. Um item nunca modifica o oráculo de um item anterior.**
Se um item invalida uma asserção anterior, isso é conflito de contrato entre
specs e sobe para decisão explícita — não para edição silenciosa. O oráculo do
item `001` deve continuar aprovando em `012`.

**2. Nenhum oráculo altera o estado que mede.**
Arquivos-isca criados para testar regras de exclusão são removidos via `trap`,
inclusive em interrupção. Um oráculo que modifica o que observa não é oráculo.

**3. Uma asserção reprovada não interrompe as demais.**
O operador precisa do quadro completo, não do primeiro erro. O script acumula
violações e reporta todas.

## Restrição de dependências por item

| Itens | Podem usar |
|---|---|
| `001`–`003` | shell, git, Python 3.12 **stdlib** apenas |
| `004`+ | acima, mais pytest |
| `005`+ | acima, mais Ruff |
| `006`+ | acima, mais MyPy |
| `007`+ | acima, mais pip-audit e Trivy |

Um oráculo que exija ferramenta ainda não instalada no seu ponto do bootstrap
está errado, ainda que funcione na máquina de quem o escreveu.

## Uso

```bash
# um item
scripts/verify/f0-001-foundation.sh

# harness completo, parando no primeiro item não conforme
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done

# enumerar asserções sem executar
scripts/verify/f0-001-foundation.sh --list
```

## O que cada oráculo verifica

| Oráculo | Asserções | Cobre |
|---|---|---|
| `f0-001-foundation.sh` | 30 | repositório e linhas de trabalho, convenções de registro, higiene do histórico (Lei Zero, duas camadas), estado do índice |
| `f0-002-constitution.sh` | 33 | governança ratificada (10 princípios com critério de violação e origem), porta de entrada e seu orçamento, ciclo canônico, obrigações herdadas do item 001, **integridade do oráculo anterior** |
| `f0-003-ci-minimo.sh` | 14 | CI mínimo — harness Fase 0 em runner limpo (`.github/workflows/ci.yml`), determinismo e fronteira |
| `f0-004-uv-workspace.sh` | 14 | UV workspace — base física (pyproject.toml + uv.lock + .venv + .python-version) |

### Integridade por resumo criptográfico (item 002, ADR-006)

A regra 1 acima — *um item nunca modifica o oráculo de um item anterior* — deixou
de ser acordo verificado por leitura de diff. A partir do item `002`, cada item
**fixa o resumo SHA-256** do oráculo anterior e o assere:

```
FR-021a  integridade  — o resumo de f0-001-foundation.sh bate com o valor fixado
FR-021b  aprovação    — f0-001-foundation.sh --quiet sai com 0
```

São duas perguntas distintas. Executar o oráculo anterior e obter `0` prova que
ele **aprova**, não que está **íntegro**: um item futuro poderia trocar uma
asserção real por uma tautologia e continuar saindo `0`. Nenhuma execução
detectaria.

**Divergência de resumo sobe para decisão explícita, nunca para atualização do
valor fixado.** Atualizar o número para fazer a asserção passar é a forma exata de
derrotá-la.

## Promoção a pytest (item 004)

O item `004` converte cada `f0-NNN-*.sh` em módulo de teste equivalente, um caso
por asserção. `--list` existe exatamente para isso: permite enumerar os casos sem
interpretar o código do script. Os scripts permanecem no repositório após a
promoção — continuam sendo a forma de verificar o bootstrap numa máquina onde as
dependências do projeto ainda não foram instaladas.
