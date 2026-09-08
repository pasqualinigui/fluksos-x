# Contrato do oráculo — `f0-016-tree.sh` (mapa FR↔asserção, ADR-015b)

Identidade 1:1. Self-check `f0-001…f0-015` em série (ADR-031) + `sha256sum -c` do manifest + CONVERGE (`tasks.md` zero `[ ]`) seguem o molde 005/015 e não re-numeram FRs.

| FR | Asserção |
|---|---|
| FR-001 | `docs/tree.md` com H1 + resumo + árvore + tabela de ponteiros |
| FR-002 | região `GENERATED-*` == saída do gerador; todo path do índice presente; nenhum fora |
| FR-003 | gerador stdlib (sem import além de stdlib), 2× byte-idêntico, só-stdout |
| FR-004 | curadoria ≤120 linhas (contagem após o marcador de fim do esqueleto) + total ≤25600 bytes |
| FR-005 | zero segredo/path ignorado no mapa (`\.env(\.|$)\|secrets/` ausentes; todo path listado passa em `git ls-files --error-unmatch`) |
| FR-006 | ponteiros cobrem release/bot/compose-docker-env + destinos existem e sem duplicata |
| FR-007 | contrato de interface obedecido (`--quiet`/`--list`, 0/1/2, 1 linha por asserção, só-leitura, determinismo 2×) |
| FR-008 | `docs/plan/audit/f0-audit-013-016.md` existe com `Veredito`/`Achados`/`Destino` |
| FR-009 | `specs/README.md` `016 ✅`+hash; `tasks.md` zero `[ ]`; par vermelho→verde no log; manifest + self-check serial |

Sem git (impossível neste repo) ⇒ FR-002/005 degradam para erro nomeado, nunca verde falso.
