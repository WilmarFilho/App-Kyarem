-- Habilita extensões essenciais no banco de dados (public já possui por padrão)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Criação do Schema Operational
-- Todo o tráfego transacional de comandos (gravação) vai focar neste schema.
CREATE SCHEMA IF NOT EXISTS operational;

-- Garantir acesso para o supabase
GRANT USAGE ON SCHEMA operational TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA operational TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA operational TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA operational TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA operational GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA operational GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA operational GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
