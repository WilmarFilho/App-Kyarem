# Plano de Refatoracao do Back-end e Banco

## 1. Contexto

Este plano foi montado a partir do codigo do projeto, com foco no modulo `Back-API-Kyarem`.

O que hoje ja existe de positivo:

- Spring Boot 3.5 com Java 21
- JPA + Flyway + PostgreSQL no Supabase
- `ddl-auto=validate` e `open-in-view=false`
- separacao razoavel por dominios (`cadastros`, `competicao`, `partidas`, `identity`, `storage`)
- `EntityGraph` em alguns repositorios para evitar problemas de lazy loading
- tentativa de tornar eventos idempotentes com `local_evento_id`
- testes automatizados basicos do back-end

Ao mesmo tempo, o projeto ainda carrega decisoes de MVP e isso aparece principalmente em dois pontos:

1. o schema real do Supabase parece ter sofrido drift em relacao ao que esta versionado
2. a ideia de "modalidade generica" existe no modelo, mas a regra de negocio principal ainda esta acoplada ao fluxo atual de futsal

## 2. Leitura atual do projeto

### 2.1 Banco atual inferido pelo repositorio

Pelo codigo e pelas migrations, hoje o modelo principal esta organizado assim:

- `esportes`
- `tipos_eventos`
- `campeonatos`
- `modalidades`
- `equipes`
- `equipe_atlet_inscritos`
- `equipes_staff`
- `partidas`
- `eventos_partida`
- `partida_arbitros`
- tabelas de identidade (`profiles`) e cadastro (`atleticas`, `atletas`)

Observacoes relevantes:

- `modalidades` mistura definicao de regra com instancia de campeonato
- `tipos_eventos` esta ligado a `esporte`
- `partidas` referencia `modalidade` e duas equipes
- `eventos_partida` registra ocorrencias da partida e usa `tipo_evento`
- `snapshot_sumula` e `sumula_pdf_url` tentam congelar o resultado final oficial

### 2.2 Evidencias de drift do schema

O projeto nao consegue nos dizer com 100% de certeza como o Supabase esta hoje em producao, porque ha sinais claros de divergencia entre o que esta no banco e o que esta versionado:

- `V4__align_tipos_eventos_schema.sql` declara explicitamente que o schema do Supabase nao bate com a definicao local de `tipos_eventos`
- as migrations versionadas criam `campeonatos`, `modalidades`, `equipes` e `equipe_atlet_inscritos`, mas nao criam `partidas`, `eventos_partida` e `partida_arbitros`; elas apenas alteram essas tabelas em migrations posteriores
- isso indica que parte importante do schema nasceu fora do Flyway, ou veio de um baseline nao versionado no repositorio

Conclusao pratica: hoje da para entender boa parte do modelo, mas nao da para afirmar que o repositorio representa o Supabase real sem fazer um dump/inspecao do banco de producao.

## 3. Principais limitacoes encontradas

### 3.1 A generalizacao por modalidade existe no dado, mas nao no motor

O projeto ja tem uma boa semente de generalizacao:

- `Modalidade` possui `regras_json`
- `TipoEvento` pertence a um `Esporte`
- `Partida` pertence a uma `Modalidade`

Mas a maior parte da regra operacional ainda esta hardcoded no servico:

- status da partida sao strings fixas como `1° tempo`, `2° tempo`, `acrescimo`, `prorrogacao`, `pausada`, `fechada`
- placar sobe quando `tipoEvento.nome == "gol"`
- substituicao tem fluxo fixo no servico
- PDF oficial conhece faltas, pausas tecnicas, gols, prorrogacao e limites de futsal
- notificacao tambem mapeia eventos por nome fixo

Na pratica, isso significa que uma nova modalidade ainda exigira mexer em varios pontos do sistema, e nao apenas cadastrar novas regras.

### 3.2 `tipos_eventos.nome` esta fazendo papel de codigo e de label

Hoje o campo `nome` de `tipos_eventos` esta sendo usado como:

- codigo tecnico: `GOL`, `FALTA`, `CARTAO_AMARELO`
- nome de exibicao
- gatilho de regra de negocio

Isso e perigoso porque:

- mistura semantica de dominio com apresentacao
- dificulta localizacao e internacionalizacao
- aumenta a chance de quebrar regra por erro de texto
- impede evoluir nomes de exibicao sem afetar o motor

### 3.3 `regras_json` ainda nao e contrato de regra

Hoje `regras_json`:

- aceita qualquer objeto JSON
- nao possui schema versionado
- nao e validado semanticamente
- quase nao participa da execucao da regra

Ou seja: ele armazena configuracao, mas ainda nao dirige o comportamento do sistema.

### 3.4 Existem duplicacoes de fonte de verdade

Os exemplos mais claros sao:

- `modalidades.tempo_partida_minutos` e o possivel `tempoRegulamentar` dentro de `regras_json`
- `modalidades.campeonato_nome` duplicando o nome do campeonato
- placar persistido em `partidas` e ao mesmo tempo derivavel dos eventos

Essas duplicacoes facilitam inconsistencia e precisam ser tratadas com uma fonte de verdade clara.

### 3.5 O modelo atual assume modalidades coletivas

O desenho atual foi feito para equipes, atletas inscritos e staff:

- `equipes`
- `equipe_atlet_inscritos`
- `equipes_staff`
- `partida` com `equipe_a_id` e `equipe_b_id`

Se o roadmap incluir modalidades individuais, duplas ou formatos nao baseados em equipe, esse ponto vai exigir uma abstracao maior.

### 3.6 Falta endurecimento de banco para producao

Hoje faltam ou parecem inconsistentes:

- baseline unico e reproduzivel do schema
- constraints unicas relevantes
- indices em relacoes e filtros de alto uso
- estrategia clara de auditoria/soft delete para eventos oficiais
- controle de concorrencia para atualizacao de partida/eventos

### 3.7 Side effects de producao estao muito acoplados ao fluxo transacional

Hoje o ciclo da partida faz de forma sincrona:

- gravacao de evento
- atualizacao de placar
- envio de push
- geracao/upload de PDF no fechamento

Para producao, isso aumenta:

- tempo de resposta
- fragilidade transacional
- dificuldade de reprocessar
- risco de erro externo impactar o fluxo principal

### 3.8 A sumula oficial esta fortemente acoplada ao futsal

O `SumulaOficialPdfService` hoje e basicamente uma implementacao especializada de futsal:

- `MAX_PLAYERS = 13`
- contagem de faltas acumuladas
- pedidos de tempo
- logica de gols por periodo
- layout unico da sumula
- eventos de pausa tecnica, prorrogacao e afins

Isso e totalmente normal para o MVP, mas precisa sair do fluxo generico se a meta e suportar novas modalidades com baixo custo.

## 4. Objetivo da refatoracao

O objetivo nao deve ser "deixar tudo abstrato". O objetivo deve ser:

- manter um monolito modular, simples de operar
- permitir adicionar nova modalidade com alteracoes localizadas
- evitar que cada modalidade exija mexer no servico central de partidas
- recuperar governanca do schema do banco
- melhorar escalabilidade operacional para producao
- preservar o que ja funciona no MVP enquanto o motor novo entra por etapas

## 5. Arquitetura-alvo recomendada

### 5.1 Estrategia geral

A recomendacao aqui e manter um **monolito modular** e nao quebrar em microservicos agora.

Motivos:

- o dominio ainda esta amadurecendo
- o gargalo principal nao e distribuicao, e sim acoplamento de regra
- separar em servicos agora aumentaria complexidade operacional cedo demais

### 5.2 Modulos de dominio sugeridos

Estruturar o back-end em camadas mais claras:

- `catalogo`
  - esportes
  - tipos de evento
  - templates de modalidade
- `competicao`
  - campeonatos
  - inscricoes
  - participantes/equipes
- `motor-de-partida`
  - comandos
  - maquina de estados
  - validadores
  - projeções derivadas
- `sumulas-e-relatorios`
  - geracao de snapshot
  - geracao de PDF oficial por modalidade
- `infra`
  - storage
  - notificacoes
  - autenticacao
  - persistencia

### 5.3 Motor por estrategia

O ideal e mover a regra de modalidade para um contrato explicito:

```java
public interface MatchRuleEngine {
    boolean supports(String modalidadeCode);
    MatchTransitionResult apply(MatchState state, MatchCommand command);
}
```

Primeiro passo:

- extrair um `FutsalRuleEngine` usando a logica atual
- depois registrar novos engines por modalidade ou por template de modalidade

Isso evita:

- `if` espalhado em `PartidaService`
- comparacao de strings como `"gol"`
- acoplamento do fluxo generico ao futsal

### 5.4 Separar comando, evento e projeção

Sugestao de fluxo:

1. controller recebe comando
2. application service carrega `Partida`
3. `MatchRuleEngine` valida e aplica
4. sistema persiste evento bruto
5. sistema atualiza projecoes derivadas
6. side effects rodam apos commit

Esse desenho ajuda muito em:

- auditoria
- idempotencia
- reprocessamento
- manutencao de placar
- suporte a novas modalidades

## 6. Plano de refatoracao do banco

### Fase 0. Descoberta do schema real

Antes de qualquer refactor estrutural:

- extrair um dump/schema snapshot do Supabase real
- comparar com o Flyway atual
- decidir qual sera a fonte oficial de verdade

Entrega esperada:

- documento de gap entre `schema real` e `schema versionado`
- baseline oficial do banco

### Fase 1. Corrigir governanca do schema

Objetivo: fazer o banco ser reconstruivel a partir do repositório.

Acoes:

- criar um baseline oficial do schema atual real
- parar de depender de tabelas "ja existentes fora do Flyway"
- garantir que todas as tabelas importantes estejam no fluxo de migration
- revisar encoding/UTF-8 das migrations

Pontos criticos:

- `partidas`
- `eventos_partida`
- `partida_arbitros`
- constraints unicas e indices ausentes

### Fase 2. Endurecer integridade e performance

Adicionar ou revisar:

- unique em `tipos_eventos (esporte_id, codigo)` ou equivalente
- unique em `equipes (campeonato_id, modalidade_id, atletica_id)` se essa for a regra do negocio
- unique em `equipe_atlet_inscritos (equipe_id, atleta_id)`
- unique parcial em `eventos_partida.local_evento_id` quando nao nulo
- indice em todos os FKs usados em consulta
- indice em `partidas (modalidade_id, status, agendado_para)`
- indice em `eventos_partida (partida_id, criado_em)`
- indice em `eventos_partida (partida_id, tipo_evento_id)`
- indice em `partida_arbitros (arbitro_id, partida_id)`

Tambem vale adicionar:

- `criado_por`, `atualizado_em`, `atualizado_por` onde fizer sentido
- `version` para optimistic locking em agregados concorridos

### Fase 3. Modelar melhor a configuracao de modalidade

Recomendacao:

- separar **template de modalidade** de **modalidade de campeonato**

Exemplo sugerido:

- `modalidade_templates`
  - definicao reutilizavel
  - ligada ao esporte
  - possui schema de regra
  - possui codigo tecnico
- `campeonato_modalidades`
  - referencia o template
  - permite overrides por campeonato
  - controla inscricao/agenda daquela competicao

Beneficio:

- futsal masculino/feminino/universitario podem reaproveitar o mesmo template
- nova competicao nao precisa recriar toda a definicao do zero

### Fase 4. Redesenhar tipos de evento como metadados

Hoje `tipos_eventos.nome` e pouco expressivo como estrutura de regra.

Sugestao:

- manter tabela de tipos, mas com metadados de comportamento

Campos sugeridos:

- `codigo`
- `nome_exibicao`
- `categoria`
- `requer_equipe`
- `requer_autor`
- `requer_alvo`
- `impacta_placar`
- `delta_placar`
- `impacta_status`
- `transicao_status`
- `ordem_exibicao`
- `payload_schema_json`
- `ativo`

Assim a regra deixa de depender de string literal no servico.

### Fase 5. Evoluir `partidas` e `eventos_partida`

#### `partidas`

Hoje o campo `status` mistura estado tecnico e label localizavel.

Sugestao:

- substituir por `state_code`
- adicionar `periodo_atual`
- adicionar `clock_state`
- manter `placar_casa` / `placar_fora` apenas como projecao denormalizada
- considerar mover snapshots versionados para uma tabela propria se houver historico de fechamento

#### `eventos_partida`

Sugestao de evolucao:

- `event_code`
- `periodo`
- `clock_seconds`
- `sequence_no`
- `actor_participant_id`
- `target_participant_id`
- `payload_json`
- `created_by`
- `correlation_id`
- `voided_at`
- `void_reason`

Importante:

- evitar hard delete para evento oficial
- preferir "anular" evento por auditoria

### Fase 6. Decisao estrutural sobre participantes

Este e o ponto de maior impacto futuro.

Se o roadmap for somente modalidades coletivas:

- manter `equipes` faz sentido
- basta generalizar regras/eventos

Se o roadmap incluir modalidades individuais ou duplas:

- vale introduzir `participantes_competicao`
- `equipes` vira um tipo de participante
- `partida` passa a referenciar `participante_a_id` e `participante_b_id`

Minha recomendacao:

- decidir isso antes da fase estrutural do banco
- porque essa escolha muda bastante o modelo

## 7. Plano de refatoracao do back-end

### Fase 1. Estabilizar a camada atual sem trocar comportamento

Objetivo:

- parar de espalhar regra de negocio no controller e nos services centrais

Acoes:

- criar objetos de comando para operacoes de partida
- padronizar exceptions de dominio
- remover `System.out.println` e trocar por logger estruturado
- separar validacoes de dominio de efeitos externos

### Fase 2. Extrair o motor de futsal para um engine proprio

Objetivo:

- tirar do `PartidaService` e `EventoPartidaService` a responsabilidade de conhecer o esporte atual

Acoes:

- criar `FutsalRuleEngine`
- mover para esse engine:
  - estados validos
  - transicoes
  - impacto de eventos
  - substituicoes
  - calculo de placar
- fazer `PartidaService` virar orquestrador e nao detentor da regra

### Fase 3. Transformar `PartidaService` em application service

O `PartidaService` deve:

- carregar agregado
- delegar validacao e decisao ao engine
- persistir comandos/eventos/projecoes
- publicar eventos de integracao

Ele nao deve continuar sendo:

- maquina de estados
- montador de snapshot
- gerador de PDF
- adaptador de storage
- concentrador de side effects

### Fase 4. Reestruturar o fluxo de eventos

Criar uma camada mais explicita:

- `RegisterMatchEventHandler`
- `ChangeMatchStateHandler`
- `CloseScoresheetHandler`
- `UndoMatchEventHandler`

Cada handler deve operar com:

- comando de entrada
- regra/engine
- persistencia
- publicacao de eventos pos-commit

### Fase 5. Tratar projeções como responsabilidade separada

Separar derivacoes do evento bruto:

- placar atual
- elenco ativo
- snapshot final
- feed/notificacao

Isso permite:

- recalcular se a regra mudar
- reprocessar historico
- reduzir acoplamento no fluxo de gravacao

### Fase 6. Tirar PDF oficial do caminho generico

Recomendacao:

- criar `OfficialReportGenerator`
- implementar primeiro `FutsalOfficialReportGenerator`
- no futuro adicionar `BasqueteOfficialReportGenerator`, `VoleiOfficialReportGenerator` etc.

Assim o layout e a logica de apuracao deixam de contaminar o motor base.

### Fase 7. Tornar side effects assíncronos

Idealmente:

- notificacao push apos commit
- upload de PDF apos commit
- uso de outbox ou `@TransactionalEventListener`

Beneficios:

- menos latencia no endpoint
- menos acoplamento com servicos externos
- maior resiliencia para producao

## 8. Ordem recomendada de execucao

### Sprint 0

- extrair schema real do Supabase
- fechar baseline oficial
- mapear queries mais usadas em producao

### Sprint 1

- corrigir migrations faltantes
- adicionar constraints e indices prioritarios
- padronizar codigos tecnicos de status e eventos
- remover duplicacoes mais perigosas

### Sprint 2

- extrair `FutsalRuleEngine`
- reescrever `PartidaService` e `EventoPartidaService` como orquestradores
- introduzir handlers/comandos

### Sprint 3

- externalizar side effects para pos-commit
- isolar geracao de sumula oficial
- adicionar auditoria/void em eventos

### Sprint 4

- modelar template de modalidade vs instancia de campeonato
- versionar `regras_json` e validar schema
- preparar a estrutura para a segunda modalidade

### Sprint 5

- implementar uma segunda modalidade usando o motor novo
- ajustar gaps de abstração descobertos
- concluir hardening para producao

## 9. Backlog prioritario

### P0

- levantar schema real do Supabase e oficializar baseline
- garantir que o repositorio consiga recriar todas as tabelas criticas
- separar `codigo` de `nome_exibicao` em tipos de evento
- parar de basear regra em string literal de evento
- remover status localizados como contrato tecnico

### P1

- extrair motor de futsal
- mover PDF e notificacoes para fluxo pos-commit
- adicionar indices e constraints principais
- adicionar auditoria/void para eventos

### P2

- separar template de modalidade de modalidade em campeonato
- definir schema versionado para `regras_json`
- avaliar abstracao de participante generico

### P3

- caching de catalogos
- paginacao em endpoints de listagem
- metricas e tracing mais ricos
- reprocessamento de projeções

## 10. Decisoes que voces precisam tomar antes da refatoracao estrutural

1. O produto vai suportar modalidades individuais/duplas no medio prazo?
2. A sumula oficial sera diferente por modalidade ou existira um formato unico com pequenas variacoes?
3. O placar precisa ser sempre uma projecao recalculavel, ou pode continuar persistido como cache derivado?
4. Eventos precisam de trilha completa de auditoria e anulacao oficial?
5. A captura offline/mobile com reenvio e conflito sera parte forte do produto?

Essas respostas definem o quanto vale genericizar agora.

## 11. Recomendacao final

Minha recomendacao e a seguinte:

- **nao** tentar fazer um framework ultra generico de modalidade de uma vez
- **sim** separar o que e catalogo, o que e regra, o que e projeção e o que e side effect
- **sim** usar o futsal atual como primeira implementacao de um motor por estrategia
- **sim** corrigir primeiro a governanca do banco, porque hoje existe risco real de drift e dificuldade de reproducao

A melhor forma de validar que a arquitetura nova esta certa e:

1. estabilizar o banco
2. extrair o motor de futsal
3. implementar uma segunda modalidade usando o novo desenho

Se a segunda modalidade entrar sem alterar o servico central de partidas, a refatoracao tera atingido o objetivo correto.
