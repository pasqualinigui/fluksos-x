# Checklist — Metade servidora (🧑)

**Purpose**: configuração no lado do PyPI e GitHub que não vive em arquivo
**Spec**: `specs/013-release-automation/spec.md` (FR-014, SC-008)
**Natureza**: config de servidor aplicada por humano; o oráculo assere este documento, nunca o servidor (sem token — Lei Zero)

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

## GitHub — Environment protegido

- [ ] Acessar https://github.com/pasqualinigui/fluksos-x/settings/environments
- [ ] **New environment**
- [ ] Nome: `release`
- [ ] **Required reviewers**: adicionar mantenedores autorizados (approval manual)
- [ ] **Deployment branches**: restringir para tags (`v*`) ou todos os branches (decisão do mantenedor)
- [ ] Salvar

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

- Aplicado em: **____-__-__** por: **________________**
- Links dos releases no PyPI:
  - `fkx-core`: __________________
  - `fkx-cli`: __________________
- Link do GitHub Release: __________________
- Divergência declarada (se houver): __________________
