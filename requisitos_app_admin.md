# Documento de Requisitos: App Administrativo e de Arbitragem (Kyarem)

Este documento descreve os requisitos funcionais e não funcionais para o aplicativo Administrativo e de Arbitragem do ecossistema Kyarem. O foco é estabelecer as regras de negócio, fluxos de permissão, integrações arquiteturais e o sistema de apito em tempo real.

---

## 1. Atores do Sistema

*   **Administrador (Admin):** Usuário com privilégios máximos. Responsável pela gestão estrutural (campeonatos, modalidades, atléticas, papéis) e gestão de partidas.
*   **Árbitro (Referee):** Usuário focado na operação das partidas. Pode criar, visualizar e apitar jogos, bem como gerenciar a súmula em tempo real.

---

## 2. Requisitos Funcionais (RF)

### 2.1. Autenticação e Gestão de Acesso
*   **RF01 - Login Restrito:** O sistema deve permitir o login apenas para usuários com os papéis de `Admin` ou `Árbitro`.
*   **RF02 - Redefinição de Senha:** O sistema deve fornecer um fluxo seguro para a redefinição de senha através do e-mail.
*   **RF03 - Bloqueio de Cadastro (Sign Up):** O aplicativo **não** deve possuir tela ou rota para autocadastro. A criação de contas é feita exclusivamente por convite/criação via Admins.

### 2.2. Gestão de Partidas
*   **RF04 - Visualização de Partidas:** Admins e Árbitros devem conseguir visualizar o catálogo e a lista de partidas do sistema.
*   **RF05 - Criação de Partidas:** Admins e Árbitros devem conseguir criar novas partidas. O fluxo de criação exige a seleção obrigatória de:
    *   Campeonato
    *   Modalidade (previamente cadastrada e associada ao campeonato)
    *   Times (Equipe A e Equipe B)
*   **RF06 - Edição de Partidas e Atribuição de Árbitros:** A edição dos detalhes de uma partida e a adição de outros árbitros para apitar aquele jogo deve ser restrita **exclusivamente** ao usuário (Admin ou Árbitro) que **criou** a partida.

### 2.3. Funcionalidades Administrativas (Exclusivo Admins)
*   **RF07 - Gestão de Campeonatos:** Admins devem conseguir criar e editar Campeonatos.
*   **RF08 - Gestão de Atléticas:** Admins devem conseguir criar e editar Atléticas (organizações estudantis/times).
*   **RF09 - Gestão de Papéis e Usuários:** Admins devem conseguir criar perfis para Árbitros, Presidentes de Atlética ou Dirigentes. O sistema deve permitir:
    *   Criar um novo usuário do zero e associá-lo ao papel.
    *   Vincular um usuário já existente no sistema a um desses papéis.
*   **RF10 - Gestão de Modalidades:** Admins devem conseguir cadastrar modalidades esportivas e associá-las aos respectivos campeonatos.

### 2.4. Módulo de Apito em Tempo Real (Súmula Digital)
*   **RF11 - Operação Multi-modalidade:** O sistema de apito deve suportar a operação de partidas de diferentes modalidades esportivas, adaptando as regras e métricas necessárias.
*   **RF12 - Registro de Eventos:** Árbitros devem conseguir registrar eventos do jogo em tempo real (ex: gols, pontos, faltas, cartões, substituições).
*   **RF13 - Resumo Estatístico:** Durante a partida, a interface deve exibir um resumo estatístico em tempo real de cada jogador em campo.
*   **RF14 - Pênaltis/Shootouts:** O módulo de apito deve possuir suporte e tela dedicada para a cobrança de pênaltis, acionada quando o empate persistir e as regras do campeonato exigirem.
*   **RF15 - Encerramento e Fechamento de Súmula:** O árbitro deve ser capaz de encerrar oficialmente a partida, gerando e fechando a súmula final de forma imutável.

---

## 3. Requisitos Não Funcionais (RNF)

### 3.1. Arquitetura e Integração (CRÍTICO)
*   **RNF01 - Isolamento do Supabase:** O aplicativo Administrativo **NUNCA** deve se comunicar diretamente com a API do Supabase (BaaS). Toda e qualquer comunicação, **incluindo as rotas de Autenticação (Login, Redefinição de Senha)**, deve transitar exclusivamente pelo Backend (API Java/Spring Boot). O Backend atuará como gateway e orquestrador.

### 3.2. Sincronização e Tempo Real
*   **RNF02 - Sincronização Multi-Árbitro:** Se múltiplos árbitros estiverem apitando a mesma partida, os eventos registrados por um devem ser sincronizados e refletidos na tela dos demais em tempo real (via WebSockets/SSE gerenciados pelo Backend).
*   **RNF03 - Sincronização com Clientes Externos:** Eventos de tempo real registrados no app Admin devem ser propagados (via Outbox Pattern e WebSockets do Backend) para o aplicativo dos torcedores.

### 3.3. Resiliência e Manutenção de Estado
*   **RNF04 - Recuperação de Estado (State Recovery):** O aplicativo deve suportar que o árbitro minimize o app, troque de tela ou até mesmo sofra uma desconexão ou fechamento acidental. Ao retornar para a tela da partida, o app deve reconstruir **todo o estado atual e cronômetro** de forma precisa, baseando-se no snapshot e eventos cacheados ou recebidos do backend.
*   **RNF05 - Consistência Offline-First (Parcial):** O sistema deve lidar graciosamente com breves quedas de conexão de internet durante a partida, permitindo que os eventos locais sejam enfileirados e sincronizados com o backend assim que a rede for restabelecida.

---

> [!IMPORTANT]
> **Atenção à Arquitetura:** O **RNF01** é o princípio arquitetural mais restritivo. Mesmo usando o SDK do Supabase no Flutter (como visto no `main.dart` atual), ele deve ser configurado apenas para gerenciamento de sessão local ou deve ser totalmente removido em favor de chamadas HTTP diretas para a API do backend Spring Boot, que fará o proxy da autenticação para o Supabase.

> [!TIP]
> Para o **RNF04 (Recuperação de Estado)** e **RNF02 (Sincronização)**, é recomendado utilizar uma arquitetura orientada a eventos no Flutter (como BLoC ou Riverpod) ouvindo um Stream de eventos via WebSocket, aliado a um Snapshot inicial fornecido via API REST ao carregar a tela da partida.
