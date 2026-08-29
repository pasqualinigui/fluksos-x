# Quickstart — Validação da Fundação de Versionamento

**Feature**: `001-git-branching-strategy` · **Data**: 2026-08-29

Roteiro de validação ponta a ponta. Prova que a fundação satisfaz a spec e que o
ciclo vermelho→verde ocorreu de fato.

Referências: [contrato do oráculo](./contracts/oracle-cli.md) ·
[modelo de dados](./data-model.md) · [pesquisa](./research.md)

---

## Pré-requisitos

Tudo já verificado presente na máquina alvo. Nada a instalar — e essa é a
restrição, não a conveniência (FR-019).

| Ferramenta | Versão verificada |
|---|---|
| git | 2.55.0 |
| Python | 3.12.3 |
| interpretador de shell | bash |

**Deliberadamente ausentes**: `pytest`, `ruff`, `mypy`, `lefthook`, `trivy`,
`gitleaks`. Chegam nos itens 005–009. Se o oráculo precisar de algum deles para
rodar, a implementação está errada.

---

## Cenário 1 — Evidência do vermelho 🔴

**Quando**: após a Fase C, antes da Fase D.

```bash
scripts/verify/f0-001-foundation.sh ; echo "exit=$?"
```

**Esperado**: `exit=1`, com reprovações em `FR-001` (repositório inexistente),
`FR-002`, `FR-004`..`FR-007` (convenções não documentadas) e `FR-015` (sem
registro inicial). A mensagem de `FR-001` precisa ser informativa, não um erro
abrupto (FR-021).

**Por que importa**: é a única prova de test-first disponível para este item —
`pytest` só chega no item 007. Sem esta execução registrada, SC-004 falha
mesmo que todo o resto funcione.

> Guardar a saída. Ela é o artefato de evidência, não um subproduto do console.

---

## Cenário 2 — Evidência do verde 🟢

**Quando**: após a Fase D.

```bash
scripts/verify/f0-001-foundation.sh ; echo "exit=$?"
```

**Esperado**: `exit=0`, todas as asserções aprovadas.

---

## Cenário 3 — Determinismo (SC-003)

```bash
scripts/verify/f0-001-foundation.sh > /tmp/run1.txt 2>&1
scripts/verify/f0-001-foundation.sh > /tmp/run2.txt 2>&1
diff /tmp/run1.txt /tmp/run2.txt && echo "DETERMINISTICO"
```

**Esperado**: `diff` sem diferenças. Qualquer divergência indica dependência de
horário, de ordem de leitura do sistema de arquivos ou de identificador gerado —
violação da restrição 3 do contrato.

Medir também a duração: precisa concluir em menos de 5 segundos.

---

## Cenário 4 — A exclusão realmente protege (FR-008, FR-009)

O cenário que a pesquisa E1 revelou estar **descoberto** no template canônico da
indústria.

```bash
touch .env .env.local .env.production .env.example
git status --porcelain
```

**Esperado**: apenas `.env.example` aparece como não rastreado. As três variantes
de segredo permanecem invisíveis ao versionador.

**Falha esperada se a correção D1 não tiver sido aplicada**: `.env.local` e
`.env.production` apareceriam — segredos a um comando de distância do histórico
permanente.

```bash
rm -f .env .env.local .env.production .env.example
```

---

## Cenário 5 — A trava de dependências sobrevive (FR-013)

```bash
touch uv.lock
git status --porcelain uv.lock
```

**Esperado**: aparece como não rastreado, isto é, **versionável**. Se estiver
invisível, algum padrão de exclusão a capturou e o controle de cadeia de
suprimentos foi desfeito em silêncio — exatamente a regressão que a asserção
positiva de `FR-013` existe para detectar.

```bash
rm -f uv.lock
```

---

## Cenário 6 — Exclusão parcial do diretório do motor (FR-012)

```bash
mkdir -p .fluksos-x/sessions .fluksos-x/specs
touch .fluksos-x/sessions/s.json .fluksos-x/specs/keep.md
git status --porcelain .fluksos-x/
```

**Esperado**: `.fluksos-x/specs/keep.md` visível; `.fluksos-x/sessions/s.json`
invisível. Confirma que o diretório-pai permanece versionável enquanto os
subdiretórios efêmeros são excluídos (E2).

```bash
rm -rf .fluksos-x
```

---

## Cenário 7 — Protocolo de especificação versionado (FR-023)

Os artefatos que fixam **com que protocolo o motor foi construído** precisam
entrar no histórico; a configuração local de máquina, não.

```bash
mkdir -p .claude
touch .claude/settings.local.json
git status --porcelain .claude/
```

**Esperado**: as habilidades do motor de especificação em `.claude/skills/`
aparecem como versionáveis; `.claude/settings.local.json` permanece invisível.

**Por que importa**: se as habilidades ficarem fora do histórico, o protocolo de
especificação pode derivar entre os doze itens da Fase 0 sem deixar rastro — e o
processo derivaria junto, tornando os itens incomparáveis entre si. Se a
configuração local entrar, caminhos e permissões da máquina do mantenedor vazam
para o repositório.

```bash
rm -f .claude/settings.local.json
```

---

## Cenário 8 — O falso-negativo que o oráculo precisa detectar (FR-020)

Este cenário verifica o **oráculo**, não a fundação. Executar em cópia
descartável, nunca no repositório do projeto.

1. Em um repositório descartável, registrar um arquivo de ambiente **antes** de
   existir qualquer regra de exclusão.
2. Só então acrescentar as regras.
3. Executar o oráculo.

**Esperado**: `FR-020a` reprova com severidade crítica, nomeando o arquivo.

**Falha característica**: um oráculo que consulte apenas as regras de exclusão
aprova este cenário — o falso-negativo demonstrado em E7. Se a asserção passar
aqui, a implementação está errada mesmo tendo aprovado.

---

## Cenário 9 — Estado final do repositório

```bash
git branch --format='%(refname:short)'      # main, develop
git log --oneline                            # registro inicial conforme
git config --local user.email                # pasqualini166@gmail.com
git config --global --get-regexp 'init|user' # inalterado pelo item
```

**Esperado**: as duas linhas presentes; registro inicial obedecendo à convenção;
identidade em escopo local; escopo global sem qualquer entrada escrita por este
item (FR-003).

---

## Critério de conclusão

| # | Condição | Requisito |
|---|---|---|
| 1 | Cenário 1 registrado com reprovação | SC-004 |
| 2 | Cenário 2 aprovando integralmente | SC-004 |
| 3 | Cenário 3 sem diferenças, abaixo de 5 s | SC-003 |
| 4 | Cenários 4, 5, 6 e 7 conforme o esperado | SC-001, FR-023 |
| 5 | Cenário 8 detectando o arquivo já rastreado | FR-020 |
| 6 | Cenário 9 com estado final íntegro e escopo global intacto | FR-001..FR-003 |

Atendidos os seis, o item está pronto para `/speckit-tasks` → implementação →
`/speckit-analyze` → `/speckit-converge`.
