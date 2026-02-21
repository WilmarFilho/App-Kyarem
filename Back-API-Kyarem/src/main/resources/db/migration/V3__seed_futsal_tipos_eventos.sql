-- Seed: Futsal + catálogo fechado de eventos (MVP)
INSERT INTO esportes (nome)
VALUES ('Futsal')
ON CONFLICT (nome) DO NOTHING;

-- Captura o id do futsal
DO $$
DECLARE
    futsal_id UUID;
BEGIN
    SELECT id INTO futsal_id FROM esportes WHERE nome = 'Futsal';

    -- Tipos de eventos (MVP)
    INSERT INTO tipos_eventos (esporte_id, nome) VALUES
      (futsal_id, 'INICIO_1_TEMPO'),
      (futsal_id, 'FIM_1_TEMPO'),
      (futsal_id, 'INICIO_2_TEMPO'),
      (futsal_id, 'FIM_PARTIDA'),
      (futsal_id, 'GOL'),
      (futsal_id, 'FALTA'),
      (futsal_id, 'CARTAO_AMARELO'),
      (futsal_id, 'CARTAO_VERMELHO'),
      (futsal_id, 'SUBSTITUICAO'),
      (futsal_id, 'PENALTI_MARCADO'),
      (futsal_id, 'PENALTI_CONVERTIDO'),
      (futsal_id, 'PENALTI_PERDIDO'),
      (futsal_id, 'TIRO_LIVRE_DIRETO'),
      (futsal_id, 'PEDIDO_TEMPO'),
      (futsal_id, 'WO')
    ON CONFLICT (esporte_id, nome) DO NOTHING;
END $$;
