# RESEARCH — F0/013 · Automação de release (semantic-release, PyPI OIDC, SBOM)

> **Item do plano:** 0.15 (§17 Fase 0, Emenda 1) · **Ordem de execução:** 013/016 (ADR-011)
> **Data da verificação:** 2026-09-06 · **Papel:** Pesquisador
> **Método:** consulta direta a registries, docs oficiais e ao disco, mais execução
> em réplica descartável fora do repositório. Nenhum dado por memória.
> **Hierarquia de fontes (ADR-025):** P0 = registry API + executado + arquivos do repo ·
> P1 = docs oficiais + GitHub releases · P2 = padrões estáveis · P3 = comunidade (só
> com corroboração P0/P1). Versão ou comportamento externo exige ≥2 fontes
> independentes incluindo P0.
> **Insumo anterior:** `specs/010-ci-completo/spec.md` › Contratos (mensagens validadas
> + pipeline verde como base para o `semantic-release`) + `specs/004-uv-workspace/spec.md`
> (`uv build`/`uv export` como capability de 013) + `specs/005-pytest/spec.md`
> (`--no-dev` no artefato) + `specs/008-pip-audit-trivy/spec.md` (D2/D4: `pylock.toml`
> e SBOM diferidos a 013) + `specs/011`/`012` (D1: runtime funcional porque *"013 não
> herdará correção"*) + ADR-009 (Emenda 1), ADR-011, ADR-015, ADR-017, ADR-025,
> ADR-027 §5, ADR-030, ADR-031, ADR-032.
> **Base:** harness 12/12 + manifest 12/12 verdes; `main` e `develop` com 10 checks
> obrigatórios sem-bypass; três pushes consecutivos verdes no runner após ADR-031.
> Diferente de todos os researches anteriores, este é o primeiro escrito com o
> portão servidor **determinístico** — a taxa de 25% de reprovação do self-check
> (ADR-031) teria contaminado qualquer medição feita aqui.

---

## Q1 — Pin canônico: `python-semantic-release`?

**Fonte (P0):** `https://pypi.org/pypi/python-semantic-release/json` → **10.6.2**,
`requires_python ~=3.8`, upload `2026-08-28T20:23:01` — fetch 2026-09-06.

**Fonte (P1, independente):** `https://api.github.com/repos/python-semantic-release/python-semantic-release/releases/latest`
→ `tag_name v10.6.2`, `published_at 2026-08-28T20:22:38Z`, `prerelease: false`.

**Fonte (P0, executada):** `uv run --with "python-semantic-release==10.6.2" -- semantic-release --version`
→ `semantic-release, version 10.6.2`.

**Achado:** pin **10.6.2**, triangulado P0+P1+P0-executado. `~=3.8` cobre a faixa
`>=3.12,<3.14` do projeto. `requires_dist` traz `click<8.5.0,~=8.1.0`,
`click-option-group~=0.5.0`, `gitpython~=3.0`, `requests~=2.25` — nota de cadeia:
**`click` real entra no `uv.lock`** pela primeira vez (typer 0.27.2 o vendoriza,
Q3 da 012). Como grupo `dev`, não viaja no artefato publicado (`--no-dev`, 005).

---

## Q2 — Superfície executada do `semantic-release`

**Fonte (P0, executada):** `semantic-release --help` → 4 comandos:
`changelog`, `generate-config`, `version`, `publish`.

**Fonte (P0, executada):** `semantic-release version --help` — o enunciado do
próprio comando declara o comportamento **padrão**:

> *"Write this new version to the project metadata locations · Create a new commit ·
> Tag this commit · **Push the new tag and commit to the remote** · Create a release
> (if supported) in the remote VCS"*

Flags de desligamento verificadas: `--no-commit`, `--no-tag`, `--no-changelog`,
`--no-push`, `--no-vcs-release`, `--skip-build`, e as de leitura pura `--print`,
`--print-tag`, `--print-last-released`.

**Achado:** o comando é, por padrão, um efeito colateral de escrita no remoto. As
flags de leitura pura existem e são o caminho compatível com portão (ver Q7).

---

## Q3 — Config padrão (o que o projeto herda sem declarar nada)

**Fonte (P0, executada):** `semantic-release generate-config --pyproject` em repositório
descartável (`/tmp/.../scratchpad/013/psr`, nunca neste repo):

| Chave | Padrão | Consequência para o fluksos-x |
|---|---|---|
| `commit_parser` | `"conventional"` | casa com commitlint da 010 (11 tipos) — o pré-requisito que a 010 transferiu está cumprido |
| `tag_format` | `"v{version}"` | `v0.2.0` |
| `branches.main.match` | `"(main\|master)"` | casa com a linha única da ADR-032 |
| `allow_zero_version` | `false` | **primeiro release saltaria para 1.0.0** |
| `major_on_zero` | `true` | em 0.x, `feat!` viraria 1.0.0 |
| `changelog_file` (default template) | `CHANGELOG.md` | arquivo novo na raiz |
| `dist_glob_patterns` | `["dist/*"]` | `dist/` já está no `.gitignore` |
| `upload_to_vcs_release` | `true` | anexa artefatos ao GitHub Release |
| `no_git_verify` | `false` | o commit do PSR roda ganchos locais (inerte no runner) |

**Fonte (P0, executada — introspecção do schema, mais forte que documentação):**
`RawConfig.model_fields` → `version_toml: Optional[Tuple[str, ...]]` e
`version_variables: Optional[Tuple[str, ...]]`.

**Achado:** `version_toml` é **tupla** — o PSR carimba a versão em **múltiplos**
arquivos. É o mecanismo que resolve o monorepo de dois pacotes (Q4). Os dois
padrões que **não** servem ao estado atual são `allow_zero_version = false` e
`major_on_zero = true`: sem alterá-los, o primeiro release publica **1.0.0** de um
motor com 12 de 16 itens da Fase 0 — decisão que pertence ao CLARIFY, não à
configuração acidental.

---

## Q4 — Dois pacotes publicáveis: como versionar?

**Fonte (P0, repo):** três `version = "0.1.0"` estáticos — raiz `fluksos-x`
(`[tool.uv] package = false`, **não publicável**), `packages/core` (`fkx-core`),
`packages/cli` (`fkx-cli`). Ambos com `requires-python >=3.12,<3.14` e backend
`hatchling`.

**Fonte (P0, executada — réplica do monorepo em `/tmp/.../scratchpad/013/mono`):**
com `version_toml` apontando aos três arquivos, `allow_zero_version = true`,
`major_on_zero = false`, e histórico `feat(core):` + `fix(cli):` sobre a tag `v0.1.0`:

```
semantic-release version --print       → 0.2.0
semantic-release version --print-tag   → v0.2.0
semantic-release version --no-push --no-vcs-release --skip-build
  → pyproject.toml                  version = "0.2.0"
  → packages/core/pyproject.toml    version = "0.2.0"
  → packages/cli/pyproject.toml     version = "0.2.0"
  → tag local v0.2.0 criada
  → CHANGELOG.md gerado, seções por tipo de Conventional Commit
```

**Achado:** versionamento **em lockstep** dos dois pacotes é executável e provado.
A alternativa — versões independentes por pacote — exigiria uma instância de PSR
por pacote com `tag_format` distinto (`core-v{version}`), o que multiplica tags,
CHANGELOGs e superfície de erro para dois pacotes que hoje são liberados juntos e
onde `fkx-cli` depende de `fkx-core` como membro do workspace. **Lockstep é a
recomendação; a escolha é do CLARIFY.**

---

## Q5 — Build e SBOM: o que o `uv` já entrega sem dependência nova?

**Fonte (P0, executada):** `uv --version` → **0.12.1** nesta máquina.
`uv export --help` → `--format` com valores `requirements.txt`, `pylock.toml`,
**`cyclonedx1.5`**.

**Fonte (P0, executada):** `uv export --format cyclonedx1.5 --all-packages -o …`
→ JSON com `bomFormat: CycloneDX`, `specVersion: 1.5`, **55 componentes**,
`metadata.tools = [{vendor: "Astral Software Inc.", name: "uv", version: "0.12.1"}]`.

**Fonte (P0, executada):** `uv build --all-packages -o …` → 4 artefatos
(`fkx_core`/`fkx_cli` × `sdist`+`wheel`), repositório permanece limpo.

**Fonte (P0):** `https://pypi.org/pypi/cyclonedx-bom/json` → **7.3.1**, upload
`2026-07-23`; triangulado com `https://api.github.com/repos/CycloneDX/cyclonedx-python/releases/latest`
→ `v7.3.1`.

**Achado que muda o desenho previsto:** a 008 (D4) e a 005 deixaram
`cyclonedx-bom 7.3.1` reservado para a 013 — mas **o `uv` já emite CycloneDX 1.5
nativamente**, a partir do `uv.lock`, que é a fonte de verdade da resolução. Adotar
`cyclonedx-bom` acrescentaria uma dependência (com `chardet`, `pip-requirements-parser`,
`cyclonedx-python-lib[validation]`) para produzir o que já se produz sem ela, e
introduziria uma **segunda** fonte para o mesmo fato — exatamente o que a 008/D2
rejeitou ao recusar `requirements.txt`. Recomendação: **SBOM via `uv export`**,
`cyclonedx-bom` descartado com este registro. Limite honesto: não comparei o
conteúdo dos dois SBOMs campo a campo; se o CLARIFY exigir campo específico
(ex.: `vulnerabilities`), a comparação é tarefa do PLAN.

---

## Q6 — Via de publicação: `uv publish` ou action da PyPA?

**Fonte (P0, executada):** `uv publish --help` → `--trusted-publishing
[automatic|always|never]`, `--dry-run`, `--check-url`, `--no-attestations`
(*"Do not upload attestations for the published files"*).

**Fonte (P0, executada):** `uv publish --dry-run "<dist>/*"` → verifica e lista os
4 artefatos, **sem credencial e sem publicar**. Elo verificado (princípio VIII).

**Fonte (P1):** docs uv › *Integration › GitHub Actions* — job de publicação com
`permissions: id-token: write`, `uv build` + `uv publish`, *"The workflow uses
Trusted Publishing, so no credentials need to be configured"*, e recomendação de
**separar build e publish em jobs distintos** para que a permissão elevada não
alcance o build.

**Fonte (P1, independente):** docs PyPI › *Trusted publishers › Using a publisher* —
`permissions: id-token: write` é *"mandatory for Trusted Publishing"*; sem ela
*"GitHub Actions will refuse to give you an OIDC token"*; permissão **no nível do
job** é *"strongly encouraged, as it reduces unnecessary credential exposure"*.

**Fonte (P1) — procedência, o ponto que decide:** docs PyPI ›
*Attestations › Producing attestations* nomeia quem produz atestado PEP 740:
**`pypa/gh-action-pypi-publish`** (*"attestations are generated and uploaded
automatically by default, with no additional configuration necessary"*),
`pypi-attestations`, `actions/attest` e `twine --attestations`. **`uv` não
consta da lista.**

**Fonte (P1, uv) — confirmação pelo lado oposto:** docs uv › *Publishing* —
*"uv publish does not currently generate attestations; attestations must be
created separately before publishing"*. O `uv publish` apenas **envia** arquivos
`[distribuição].publish.attestation` que já existam ao lado da distribuição.

**Fonte (P0, rastreador):** `astral-sh/uv` issues **#19489** *"Generate PEP 740
attestations"* e **#15618** *"uv publish: create attestations"* — ambas
**abertas** em 2026-09-06. Geração é pedido de funcionalidade, não comportamento.

**Fonte (P1):** README da `pypa/gh-action-pypi-publish` — sobe de `dist/` por
padrão; sob trusted publishing dispensa usuário e senha; exige
`id-token: write`; *"Generating signed digital attestations for all the
distribution files and uploading them all together is now on by default for all
projects using Trusted Publishing"*.

**Fonte (P0, executada — pin):** `v1.14.2` (release de 2026-07-29) é **tag
anotada**; o SHA do objeto de tag (`a892a5a6…`) **não** é pinável. Commit:
`dc37677b2e1c63e2034f94d8a5b11f265b73ba33`.

**Achado (corrigido — ver §Correção abaixo):** a construção fica com
`uv build --all-packages`; a **publicação** fica com a action oficial da PyPA,
porque ela é a única das duas que **produz** o atestado de procedência. O
argumento de "zero actions novas para pinar" não sobrevive à medição: o
repositório já pina **5** actions por SHA (`checkout`, `setup-python`,
`setup-uv`, `trivy-action`, `gitleaks-action`); a sexta é a oficial nomeada pela
documentação do próprio índice. Trocar procedência verificável por uma action a
menos é mau negócio para um projeto cuja tese é que conformidade se decide por
verificação, não por confiança.

### Correção de método (princípio VII — registra a causa, não só o conserto)

A primeira redação desta Q6 afirmava *"attestations PEP 740 são o padrão"* do
`uv publish`, e concluía que a action seria supérflua. A afirmação foi
**inferida da existência da flag `--no-attestations`** — nenhuma fonte foi
consultada sobre o comportamento. A flag descreve envio, não geração, e a
diferença era a única coisa que importava.

O defeito não foi de fonte errada: foi de **inferência apresentada como fato**
dentro de uma linha rotulada `Fonte (P0, executada)`. O rótulo dizia
"executada" porque o `--help` foi de fato executado; o que não foi executado nem
consultado foi a conclusão pendurada nele, entre parênteses.

Regra que este achado acrescenta ao método, para além deste item: **em linha de
`Fonte`, só entra o que a fonte diz.** Consequência derivada vai para `Achado`,
onde é visivelmente conclusão e não citação. Uma inferência dentro de uma
citação é indistinguível de evidência na releitura — que é exatamente como esta
passou pelo SPECIFY e pelo CLARIFY sem ser pega.

---

## Q7 — O conflito estrutural: o commit de versão versus a proteção de `main`

Esta é a pergunta que decide o desenho do item, e nasce do cruzamento de dois
fatos verificados.

**Fato 1 (P0, executada — Q2):** `semantic-release version` **commita, taggeia e
faz push** na linha de release por padrão.

**Fonte (P0, repo — evidência registrada):** `docs/plan/decisions.md` ADR-028,
adendo 2026-09-05: *"push direto em `main` recusado (`protected branch hook
declined`)"*, com `specs/010-ci-completo/branch-protection.md` como checklist.
A proteção vigente (verificada por API nesta sessão) tem 10 checks obrigatórios,
`enforce_admins: true`, sem atores de bypass.

**Fato 2 (P0, executada — API do servidor, 2026-09-06):**

```
GET /repos/pasqualinigui/fluksos-x/rulesets        → 0 rulesets
GET /repos/pasqualinigui/fluksos-x/tags/protection → 404 Not Found
```

**Achado — o eixo do desenho:** a proteção alcança **linhas** (`refs/heads/main`,
`refs/heads/develop`), **não tags**. Portanto:

- um release que precise **commitar** a versão em `main` colide com a proteção e
  só passaria abrindo bypass — o que contradiz a 010 FR-009 e a evidência do
  cenário 🧑 da ADR-028;
- um release **dirigido por tag** não colide com nada: a tag é empurrável, e o
  `release.yml` dispara em `on: push: tags:`.

Três desenhos possíveis, com o custo de cada um (a escolha é do CLARIFY):

| Desenho | Como a versão é fixada | Colide com a proteção? | Custo |
|---|---|---|---|
| **A — tag dirige, sem commit** | tag é a fonte; `pyproject` fica com versão dinâmica derivada do VCS | **não** | exige `hatch-vcs` (P0: **0.5.0**, `hatchling>=1.1.0` + `setuptools-scm>=8.2.0`) e torna `version` dinâmico nos dois pacotes |
| **B — PSR calcula, humano/PR aplica** | `semantic-release version --no-push` numa `feature/*`, entra em `main` por PR com os 10 checks | **não** | um PR por release; o release deixa de ser um clique |
| **C — PSR empurra direto** | padrão do PSR | **sim** | exigiria bypass na proteção — contradiz 010 FR-009 e ADR-028 |

**C está descartado por conflito com item convergido**, não por preferência. Entre
A e B: A tem menos passos mas troca a versão estática (hoje asserida como texto em
três arquivos) por resolução em tempo de build; B preserva o artefato legível e usa
o portão que já existe, ao custo de um PR. **Recomendação: B**, por coerência com
ADR-032 (linha única, tudo entra por PR verificado) e porque não introduz
dependência nova. Decisão do mantenedor no CLARIFY.

---

## Q8 — Configuração no lado do PyPI (o que não vive em arquivo)

**Fonte (P1):** docs PyPI › *Adding a publisher* — campos obrigatórios: **owner**,
**repository**, **nome do arquivo de workflow**. O **environment** é opcional, mas
*"strongly recommended: with a GitHub environment, you can apply additional
restrictions to your trusted workflow, such as requiring manual approval on each
run by a trusted subset of repository maintainers"*.

**Fonte (P1):** docs PyPI › *Creating a project through OIDC* — **pending publisher**:
projeto que ainda não existe no PyPI é criado no primeiro upload; o pending
publisher *"does not create a project or reserve a project's name until it is
actually used to publish"*, e **é invalidado se outra pessoa registrar o nome antes**.

**Fonte (P0, executada — 2026-09-06):** disponibilidade dos nomes no PyPI:

| Nome | HTTP | Estado |
|---|---|---|
| `fkx-core` | 404 | livre |
| `fkx-cli` | 404 | livre |
| `fluksos-x` | 404 | livre |
| `fkx` | 404 | livre |

**Achado:** são necessários **dois** pending publishers (um por pacote), cada um
nomeando o arquivo de workflow. Risco registrado, com data: os nomes estão livres
**hoje**; o pending publisher não os reserva. Entre esta pesquisa e o primeiro
publish existe uma janela em que um terceiro pode tomar o nome — fato de
plataforma, não hipótese. Cabe ao CLARIFY decidir se isso antecipa um release
`0.x` inaugural apenas para reservar os nomes.

**Limite honesto:** esta é a metade servidora do item, do mesmo tipo que a A1 da
auditoria 009–012 (que ficou 3 itens sem prova). Configuração de pending publisher
é **cenário humano (🧑)** com checklist versionado — precedente 003-T031/010. Não
existe forma de provar OIDC localmente: só o runner emite o token.

---

## Q9 — Pergunta-padrão de ambiente (obrigatória a partir da 013 — adendo ADR-027 §5/ADR-030)

> *"O que este item assume sobre o ambiente de execução, e onde está a prova
> executada dessa suposição?"*

| Suposição do item | Prova | Estado |
|---|---|---|
| `semantic-release` roda em repositório com remoto `origin` configurado | executada: sem remoto, até `version --print` aborta com `error: No such remote 'origin'` | **provada** (e é armadilha real: o runner faz checkout com `origin`, mas um clone raso/local não) |
| PSR precisa de token de VCS para criar release | executada: `WARNING Token value is missing!` em `--print`; o release em si exige `GH_TOKEN` | **provada parcialmente** — a criação do release só se prova no runner |
| Tags não são bloqueadas pela proteção | executada: 0 rulesets + 404 em `tags/protection` | **provada** |
| Commit direto em `main` é recusado | evidência registrada (ADR-028, `branch-protection.md`), **não** re-executada nesta sessão | **declarada, a re-provar na fase TESTS** |
| OIDC emite token no runner e o PyPI o aceita | — | **não provável localmente**; é o cenário 🧑 da Q8 |
| `uv build`/`uv export`/`uv publish --dry-run` funcionam na faixa 3.12–3.13 | executadas nesta máquina (3.12) | **provada em 3.12**; a matriz do CI cobre 3.13 |
| `uv` do runner tem `--format cyclonedx1.5` | local é `uv 0.12.1`; o runner instala via `astral-sh/setup-uv` pinada por SHA, **sem versão fixa de uv** | **lacuna**: a versão de `uv` no runner não é pinada — se o formato mudar de nome, o release quebra sem aviso. Insumo para o PLAN |

A última linha é um achado próprio desta pergunta: ela não teria aparecido sem a
obrigação da ADR-030. `setup-uv` sem `version:` resolve para a mais recente.

---

## Q10 — Fronteira: o que reprova hoje se os artefatos da 013 existirem?

**Fonte (P0, repo — varredura mecânica sobre os 12 oráculos, 2026-09-06):**

| Artefato da 013 | Asserção que incide | Veredito |
|---|---|---|
| `.github/workflows/release.yml` | **nenhuma** — nenhum oráculo enumera arquivos de workflow; todos referenciam `ci.yml` por caminho | livre |
| `permissions: id-token: write` no `release.yml` | `f0-003` FR-007 grepa **só** `$CI_YML`, e sua evidência já diz *"só em 013 trusted publishing"* | livre por desenho |
| `on: push: tags:` no `release.yml` | `f0-003` FR-008 grepa **só** `$CI_YML`; evidência diz *"deferido 013"* | livre por desenho |
| `CHANGELOG.md` na raiz | nenhuma menção em oráculo algum | livre |
| `python-semantic-release==10.6.2` em `dev` | asserções de `dev` são de **inclusão** (`assert "x==y" in dev`), nunca lista fechada | livre |
| `dist/`, `*.whl`, `*.tar.gz` | já excluídos pelo `.gitignore` (bloco *Distribution / packaging*) | livre |
| **`pylock.toml` versionado na raiz** | `f0-008` **FR-001** e **FR-013** — ambas reprovam com *"só em 013"* | **conflito previsto (2 pontos)** |
| **`sbom.cyclonedx.json` / `cyclonedx.json` / `bom.json` versionados na raiz** | `f0-008` **FR-013** — *"cyclonedx SBOM artefato existe (só em 013)"* | **conflito previsto (1 ponto)** |

**Achado:** os três pontos de conflito estão **todos** em `f0-008`, e **todos são
evitáveis por desenho**. Se `pylock.toml` e o SBOM forem gerados no ato do release
e anexados ao GitHub Release — em vez de versionados na raiz — **a 013 não tem
conflito de fronteira nenhum**, e seria o primeiro item desde a 009 a não precisar
do procedimento ADR-017.

O argumento não é conveniência: um SBOM versionado descreve o `uv.lock` do commit
em que foi gerado e **envelhece em silêncio** a cada mudança de dependência; um
SBOM gerado no release descreve exatamente o que foi publicado. O artefato efêmero
é o mais verdadeiro dos dois. Se o CLARIFY preferir versioná-los, o procedimento
ADR-017 se aplica aos 3 pontos acima (8ª execução) — e a spec precisa dizer quem
regenera o arquivo quando o lock muda.

---

## Decisões (insumo ao SPECIFY/CLARIFY — nada aqui é norma)

- **D1.** Pin `python-semantic-release==10.6.2` no grupo `dev` (Q1). `click` real
  entra no `uv.lock` como transitivo — anotar, não pinar.
- **D2.** Build e SBOM por `uv` (`uv build --all-packages`, `uv export --format
  cyclonedx1.5`): **`cyclonedx-bom` descartado** com registro (Q5). Reverte a
  reserva feita pela 008/D4, com fonte executada.
- **D3.** Construção por `uv build --all-packages`; **publicação pela action
  oficial `pypa/gh-action-pypi-publish`** (`v1.14.2`, commit
  `dc37677b2e1c63e2034f94d8a5b11f265b73ba33`), em job separado do build, com
  `permissions: id-token: write` **no nível do job** (Q6). Motivo: é a única das
  duas vias que **produz** atestado de procedência PEP 740 — o `uv publish` só
  enviaria atestado gerado por outro. Supersede a redação anterior desta decisão,
  que era inferência (ver Q6 › *Correção de método*).
- **D4.** Versionamento em **lockstep** dos dois pacotes via `version_toml` com os
  três `pyproject.toml` (Q4). Versões independentes ficam registradas como
  alternativa rejeitada, não como omissão.
- **D5.** `allow_zero_version = true` + `major_on_zero = false` — o motor
  permanece em `0.x` durante a Fase 0. Sem isso o primeiro release é `1.0.0` por
  acidente de configuração (Q3).
- **D6.** Fluxo **B** (PSR calcula em `feature/*`, versão entra em `main` por PR;
  tag dispara o `release.yml`) — recomendado por não colidir com a proteção nem
  introduzir dependência nova. A e C registrados com custo; **C descartado por
  conflito com item convergido** (Q7).
- **D7.** `pylock.toml` e SBOM **efêmeros**, anexados ao GitHub Release, não
  versionados — evita os 3 pontos de fronteira e mantém o artefato honesto (Q10).
- **D8.** Dois pending publishers no PyPI (`fkx-core`, `fkx-cli`) + GitHub
  environment protegido com aprovação manual, como cenário 🧑 com checklist
  versionado, no molde de `branch-protection.md` (Q8).
- **D9.** Pinar a versão do `uv` no `release.yml` (`setup-uv` aceita `version:`) —
  o release não pode depender de "a mais recente" para um formato de SBOM (Q9).

## Declaração de impacto de fronteira (insumo ao PLAN — ADR-017)

Sob **D7**, a 013 **não** toca oráculo anterior: os 3 pontos de `f0-008` (FR-001 e
FR-013) só disparam com `pylock.toml`/SBOM versionados na raiz, e o desenho os
mantém efêmeros. Seria o primeiro item desde a 009 sem execução do procedimento de
fronteira — o que só é digno de nota porque a alternativa existe e foi medida, não
porque se procurou evitá-la.

Se o CLARIFY escolher versionar os artefatos, o PLAN declara os 3 pontos e a ADR
prévia autoriza a forma exata (8ª execução do ADR-017), com legitimidade pelo
`uv.lock` no padrão ADR-018 — nunca por nome estático.

## Out of Scope (Escada)

Renovate/Dependabot (**014**) · `docker-compose` (**015**) · `docs/tree.md` (**016**) ·
publicação de imagem de container · assinatura Sigstore além das attestations que o
`uv publish` já sobe por padrão · release de pré-lançamento (`rc`) e canais múltiplos
(sem consumidor: um mantenedor, uma linha — ADR-032) · versões independentes por
pacote (Q4, alternativa registrada) · `cyclonedx-bom` (Q5, descartado com fonte) ·
matriz *provado-vs-declarado* (roteamento ADR-025, item DevOps/Fase 2).

## Registro de execução

Réplicas descartáveis em `/tmp/.../scratchpad/013/` (`psr/`, `mono/`, `remote.git/`,
`dist/`, `sbom.json`, `pylock.toml`) — **nenhum artefato foi criado no repositório**;
`git status` limpo durante toda a pesquisa, e `uv build` executado com `-o` fora da
árvore justamente para não criar `dist/`. Harness 12/12 verde antes e depois.
