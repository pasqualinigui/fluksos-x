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

## Adendo — forense do fan-out (2026-09-05, sessão servidor)

Reprodução dirigida do fan-out (`for o in … & wait`, 9 oráculos): 1/3 bursts
falha em `f0-007` FR-010 com mecanismo capturado — `mypy --help` parcial
(contém `strict`, falta `disallow-untyped-calls`); 8/8 seriais verdes;
6/6 `mypy --help` concorrentes isolados com 320/320 linhas. Ou seja: o
truncamento só ocorre no burst completo (10 oráculos × ferramentas externas),
nunca em concorrência homogênea — contenção de recurso compartilhado
(lock do `uv`/CPU/memória sob ~10GB ocupados), não defeito de lógica.

**Agravante sistêmico (novo, mesma família do item 2):** o padrão
`OUT=$(uv run … || true)` engole terminação anormal (ex.: 137/OOM) — a
asserção vê "saída parcial", nunca "processo morto". Toda asserção com
`|| true` sobre ferramenta externa tem esse ponto cego (princípio X:
falha deve nomear requisito **e evidência** — aqui a evidência do crash
é descartada por construção). Endurecimento candidato (via ADR-017, nunca
direto): capturar `$?` separadamente e evidenciar terminação anormal como
classe distinta de "saída sem marcador".

---

## Fechamento — medição pareada e aplicação dos caminhos 1 e 2 (2026-09-05, sessão remediação)

> Este arquivo abre dizendo *"Pendente: aplicação do caminho 1 e experimento do
> caminho 2"*. Ambos foram executados. Decisão em **ADR-031**.

### O experimento que faltava (caminho 2)

Em vez de carga sintética, o vetor foi medido diretamente: os dois oráculos com
maior fan-out, 20 execuções cada, sem carga artificial nenhuma.

| Momento | `f0-011` (10 aninhados) | `f0-012` (11 aninhados) | Agregado |
|---|---|---|---|
| **Antes** (fan-out paralelo) | 4/20 reprovações | 6/20 reprovações | **10/40 — 25%** |
| **Depois** (self-check serial) | 0/20 | 0/20 | **0/40 — 0%** |

Custo: harness completo 66,8s → 84s (+17s). A estimativa a priori de +30s era
pessimista — sem contenção, cada aninhado também roda mais rápido.

**A leitura da ADR-019 cai por aqui.** "Ambiental sob carga" descrevia a
observação (falhas heterogêneas, isoladas-verdes) mas errava a causa: a carga
que importava era a que o **próprio oráculo criava**, não a da máquina. Por isso
nunca reproduzia isolado — isolado não há fan-out.

### Caminho 1 aplicado (`f0-008` FR-007)

A captura passou a ser única: a tentativa que **decide** é a que **evidencia**,
e o código de saída da ferramenta entra na linha de evidência. O mascaramento
descrito no item 2 do diagnóstico acima deixa de existir neste sítio.

### O que continua aberto

O ponto cego `OUT=$(uv run … || true)` (terminação anormal engolida) permanece,
agora como dívida nomeada da auditoria pós-016 — ver ADR-031 §5. Com o fan-out
removido, a pressão que o tornava visível diminuiu, o que **aumenta** o risco de
ele apodrecer despercebido: fica o registro.
