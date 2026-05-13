-- =============================================================================
-- V1 - Inicializacao dos schemas e extensoes
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS operational;
CREATE SCHEMA IF NOT EXISTS public;
