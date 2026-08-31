# Índice de Specs — fluksos-x

> **Invariante (ADR-011):** `número da spec = posição de execução`, **não** número do item no plano (`§17`). O plano (`docs/plan/implementation_plan.md:830-846`) registra a **intenção** histórica; este índice + `docs/plan/decisions.md` (ADR-001/009/011) registra a **execução**.
>
> **Leitura:** `Spec 005` **sempre** é `Pytest` (005ª a executar) e `Item 0.4` **sempre** é `Pytest` (4º item do §17). `0.5` é `Lefthook` e `009` é `Lefthook`. Para traduzir, use `spec.md:11` de cada spec ou esta tabela — nunca o plano isolado.

**Estrutura flat determinística:** `specs/<NNN>-<slug>/spec.md` com `NNN` sequencial (`feature_numbering=sequential` em `.specify/init-options.json:4`). Flat é o contrato do `specify` (`check-prerequisites.sh` deriva `FEATURE_DIR` de `specs/NNN`). Subpastas por fase (`specs/f0/005-...`) quebrariam a tool e exigiriam `mv` ao reordenar (viola `ADR-002`). A fase já vive no nome e no front-matter (`Item do plano: 0.X`).

## Mapa vigente — Fase 0 (16 posições, ADR-011)

| Spec | Item plano | Fase | Título | Status |
|---|---|---|---|---|
| `001` | **0.9** | F0 | Git + branching strategy | ✅ concluída |
| `002` | **0.11** | F0 | Constitution + porta de entrada | ✅ concluída |
| `003` | **0.13** | F0 | CI mínimo | ✅ concluída |
| `004` | **0.1** | F0 | UV workspace monorepo | ✅ concluída |
| `005` | **0.4** | F0 | Pytest 9.1.1 — harness TDD | ✅ concluída (`68c38fb`) |
| `006` | **0.2** | F0 | Ruff 0.16.5 | ✅ concluída (`8918fab`) |
| `007` | **0.3** | F0 | MyPy 2.3.1 strict | ✅ concluída |
| `008` | **0.12** | F0 | pip-audit + Trivy | ⏳ |
| `009` | **0.5** | F0 | Lefthook 2.1.11 | ⏳ |
| `010` | **0.14** | F0 | CI completo + branch protection | ⏳ |
| `011` | **0.6** | F0 | `packages/core` | ⏳ |
| `012` | **0.7** | F0 | `packages/cli` | ⏳ |
| `013` | **0.15** | F0 | Automação de release | ⏳ |
| `014` | **0.16** | F0 | Atualização de dependências | ⏳ |
| `015` | **0.8** | F0 | docker-compose | ⏳ |
| `016` | **0.10** | F0 | `docs/tree.md` | ⏳ |

*Mapa histórico original (12 itens) em `ADR-001` permanece como registro; `ADR-011` o supersede para 16.*

## Como ler uma spec

```
specs/005-pytest/spec.md:11
  Item do plano: 0.4 (§17 Fase 0) · Ordem de execução: 005 de 016 (ADR-011)
```

* `005` = 5ª a executar (este índice)
* `0.4` = 4º item do `§17` (plano)
* `005 → 0.4` é a tradução; `009 → 0.5` é Lefthook

## Próximas fases (resumo)

| Fase | Itens | Tema |
|---|---|---|
| F1 | 8 itens (1.1–1.8) | Harness & Indexação |
| F2 | 10 itens (2.1–2.10) | Agentes Core + Golden tests + Teto custo |
| F3 | 9 itens (3.1–3.9) | Memória & Observabilidade + Retenção |
| F4 | 11 itens (4.1–4.11) | CLI/TUI & Polish + Contrato saída CLI |

*Após `016`, a numeração segue `017...` flat, sem reiniciar por fase.*

## Onde vivem as fontes

| Preciso de | Vou a |
|---|---|
| Mapa de execução vigente | Este arquivo + `docs/plan/decisions.md` (ADR-011) |
| Intenção histórica do plano | `docs/plan/implementation_plan.md:830-879` |
| Pesquisa por item | `docs/plan/research/f0-NNN-*.md` |
| Harness | `scripts/verify/f0-NNN-*.sh` + `manifest.sha256` |
