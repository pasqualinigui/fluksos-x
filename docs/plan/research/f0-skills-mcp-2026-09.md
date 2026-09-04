# Pesquisa — Skills de agente + MCP no motor fluksos-x

> **Data**: 2026-09-04 · **Tipo**: evidência não-normativa (não cria regra; alimenta
> item 2.6 e Fase 2) · **Método**: verificação contra fonte primária (docs oficiais,
> registros, repositórios) via busca web datada. Nenhuma conclusão por memória.
> **Questões**: (Q1) a base atual do motor é "ouro sênior"? (Q2) `find-skills` +
> skill que cria skills + MCPs oficiais fazem sentido no motor, nos projetos, ou
> em ambos? (Q3) Tavily/Firecrawl são necessários?

---

## 1. Veredito

**(Q1) Sim, com 3 lacunas nomeadas (§5).** SDD+TDD+harness+observabilidade+toolchain
pinada (pytest/mypy/ruff/pydantic/lefthook/uv+CI+ADD) coincide com o consenso 2026
de *harness engineering*: OpenAI (Lopopolo, fev/2026) e Hashimoto ("quando o agente
erra, construa solução para nunca errar de novo" = princípio VII literal); análise
GitHub de 2500+ repos `AGENTS.md` (fronteira Always/Ask-First/Never + gates
mecânicos > prosa = princípios I+VI); literatura Augment/TopGenAIJobs ("rules files
sozinhos são probabilísticos; combine com linters e CI gates" = I+VI). O plano
ainda cobre o que a maioria esquece: golden tests (2.9), teto custo/latência (2.10),
retenção de efêmeros (3.9), contrato de saída CLI (4.11), CI que neutraliza
`--no-verify` (0.14/ADR-009), integridade por hash (ADR-006/015).

**(Q2) Sim — como MECANISMO no motor, CONTEÚDO nos projetos.** Skills procedurais +
`scripts/` determinísticos mapeiam 1:1 ao princípio I (roteamento probabilístico
entre regras fixas). MCPs oficiais eliminam adivinhação de API (princípio VIII).
Mas descoberta/criação/atualização sem trava quebra II, III, VI — a trava proposta
está no §4. Linha divisória: motor nunca tem skill de domínio hardcoded (IX);
projeto nunca inventa mecanismo próprio de verificação.

**(Q3) Não, agora.** Esta pesquisa usou busca web genérica e bastou para questão
estratégica. Tavily + Crawl4AI chegam com o researcher (3.6); o plano já prefere
Crawl4AI local gratuito a Firecrawl pago — manter.

## 2. Estado da arte verificado (fontes primárias)

| # | Afirmação | Fonte (acesso 2026-09-04) |
|---|---|---|
| E1 | Agent Skills é padrão aberto: dir + `SKILL.md` (frontmatter `name`+`description`) + `scripts/` + `references/` + `assets/`; Apache-2.0 | `agentskills.io/specification`, `github.com/agentskills/agentskills` |
| E2 | Disclosure progressiva em 3 níveis (metadata ~100 tokens → SKILL.md → arquivos sob demanda); `SKILL.md` <500 linhas; scripts para trabalho mecânico determinístico | especificação oficial + Anthropic Engineering "Equipping agents…" (out/2025) |
| E3 | "Skills podem incluir código; código é determinístico, workflow consistente" | mesmo artigo Anthropic |
| E4 | Composição canônica: Skills = procedimento, MCP = ambiente/ferramentas, subagentes = decomposição/paralelismo | guias 2026 convergentes (anhtu.dev, skywork, reactify) |
| E5 | Registry MCP oficial existe; `com.supabase/mcp` v0.11.0 oficial | `registry.modelcontextprotocol.io`, `github.com/modelcontextprotocol/registry` |
| E6 | Supabase tem MCP oficial + docs de instalação + repo `supabase/agent-skills`; recomenda read-only, project-scoping (`?project_ref=`), branching para dev | `supabase.com/docs/guides/ai-tools/mcp`, `github.com/supabase/mcp` |
| E7 | Skill oficial `skill-creator` existe no repo Anthropic; prática: testar com ~5 perguntas variantes + falsos positivos; versionar como código (semver) | `github.com/anthropics/skills` (173k★), guias 2026 |
| E8 | Risco nomeado: skills são vetor de prompt-injection; usar só fontes confiáveis; sandbox sem rede em API | docs Anthropic + guias 2026 |
| E9 | Golden dataset: 50 PoC / 100–200 produção / 300+ missão crítica; cada caso com input + sequência de tools esperada + critério de saída + anotação de falha; trajetória > só resultado; falha de produção vira caso | guias 2026 (Braintrust, Confident AI) — converge com 2.9 |
| E10 | Harness 2026 = AGENTS.md + CI como produto; "encode one rule in CI before ten prose guidelines"; garbage collection de docs | TopGenAIJobs, Augment (Hashimoto/OpenAI) |

## 3. Cobertura atual do plano (o que já existe — não duplicar)

`agents/tools/*` MCP (2.6) · researcher Tavily+Crawl4AI (3.6) · `skills/` global +
plugin system pós-MVP (§15/§features) · golden tests (2.9) · teto custo/latência
(2.10) · interview por fronteira c/ mantenedor decidindo (4.2/ADR-013, FR-017b) ·
observabilidade OTel+Langfuse (3.4/3.5) · promptfoo p/ eval (§4). **70% do
mecanismo já está desenhado; falta a política (§5).**

## 4. Julgamento determinístico (I, V, VI, VIII, IX)

- **I — `find-skills` permitido se a escolha for entre candidatos fixos.**
  Modelo indica; humano aprova; RESEARCH verifica (registry/PyPI/npm + `--help`);
  pin+hash fixam; harness assere; golden cobre. Roteamento entre regras — conforme.
  Auto-instalação pelo modelo — violação (decisão de conformidade sem regra).
- **VII/VIII — skill que cria/atualiza skills é proposta, nunca instalação.**
  Aprendizado vira artefato versionado pelo ciclo (SPECIFY→…→TESTS🔴→🟢), como a
  meta-skill oficial faz. Auto-update silencioso = edição silenciosa de oráculo
  (classe ADR-002/007) aplicada ao catálogo.
- **IX — adaptador obrigatório.** Nada de `supabase`-específico fora de adaptador
  declarado; política de escopo por MCP (default read-only + project-scoping + ramo
  de dev, cf. E6) elevada a regra do motor.
- **V — supply chain de skills.** Allowlist de fontes + hash + sandbox (E8); skill
  não-assinada/não-pinado não executa — mesma severidade da trava de dependências.
- **VI/X — observabilidade por skill.** Falha nomeia skill+MCP+versão+FR, como o
  oráculo nomeia FR hoje.

## 5. Três lacunas candidatas (observação, não norma — emenda na Fase 2)

1. **Catálogo versionado skills/MCPs** (pin+hash+allowlist, extensão do manifest
   ADR-015) — sem ele, aprovação humana apodrece em *approval fatigue*.
2. **Política de escopo/sandbox por MCP** (read-only default, scoping, teto 2.10,
   trace Fase 3) — E6 como regra, não sugestão.
3. **Eval de skill** (5 variantes + falsos positivos, E7) ligado aos golden tests
   2.9 — skill sem eval é prosa com aparência de autoridade (classe do achado
   ADR-008).

**Não trazer (firula):** marketplace interno nesta fase; auto-update sem ADR; MCP
com lógica de negócio opinativa (skill no lugar errado, E4); gateway enterprise
antes do 2.10 existir.

## 6. Destino

Alimenta o item **2.6** (`agents/tools/*`) e a **Emenda 3** futura (Fase 2). Nenhuma
spec da Fase 0 muda por este documento (princípio IV: norma sobre artefato que só
existe na Fase 2 nasceria agora como especulação).
