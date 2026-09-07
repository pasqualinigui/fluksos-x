# Data Model: Automação de release

## Entidades

### Release
Unidade publicável derivada do histórico de Conventional Commits.

### Version
Número único compartilhado por todos os pacotes publicáveis (lockstep).

### Changelog
Registro cumulativo por tipo de mudança.

### Artefato distribuível
Forma-fonte e forma-binária por pacote publicável (efêmero no repo).

### Inventário de dependências
SBOM CycloneDX 1.5 + pylock.toml (efêmero, gerado no ato do release).

## Configuração (`[tool.semantic_release]`)

| Chave | Valor |
|---|---|
| `allow_zero_version` | `true` |
| `major_on_zero` | `false` |
| `version_toml` | 3 caminhos (raiz + core + cli) |
| `tag_format` | `"v{version}"` |
| `commit_parser` | `"conventional"` |
