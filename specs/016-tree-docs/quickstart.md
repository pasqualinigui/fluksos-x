# Quickstart — validar a 016 de ponta a ponta

```bash
# 1. gerador determinístico (sem escrita)
python3 scripts/generate-tree.py > /tmp/t1.txt && python3 scripts/generate-tree.py > /tmp/t2.txt && cmp /tmp/t1.txt /tmp/t2.txt

# 2. frescor: simular divergência (sem commitar nada)
git ls-files | head -1 | xargs -I{} sh -c 'grep -v "^{}$" /tmp/t1.txt > /tmp/tmod.txt'
# oráculo deve reprovar nomeando o path quando comparado (ver FR-002 no teste real)

# 3. oráculo cheio
scripts/verify/f0-016-tree.sh

# 4. auditoria devida
ls docs/plan/audit/f0-audit-013-016.md && grep -c "Veredito\|Achados\|Destino" docs/plan/audit/f0-audit-013-016.md
```

Esperado: 1 byte-idêntico; 3 CONFORME com auditoria presente (ou reprova só FR-008 sem ela); 4 lista o relatório. SC-007 🧑: em janela nova, só `AGENTS.md` + `tree.md`, localizar 3 artefatos de itens distintos. Detalhes em `data-model.md`; mapa FR↔asserção em `contracts/oracle-cli.md`.
