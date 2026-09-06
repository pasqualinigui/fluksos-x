# Feature Specification: Automação de release — versão, CHANGELOG, artefato e publicação

**Feature Branch**: `feature/f0-release-automation`

**Created**: 2026-09-06

**Status**: Draft

**Input**: User description: "Fase 0, item 0.15 (013/016 na ordem de execução): automação de release — versionamento semântico derivado de Conventional Commits, CHANGELOG, tag, build dos pacotes publicáveis, publicação no PyPI via trusted publishing (OIDC) e SBOM anexado ao release, sem credencial em arquivo algum e sem bypass da proteção de linha."

**Item do plano**: 0.15 (§17 Fase 0, Emenda 1) · **Ordem de execução**: 013 de 016 (ADR-011)
**Pesquisa vinculante**: `docs/plan/research/f0-013-release-automation.md` (Q1–Q10, decisões D1–D9, hierarquia P0–P3 da ADR-025, pergunta-padrão de ambiente da ADR-027 §5)
**Contrato de entrada**: `specs/012-packages-cli/spec.md` › Contratos + `specs/010-ci-completo/spec.md` › Contratos + `docs/plan/decisions.md` (ADR-009, ADR-011, ADR-015, ADR-017, ADR-025, ADR-027, ADR-030, ADR-031, ADR-032) + `docs/plan/implementation_plan.md` §§3–4, 15, 17 + `specs/001-git-branching-strategy/contracts/oracle-cli.md`

---

## Contexto

O motor tem dois pacotes publicáveis (`fkx-core` da 011, `fkx-cli` da 012, ambos `0.1.0`), um portão servidor com 10 checks obrigatórios sem-bypass (010 + ADR-032) e mensagens de commit validadas (010 FR-007) — **mas nenhuma forma de entregar o que constrói**. Hoje a versão é texto estático repetido em três arquivos, não existe CHANGELOG, e a única maneira de alguém instalar o motor é clonar o repositório. A 010 registrou explicitamente que validava mensagens para "proteger o `semantic-release` de 013"; este é o item que cobra essa dívida.

O item entrega **exclusivamente**: configuração de versionamento semântico derivado de Conventional Commits sobre a linha de integração única, geração de `CHANGELOG.md`, carimbo da versão nos pacotes publicáveis, construção dos artefatos distribuíveis, publicação no índice público por identidade federada (sem credencial de longa duração) com atestado de procedência, inventário de dependências (SBOM) anexado ao release, e oráculo `f0-013` com 12–16 asserções. Não cria atualização automática de dependências (**014**), `docker-compose` (**015**), `docs/tree.md` (**016**), imagem de container, canais de pré-lançamento, nem versões independentes por pacote.

Obedece aos princípios ratificados (constitution 1.0.0): **I** determinismo (a versão é *derivada por regra* do histórico, nunca escolhida por julgamento; o formato do inventário é pinado, não "o mais recente"); **II** especificação precede código; **III** vermelho→verde em commits separados; **IV** o formato dos artefatos declarado antes de gerá-los; **V** Lei Zero (nenhuma credencial em arquivo, identidade federada de vida curta); **VI** harness é o oráculo, e a fronteira dos itens anteriores só se ajusta por ADR prévia; **VIII** todo pin e todo comportamento externo verificado com evidência executada em `docs/plan/research/f0-013-release-automation.md`; **IX** o item versiona **este** motor e não presume nada sobre a stack de sistemas-alvo; **X** falha nomeia `FR-XXX` e a evidência observada.

**Restrição estrutural que molda o item** (research Q7): a proteção de linha alcança `refs/heads/*`, **não** tags (verificado: 0 rulesets, 404 em `tags/protection`). Um release que precise gravar a versão diretamente na linha protegida colidiria com a 010 FR-009 e com a evidência da ADR-028 — por isso o fluxo de release **não pode** depender de bypass.

## Clarifications

### Session 2026-09-06

- Q: Quem — ou o quê — decide que uma publicação acontece? → A: **ato deliberado do mantenedor** (criação da tag). O pipeline MUST NOT criar a tag por conta própria a partir de integração: publicar é irreversível, e o índice recusa sobrescrever versão já aceita.
- Q: Como a versão calculada alcança a linha de integração protegida sem bypass? → A: **desenho B** — calculada em linha de funcionalidade e integrada por proposta de mudança com os 10 checks obrigatórios. Nenhuma dependência nova; a versão permanece legível no diff. Desenho A (tag como fonte, versão dinâmica) e C (gravação direta) ficam registrados como alternativas rejeitadas — C por conflito com item convergido.
- Q: Se um pacote for aceito pelo índice e o outro falhar no meio da publicação, o que a especificação exige? → A: **reexecução idempotente** — publica somente o que ainda não foi aceito, na mesma versão, sem reprovar por duplicata e sem consumir novo número. É a única saída que trata a irreversibilidade do índice como fato em vez de tentar contorná-la. **Emenda da mesma sessão**: a reexecução é ato deliberado, nunca automática dentro do fluxo — sem essa cláusula, a redação permitiria um retry automático, que é o padrão proibido pela `010` FR-010. A folga foi encontrada ao explicar a decisão, não por auditoria.
- Q: O primeiro release publica `1.0.0` ou o motor permanece em `0.x` durante a Fase 0? → A: **`0.x` durante a Fase 0** (`0.1.0 → 0.2.0` no primeiro release). `1.0.0` é compromisso público de estabilidade de superfície, e a Fase 0 não fechou.
- Q: O inventário de dependências e a trava exportada são versionados no repositório ou gerados no ato do release? → A: **efêmeros** — gerados no ato e anexados à publicação. Descrevem o que foi publicado em vez de descrever um passado, e não acionam o procedimento ADR-017 sobre a `f0-008`.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Versão derivada do histórico, nunca escolhida (Priority: P1)

O mantenedor integra trabalho na linha única usando mensagens convencionais. Ao fazer um release, a próxima versão **já está determinada** pelo histórico desde o último release: correção eleva o dígito de correção, funcionalidade eleva o dígito de funcionalidade, ruptura eleva o dígito maior. Ninguém digita um número.

**Why this priority**: é o princípio I aplicado à entrega. Enquanto a versão for escolhida por julgamento, o release é opinião — e todo o resto (CHANGELOG, tag, artefato) herda essa arbitrariedade. Sem isto, os demais cenários não têm insumo.

**Independent Test**: sobre um histórico conhecido, consultar a próxima versão sem produzir efeito colateral e conferir contra a regra declarada; repetir a consulta e obter o mesmo resultado.

**Acceptance Scenarios**:

1. **Given** o último release registrado e commits de correção desde então, **When** a próxima versão é consultada, **Then** apenas o dígito de correção sobe, e a consulta não altera arquivo, tag ou remoto.
2. **Given** o mesmo estado consultado duas vezes, **When** as duas saídas são comparadas, **Then** são idênticas (determinismo — a versão é função do histórico, não do momento).
3. **Given** commits que não descrevem mudança liberável, **When** a próxima versão é consultada, **Then** o sistema informa que não há release a fazer, em vez de inventar um incremento.

---

### User Story 2 — Registro de mudanças e versão carimbada em todos os pacotes (Priority: P1)

No release, o registro de mudanças é gerado a partir das mensagens convencionais, agrupado por tipo, e a versão é carimbada **simultaneamente** em todos os pacotes publicáveis, que caminham juntos.

**Why this priority**: é o que torna o release legível para quem consome, e a única defesa contra dois pacotes com versões divergentes que dependem um do outro.

**Independent Test**: executar o release em modo local (sem alcançar remoto algum) e conferir que o registro foi criado com as seções esperadas e que todos os pacotes publicáveis exibem a mesma versão.

**Acceptance Scenarios**:

1. **Given** commits de correção e de funcionalidade desde o último release, **When** o release é preparado, **Then** o registro de mudanças contém ambas as seções, cada entrada rastreável ao commit de origem.
2. **Given** dois pacotes publicáveis em `0.1.0`, **When** o release eleva a versão, **Then** **todos** exibem a nova versão — nenhum fica para trás.
3. **Given** um release já registrado, **When** o registro é regenerado, **Then** as entradas anteriores são preservadas, não sobrescritas.

---

### User Story 3 — Publicação sem credencial e sem bypass (Priority: P1)

O release constrói os artefatos distribuíveis e os publica no índice público autenticando por **identidade federada de vida curta**, emitida no momento da execução. Nenhuma credencial existe em arquivo, e o fluxo **não** requer contornar a proteção da linha.

**Why this priority**: é a Lei Zero (princípio V) no ponto de maior exposição do projeto — publicar é a única operação que fala com o mundo escrevendo. E é onde a proteção conquistada na 010 seria mais tentador afrouxar.

**Independent Test**: verificar que nenhum arquivo versionado contém credencial; verificar que o caminho de publicação declara a permissão de emissão de identidade **apenas** no escopo que publica; verificar que o fluxo de release não grava na linha protegida sem passar pelo portão.

**Acceptance Scenarios**:

1. **Given** o repositório inteiro, **When** varrido por padrões de credencial, **Then** nenhuma é encontrada em arquivo, exemplo ou registro (Lei Zero).
2. **Given** o caminho de publicação, **When** suas permissões são inspecionadas, **Then** a permissão de emissão de identidade está declarada no menor escopo possível e ausente do restante do pipeline.
3. **Given** o fluxo de release completo, **When** sua rota até a linha protegida é inspecionada, **Then** ela passa pelos checks obrigatórios — em nenhuma hipótese exige ator com bypass.
4. **Given** um release em que um pacote foi aceito pelo índice e o outro falhou, **When** o fluxo é reexecutado sobre a mesma versão, **Then** apenas o pacote que faltava é publicado, sem reprovar por duplicata e sem consumir novo número de versão.
5. **Given** um artefato publicado, **When** um terceiro consulta sua procedência no índice, **Then** encontra atestado que o vincula à execução que o produziu — sem precisar acreditar em declaração do projeto.

---

### User Story 4 — Inventário do que foi publicado (Priority: P2)

Cada release carrega um inventário de dependências no formato padrão da indústria, descrevendo exatamente o conjunto publicado, mais a trava exportada em formato interoperável.

**Why this priority**: é a cadeia de suprimentos (constitution › *Additional Constraints*) fechando o ciclo que a 008 abriu — auditar o que está no disco tem valor limitado se o que sai não é descrito.

**Independent Test**: gerar o inventário a partir da trava versionada e validar que o formato é o declarado, com contagem de componentes coerente com a trava.

**Acceptance Scenarios**:

1. **Given** a trava de dependências do repositório, **When** o inventário é gerado, **Then** é válido no formato declarado e nomeia a ferramenta que o produziu.
2. **Given** um release publicado, **When** seus anexos são inspecionados, **Then** o inventário está entre eles, correspondendo ao conjunto publicado.

---

### Edge Cases

- **Nenhuma mudança liberável desde a última tag**: o release não acontece e o sistema diz por quê — nunca produz versão vazia nem falha obscura.
- **Execução sem remoto configurado**: a ferramenta de versionamento aborta mesmo em consulta pura (research Q9, provado) — o contrato exige remoto presente, e a falha nomeia isso em vez de parecer defeito de lógica.
- **Formato do inventário renomeado numa versão futura da ferramenta**: por isso a versão da ferramenta de empacotamento é **pinada** no caminho de release; depender da "mais recente" transformaria uma renomeação silenciosa em release quebrado (research Q9 — lacuna encontrada pela pergunta-padrão de ambiente).
- **Nome do pacote tomado por terceiro antes da primeira publicação**: a configuração pendente do índice **não reserva** o nome (research Q8) — risco declarado, com data de verificação, não escondido.
- **Integração sem tag**: integrar na linha única **não** publica nada. A publicação só existe a partir do ato deliberado que cria a tag — não há caminho pelo qual um merge alcance o índice público sozinho.
- **Aceitação parcial entre os dois pacotes**: o índice recusa sobrescrever o que já aceitou, e não existe desfazer. A reexecução sobre a mesma versão publica somente o que falta; a versão não é queimada e o estado parcial permanece visível, nunca mascarado por sucesso falso.
- **Republicação de versão íntegra**: reexecutar um release já completo é operação nula e informativa — nem erro, nem publicação nova.
- **Artefato de construção entrando no histórico**: as exclusões versionadas já cobrem os diretórios de distribuição (verificado); o oráculo assere positivamente para que uma regressão futura reprove.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST declarar a ferramenta de versionamento semântico com pin exato no grupo de desenvolvimento (`python-semantic-release==10.6.2`, triangulado P0+P1+executado — research Q1) e MUST NOT declará-la como dependência de runtime de pacote publicável.
- **FR-002**: O sistema MUST declarar, em configuração versionada, que a versão é derivada de Conventional Commits sobre a linha de integração única (ADR-032), com formato de tag declarado e explícito.
- **FR-003**: O sistema MUST carimbar a versão em **todos** os arquivos de metadados dos pacotes publicáveis em lockstep numa única operação (research Q4, provado em réplica) — versões divergentes entre pacotes interdependentes MUST reprovar.
- **FR-004**: O sistema MUST declarar explicitamente, em configuração versionada, que a faixa de versão permanece `0.x` enquanto a Fase 0 não fechar — o comportamento MUST NOT ser herdado do padrão da ferramenta, que promoveria o primeiro release a `1.0.0` (decisão CLARIFY 2026-09-06); ruptura em `0.x` MUST NOT forçar promoção automática.
- **FR-005**: O sistema MUST gerar `CHANGELOG.md` a partir das mensagens convencionais, agrupado por tipo, preservando entradas de releases anteriores.
- **FR-006**: O sistema MUST prover fluxo de release em arquivo de workflow **próprio**, separado do pipeline de integração, disparado por evento de tag — sem alterar o pipeline de integração, cujas asserções de fronteira (`f0-003` FR-007/FR-008) permanecem verdes por escopo (research Q10). A tag MUST resultar de ato deliberado do mantenedor; o pipeline MUST NOT criá-la automaticamente a partir de integração (decisão CLARIFY 2026-09-06 — publicação é irreversível).
- **FR-007**: O fluxo de release MUST separar construção e publicação em escopos distintos, e MUST declarar a permissão de emissão de identidade federada **apenas** no escopo que publica (P1 uv + P1 PyPI, independentes — research Q6).
- **FR-008**: O sistema MUST construir os artefatos distribuíveis de todos os pacotes publicáveis (fonte + binário por pacote) sem que qualquer artefato de construção entre no histórico.
- **FR-009**: O sistema MUST publicar por identidade federada, sem credencial de longa duração em arquivo, variável versionada ou registro (Lei Zero, princípio V) — a autenticação MUST ser emitida no ato da execução. Diante de aceitação parcial (um pacote aceito, outro falho), a reexecução do fluxo sobre a **mesma** versão MUST publicar somente o que ainda não foi aceito, sem reprovar por duplicata e sem consumir novo número de versão. A reexecução MUST resultar de ato deliberado e MUST NOT ser automática dentro do fluxo: repetição automática sobre falha de publicação converteria falha genuína (credencial inválida, índice indisponível) em verde por insistência — o retry mascarador que a `010` FR-010 proíbe (decisão CLARIFY 2026-09-06, emenda da mesma sessão). A publicação MUST produzir **atestado de procedência** que vincule criptograficamente cada artefato à execução que o publicou, verificável por terceiro sem depender de declaração do projeto (research Q6 corrigida — a via de publicação escolhida é a que **gera** o atestado, não a que apenas o transporta).
- **FR-010**: O sistema MUST gerar inventário de dependências em formato padrão da indústria a partir da trava versionada, como fonte única, sem introduzir segunda ferramenta para o mesmo fato (research Q5 — reverte a reserva feita pela 008/D4, com evidência executada).
- **FR-011**: O sistema MUST gerar o inventário e a trava exportada **no ato do release** e anexá-los à publicação, e MUST NOT versioná-los no repositório (decisão CLARIFY 2026-09-06 — mantém o artefato fiel ao conjunto publicado e não aciona o procedimento ADR-017 sobre a `f0-008`).
- **FR-012**: A versão calculada MUST alcançar a linha de integração por proposta de mudança submetida aos 10 checks obrigatórios (decisão CLARIFY 2026-09-06, desenho B do research Q7), e MUST NOT exigir ator com bypass da proteção nem alteração da proteção vigente.
- **FR-013**: O sistema MUST pinar a versão da ferramenta de empacotamento usada no fluxo de release, de modo que o formato do inventário não dependa de resolução flutuante (research Q9).
- **FR-014**: O sistema MUST versionar o procedimento da metade servidora (configuração de publicação federada por pacote e escopo protegido de aprovação) como checklist executável por humano, sem token nem segredo, no molde de `branch-protection.md` (precedente 003-T031/010, research Q8).
- **FR-015**: O sistema MUST prover oráculo `scripts/verify/f0-013-release.sh` com 12–16 asserções sob o contrato `oracle-cli.md` (identidade FR↔asserção documentada, determinismo, somente leitura, self-check `f0-001…f0-012` **em série** conforme ADR-031, 13ª linha do manifest).
- **FR-016**: `specs/README.md` MUST conter `013` `✅` com hash do commit de convergência, e `tasks.md` MUST fechar com zero tarefas `[ ]` e par vermelho→verde em commits separados.

### Key Entities *(include if feature involves data)*

- **Release**: unidade publicável; atributos: versão derivada, tag, registro de mudanças, artefatos, inventário. Não existe sem histórico convencional que a determine.
- **Version**: número único e compartilhado por todos os pacotes publicáveis de um release; derivado, nunca digitado.
- **Changelog**: registro cumulativo por tipo de mudança; cada entrada rastreável ao commit de origem.
- **Artefato distribuível**: forma-fonte e forma-binária por pacote publicável; efêmero no repositório, permanente no release.
- **Inventário de dependências**: descrição do conjunto publicado, derivada da trava versionada como fonte única.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A partir de um histórico dado, a próxima versão é obtida por regra e é idêntica em duas consultas consecutivas — zero julgamento humano no número.
- **SC-002**: Todos os pacotes publicáveis exibem a mesma versão após o release, em 100% das execuções.
- **SC-003**: Zero credencial de longa duração em qualquer arquivo versionado; a varredura de segredos do pipeline permanece verde.
- **SC-004**: O fluxo de release completo não exige nenhuma alteração da proteção vigente nem ator com bypass — verificável por inspeção do fluxo e da configuração de proteção.
- **SC-005**: Cada release publicado carrega inventário de dependências válido no formato declarado.
- **SC-011**: Cada artefato publicado tem procedência verificável por terceiro no índice, vinculando-o à execução que o produziu.
- **SC-006**: Harness 13/13 + manifest 13/13 + `tasks.md` zero `[ ]` + par vermelho→verde em commits separados.
- **SC-007**: Oráculo executa 2× com saída byte-idêntica, cada execução abaixo de 5 segundos (padrão de determinismo dos oráculos anteriores).
- **SC-008**: 🧑 Cenário humano — a metade servidora é executada com checklist versionado preenchido com saídas verbatim (a divergência declarada é saída aceitável; a divergência silenciosa não é — precedente 010/SC-005).
- **SC-009**: Diante de aceitação parcial, a reexecução sobre a mesma versão completa o release em 100% dos casos sem consumir novo número de versão.
- **SC-010**: Nenhuma integração na linha única produz publicação sem o ato deliberado que cria a tag — verificável por inspeção do gatilho do fluxo.

## Assumptions

- A linha de integração é única e `develop` é espelho (ADR-032); a configuração de versionamento aponta para ela.
- Os pacotes publicáveis são os dois membros existentes; a raiz do workspace não é publicável (verificado: `package = false`).
- Os nomes de pacote estão livres no índice público na data da pesquisa (2026-09-06, verificado por API); a reserva só ocorre na primeira publicação.
- As asserções do pipeline de integração são escopadas ao seu próprio arquivo (verificado mecanicamente — research Q10), portanto um workflow de release novo não as toca.
- A verificação de identidade federada **não é reproduzível localmente**: só o executor remoto emite o token. É limite honesto declarado (ADR-025 §3), roteado ao cenário 🧑, e não será alegado como provado sem execução no servidor.
- Nomes exatos de arquivos, chaves de configuração, nomes de escopo do fluxo e ordem interna dos passos são desenho do PLAN, não desta especificação.
- **Termo canônico**: `release` (o mesmo do plano, §17 item 0.15), com `liberável` como sua forma adjetiva. Anteriormente referido também como "liberação" nesta spec; normalizado nesta sessão de clarificação.

## Contratos

### Entregue por este item

- Versionamento semântico derivado do histórico + `CHANGELOG.md` + carimbo em lockstep nos pacotes publicáveis.
- Fluxo de release próprio, disparado por tag, com construção e publicação em escopos separados, identidade federada de vida curta e atestado de procedência por artefato.
- Inventário de dependências e trava exportada, a partir da trava versionada como fonte única.
- Oráculo `f0-013` (12–16 asserções) + 13ª linha do manifest + `specs/README.md` `013 ✅`.
- Checklist versionado da metade servidora (publicação federada por pacote + escopo de aprovação).

### Recebido de itens anteriores

- De **012**: `fkx-cli` publicável com entry point funcional (não se publica o que não existe).
- De **011**: `fkx-core` publicável com superfície estável.
- De **010**: mensagens de commit validadas (pré-requisito declarado do versionamento semântico) + portão servidor + proteção sem-bypass como restrição de desenho.
- De **008**: auditoria de dependências e a reserva de inventário — **reavaliada e revertida** com evidência executada (research Q5), não herdada por inércia.
- De **005**: `--no-dev` mantém ferramenta de release fora do artefato publicado.
- De **004**: `uv.lock` como fonte única da resolução; construção e exportação sem configuração extra.
- De **001 (Lei Zero)**: exclusões que impedem artefato de construção e credencial de entrarem no histórico.
- De **ADR-031**: portão determinístico — pré-condição de um item que publica; self-check em série.
- De **ADR-032**: linha de integração única, sobre a qual a versão é derivada.

### Transferido a itens posteriores

- À **014** (atualização de dependências): pipeline de release verde como validador do que entra; trava exportada como base de comparação.
- À **016** (`docs/tree.md`): estrutura final incluindo o fluxo de release.
- À **Fase 1+**: motor instalável a partir do índice público — condição para que agentes e sistemas-alvo consumam `fkx` sem clonar o repositório.
- À **auditoria pós-016**: primeira operação do motor que escreve fora do repositório; e o ponto cego `|| true` sobre ferramenta externa (ADR-031 §5), que ganha superfície nova aqui.
