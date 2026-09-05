# RESEARCH — F0/009 · Lefthook — orquestração pre-commit do harness

> **Item do plano:** 0.5 (§17 Fase 0) · **Ordem de execução:** 009/016 (ADR-011)
> **Data da verificação:** 2026-09-04 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Hierarquia de fontes (trava desta pesquisa):** P0 = registry API + binário
> executado + arquivos do repo · P1 = docs oficiais + GitHub releases · P2 =
> engenharia big-tech/padrões adotados · P3 = comunidade (só com corroboração
> P0/P1). Proibido como fonte única: conteúdo sem data, sem autoria verificável,
> SEO-farm. Cada Q/D abaixo cita `Fonte:` datada; a ANALYZE da 009 verificará
> cada citação contra esta tabela.
> **Insumo anterior:** `specs/008-pip-audit-trivy/spec.md` › Contratos (Transferido
> à 009) + `docs/plan/decisions.md` (ADR-009 hook-é-conveniência, ADR-011 mapa,
> ADR-015 padrão, ADR-017 pré-autorização de fronteira) + `scripts/verify/README.md`
> (restrição: 009 pode assumir shell+git+python+uv+pytest+ruff+mypy+pip-audit).

Este item entrega **o orquestrador local do harness**: `lefthook.yml` com `ruff` +
`mypy --strict` + `pytest` + `pip-audit` (+ `trivy fs` quando houver Docker). Não
cria `packages/` (011/012), não edita `.github/workflows/ci.yml` (o glob
`f0-*.sh` inclui `f0-009` sem edição — padrão FR-012 da 006), não instala ganchos
globais na máquina. Hook local é conveniência com feedback em segundos, não portão
(ADR-009): o portão vive no servidor (010).

---

## Q1 — Qual pin canônico: 2.1.11 (plano) ou 2.1.12 (latest)?

**Fonte (P0/P1):** `https://api.github.com/repos/evilmartians/lefthook/releases/tags/v2.1.11`
+ `.../releases/latest` + `https://pypi.org/pypi/lefthook/json` — HTTP 200, fetch 2026-09-04.

Evidências:

```
v2.1.11  published 2026-08-21T08:17:30Z  prerelease=false
  changelog: Go 1.26.6 (#1495) + PTY terminal-size inherit (#1498)
v2.1.12  published 2026-08-28T10:21:38Z  prerelease=false  ← latest estável
  changelog: npm CI fix (#1508) + LEFTHOOK_OUTPUT precedence (#1506)
             + FAIL HOOK WHEN STAGING FIXED FILES ERRORS (#1484)
PyPI lefthook: 2.1.12 (wrapper) · releases tail […, 2.1.9] (paginado; latest 2.1.12)
```

**Achado:** o pin do plano (2.1.11, congelado em 2026-08-29) nasceu defasado em
1 dia: a 2.1.12 já existia no freeze. A 2.1.12 contém **uma correção comportamental
relevante ao harness** (#1484: gancho falha quando `stage_fixed` erra — direção
fail-closed, alinhada aos princípios I/VI) e duas irrelevantes aqui (npm CI,
precedência de env de output).

**Recomendação ao CLARIFY (não decisão desta pesquisa):** adotar **2.1.12**,
registrando o desvio do plano na spec com este Q1 como evidência — OU manter
2.1.11 por fidelidade ao plano. Não há opção "pesquisar depois": o pin entra no
`lefthook.yml:min_version` + `uv.lock` e congela na 009.

## Q2 — Como instalar deterministicamente neste repo (UV)?

**Fonte (P1+P0):** `https://lefthook.dev/installation/` (métodos: Ruby/NPM/Go/
Python/Homebrew/Winget/Scoop/deb/rpm/Alpine/Arch/Snap/Devbox/Mise/Manual) +
`https://pypi.org/pypi/lefthook/json` + binário executado abaixo — fetch 2026-09-04.

Opções avaliadas:

| Método | Determinismo neste repo | Veredito |
|---|---|---|
| `uv add --dev lefthook==2.1.x` (wrapper PyPI) | **Alto**: pin exato + hash em `uv.lock` + `uv run lefthook` sem ativação; mesmo padrão de 005–008 | **Recomendado** |
| Binário GitHub manual (`lefthook_2.1.11_Linux_x86_64.gz`) | Médio: checksum verificável (`435aff51…`, conferido §Q3), mas fora do lock, por-OS, sem update path | Reserva / CI-free |
| `go install`, brew, npm | Baixo aqui: fora do toolchain UV; quebra a Escada e a fonte única | Rejeitado |

## Q3 — O binário oficial é íntegro e o que ele declara?

**Fonte (P0, executado em /tmp, fora do repo):** download `v2.1.11`
`lefthook_2.1.11_Linux_x86_64.gz` — sha256 `435aff51fc767a7f135717a4e3e4f3282c15e0a4ca4e2dfd1b54ef8241ee5f3f`
**idêntico** ao `lefthook_checksums.txt` oficial — fetch 2026-09-04.

```
$ ./lefthook-2.1.11 version  →  2.1.11
comandos: run · install · uninstall · check-install · dump · add ·
          validate · version · self-update · help
envs: LEFTHOOK · LEFTHOOK_CONFIG · LEFTHOOK_OUTPUT · LEFTHOOK_VERBOSE
`run --help`: --job/--tag/--command/--exclude/--file/--force/--all-files/
  --no-auto-install/--no-stage-fixed/--no-tty/--[no-]fail-on-changes/--files-from-stdin
`install --help`: [hook-names...] + --force/--reset-hooks-path
```

**Achado para o oráculo:** `validate` (checa config), `dump` (config merged),
`check-install` (ganchos instalados?) são os três comandos assertáveis
mecanicamente pela 009 — nenhum exige julgamento.

## Q4 — Schema da config (`lefthook.yml`)?

**Fonte (P1):** `https://lefthook.dev/configuration/` — fetch 2026-09-04.

Top-level: `min_version` · `output` · `source_dir`/`source_dir_local` ·
`extends` · `remotes` (+git_url/ref) · `no_auto_install` · `glob_matcher` ·
`skip`/`only` · hooks (`pre-commit`, `pre-push`, …). Por job/comando:
`run`/`script`/`runner` · `glob`/`files`/`file_types`/`tags` · `parallel` ·
`stage_fixed` · `fail_text` · `skip`/`only` · `priority` · `env`/`root`.
Formatos aceitos: `lefthook.yml|yaml` (recomendado: **`lefthook.yml`** na raiz —
é o que as fronteiras 004–008 nomeiam), `.config/` e TOML/JSON alternativas
**rejeitadas aqui** (uma forma, sem ambiguidade de descoberta).

**Achados:** (a) `min_version` torna o pin **declarativo e verificado pelo
próprio lefthook** — o oráculo asserir `min_version` + `lefthook version` fecha o
loop sem confiar no lock sozinho. (b) `remotes` (config remota) é **proibido
nesta spec** — fonte externa não fixada viola VIII/Lei-Zero-supply-chain; só
config local versionada. (c) `self-update` é **proibido no config e no uso** —
atualização fora do ciclo SPEC→PLAN→… seria mutação silenciosa de toolchain.

## Q5 — `stage_fixed` e corretores no hook: sim ou não?

**Fonte (P1+P2):** docs `stage_fixed`/`fail_on_changes` + changelog 2.1.12 #1484 —
fetch 2026-09-04.

`ruff --fix`/`format` reescrevem arquivos; com `stage_fixed: true` o hook
re-adiciona ao stage — e a 2.1.12 **falha o hook se esse re-stage errar** (#1484).
Regra determinística recomendada: corretores rodam com `stage_fixed: true` **e**
o oráculo da 009 testa o caminho de erro (ou a spec escolhe `fail_on_changes`
explícito). Decisão ao PLAN; o que é proibido é corretor silencioso sem modo de
falha declarado (violação X: falha que não nomeia evidência).

## Q6 — O que a 009 orquestra (ordem e comandos)?

**Fonte:** Contratos 008→009 + `--help` locais verificados em 005–008.

Jobs `pre-commit` (sequência fail-fast explícita, não paralela entre
verificadores — saída ordenada = determinismo FR-018): `ruff check` →
`ruff format --check` → `mypy --strict` → `pytest -q` → `pip-audit`
(+ `trivy fs` quando Docker presente, senão skip documentado como na 008-FR-009).
Comandos via `uv run` (nunca binário solto — Escada). `pre-push`: harness
`for f in scripts/verify/f0-*.sh` (espelha o CI, feedback local do portão real).

## Q7 — CI precisa mudar? Ganchos valem no servidor?

**Não e não** (P1 interno: ADR-009 + `f0-003` glob). O workflow executa o glob
`f0-*.sh` — `f0-009` entra sem editar `ci.yml` (asserção espelho da FR-012/006).
Ganchos são bypassáveis por `--no-verify` (flag do cliente git, fora do repo);
o portão real são required checks (010). A 009 **não** toca `.github/`.

## Q8 — .gitignore e resíduos: o que `lefthook install` escreve?

**Fonte (P0 repo + P1 docs):** `grep -i hook .gitignore` → vazio; `lefthook install`
escreve em `.git/hooks/` (fora do índice por construção) — fetch 2026-09-04.

Nada a excluir no `.gitignore` (ganchos vivem sob `.git/`, nunca versionados).
`lefthook-local.yml` (override pessoal) deve ser **excluído preventivamente** se o
config o mencionar — decisão ao PLAN; hoje o arquivo não existe e nenhuma regra o
cria. Lei Zero: nenhuma trava de dependência é tocada (`uv.lock` versionado,
regra permanente).

## Q9 — Determinismo de execução (tempo, paralelismo, saída)?

`--job/--tag` + `parallel` por grupo dão ordem controlada; `output` + `NO_COLOR`
estabilizam texto para comparação byte-a-byte (padrão FR-014/005). Teto de tempo
segue SC da spec (espelho <5s do oráculo, não dos jobs — jobs têm teto próprio a
definir no PLAN). `LEFTHOOK=0` desliga (escape documentado, não violação: o portão
é o CI).

## Q10 — Restrição de dependências da 009 e do seu oráculo

**Fonte:** `scripts/verify/README.md` (tabela: 008+ = shell+git+python+uv+pytest+
ruff+mypy+pip-audit+trivy). A 009 pode assumir **toda** a cadeia (é a última do
harness de qualidade) + `lefthook` via `uv run`. O oráculo `f0-009` usa
`validate`/`dump`/`check-install` + `grep` estrutural no `lefthook.yml` (nunca
executa os jobs — oráculo observa, não corrige; jobs executados seriam efeito
sobre o estado medido).

---

## Declaração de impacto de fronteira (insumo obrigatório ao PLAN — ADR-017)

Levantamento mecânico (`grep -n lefthook scripts/verify/f0-00*.sh`): ao aterrissar
`lefthook.yml` + `lefthook` em dev, estes oráculos **reprovarão sobre estado
correto** se não pré-autorizados:

| Oráculo | Asserção que dispara | Condição correta que ela proíbe |
|---|---|---|
| `f0-004` FR-012 (:385/:396/:402) | `lefthook` em pyproject/groups; loop `ruff.toml mypy.ini lefthook.yml` | `lefthook==2.1.x` em dev **com** `uv.lock` + `lefthook.yml` da 009 |
| `f0-005` FR-015 (:588) | `lefthook.yml` existe | idem |
| `f0-006` FR-014 (:432) | `lefthook.yml` existe ("deve ser 009") | idem |
| `f0-007` FR-014 (:465) | `lefthook.yml` existe ("deve ser 009") | idem |
| `f0-008` FR-013 (:492) | `lefthook.yml` existe ("deve ser 009") | idem |

Procedimento ADR-017 (antes de qualquer merge): PLAN da 009 declara esta tabela +
ADR prévia autoriza o ajuste nos 5 pontos (padrão `0e7b077`: legitimidade via
`uv.lock`, nunca nome estático). **Pós-fix silencioso com regeneração de manifest
está proibido** — foi o achado A1 da auditoria `f0-audit-005-008`.

## Decisões (insumo ao SPECIFY/CLARIFY — nada aqui é norma)

- **D1.** Pin: 2.1.12 (recomendado, Q1) vs 2.1.11 (plano) — CLARIFY com mantenedor.
- **D2.** Instalação: wrapper PyPI `uv add --dev lefthook==2.1.x` (recomendado, Q2).
- **D3.** Formato/nome: `lefthook.yml` raiz, YAML (Q4).
- **D4.** `min_version` = pin (Q4) + `self-update` e `remotes` proibidos (Q4).
- **D5.** Corretores com modo de falha declarado (Q5).
- **D6.** Ordem fail-fast + `uv run`, `pre-push` espelha harness (Q6).
- **D7.** CI intocado; sem required-checks nesta spec (Q7 → 010).
- **D8.** `lefthook-local.yml`: excluir preventivamente ou omitir (Q8 → PLAN).
- **D9.** Oráculo observa via `validate`/`dump`/`check-install`, nunca executa jobs (Q10).
- **D10.** Tabela de fronteira acima vai ao PLAN + ADR prévia (ADR-017).

## Out of Scope (Escada)

`packages/` (011/012) · ganchos `pre-push` além do harness · `commitlint`/conventional-commit hook (validação de mensagem é 010) · `lefthook` no CI · qualquer escrita global na máquina · `remotes`.
