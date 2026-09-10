# Contrato do oráculo — `f1-017-harness.sh` (mapa FR↔asserção, ADR-015b)

Identidade 1:1 (12 FRs → 12 asserções). Self-check `f0-001…f0-016` em série (ADR-031) + `sha256sum -c` do manifest (17 linhas) + CONVERGE (`tasks.md` zero `[ ]`) seguem o molde 005/016 e moram nas asserções da FR-008/FR-009, sem re-numerar FRs.

| FR | Asserção |
|---|---|
| FR-001 | feedforward: binário ausente → exit `2` nomeando a pré-condição, zero processos gerados |
| FR-002 | feedback: saída `0`/`3`/`-9`/timeout julgados com returncode preservado + saída que falhou (sinal nunca verde) |
| FR-003 | literais `0/1/2` puros: os três cenários (OK/defeito/uso) saem exatamente `0`/`1`/`2` |
| FR-004 | zero retry: tentativa única por invocação (forma: captura da tentativa única em arquivo, sem re-execução; sem `sleep`/laço sobre o comando) |
| FR-005 | veredito nomeia requisito + evidência; traceback nunca é a evidência; segredo mascarado |
| FR-006 | `HarnessError(FkxError)` existe, exportado em `__init__.py`, sem `except:` nu |
| FR-007 | nenhum exit fora de `{0,1,2}` em nenhum cenário (asserção sobre os vereditos, não sobre o fonte) |
| FR-008 | contrato de interface obedecido (`--quiet`/`--list`, 0/1/2, 1 linha por asserção, só-leitura, determinismo 2×) + manifest 17/17 + self-check `f0-001…f0-016` em série |
| FR-009 | `specs/README.md` `017 ✅`+hash; `tasks.md` zero `[ ]`; par vermelho→verde no log |
| FR-010 | PLAN declara + ADR prévia autoriza (10ª execução do molde); `f0-011` FR-002 admite `harness.py` sob jurisdição 017 e nada além |
| FR-011 | só stdlib (`subprocess/os/sys`): nenhum import além; `uv.lock` sem pacote novo |
| FR-012 | POSIX declarado; portão não-POSIX fail-closed com `HarnessError` (forma de simulação a fixar no TESTS: p.ex. variável de forçamento lida pelo módulo, nunca monkeypatch no oráculo) |

Sem `git` (impossível neste repo) ⇒ asserções que dependem do índice degradam para erro nomeado, nunca verde falso (molde 016).
