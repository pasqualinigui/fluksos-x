# RESEARCH — F0/013 · Emenda: `PYSEC-2026-2132` no teto transitivo do `click`

> **Item do plano:** 0.15 (§17 Fase 0, Emenda 1) · **Ordem de execução:** 013/016 (ADR-011)
> **Data da verificação:** 2026-09-07 · **Papel:** Pesquisador
> **Natureza:** emenda ao `f0-013-release-automation.md` (2026-09-06). Não substitui:
> acrescenta o que o advisory tornou verificável **depois** da convergência do item.
> **Método:** consulta direta a OSV, PyPI e ao disco, mais execução em réplica
> descartável fora do repositório. Nenhum dado por memória.
> **Hierarquia de fontes (ADR-025):** P0 = registry API + executado + arquivos do repo ·
> P1 = docs oficiais + advisory database · P2 = padrões estáveis · P3 = comunidade.
> **Insumo anterior:** `f0-013-release-automation.md` Q1 (que já registrou
> `click<8.5.0,~=8.1.0` e a entrada do `click` no `uv.lock`) + `specs/008-pip-audit-trivy`
> (o oráculo que reprova) + ADR-031, ADR-032.
> **Gatilho:** PR #16 com 3 dos 10 checks vermelhos (`audit`, `harness`, `verify`).

---

## O que a pesquisa anterior acertou, e o que não podia saber

A Q1 de 2026-09-06 registrou textualmente que `requires_dist` do PSR traz
`click<8.5.0,~=8.1.0` e que **"`click` real entra no `uv.lock` pela primeira vez"**.
O fato foi medido e anotado corretamente. O que não existia naquela data era o
advisory. Não há erro de método a corrigir aqui — há fato novo a incorporar.

---

## Q1 — O advisory existe, e qual é exatamente o seu alcance?

**Fonte (P0):** `https://api.osv.dev/v1/vulns/PYSEC-2026-2132` — fetch 2026-09-07.

```
ID        PYSEC-2026-2132
ALIASES   CVE-2026-7246, GHSA-47fr-3ffg-hgmw
DETAILS   Pallets Click, versions 8.3.2 and below, contain a command injection
          vulnerability in the click.edit() function, allowing attackers to pass
          arbitrary OS commands from an unprivileged account.
RANGES    introduced 0 → fixed 8.3.3
SEVERITY  CVSS:3.1/AV:L/AC:H/PR:H/UI:R/S:C/C:H/I:H/A:H
REFS      github.com/pallets/click/releases/tag/8.3.3
```

**Fonte (P0, disco):** a superfície vulnerável, lida no venv do projeto —
`.venv/.../click/_termui_impl.py:514` `class Editor`, método `edit_file`:

```python
c = subprocess.Popen(f'{editor} "{filename}"', env=environ, shell=True)
```

`shell=True` sobre f-string com `filename` interpolado. O vetor é `click.edit()`, e
nada além dele.

**Achado:** advisory legítimo, corrigido em **8.3.3**, vetor restrito a `click.edit()`.

---

## Q2 — Quem, no grafo, traz o `click` 8.1.8?

**Fonte (P0, `uv.lock`):** varredura de dependentes do pacote `click`.

```
python-semantic-release 10.6.2  → click
click-option-group      0.5.9   → click
```

**Fonte (P0, PyPI `requires_dist` do PSR 10.6.2):**

```
click~=8.1.0;              python_version == "3.8"
click~=8.1.0;              python_version == "3.9"
click<8.5.0,~=8.1.0;       python_version >= "3.10"
```

`~=8.1.0` é *compatible release* sobre três componentes: `>=8.1.0, ==8.1.*` — ou
seja, `<8.2.0`. A interseção com `<8.5.0` é `>=8.1.0,<8.2.0`. O teto é **do PSR**,
não do projeto, e é ele que prende a resolução em 8.1.8.

**Achado:** o `click` entra **exclusivamente** pela cadeia do PSR, grupo `dev`.

---

## Q3 — O `click` viaja no artefato publicado? (a pergunta que decide a gravidade)

Duas verificações independentes, porque a resposta muda a classe do problema.

**Fonte (P0, PyPI `requires_dist` do `typer` 0.27.2):**

```
shellingham>=1.3.0 · rich>=13.8.0 · annotated-doc>=0.0.2 · colorama; Windows
```

Sem `click`. O `typer` 0.27.2 **vendoriza** — confirmando a nota da Q3 da 012.

**Fonte (P0, disco):** o pacote vendorizado, `typer/_click/`:

```
_compat  core  decorators  exceptions  formatting  globals  parser
shell_completion  _termui_impl  termui  _textwrap  types  utils  _winconsole
```

```
grep -rn "edit" typer/_click/*.py   →  0 ocorrências
grep -rn "class Editor" typer/      →  0 ocorrências
```

O `typer` removeu o módulo do editor ao vendorizar. A superfície vulnerável **não
existe** na cópia que viaja.

**Achado:** `fkx-cli` **não** carrega `PYSEC-2026-2132`, por dois motivos
independentes — o `click` de topo é `dev` (não sai sob `--no-dev`, FR-001/005) e o
`click` vendorizado no `typer` não tem `edit()`. O impacto é sobre a **cadeia de
desenvolvimento**, não sobre o produto. O portão vermelho continua correto: o
`pip-audit` mede o ambiente resolvido, e nele a falha está presente.

---

## Q4 — Existe versão do PSR que resolva por atualização simples?

**Fonte (P0):** `https://pypi.org/pypi/python-semantic-release/json` → `info.version`
= **10.6.2**, upload `2026-08-28`. É a última publicada.

**Achado:** não há para onde subir. O teto `~=8.1.0` é o estado corrente do upstream.

---

## Q5 — O `pip-audit` 2.10.1 aceita supressão por configuração versionada?

**Fonte (P0, executada):** `uv run pip-audit --help`.

```
--ignore-vuln ID   ignore a specific vulnerability by its vulnerability ID;
                   this option can be used multiple times (default: [])
```

Nenhuma opção de arquivo de configuração. `--ignore-vuln` é **exclusivamente** de
linha de comando.

**Achado, e ele é decisivo:** suprimir exigiria editar `ci.yml`, `lefthook.yml` **e
`scripts/verify/f0-008-pip-audit.sh`**. O terceiro é o oráculo de um item anterior
— **Regra 5**. A via de supressão está vedada por governança, antes do mérito.

---

## Q6 — O PSR 10.6.2 funciona sobre `click` corrigido?

**Fonte (P0, executada):** réplica descartável fora do repositório, PSR instalado
por resolução normal e `click` substituído por `--no-deps`.

| `click` | `semantic-release --version` | `--noop version --print` (repo real) | `--noop changelog` |
|---|---|---|---|
| 8.1.8 *(base)* | `version 10.6.2` | exit 0 | exit 0 |
| 8.3.3 | `version 10.6.2` | — | — |
| 8.4.2 | `version 10.6.2` | exit 0, **saída byte-idêntica à base** | exit 0 |
| 8.5.0 | `version 10.6.2` | — | — |

O `click-option-group` 0.5.9, que é onde uma ruptura de API do `click` apareceria
primeiro, participa de todas as execuções: é ele que monta os grupos de opção do
`semantic-release`, exercitados no `--help` e no parse de `version`/`changelog`.

**Achado:** compatibilidade **medida**, não presumida. O teto do PSR é
conservador, não necessário — ao menos na superfície que este projeto usa.

---

## Q7 — O `uv` corrige a resolução, e a que custo?

**Fonte (P1, docs `uv`):** `constraint-dependencies` **restringe** dentro do que já
é declarado — não consegue violar `~=8.1.0`, e produziria conflito.
`override-dependencies` **substitui** a declaração do pacote a montante. É a única
das duas que resolve.

**Fonte (P0, executada):** cópia do repositório no scratchpad, com

```toml
[tool.uv]
override-dependencies = ["click>=8.3.3,<8.5.0"]
```

```
uv lock                          → Resolved 69 packages · Updated click v8.1.8 -> v8.4.2
                                   (nenhum outro pacote alterado)
uv sync --frozen --all-packages  → Checked 67 packages        ← a forma exata da CI
uv run pip-audit                 → No known vulnerabilities found
uv run ruff check .              → All checks passed!
uv run mypy --strict .           → no issues found in 18 source files
uv run fkx --version             → 0.1.0
scripts/verify/f0-008-pip-audit.sh → 15/16 CONFORME
```

O limite superior `<8.5.0` **preserva** o teto que o próprio PSR declara. O override
levanta somente a trava que carrega o CVE.

**Achado:** correção verificada de ponta a ponta, com diff mínimo (um pacote).

**Limite honesto:** `override-dependencies` é global e silencioso — vale para todo o
grafo e não avisa quando mascara um conflito futuro. Por isso a mitigação nasce com
especificador mínimo, **asserida literalmente** por oráculo (FR-017) e com condição
de saída transferida (ADR-034 §5).

---

## Q8 — Editar o oráculo do 013 quebra oráculo anterior?

**Fonte (P0, disco):** `f0-009` FR-014, `f0-010` FR-012, `f0-011` FR-011 e `f0-012`
FR-011 executam `sha256sum -c manifest.sha256` sobre o manifest **inteiro** — a 13ª
linha inclusive. As asserções de contagem são **piso** (`>=N`), não igualdade.

**Achado, e é restrição de sequenciamento, não observação:** alterar
`f0-013-release.sh` muda seu resumo. Se o commit **vermelho** não regenerar a 13ª
linha do manifest no mesmo ato, quatro oráculos anteriores reprovam junto — o que
seria regressão em item anterior (**Regra 5**) causada pelo próprio portão vermelho.
O commit 🔴 leva script **e** manifest; o vermelho fica restrito ao `FR-017`.

---

## Síntese das decisões

| # | Decisão | Fundada em |
|---|---|---|
| **E1** | `override-dependencies = ["click>=8.3.3,<8.5.0"]` no `[tool.uv]` | Q1, Q6, Q7 |
| **E2** | Supressão por `--ignore-vuln` **rejeitada** — vedada pela Regra 5 | Q5 |
| **E3** | Isolar o PSR fora do workspace **rejeitada** — resolve por invisibilidade | Q2, Q3 |
| **E4** | A emenda pertence ao **013**, não a spec nova — o override existe pelo PSR | Q2 |
| **E5** | Commit 🔴 leva script + 13ª linha do manifest, atomicamente | Q8 |
| **E6** | Condição de saída transferida ao **014** | Q4, Q7 |
| **E7** | `--no-verify` nos commits pré-verde; assimetria do `lefthook.yml` transferida ao **014** | Q9 |

---

## Q9 — Achado colateral: o portão local impede commitar a própria correção

**Fonte (P0, executada):** primeira tentativa de commit deste arquivo.

```
🥊 lefthook v2.1.12  hook: pre-commit
   pip-audit ❯ Found 1 known vulnerability in 1 package … exit status 1
```

O `lefthook.yml` roda `pip-audit` em `pre-commit`. Enquanto a vulnerabilidade
existe, **nenhum** commit passa — inclusive os commits de pesquisa, de spec e o
próprio portão vermelho que a Regra 2 exige antes do verde. O bloqueio é circular:
a única saída pelo hook seria inverter a ordem e commitar o verde primeiro, que é
exatamente o que a Regra 2 proíbe.

O `harness` e o `trivy` vivem em `pre-push`, não em `pre-commit` — foi por isso que
o portão vermelho original do 013 (`343bc82`) pôde ser commitado com o oráculo
reprovando. O `pip-audit` em `pre-commit` não tem essa folga.

**Achado (E7):** os commits anteriores ao verde vão com `--no-verify`, com os
demais portões (`ruff`, `ruff-format`, `mypy --strict`, `pytest`) executados à mão e
verdes, registrado em cada mensagem. Nada vinculante é contornado: os 10 checks
obrigatórios sem-bypass julgam o head final. **A assimetria é defeito de desenho do
`lefthook.yml`, não deste ciclo** — um gate de vulnerabilidade em `pre-commit`
converte "corrigir a vulnerabilidade" em operação impossível. Transferido ao
**014** junto com E6, que é o item que possui a política de dependências.
