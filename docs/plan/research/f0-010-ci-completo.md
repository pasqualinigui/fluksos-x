# RESEARCH — F0/010 · CI completo + branch protection — portão servidor

> **Item do plano:** 0.14 (§17 Fase 0, Emenda 1) · **Ordem de execução:** 010/016 (ADR-011)
> **Data da verificação:** 2026-09-04 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Hierarquia de fontes:** P0 = registry/API + binário executado + arquivos do repo ·
> P1 = docs oficiais + GitHub releases · P2 = engenharia big-tech/padrões · P3 =
> comunidade (só com corroboração). Proibido como fonte única: sem data/autoria.
> **Insumo anterior:** Contratos 008→010 e 009→010 + ADR-009 (hook é conveniência;
> `--no-verify` se neutraliza no servidor) + ADR-015/016/017 + ADR-019 (quarentena
> de flake) + `docs/plan/implementation_plan.md` §17 Emenda 1 + `.github/workflows/ci.yml` (003).

Este item entrega **o portão**: workflow completo (harness + ruff + mypy + pytest +
pip-audit + gitleaks + cobertura + matriz Python + `uv sync --frozen` + validação
de mensagem) e branch protection com required checks que tornam `--no-verify`
inócuo. Não cria `packages/` (011/012), release (013), dependabot/renovate (014),
nem credencial alguma no repo (Lei Zero — sem token, sem API-autenticação a partir
do harness).

---

## Q1 — Required checks neutralizam `--no-verify`? Como configurar?

**Fonte (P1):** `https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches` — fetch 2026-09-04.

Sim, por construção documentada: com "Require status checks before merging",
toda mudança em branch protegida exige checks `successful|skipped|neutral` —
o commit local burlado **não tem como passar**: o merge trava até o runner
validar. Peças aplicáveis: checks obrigatórios (estritos = branch atualizada
antes do merge; frouxos = sem exigência) · "Do not allow bypassing" (aplica
até a admins — sem isso, o mantenedor-admin bypassa o próprio portão) ·
nomes de job **únicos entre workflows** (nomes repetidos = merge travado por
ambiguidade) · force-push/deleção bloqueados por padrão em branch protegida.

**Achado para o oráculo:** proteção é **config de servidor, não arquivo** — o
harness não pode asseri-la sem token (Lei Zero proíbe token no repo). Padrão
herdado de 003-T031: oráculo assere o lado versionável (jobs nomeados estáveis
no workflow + procedimento documentado) e o lado servidor vira cenário humano
(🧑) com checklist + evidência de verificação na convergência.

## Q2 — Branch protection clássica ou rulesets?

**Fonte (P1):** mesma página + `.../managing-rulesets/about-rulesets` (conversão
1-regra-por-vez; rulesets permitem múltiplas regras simultâneas) — fetch 2026-09-04.

Regra clássica cobre 100% da necessidade ADR-009 (checks + sem-bypass +
sem-force). Rulesets adicionam composição multi-regra sem benefício nesta escala
(1 mantenedor, 2 linhas principais). **Recomendação ao PLAN: regra clássica em
`main` + `develop`** (mesmas exigências); revisitar rulesets quando houver
múltiplos times/ambientes. Sem inventar granularidade.

## Q3 — Reviews obrigatórios com 1 mantenedor?

**Fonte (P1):** seção "Require pull request reviews" — reviews exigem aprovador
com write; sem outro humano, **trava o próprio mantenedor** (deadlock por
desenho) — fetch 2026-09-04.

**Recomendação ao CLARIFY: NÃO exigir reviews** (portão = checks, não pessoas);
reavaliar quando houver 2º colaborador com write. CODEOWNERS segue irrelevante
(ADR-009 lacuna 12, mesma conclusão).

## Q4 — `uv` no CI: setup-uv oficial, qual pin, precisa de setup-python?

**Fonte (P0/P1):** `https://api.github.com/repos/astral-sh/setup-uv/releases/latest`
→ **v10.0.1** (2026-08-14) + README oficial (uso `uses: astral-sh/setup-uv@<SHA> # v10.0.1`,
SHA `20cfd1bf945f4377ade1205e4dbc17946fc9a30d`; `enable-cache: auto`;
`uv run --frozen pytest`; matriz `python-version: [${{ matrix }}]`; FAQ: setup-python
opcional e ~1s mais rápido por imagem conter Pythons) — fetch 2026-09-04.

Decisões: `setup-uv` oficial (não script manual); pin por **SHA + comentário
de versão** (imutável; tag major é mutável — mesma doutrina do manifest);
`uv sync --frozen` prova coerência do lock (lacuna 8 da ADR-009);
`enable-cache: auto`. Manter `setup-python` (imagem com Python = ~1s, e 003 já
o usa) OU delegar ao uv — **ao PLAN** (ambos determinísticos; não duplicar
instalação Python sem motivo).

## Q5 — Pins `actions/checkout` e `setup-python` da 003 ainda valem?

**Fonte (P0):** tags + latest: checkout **v7.0.1** (2026-07-20), setup-python
**v7.0.0** (2026-07-20); majors `v7` existem — fetch 2026-09-04.

Válidos. 003 usou majors (`@v7`) + versões em comentário — para 010, **elevar a
SHA + comentário** (padrão setup-uv acima). Efeito colateral honesto: tamper de
tag major (ataque real de supply chain) deixa de ser ameaça silenciosa.

## Q6 — Matriz Python: quais versões?

**Fonte:** `pyproject.toml` `requires-python >=3.12,<3.14` (repo, P0) + matriz
oficial setup-uv (P1) — fetch 2026-09-04.

**`["3.12", "3.13"]`** — exatamente o intervalo declarado, sem inventar 3.11
(fora do requires) nem 3.14 (fora do teto). Runner `ubuntu-24.04` (003, fixo,
nunca `latest`).

## Q7 — Portão de cobertura: ferramenta e limiar?

**Fonte (P0):** `https://pypi.org/pypi/pytest-cov/json` → **7.1.0**; `pytest 9.1.1`
+ 15 passed locais — fetch 2026-09-04. Limiar: **sem fonte externa aplicável**
(número de projeto, não de upstream) — vai a CLARIFY com recomendação:
`--fail-under` inicial **baixo e honesto** (medir cobertura real primeiro,
fixar limiar ≤ medido; elevar depois — mesma doutrina "medir, nunca inventar"
de SC-006/009). Cobertura hoje é relatório; a 010 a transforma em portão
(lacuna 7 da ADR-009).

## Q8 — Validação de mensagem de commit: qual ferramenta?

**Fonte (P0):** tags `conventional-changelog/commitlint` → **v21.2.2** — fetch
2026-09-04. Papel: `semantic-release` (013) **depende** de Conventional Commits;
mensagem malformada quebra versionamento em silêncio (lacuna 5 da ADR-009).

**Recomendação ao PLAN:** job `commitlint` no workflow validando o intervalo do
push/PR (config `commitlint.config.js` versionada ou preset + regras locais).
Gramática do repo (CONTRIBUTING, 11 tipos) é superconjunto do conventional —
o preset deve aceitar os 11 tipos ou a validação reprovaria histórico conforme
(SC-002/001!). **Armadilha nomeada**: validar só conventional estrito quebra
`perf/build/style/revert` — passar a lista de tipos como config versionada.

## Q9 — gitleaks: pin, modo, baseline?

**Fonte (P0):** `https://api.github.com/repos/gitleaks/gitleaks/releases/latest`
→ **v8.30.1** (2026-03-21, estável) — fetch 2026-09-04. Repo tem
`.gitleaksignore`? **Não** (só docs; `ls` raiz não mostra — verificar no PLAN:
se ausente, criar vazio documentado ou omitir; gitleaks oficial usa
`.gitleaks.toml` + `GITLEAKS_LICENSE`? não — OSS sem licença).

Modo: `gitleaks detect --source . -v` via action dedicada
`gitleaks/gitleaks-action v3.0.0` (SHA `e0c47f4f8be36e29cdc102c57e68cb5cbf0e8d1e`,
verificada via API 2026-09-04 na remediação ANALYZE M1). Baseline:
histórico já auditado (001 FR-020b); job falha em segredo novo.

## Q10 — Trivy + pip-audit no CI; flake-quarentena (ADR-019)?

**Fonte (P0/P1):** action repo correto é **`aquasecurity/trivy-action`**
(`aquasec/trivy-action` dá **404** — armadilha de org registrada) tags →
**v0.36.0**; imagem Docker `aquasec/trivy` (Docker Hub, 008 inalterado);
runners `ubuntu-24.04` têm Docker (Trivy pleno, fecha B2 da auditoria) —
fetch 2026-09-04.

Quarentena ADR-019 no workflow: `timeout-minutes` por job (teto explícito em
vez de EPOCHSECONDS sob carga) + `retry`? Actions não tem retry nativo de step
confiável — política honesta: timeout + falha visível + re-run manual; **sem**
`continue-on-error` (003-FR-011 proíbe mascarar) e **sem** `retry` que
transforme vermelho real em verde eventual. Runner dimensionado =
`ubuntu-24.04` padrão; dimensionamento além disso é observação, não ação.

## Decisões (insumo ao SPECIFY/CLARIFY — nada aqui é norma)

- **D1.** Checks obrigatórios estritos? Recomendado **frouxo** (menos builds; repo de 1 mantenedor) + sem-bypass inclusive admin — CLARIFY confirma.
- **D2.** Proteção clássica em `main`+`develop`, sem reviews obrigatórios (Q2/Q3).
- **D3.** `setup-uv@v10.0.1` por SHA + `uv sync --frozen` + cache auto (Q4).
- **D4.** Actions por SHA + comentário (Q5); runner fixo `ubuntu-24.04`.
- **D5.** Matriz `["3.12","3.13"]` (Q6).
- **D6.** `pytest-cov 7.1.0` + `--fail-under` medido-primeiro (Q7 → CLARIFY o número).
- **D7.** `commitlint v21.2.2` com os 11 tipos do repo (Q8).
- **D8.** `gitleaks v8.30.1` modo `detect` (Q9).
- **D9.** `trivy-action v0.36.0` (`aquasecurity/`, não `aquasec/`) + `pip-audit` job (Q10).
- **D10.** Quarentena: `timeout-minutes` explícito, sem `continue-on-error`, sem retry mascarador (Q10/ADR-019).

## Declaração de impacto de fronteira (insumo ao PLAN — ADR-017)

009 não declara fronteira sobre `.github/` (FR-009: CI intocado **pela 009**);
a 010 é a **dona designada** do diretório (Emenda 1). Impacto esperado: estender
`.github/workflows/ci.yml` (003) para workflow completo — edição do artefato
da 003, não do seu oráculo (`f0-003` continua verde: glob inclui novos jobs
sem mudar de forma? **verificar no PLAN**: se o workflow mudar de forma que
FRs da 003 reprovem — ex.: job `verify` renomeado — é conflito e sobe para ADR
prévia; renomear job é proibido sem ela, pois quebraria required checks
nominais). Nenhum oráculo 001–009 é tocado pela 010 salvo via ADR prévia.

## Out of Scope (Escada)

`packages/` (011/012) · release/semantic-release (013) · dependabot/renovate
(014) · gitleaks *baseline histórica* além do detect (histórico já auditado) ·
tokens/credenciais em qualquer arquivo (Lei Zero) · self-hosted runners ·
merge queue · CODEOWNERS · ambientes `dev`/`staging` reais.
