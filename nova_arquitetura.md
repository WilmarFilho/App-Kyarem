# KYAREM - NOVA ARQUITETURA E NOVA ESTRUTURA DE BANCO

## Objetivo
Consolidar a evolucao do sistema para suportar:
- uma unica base de autenticacao em auth.users
- app global como unica porta de cadastro
- app do campeonato sem cadastro, apenas login e autorizacao contextual
- app admin apenas para perfis administrativos e arbitros
- multiplos campeonatos
- multiplos esportes e multiplas modalidades do mesmo esporte
- operacao critica de arbitragem com escrita consistente
- leitura publica desacoplada via read models e realtime


## 1. ARQUITETURA GERAL
Arquitetura recomendada:
- backend principal em Spring Boot
- banco principal no Supabase Cloud (Postgres)
- separacao logica entre schema operacional e schema publico
- eventos de dominio para atualizar leituras publicas, metricas e realtime
- realtime proprio via SSE

Fluxo principal:
1. Admin/arbitro envia acao para a API
2. API valida a regra de negocio
3. API grava no banco operacional
4. API registra evento na outbox
5. publicador envia evento para o broker
6. workers atualizam projeções publicas e metricas
7. gateway realtime envia update SSE para apps publicos

Principio:
- operacoes criticas ficam sincronas entre app admin -> API -> banco
- efeitos derivados ficam assincronos via eventos


## 2. CONTAINERS/SERVICOS
Servicos principais:
- api-core
  Backend principal. Centraliza regra de negocio, escrita critica, autenticacao/autorizacao e API publica.

- rabbitmq
  Broker para propagacao de eventos internos.

- outbox-publisher
  Le eventos gravados na outbox e publica no broker de forma segura.

- projection-worker
  Atualiza tabelas/read models do schema publico.

- metrics-worker
  Processa ranking, estatisticas e consolidacoes.

- realtime-gateway
  Mantem conexoes SSE com apps publicos e envia atualizacoes quando os dados publicos mudam.

Infra externa:
- Supabase Cloud
  auth.users + Postgres principal.
  O app geral le o schema public diretamente via Supabase SDK com RLS.
  RLS policies garantem que cada usuario opera apenas seus proprios dados.


## 3. FLUXO DE IDENTIDADE E ACESSO
Regra principal de Cadastro:
- Uma pessoa comum SO pode se cadastrar primeiramente atraves do App Global.
- Todo cadastro no App Global cria a conta OBRIGATORIAMENTE com a role global USER.
- Contas administrativas (ADMIN) sao criadas APENAS internamente (fluxo restrito/scripts).
- Nenhuma outra role e concedida no momento do cadastro. Os demais acessos (contextuais ou elevacoes globais) sao sempre atribuidos posteriormente a essa conta USER base.

Apps:
- App global
  Unico local publico de cadastro. Login de qualquer pessoa.
  Local onde o presidente/dirigente faz toda a GESTAO da sua atletica (criar times, convocar/escalar atletas, gerir elenco permanente).

- App do campeonato
  Sem cadastro publico.
  Login de qualquer pessoa para acompanhamento e consumo de dados publicos.
  Para presidentes/dirigentes, e o local usado exclusivamente para INSCREVER seus times (ja criados no app global) no torneio atual.

- App admin
  Sem cadastro publico.
  Login permitido APENAS para administradores (role global ADMIN) e arbitros (role contextual REFEREE).

Papeis globais:
- USER
- ADMIN

Papeis contextuais:
- PRESIDENT
- DIRECTOR
- ATHLETE
- REFEREE

Regra de promocao:
- presidente e dirigente se cadastram como USER no app global
- depois recebem papel contextual internamente
- atleta tambem nasce como USER
- quando for convocado, passa a ter vinculo contextual de atleta


## 4. MODELAGEM CONCEITUAL DO BANCO
Separacao de schemas:
- operational
  Tabelas transacionais e de dominio.

- public
  Tabelas de leitura publica, read models e dados para apps publicos.

Observacao:
- auth.users continua no schema auth do Supabase
- operational.profiles referencia auth.users


## 5. ESTRUTURA DO SCHEMA OPERATIONAL

## 5.1 Identidade e autorizacao
auth.users
- tabela nativa do Supabase
- conta de autenticacao unica por pessoa

operational.profiles
- 1:1 com auth.users
- dados basicos do usuario
- id = auth.users.id

Campos principais:
- id
- nome_completo
- nome_exibicao
- email
- telefone
- avatar_url
- status
- criado_em
- atualizado_em

operational.roles_globais
- catalogo de papeis globais

Valores:
- USER
- ADMIN

operational.usuarios_roles_globais
- vinculo usuario -> papel global

Relacionamento:
- profiles 1:N usuarios_roles_globais
- roles_globais 1:N usuarios_roles_globais

operational.papeis_contexto
- catalogo de papeis contextuais

Valores:
- PRESIDENT
- DIRECTOR
- ATHLETE
- REFEREE

operational.quadro_arbitros
- vinculo do usuario com o quadro de arbitragem
- materializa a existencia do papel contextual REFEREE antes de qualquer partida

Campos:
- id
- user_id
- status
- criado_por
- criado_em

Regra:
- um usuario continua sendo globalmente USER ou ADMIN
- o fato de ele poder atuar como arbitro fica registrado aqui, e nao em role global
- um arbitro pode existir no sistema sem estar vinculado a nenhuma partida
- somente usuarios com registro ATIVO em operational.quadro_arbitros possuem o papel contextual REFEREE


## 5.2 Estrutura esportiva base
operational.esportes
- tipo macro do esporte

Exemplos:
- futebol
- basquete
- volei

operational.modalidades_catalogo
- modalidades reais derivadas de um esporte

Exemplos:
- esporte: futebol
  modalidades: futsal, society, campo

- esporte: volei
  modalidades: quadra, areia

Campos principais:
- id
- esporte_id
- nome
- slug
- genero
- motor_regras
- motor_configs_default
- ativo

Relacionamento:
- esportes 1:N modalidades_catalogo

Interpretacao correta:
- esporte = macro categoria
- modalidade_catalogo = disciplina/modalidade concreta
- campeonato_modalidades = configuracao daquela modalidade dentro de um campeonato especifico


## 5.3 Campeonatos e modalidades por campeonato
operational.campeonatos
- campeonato base

Campos:
- id
- nome
- nivel
- data_inicio
- data_fim
- status
- escudo_url
- criado_em

operational.campeonato_modalidades
- instancia da modalidade dentro do campeonato
- permite regras diferentes por campeonato

Campos principais:
- id
- campeonato_id
- modalidade_catalogo_id
- nome_exibicao
- categoria
- genero
- regras_json
- formato_fases_json
- tempo_partida_minutos
- permite_prorrogacao
- permite_penaltis
- status

Exemplo:
- Campeonato 2026
- modalidade_catalogo = futsal
- categoria = masculino
- genero = universitario
- regras_json especificas do campeonato

Relacionamentos:
- campeonatos 1:N campeonato_modalidades
- modalidades_catalogo 1:N campeonato_modalidades


## 5.4 Atleticas, membros e atletas
operational.atleticas
- entidade principal da atletica

Campos:
- id
- nome
- sigla
- slug
- cor_principal
- escudo_url
- criado_por
- criado_em
- status

Regra:
- presidente/dirigente pode criar uma ou varias atleticas

operational.atletas
- extensao de um profile para contexto esportivo

Campos:
- id
- user_id
- nome_competicao
- foto_url
- data_nascimento
- genero
- ativo
- criado_em

Regra:
- user_id unico
- um usuario comum so vira atleta quando houver esse registro + vinculos contextuais

operational.atletica_membros
- vinculo entre usuario e atletica
- armazena papeis contextuais na atletica e gerencia a convocacao de novos membros

Campos:
- id
- atletica_id
- user_id
- papel_codigo
- status             (CONVOCADO | ATIVO | INATIVO | RECUSADO)
- criado_por
- criado_em

Usos:
- PRESIDENT de uma atletica
- DIRECTOR de uma atletica
- ATHLETE vinculado estruturalmente a uma atletica

Regras importantes:
- um usuario pode ter mais de um papel na mesma atletica se a regra permitir
- deve existir no maximo um PRESIDENT ativo por atletica


## 5.4.1 Quadro de arbitragem
operational.quadro_arbitros
- registro operacional dos usuarios aptos a arbitrar
- separa claramente "ser arbitro" de "estar escalado em uma partida"

Campos:
- id
- user_id
- status                 (ATIVO | INATIVO | SUSPENSO)
- criado_por
- criado_em

Usos:
- marcar um usuario como arbitro no sistema antes de qualquer escala
- controlar ativacao, inativacao ou suspensao do arbitro
- servir como fonte oficial para listar arbitros no app admin

Regra:
- o usuario permanece com suas roles globais originais
- o papel contextual REFEREE existe quando houver vinculo ATIVO nesta tabela
- estar em operational.partida_arbitros nao cria o arbitro; apenas representa uma escala/autorizacao para uma partida especifica


## 5.5 Participacao da atletica no campeonato
operational.campeonato_atleticas
- vinculo da atletica com o campeonato

Campos:
- id
- campeonato_id
- atletica_id
- criado_em

Relacionamento:
- campeonatos N:N atleticas via campeonato_atleticas


## 5.6 Times da atletica
operational.times_atletica
- times permanentes da atletica por modalidade

Campos:
- id
- atletica_id
- modalidade_catalogo_id
- nome
- categoria
- genero
- status
- criado_por
- criado_em

Exemplos:
- Atletica A / futsal masculino
- Atletica A / volei feminino

Observacao:
- a composicao de atletas por time nao e mais mantida em tabela propria.
- o vinculo atleta -> time passa a existir somente em `operational.campeonato_atletas`, no contexto do campeonato.


## 5.7 Inscricao de times e roster no campeonato
operational.campeonato_times
- time da atletica inscrito em uma modalidade especifica do campeonato

Campos:
- id
- campeonato_id
- campeonato_atletica_id
- campeonato_modalidade_id
- time_atletica_id
- status
- criado_em

Relacionamentos:
- campeonato_atleticas 1:N campeonato_times
- campeonato_modalidades 1:N campeonato_times
- times_atletica 1:N campeonato_times

operational.campeonato_atletas
- roster final do atleta no campeonato
- e a fonte unica da relacao atleta -> time dentro do campeonato

Campos:
- id
- campeonato_id
- atletica_id
- campeonato_time_id
- atleta_id
- status
- numero_camisa
- is_capitao
- is_goleiro
- inscrito_em

Regra critica:
- um atleta nao pode jogar por mais de uma atletica no mesmo campeonato

Implementacao:
- unique parcial em (campeonato_id, atleta_id)
  considerando status ativos
  
Esse ponto resolve a regra:
"nao pode um atleta jogar em mais de uma atletica por campeonato"


## 5.8 Staff do time
operational.equipes_staff
- staff de apoio do time no campeonato

Campos:
- id
- campeonato_time_id
- user_id nullable
- cargo
- criado_em

Observacao:
- o nome do staff deve ser resolvido pelo profile vinculado em `user_id`


## 5.9 Tipos de eventos e regras de partida
operational.tipos_eventos
- catalogo de eventos por modalidade
- os eventos sao rigorosamente separados por "escopo" para diferenciar acoes gerais da partida de acoes desportivas

Campos:
- id
- modalidade_catalogo_id
- codigo
- nome
- escopo                 (PARTIDA | EQUIPE | ATLETA)
- impacta_placar
- pontos_pro             (pontos para a equipe que gerou o evento)
- pontos_contra          (pontos para a equipe adversaria)
- payload_schema_json
- ordem_exibicao
- ativo

Separacao dos Escopos:
1. EVENTOS DE PARTIDA (Gerais): Nao envolvem times ou atletas, gerenciam o relogio e o estado.
   Exemplos: INICIO_1_TEMPO, FIM_1_TEMPO, PAUSA_MEDICA.
2. EVENTOS DE EQUIPE: Pertencem a um time, mas nao a um individuo especifico.
   Exemplos: TIMEOUT_PEDIDO, PONTO_CONTRA, FALTA_TECNICA_BANCO.
3. EVENTOS DE ATLETA: Acoes diretas de um jogador em quadra/campo.
   Exemplos: GOL, CESTA, CARTAO_AMARELO, SUBSTITUICAO.

Isso orienta a API a exigir (ou ignorar) equipe_id e atleta_id dependendo do escopo do evento.

Exemplo:
- futsal tem eventos diferentes de futebol de campo
- volei tem eventos diferentes de basquete

Relacionamento:
- modalidades_catalogo 1:N tipos_eventos


## 5.10 Partidas e arbitragem
operational.partidas
- agregado principal de operacao critica

Campos principais:
- id
- campeonato_id
- campeonato_modalidade_id
- campeonato_time_a_id
- campeonato_time_b_id
- status
- periodo_atual
- status_antes_pausa
- categoria
- fase
- rodada
- agendado_para
- iniciada_em
- encerrada_em
- local
- placar_a
- placar_b
- snapshot_sumula
- sumula_pdf_url
- hash_integridade
- versao_estado
- criado_por             (user_id do arbitro/admin que criou)
- criado_em
- atualizado_em

Status suportados (Ciclo de Vida Macro):
- AGENDADA
- EM_ANDAMENTO
- INTERVALO
- PAUSADA
- FECHADA          (Sumula encerrada pelo mesario, aguarda assinatura/auditoria)
- FINALIZADA       (Confirmada oficialmente, imutavel)
- CANCELADA
- WO

Observacao sobre periodo_atual:
- Para suportar qualquer esporte sem inflar o Enum de status, o campo `periodo_atual` (String) dita a fase especifica da partida.
- Futsal/Futebol: "1_TEMPO", "2_TEMPO", "PRORROGACAO", "PENALTIS"
- Basquete: "Q1", "Q2", "Q3", "Q4", "OT"
- Volei: "SET1", "SET2", "SET3", "SET4", "TIE_BREAK"
- A API rege o bloqueio de dados pelo `status`, enquanto o app renderiza a tela com base no `periodo_atual`.

Observacao sobre versao_estado:
- Funciona como um controle de concorrencia (Optimistic Locking). Evita que acoes simultaneas de dois arbitros na sumula se sobrescrevam, garantindo a integridade dos dados da partida.
- Auxilia na Sincronizacao Realtime (SSE): os apps publicos utilizam essa versao para saber se perderam algum evento (caso a rede oscile) e, se necessario, disparam um recarregamento completo para manter o placar sempre correto na tela.

operational.partida_arbitros
- arbitros vinculados e autorizados a editar a sumula da partida

Campos:
- id
- partida_id
- arbitro_user_id
- funcao                 (PRINCIPAL | AUXILIAR | MESARIO)
- is_criador             (define se e o dono da partida)
- adicionado_por         (user_id de quem o associou)
- criado_em

Regra:
- Admin global vincula o usuario ao operational.quadro_arbitros, concedendo o papel contextual REFEREE.
- Quando o arbitro cria a partida, ele e automaticamente salvo aqui com `is_criador = true`.
- Apenas o arbitro "criador" da partida (ou um ADMIN) tem permissao para associar outros arbitros a ela.
- Somente os arbitros listados nesta tabela tem acesso de escrita na sumula.
- O arbitro_user_id deve possuir vinculo ATIVO em operational.quadro_arbitros.


## 5.11 Eventos da partida
operational.eventos_partida
- historico auditavel das acoes registradas na sumula

Campos principais:
- id
- partida_id
- tipo_evento_id
- equipe_id
- atleta_id
- atleta_sai_id
- arbitro_user_id
- periodo
- minuto
- segundo
- tempo_cronometro
- descricao_detalhada
- payload_json
- is_substitution
- local_evento_id
- ordem_evento
- criado_em

Regras:
- local_evento_id unico para idempotencia
- ordem_evento garante ordenacao estavel


## 5.12 Outbox para eventos de dominio
operational.outbox_events
- eventos de integracao gravados junto da transacao principal

Campos:
- id
- aggregate_type
- aggregate_id
- event_type
- payload_json
- occurred_at
- published_at
- status
- retry_count

Usos:
- MatchScoreUpdated
- MatchFinished
- ScoreSheetClosed
- RankingRecalculationRequested


## 5.13 Social e notificacoes
Escopo removido do schema operacional nesta arquitetura.

Tabelas removidas:
- operational.posts_sociais
- operational.posts_curtidas
- operational.posts_comentarios
- operational.seguidores
- operational.notificacoes


## 6. ESTRUTURA DO SCHEMA PUBLIC
Esse schema nao deve concentrar regras de negocio.
Ele existe para leitura publica, consulta rapida e realtime.
O app geral consome esse schema diretamente via Supabase SDK com RLS.

Nota sobre pontuacao:
- Campos de pontuacao sao genericos (pontos_pro, pontos_contra, pontuacoes)
- Gols, cestas, pontos, sets — tudo e "pontuacao" no nivel do schema
- Detalhes especificos de cada esporte ficam em campos _json


## 6.1 Vitrine de campeonatos e modalidades
public.campeonatos_vitrine

Campos:
- campeonato_id
- nome
- slug
- escudo_url
- data_inicio
- data_fim
- status
- modalidades_ativas
- atualizado_em

public.modalidades_vitrine

Campos:
- campeonato_modalidade_id
- campeonato_id
- esporte_nome
- modalidade_nome
- nome_exibicao
- categoria
- genero
- status
- atualizado_em


## 6.2 Partidas ao vivo e historico
public.partidas_ao_vivo

Campos:
- partida_id
- campeonato_id
- campeonato_modalidade_id
- time_a_nome
- time_b_nome
- time_a_escudo_url
- time_b_escudo_url
- time_a_atletica_id
- time_b_atletica_id
- time_a_cor_principal
- time_b_cor_principal
- placar_a
- placar_b
- status
- periodo_atual
- cronometro
- local
- agendado_para
- versao_estado
- atualizado_em

public.partidas_historico
- read model completo de partidas encerradas ou finalizadas

Campos:
- partida_id
- campeonato_id
- campeonato_slug
- campeonato_nome
- campeonato_modalidade_id
- esporte_nome
- modalidade_nome
- fase
- rodada
- categoria
- genero
- time_a_id
- time_a_nome
- time_a_sigla
- time_a_escudo_url
- time_a_atletica_id
- time_a_atletica_nome
- time_a_cor_principal
- time_b_id
- time_b_nome
- time_b_sigla
- time_b_escudo_url
- time_b_atletica_id
- time_b_atletica_nome
- time_b_cor_principal
- placar_a
- placar_b
- resultado              (VITORIA_A | EMPATE | VITORIA_B)
- houve_prorrogacao
- houve_penaltis
- placar_penaltis_a
- placar_penaltis_b
- local
- agendado_para
- iniciada_em
- encerrada_em
- duracao_minutos
- sumula_pdf_url
- atualizado_em

public.eventos_partida_publicos
- linha do tempo de eventos de qualquer partida (ao vivo e historico)
- generalizado para qualquer modalidade

Campos:
- evento_id
- partida_id
- tipo_evento_codigo     (ex: GOL, CESTA, PONTO, CARTAO_AMARELO, SUBSTITUICAO, SET_GANHO)
- tipo_evento_nome
- impacta_placar
- equipe_id
- equipe_nome
- equipe_cor
- atleta_id              (nullable)
- atleta_nome_exibicao
- atleta_foto_url
- atleta_sai_id          (nullable — substituicoes)
- atleta_sai_nome
- periodo
- minuto
- segundo
- descricao
- payload_json           (dados extras especificos da modalidade)
- criado_em

public.estatisticas_partida
- estatisticas agregadas por partida via JSON (flexivel por modalidade)

Campos:
- partida_id
- campeonato_modalidade_id
- time_a_id
- time_b_id
- stats_time_a_json      (futsal: finalizacoes/posse/faltas | basquete: arremessos/rebotes | volei: aces/bloqueios)
- stats_time_b_json
- top_atletas_json       (destaques da partida)
- atualizado_em


## 6.3 Classificacoes e rankings
public.classificacoes
- pontuacao generica para suportar qualquer esporte

Campos:
- id
- campeonato_modalidade_id
- atletica_id
- time_id
- time_nome
- escudo_url
- cor_principal
- grupo
- posicao
- pontos
- jogos
- vitorias
- derrotas
- empates
- jogos_em_casa
- jogos_fora
- pontos_pro             (gols no futsal, cestas no basquete, pontos no volei, etc.)
- pontos_contra
- saldo_pontos
- forma_recente_json     (ex: ["V","V","E","D","V"])
- partidas_ids_json
- atualizado_em

public.artilharia
- ranking de pontuadores por modalidade
- gols no futebol, cestas no basquete, pontos no volei — tudo como "pontuacoes"

Campos:
- campeonato_modalidade_id
- atleta_id
- user_id
- nome_exibicao
- foto_url
- atletica_id
- atletica_nome
- atletica_escudo_url
- pontuacoes             (total — gols, cestas, pontos, etc.)
- pontuacoes_json        (breakdown por tipo de evento de pontuacao da modalidade)
- jogos
- minutos_jogados        (quando aplicavel)
- posicao_ranking
- atualizado_em

public.ranking_assistencias
- ranking de assistencias por modalidade

Campos:
- campeonato_modalidade_id
- atleta_id
- user_id
- nome_exibicao
- foto_url
- atletica_id
- atletica_nome
- atletica_escudo_url
- assistencias
- jogos
- posicao_ranking
- atualizado_em

public.ranking_geral_campeonato
- pontuacao consolidada de atleticas across todas as modalidades

Campos:
- campeonato_id
- atletica_id
- atletica_nome
- atletica_sigla
- atletica_escudo_url
- atletica_cor_principal
- pontos_totais
- ouro
- prata
- bronze
- modalidades_participadas
- posicao
- atualizado_em


## 6.4 Perfis publicos
public.metricas_atletas
- metricas publicas agregadas por atleta

Campos:
- atleta_id
- user_id
- nome_exibicao
- foto_url
- atletica_atual_id
- atletica_atual_nome
- atletica_atual_escudo_url
- esportes_json
- campeonatos_participados
- titulos
- metricas_por_campeonato_json
- ultima_partida_em
- atualizado_em

public.perfis_atletas
- perfil publico completo do atleta

Campos:
- atleta_id
- user_id
- nome_exibicao
- foto_url
- genero
- data_nascimento_ano
- bio
- atletica_atual_id
- atletica_atual_nome
- atletica_atual_escudo_url
- atletica_atual_cor
- historico_atleticas_json
- esportes_praticados_json
- campeonatos_json
- stats_carreira_json     (totais por modalidade — genericos)
- atualizado_em

public.perfis_atleticas
- perfil publico da atletica

Campos:
- atletica_id
- nome
- sigla
- slug
- cor_principal
- escudo_url
- bio
- universidade
- cidade
- site_url
- instagram_url
- campeonatos_participados
- titulos_json
- modalidades_ativas_json
- atletas_ativos
- ultima_atividade_em
- atualizado_em


## 6.5 Comparacoes pre-calculadas
public.snapshot_comparacao_atletas
- pre-calculado pelo metrics-worker sob demanda

Campos:
- id
- atleta_a_id
- atleta_b_id
- campeonato_modalidade_id  (nullable — comparacao em contexto ou carreira geral)
- stats_a_json
- stats_b_json
- gerado_em
- valido_ate

public.snapshot_comparacao_times

Campos:
- id
- time_a_id
- time_b_id
- campeonato_modalidade_id
- stats_a_json
- stats_b_json
- confrontos_diretos_json   (historico de partidas entre os dois)
- gerado_em
- valido_ate


## 6.6 Rede Social
Fora de escopo nesta versao da arquitetura.


## 6.7 Timeline ao vivo do campeonato
public.timeline_campeonato
- feed cronologico de eventos relevantes do campeonato

Campos:
- id
- campeonato_id
- tipo_evento             (PONTUACAO | CARTAO | RESULTADO | INICIO_PARTIDA | FIM_PARTIDA | DESTAQUE)
- referencia_partida_id
- referencia_time_id
- referencia_atleta_id
- titulo
- descricao_curta
- payload_json
- ocorrido_em
- atualizado_em

Fluxo:
- projection-worker popula todas as tabelas do schema public
- app geral le via Supabase SDK com RLS
- realtime-gateway envia mudancas via SSE a partir das tabelas criticas


## 7. RELACIONAMENTOS PRINCIPAIS
Identidade:
- auth.users 1:1 operational.profiles
- operational.profiles 1:N operational.usuarios_roles_globais

Contexto de atletica:
- operational.atleticas 1:N operational.atletica_membros
- operational.profiles 1:N operational.atletica_membros

Contexto de arbitragem:
- operational.profiles 1:N operational.quadro_arbitros
- operational.quadro_arbitros 1:N operational.partida_arbitros (por user_id, de forma logica)

Estrutura esportiva:
- operational.esportes 1:N operational.modalidades_catalogo
- operational.modalidades_catalogo 1:N operational.campeonato_modalidades

Campeonato:
- operational.campeonatos 1:N operational.campeonato_modalidades
- operational.campeonatos 1:N operational.campeonato_atleticas
- operational.campeonatos 1:N operational.campeonato_times
- operational.campeonatos 1:N operational.campeonato_atletas
- operational.campeonatos 1:N operational.partidas

Atletica e times:
- operational.atleticas 1:N operational.times_atletica
- operational.campeonato_atleticas 1:N operational.campeonato_times
- operational.times_atletica 1:N operational.campeonato_times

Atletas:
- operational.profiles 1:0..1 operational.atletas
- operational.atletas 1:N operational.campeonato_atletas

Partidas:
- operational.campeonato_modalidades 1:N operational.partidas
- operational.campeonato_times 1:N operational.partidas como time A
- operational.campeonato_times 1:N operational.partidas como time B
- operational.partidas 1:N operational.partida_arbitros
- operational.partidas 1:N operational.eventos_partida

Eventos:
- operational.modalidades_catalogo 1:N operational.tipos_eventos
- operational.tipos_eventos 1:N operational.eventos_partida

Leitura publica:
- operational.campeonatos         -> public.campeonatos_vitrine
- operational.campeonato_modalidades -> public.modalidades_vitrine
- operational.partidas            -> public.partidas_ao_vivo
- operational.partidas            -> public.partidas_historico
- operational.eventos_partida     -> public.eventos_partida_publicos
- operational.partidas            -> public.estatisticas_partida
- operational.campeonato_times    -> public.classificacoes
- operational.campeonato_times    -> public.artilharia
- operational.campeonato_times    -> public.ranking_assistencias
- operational.campeonatos         -> public.ranking_geral_campeonato
- operational.atletas             -> public.metricas_atletas
- operational.atletas             -> public.perfis_atletas
- operational.atleticas           -> public.perfis_atleticas
- operational.atletas             -> public.snapshot_comparacao_atletas
- operational.campeonato_times    -> public.snapshot_comparacao_times
- operational.partidas            -> public.timeline_campeonato


## 8. DIFERENCAS IMPORTANTES EM RELACAO AO BANCO ATUAL
Banco atual observado:
- profiles.role simplifica demais o modelo
- modalidades hoje esta ligada diretamente ao campeonato
- tipos_eventos hoje esta ligado ao esporte, nao a modalidade concreta
- atletas hoje nao estao claramente ligados a auth.users
- equipes hoje ja nascem por campeonato/modalidade

Evolucao proposta:
- remover dependencia de um unico campo profiles.role
- separar roles globais e papeis contextuais
- manter auth.users como identidade unica
- introduzir operational.atletas como extensao esportiva do usuario
- separar:
  esporte -> modalidade_catalogo -> campeonato_modalidade
- transformar equipe atual em duas camadas:
  times_atletica -> campeonato_times
- mover leitura publica para schema public
- padronizar partida como agregado principal da arbitragem


## 9. FLUXOS DE NEGOCIO IMPORTANTES
9.1 Cadastro de usuario comum (App Global)
1. usuario acessa o app global
2. realiza o cadastro (unico fluxo publico permitido para criacao de conta)
3. entra em auth.users
4. cria operational.profiles
5. recebe OBRIGATORIAMENTE a role global USER

9.1.1 Cadastro de Administradores (Interno)
1. Operacao restrita feita internamente fora do fluxo do app publico
2. Usuario recebe a role global ADMIN

9.2 Criacao da atletica e diretoria (App Administrativo)
1. Admin do sistema acessa o app administrativo
2. Admin cria a entidade atletica (operational.atleticas)
3. Admin seleciona ou cria um usuario
4. Admin associa esse usuario com o papel PRESIDENT ou DIRECTOR em operational.atletica_membros

9.3 Convocacao de atletas para a atletica (App Global)
1. presidente/dirigente acessa o app global
2. convoca usuarios comuns para fazerem parte da sua atletica
3. cria registro em operational.atletica_membros com papel ATHLETE e status CONVOCADO
4. se o usuario aceitar, status muda para ATIVO (e se torna operational.atletas caso ainda nao seja)

9.4 Criacao de times (App Global)
1. presidente/dirigente cria os times permanentes (times_atletica) por modalidade_catalogo

9.5 Inscricao no campeonato (App Campeonato)
1. presidente/dirigente entra no app do campeonato
2. inscreve os times da atletica nas modalidades do campeonato (cria campeonato_times)
3. o roster oficial do time no campeonato fica em `campeonato_atletas`, que passa a ser a fonte unica do vinculo atleta -> time
4. unique parcial impede o mesmo atleta em duas atleticas no mesmo campeonato

9.6 Criacao de Partidas e Equipe de Arbitragem (App Administrativo)
1. Admin interno adiciona o usuario ao operational.quadro_arbitros
2. O arbitro acessa o app administrativo e cria uma partida (selecionando modalidade e times)
3. O banco salva a partida e insere o arbitro em `partida_arbitros` como `is_criador = true`
4. O arbitro "criador" gerencia sua mesa, adicionando outros usuarios (tambem REFEREEs) a partida
5. A partir desse momento, todos dessa equipe podem registrar acoes na sumula simultaneamente

9.7 Operacao de arbitragem
1. arbitro (autorizado em partida_arbitros) envia acao para API
2. API grava no schema operational
3. API registra evento na outbox
4. workers atualizam schema public
5. realtime-gateway envia atualizacao SSE

9.8 Fechamento de sumula
1. arbitro envia comando para fechar a partida pela API
2. API valida consistencia
3. API fecha a partida/sumula no banco
4. API publica evento na outbox
5. workers atualizam classificacoes, metricas e visoes publicas

## 10. DECISOES TECNICAS FINAIS
1. Nao usar o realtime nativo do banco como peca central de longo prazo.
2. Manter escrita critica do admin sempre via API.
3. Usar eventos apenas como consequencia da escrita persistida.
4. Separar leitura publica da escrita operacional.
5. Modelar esporte e modalidade em niveis diferentes.
6. Modelar papeis globais e contextuais separadamente.
7. Permitir que todo usuario acesse o app do campeonato, mas restringir acoes por contexto.
8. Garantir por banco que atleta nao joga por duas atleticas no mesmo campeonato.
9. Deixar o schema public preparado para apps publicos e SSE.
10. Manter compatibilidade conceitual com as entidades atuais de campeonato, modalidade, equipe, partida e evento, mas com estrutura mais forte para crescimento.
11. O app geral nao tem acesso direto a api-core. Consome o schema public via Supabase SDK com RLS.
12. Campos de pontuacao sao sempre genericos no schema public. Especificidades de cada esporte ficam em campos _json para suportar qualquer modalidade.


## 11. RESUMO EXECUTIVO
O novo desenho passa a ter:
- identidade unica em auth.users
- profiles como extensao da conta
- roles globais para USER e ADMIN
- papeis contextuais para PRESIDENT, DIRECTOR, ATHLETE e REFEREE
- quadro de arbitragem proprio para representar arbitros antes de qualquer escala em partida
- atleticas e times organizados por modalidade_catalogo
- campeonato com modalidades configuraveis por regras proprias
- atleta vinculado a usuario, mas operando por entidade esportiva propria
- partidas e eventos como nucleo da operacao de arbitragem
- schema operational para transacao e escrita critica
- schema public para leitura publica, metricas e realtime
- arquitetura orientada a eventos para propagacao, sem abrir mao da consistencia nas operacoes criticas
- app geral consome Supabase SDK diretamente (sem api-core) para leitura publica
- campos de pontuacao genericos no schema public para suportar todos os esportes e modalidades
- comparacoes entre atletas e times pre-calculadas pelo metrics-worker
- perfis publicos ricos de atletas e atleticas
- historico completo de partidas e eventos acessivel pelo app geral
- timeline ao vivo do campeonato com eventos relevantes agregados
