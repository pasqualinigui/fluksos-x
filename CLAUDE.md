@AGENTS.md

## Específico deste agente

Este arquivo existe porque o Claude Code lê `CLAUDE.md`, não o arquivo do formato
aberto — verificado na documentação do fornecedor e registrado em
`docs/plan/research/f0-002-constitution.md`, Q4. A importação acima é a forma
recomendada pela própria documentação: fonte única, sem texto duplicado.

Arquivo regular por decisão registrada (C5): link simbólico exigiria privilégio de
administrador no Windows, e este artefato é versionado e viaja.

**Orçamento de contexto.** Acima de 200 linhas somadas a adesão do agente ao
próprio conteúdo degrada, e importar não alivia — o conteúdo importado é carregado
junto. Limite deste par: 175 linhas. Conteúdo novo entra como ponteiro.
