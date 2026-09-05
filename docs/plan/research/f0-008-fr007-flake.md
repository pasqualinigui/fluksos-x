# RESEARCH — A2 (auditoria 009–012) · transiência 008-FR-007 sob contenção

> **Data da verificação:** 2026-09-05 · **Papel:** Investigador (não-item, destino
> da auditoria `docs/plan/audit/f0-audit-009-012.md` › A2) · **Método:** execução
> concorrente controlada + leitura do código da asserção. Nenhum dado por memória.
> **Amostras prévias:** 009 (ADR-019, string presente na re-execução) + auditoria
> 009–012 (mesma assinatura). Total na mesma FR antes deste arquivo: **2**.

## Código sob exame

`scripts/verify/f0-008-pip-audit.sh` (FR-007):

```sh
if ! uv run pip-audit --dry-run 2>&1 | grep -q "would have audited" 2>/dev/null; then
  out=$(uv run pip-audit --dry-run 2>&1 | head -5 | tr -d '\n' | cut -c1-120)
  fail "FR-007" ... "pip-audit --dry-run não coletou: $out"
```

## Reprodução (2026-09-05, máquina do mantenedor)

| Experimento | Carga | Resultado |
|---|---|---|
| 6× `pip-audit --dry-run` concorrentes | ~2.0 | 6/6 passam |
| 3× `f0-008 --quiet` concorrentes | ~5.2 | **1/3 falha** |
| 4× `f0-008 --quiet` concorrentes | alta | **3/4 falham**: FR-007 (assinatura idêntica, string presente na evidência) + FR-010 (`>5s`, 7s) |

Isolado/serial: sempre verde (15/16 CONFORME). Transiente puro, dependente de carga.

## Diagnóstico

1. **Vetor primário: contenção sob fan-out.** O self-check (`for o in … & wait`)
   dispara 10–11 oráculos em paralelo, cada um com vários `uv run` (lock de
   projeto + CPU). Sob load ~5, tentativas de `uv run` degradam/falham; a
   re-execução da evidência (serial, calma) contém a string — por isso a
   evidência "prova" o que o grep "não viu".
2. **Agravante de método (achado próprio desta investigação): a evidência
   mascara a assinatura.** A linha de evidência vem da **segunda** invocação
   (calma), nunca da tentativa que falhou. O transiente real (lock timeout?
   saída parcial? truncamento?) é descartado pelo próprio oráculo. Toda
   investigação futura de flake começa cega por construção.
3. **FR-010 confirma a classe**: `>5s` sob carga com `EPOCHSECONDS` (resolução
   1s) — instrumento grosseiro + ambiente carregado, já anotado na ADR-019 §3.

## Caminho prescrito (não aplicado aqui — exige procedimento ADR-017 próprio)

1. **Estreito, em `f0-008` FR-007**: capturar a saída da tentativa única em
   arquivo temporário (`trap`), grepar o arquivo, evidenciar **a tentativa que
   falhou** (elimina o mascaramento do item 2 sem mudar semântica; sem retry —
   proibido pela 010 FR-010/ADR-019).
2. **Largo (classe, 8+ oráculos com fan-out `& wait`)**: experimento dedicado —
   serializar self-check vs. manter paralelo com quarentena documentada; custo
   (tempo) × benefício (determinismo sob carga) medido, não alegado. Dono:
   auditoria pós-016, insumos = este arquivo + §3 do relatório.
3. **Nada aqui autoriza edição de oráculo convergido.** Qualquer aplicação
   passa por PLAN-declara → ADR-autoriza → verde-aplica → manifest-cita.

## Efeito deste arquivo

A2 passa de "defeito a investigar" para "defeito investigado com causa e
caminho": contenção sob fan-out paralelo + evidência que mascara a assinatura.
Pendente: aplicação do caminho 1 (via ADR-017) e experimento do caminho 2.
