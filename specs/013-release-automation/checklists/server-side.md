# Checklist — Metade servidora (🧑)

**Purpose**: configuração no lado do PyPI e GitHub que não vive em arquivo
**Spec**: `specs/013-release-automation/spec.md` (FR-014, SC-008)
**Natureza**: config de servidor; o oráculo assere este documento, nunca o servidor (sem token — Lei Zero)

> **Emenda 2026-09-07 (ADR-035).** A metade servidora deixou de ser exclusivamente
> manual: a ADR-035 estabeleceu o molde de **script com código de saída**
> (`scripts/governance/apply-adr-035.sh`) para config de servidor. A metade
> **GitHub** deste checklist foi aplicada por API e está registrada em Evidência.
> A metade **PyPI** permanece manual e é a única que resta: exige sessão
> autenticada no PyPI, que o motor não tem e não deve ter (Lei Zero).

## PyPI — Pending Publishers

Para cada pacote (`fkx-core`, `fkx-cli`):

- [ ] Acessar https://pypi.org/manage/account/publishing/
- [ ] **Add a new pending publisher**
- [ ] Preencher:
  - Project name: `fkx-core` (respectivamente `fkx-cli`)
  - Owner: `pasqualinigui`
  - Repository name: `fluksos-x`
  - Workflow name: `release.yml`
  - Environment: `release` (criado no passo seguinte)
- [ ] Confirmar criação

> **Risco registrado**: pending publisher **não** reserva o nome. Entre esta configuração e o primeiro publish, um terceiro pode tomar `fkx-core` ou `fkx-cli` (Q8). Verificado livre em 2026-09-06.

## GitHub — Environment protegido ✅ aplicado 2026-09-07

- [x] Environment `release` criado (`PUT /repos/{owner}/{repo}/environments/release`)
- [x] **Required reviewers**: `pasqualinigui` — publicação exige aprovação manual
- [x] **Deployment branches**: `tag:v*` — decisão do mantenedor resolvida pela restrição mais estreita, coerente com FR-006 (a tag é o gatilho; branch nenhum publica)
- [x] Estado medido após aplicar

```
name                 release
reviewers            pasqualinigui
prevent_self_review  false
branch_policy        custom_branch_policies=true · tag:v* (1 política)
```

> **Armadilha registrada — `prevent_self_review` MUST ficar `false`.** Com `true`,
> o mantenedor único não pode aprovar o próprio deployment: impasse permanente,
> sem saída que não seja remover o required reviewer. É a mesma classe de
> armadilha que a ADR-035 §4 proíbe em `required_pull_request_reviews`, e pela
> mesma razão — regra de revisão que pressupõe dois atores, aplicada onde há um.
> Reabrir apenas quando houver segundo mantenedor autorizado.

## Workflow — Configuração no `release.yml`

Confirmar que o workflow referencia o environment:

```yaml
jobs:
  publish:
    environment:
      name: release
      url: https://pypi.org/project/fkx-core/  # ou fkx-cli
```

## Primeiro Release — Execução

- [ ] Criar tag manualmente: `git tag v0.2.0 && git push origin v0.2.0`
- [ ] Workflow dispara automaticamente (`on: push: tags:`)
- [ ] Approval manual no environment `release` (se configurado)
- [ ] Aguardar jobs `build` e `publish` completarem
- [ ] Verificar no PyPI: https://pypi.org/project/fkx-core/ e https://pypi.org/project/fkx-cli/
- [ ] Verificar no GitHub: https://github.com/pasqualinigui/fluksos-x/releases

## Evidência de aplicação

### Metade GitHub — ✅ completa

- Aplicado em: **2026-09-07** por: **agente, via API, sob a ADR-035**
- Environment `release`: required reviewer `pasqualinigui` · `tag:v*` · `prevent_self_review=false`
- Proteção de linha e settings do repositório: `scripts/governance/apply-adr-035.sh --check` → **CONFORME**

### Metade PyPI — ⏳ pendente, e é a única

- [ ] Pending publisher `fkx-core`
- [ ] Pending publisher `fkx-cli`
- Links dos releases no PyPI:
  - `fkx-core`: __________________
  - `fkx-cli`: __________________
- Link do GitHub Release: __________________
- Divergência declarada (se houver): __________________

> **Por que esta metade não foi automatizada.** Exige sessão autenticada no PyPI.
> O motor não tem essa credencial e **não deve tê-la** — é exatamente o segredo de
> longa duração que o FR-009 elimina do fluxo. Automatizá-la contradiria o item.
>
> **Não bloqueia a 014.** O `release.yml` só dispara em tag `v*`, e a Fase 0 não
> emite tag. O momento de consumo é o **primeiro release real**, e o checklist
> acima é o procedimento. O risco de nome (Q8: pending publisher não reserva o
> nome) permanece registrado e cresce com o tempo — é o único argumento para
> aplicar antes do release, e é decisão do mantenedor.
