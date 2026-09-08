# Research (consolidação Phase 0) — 016 tree-docs

**Fonte vinculante**: `docs/plan/research/f0-016-tree.md` (Q1–Q5, D1–D5, E1–E6, fetch 2026-09-09). Abaixo, só decisões; o porquê mora no vinculante.

## Decisões

- **Decision: mapa estático anotado versionado** (`docs/tree.md`: H1 + resumo + árvore por diretório + tabela de ponteiros).
  Rationale: caso de uso é navegação zero-contexto (bootstrap); dinamismo por relevância é runtime da Fase 1 (1.5), sem consumidor agora (IV).
  Alternatives considered: repo-map aider dinâmico (rejeitado: Fase 1); llms.txt web literal (rejeitado: alvo divergente; filosofia adotada).
- **Decision: verificação automática + atualização assistida.**
  Rationale: nada residente/committando sozinho (Ambiente sob demanda); harness detecta, humano conserta (doutrina ADR-035 §5).
  Alternatives considered: gerador auto-commitante (rejeitado: mata curadoria); só-manual sem verificação (rejeitado: apodrece).
- **Decision: dois andares — esqueleto completo gerado + curadoria ≤120 linhas.**
  Rationale: completude mecânica + orientação com teto asserido; total <25 KB cabe no bootstrap.
  Alternatives considered: teto 80 (pobre) / 200 (custoso) — 120 ratificado no CLARIFY 2026-09-09.
- **Decision: granularidade por diretório (1º/2º nível) + ponteiros para artefatos-chave.**
  Rationale: índice já detalha arquivos; curadoria orienta sem duplicar (CLARIFY 2026-09-09).
- **Decision: 016 herda a FR da auditoria `f0-audit-013-016`.**
  Rationale: 16−12=4 → DUE; molde 009/ADR-016; checkpoint não-item pré-converge.
- **Decision: stdlib + `git ls-files`; sem `tree`, sem ctags, sem tokenizador.**
  Rationale: portabilidade do harness + determinismo entre modelos + escada; limites em linhas+bytes.
