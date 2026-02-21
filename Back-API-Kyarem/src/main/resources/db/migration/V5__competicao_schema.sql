-- Criação idempotente das tabelas de competição (para ambientes novos).
-- Observação: em ambientes Supabase já existentes, esses comandos não alteram o schema.

CREATE TABLE IF NOT EXISTS public.campeonatos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  nivel_campeonato text,
  data_inicio date,
  data_fim date,
  criado_em timestamp with time zone DEFAULT now(),
  CONSTRAINT campeonatos_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.modalidades (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  campeonato_id uuid,
  campeonato_nome text,
  esporte_id uuid,
  nome text NOT NULL,
  tempo_partida_minutos integer DEFAULT 40,
  regras_json jsonb,
  criado_em timestamp with time zone DEFAULT now(),
  CONSTRAINT modalidades_pkey PRIMARY KEY (id),
  CONSTRAINT modalidades_campeonato_id_fkey FOREIGN KEY (campeonato_id) REFERENCES public.campeonatos(id),
  CONSTRAINT modalidades_esporte_id_fkey FOREIGN KEY (esporte_id) REFERENCES public.esportes(id)
);

CREATE TABLE IF NOT EXISTS public.equipes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  atletica_id uuid,
  campeonato_id uuid,
  modalidade_id uuid,
  nome_equipe text NOT NULL,
  criado_em timestamp with time zone DEFAULT now(),
  CONSTRAINT equipes_pkey PRIMARY KEY (id),
  CONSTRAINT equipes_atletica_id_fkey FOREIGN KEY (atletica_id) REFERENCES public.atleticas(id),
  CONSTRAINT equipes_campeonato_id_fkey FOREIGN KEY (campeonato_id) REFERENCES public.campeonatos(id),
  CONSTRAINT equipes_modalidade_id_fkey FOREIGN KEY (modalidade_id) REFERENCES public.modalidades(id)
);

CREATE TABLE IF NOT EXISTS public.equipe_atlet_inscritos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  equipe_id uuid,
  atleta_id uuid,
  numero_camisa integer,
  ativo boolean DEFAULT true,
  CONSTRAINT equipe_atlet_inscritos_pkey PRIMARY KEY (id),
  CONSTRAINT equipe_atlet_inscritos_equipe_id_fkey FOREIGN KEY (equipe_id) REFERENCES public.equipes(id),
  CONSTRAINT equipe_atlet_inscritos_atleta_id_fkey FOREIGN KEY (atleta_id) REFERENCES public.atletas(id)
);
