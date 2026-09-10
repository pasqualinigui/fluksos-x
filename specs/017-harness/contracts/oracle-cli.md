# Contrato do oráculo — `f1-017-harness.sh` (mapa FR↔asserção, ADR-015b)

Identidade 1:1 (12 FRs → 12 asserções). Self-check `f0-001…f0-016` em série (ADR-031) + `sha256sum -c` do manifest (17 linhas) + CONVERGE (`tasks.md` zero `[ ]`) seguem o molde 005/016 e moram nas asserções da FR-008/FR-009, sem re-numerar FRs.

> A03 (mapeamento positivo `0/1/2`) vs A07 (proibição negativa fora de `{0,1,2}`): distinção intencional (ANALYZE A1, manter) — uma prova o alfabeto, a outra proíbe o fora-do-alfabeto.

## Superfície (ANALYZE F1 + adendo pré-vermelho — fixada aqui, não no TESTS)

```python
veredito = harness.run(cmd, *, timeout=None, requisito="HARNESS") -> Veredito
Veredito(requisito: str, evidencia: str, exit: Literal[0, 1, 2], returncode: int)
```

`requisito` é o ID `FR-XXX` informado pelo chamador (o módulo é genérico: quem chama nomeia o requisito — sem ele, FR-005 seria inexigível); `evidencia` é a saída observada (nunca traceback, segredo mascarado); `exit` é o literal; `returncode` é o código preservado (negativo por sinal: `-9` medido). O vermelho (T007/T010) chama exatamente esta forma; o verde a implementa sem desviar.

| FR | Asserção |
|---|---|
| FR-001 | feedforward: binário ausente → exit `2` nomeando a pré-condição, zero processos gerados (forma ANALYZE C1: comando que criaria marcador se executasse + pré-condição inválida → marcador ausente = prova) |
| FR-002 | feedback: saída `0`/`3`/`-9`/timeout julgados com returncode preservado + saída que falhou (sinal nunca verde; vazio com guarda estilo `-z` vira vermelho nomeado, molde `f0-015/016` — ANALYZE C4) |
| FR-003 | literais `0/1/2` puros: os três cenários (OK/defeito/uso) saem exatamente `0`/`1`/`2` |
| FR-004 | zero retry: tentativa única por invocação (forma ANALYZE C2: proibidos em `harness.py` os identificadores `tenacity\|backoff`, import com `retry` e `time.sleep`; captura da tentativa única em arquivo, sem re-execução) |
| FR-005 | veredito nomeia requisito + evidência; traceback nunca é a evidência; segredo mascarado (guardas contra vazio em A02 valem aqui — ANALYZE C4) |
| FR-006 | `HarnessError(FkxError)` existe, exportado em `__init__.py`, sem `except:` nu |
| FR-007 | nenhum exit fora de `{0,1,2}` em nenhum cenário (asserção sobre os vereditos, não sobre o fonte) |
| FR-008 | contrato de interface obedecido (`--quiet`/`--list`, 0/1/2, 1 linha por asserção, só-leitura, determinismo 2×) + manifest 17/17 + self-check `f0-001…f0-016` em série |
| FR-009 | `specs/README.md` `017 ✅`+hash; `tasks.md` zero `[ ]`; par vermelho→verde no log |
| FR-010 | PLAN declara + ADR prévia autoriza (10ª execução do molde); `f0-011` FR-002 admite `harness.py` sob jurisdição 017 e nada além |
| FR-011 | só stdlib (`subprocess/os/sys`): nenhum import além; `uv.lock` sem pacote novo |
| FR-012 | POSIX declarado; portão não-POSIX fail-closed com `HarnessError` (forma ANALYZE C3: o módulo lê `FKX_HARNESS_FORCE_PLATFORM` (`posix`|`nonposix`, default autodetect); o oráculo fixa `nonposix` e exige a recusa nomeada; nunca monkeypatch no oráculo) |

Sem `git` (impossível neste repo) ⇒ asserções que dependem do índice degradam para erro nomeado, nunca verde falso (molde 016).
