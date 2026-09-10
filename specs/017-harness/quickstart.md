# Quickstart — validar a 017 de ponta a ponta

```bash
# 1. superfície pública (após o verde; no vermelho este import falha — é o esperado)
uv run --frozen --all-packages python -c "import fkx_core; print(fkx_core.HarnessError)"

# 2. os três exits pelo módulo (roteiro do SC-006 🧑)
uv run --frozen --all-packages python - <<'EOF'
from fkx_core import harness
print(harness.run(["true"]).exit)                 # esperado: 0
print(harness.run(["bash", "-c", "exit 3"]).exit) # esperado: 1
print(harness.run(["binario-inexistente-017"]).exit)  # esperado: 2
EOF

# 3. morte por sinal nunca é verde
uv run --frozen --all-packages python -c "from fkx_core import harness; v = harness.run(['bash', '-c', 'kill -9 \$\$']); print(v.exit, v.returncode)"

# 4. oráculo cheio
scripts/verify/f1-017-harness.sh
```

Esperado: 1 importa `HarnessError`; 2 imprime `0`, `1`, `2` nomeados; 3 imprime falha com `-9` (nunca `0`); 4 CONFORME 12/12. Nomes exatos de funções/assinaturas são desenho do TESTS/IMPLEMENT (este roteiro usa a forma candidata `harness.run` → veredito; se o PLAN fixar outra, este arquivo acompanha antes do verde). Detalhes em `data-model.md`; mapa FR↔asserção em `contracts/oracle-cli.md`.
