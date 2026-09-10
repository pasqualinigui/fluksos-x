# Data Model — 017 harness

## Pré-condição

Fato verificável antes de executar: binário resolvido no `PATH`, variáveis obrigatórias presentes, plataforma POSIX. Validação: cada pré-condição ausente retorna erro de uso (`2`) nomeando-a, com zero processos gerados.

## Execução capturada

Resultado de `subprocess.run(check=False, capture_output=True, timeout=…)`: `returncode` preservado (inclusive negativo por sinal: `-9` medido), `stdout`/`stderr` capturados, expiração com kill + saída parcial (fail-closed). Validação: nenhum caminho engole terminação anormal; `TimeoutExpired` mata e evidencia.

## Veredito

`requisito: str` (ID `FR-XXX` informado pelo chamador) + `evidencia: str` (saída observada, nunca traceback, segredo mascarado) + `exit: Literal[0, 1, 2]` + `returncode: int` (preservado; negativo por sinal). Superfície construtora em `contracts/oracle-cli.md` › Superfície (ANALYZE F1 + adendo). Validação: todo veredito carrega os quatro campos; segredo mascarado (`SecretStr` nunca em claro — Lei Zero).

## Erro do módulo

`HarnessError(FkxError)` (CLARIFY 2026-09-10): falhas do próprio harness (pré-condição inválida, plataforma não-POSIX, uso incorreto da API). Exportado em `fkx_core/__init__.py` (superfície pública, molde 011). Validação: `except:` nu e `BaseException` direta proibidos (FR-006 da 011, vigente); mensagem contextual sem segredo.
