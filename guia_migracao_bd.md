# Guia de Reset Total do Banco de Dados Kyarem

Conforme definido na nova arquitetura, este documento orienta sobre como **excluir completamente a estrutura antiga** do Supabase e subir as novas migrations (V1 a V9) que implementam o padrão de Schemas Isolados e Event-Driven.

## 1. Exclusão do Banco Atual

> [!WARNING]  
> **PERDA TOTAL DE DADOS:** Este comando apagará tudo o que existe no banco de dados hoje.

Como a sua configuração do MCP Server no arquivo `mcp_config.json` apontou para a URL do Supabase mas não forneceu o `Authorization: Bearer <seu-token>`, o servidor MCP recusou a minha conexão, impedindo que eu mesmo rode o comando.

Para fazer a limpeza de forma segura, abra o **SQL Editor** lá no painel web do Supabase do projeto `hlgnackuzfhkhloemtey` e rode este comando exato:

```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres, public;
```

Isso fará o Supabase voltar a um estado virgem.

## 2. A Nova Estrutura de Migrations

Apaguei as 12 migrations antigas que você tinha e escrevi 9 migrations totalmente novas, separadas por domínio, localizadas em `api-core/src/main/resources/db/migration/`:

1. `V1__init_schemas_and_extensions.sql` — Cria o esquema `operational`.
2. `V2__operational_identidade.sql` — Perfis e papéis globais.
3. `V3__operational_catalogo_esportivo.sql` — Esportes, modalidades e tipos de eventos.
4. `V4__operational_atleticas_e_atletas.sql` — Entidades base da estrutura da atlética.
5. `V5__operational_campeonatos_e_times.sql` — Inscrições, campeonatos e vínculos.
6. `V6__operational_partidas_e_arbitragem.sql` — Motor de jogo e sumula.
7. `V7__operational_outbox_events.sql` — A tabela fila de mensagens transacional do sistema.
8. `V8__public_application_logs.sql` — A tabela onde TODOS os containers gravarão logs (Recriada intacta).
9. `V9__public_read_models.sql` — Vitrines e modelos desnormalizados para leitura do app.

## 3. Como Aplicar

Após rodar o script de exclusão no painel do Supabase, você só precisa iniciar a API Core localmente ou fazer um push para o GitHub Actions. 
Como o módulo `api-core` roda o Flyway ao iniciar, ele detectará o banco virgem e aplicará todos os novos 9 arquivos sequencialmente.

> [!TIP]  
> Se quiser ver o estado final do schema antes de subir, você pode rodar `./gradlew :api-core:flywayMigrate` no seu terminal, desde que as variáveis no seu `.env` apontem corretamente para o seu Supabase.
