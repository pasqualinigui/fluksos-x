# Data Model — 016 tree-docs

## Mapa

`docs/tree.md`. Campos: H1 (nome do projeto), bloco de resumo (blockquote, o que é + como ler), árvore anotada (1 linha por diretório 1º/2º nível, decisão 2026-09-09), tabela de ponteiros ("onde ler o quê": assunto → path → 1 linha de papel).
Validação: H1 presente; resumo presente; curadoria (tudo após o marcador de esqueleto) conta ≤120 linhas; total <25 KB (teto: 25600 bytes).

## Esqueleto

Emitido por `scripts/generate-tree.py` a partir de `git ls-files` (`LC_ALL=C`, ordenado). Contém todos os paths rastreados, um por linha, sem anotação. Delimitado por marcadores grepeáveis (`<!-- GENERATED-START -->` / `<!-- GENERATED-END -->`) para o oráculo comparar só esta região.
Validação: região gerada == saída do gerador byte a byte; todo path do índice presente; nenhum path fora do índice presente.

## Ponteiro

Linha da tabela: `| assunto | path | papel |`. Validação: `path` existe no índice (`git ls-files --error-unmatch`); sem duplicatas de path; destinos dos herdados obrigatórios (release 013, bot 014, compose/docker/`.env` 015).

## Gerador

`scripts/generate-tree.py`. stdlib puro; lê `git ls-files`; escreve só em stdout; exit 0; byte-idêntico 2×; sem dependência além de `git` + Python 3.12+.

## Relatório de auditoria

`docs/plan/audit/f0-audit-013-016.md`. Cabeçalhos grepeáveis `Veredito`, `Achados`, `Destino` (formato ADR-014). Checkpoint não-item: produzido antes do converge, fora do mapa ADR-011.
