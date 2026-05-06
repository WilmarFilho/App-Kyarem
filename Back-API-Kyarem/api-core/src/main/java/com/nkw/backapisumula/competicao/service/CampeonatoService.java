package com.nkw.backapisumula.competicao.service;

import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class CampeonatoService {

    private static final Logger log = LoggerFactory.getLogger(CampeonatoService.class);

    private final CampeonatoRepository repo;
    private final JdbcTemplate jdbc;

    public CampeonatoService(CampeonatoRepository repo, JdbcTemplate jdbc) {
        this.repo = repo;
        this.jdbc = jdbc;
    }

    public List<Campeonato> list() {
        return repo.findAll();
    }

    public Campeonato getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalArgumentException("Campeonato não encontrado."));
    }

    @Transactional
    public Campeonato create(Campeonato c) {
        c.setNome(c.getNome().trim());
        if (c.getNivel() != null) c.setNivel(c.getNivel().trim());
        if (c.getEscudoUrl() != null) c.setEscudoUrl(c.getEscudoUrl().trim());
        if (c.getStatus() == null) c.setStatus("AGENDADO");
        c.setCriadoEm(OffsetDateTime.now());
        Campeonato saved = repo.save(c);
        replicarParaPublic(saved);
        return saved;
    }

    @Transactional
    public Campeonato update(UUID id, Campeonato patch) {
        Campeonato c = getOrThrow(id);
        if (patch.getNome() != null) c.setNome(patch.getNome().trim());
        if (patch.getNivel() != null) c.setNivel(patch.getNivel().trim());
        if (patch.getDataInicio() != null) c.setDataInicio(patch.getDataInicio());
        if (patch.getDataFim() != null) c.setDataFim(patch.getDataFim());
        if (patch.getEscudoUrl() != null) c.setEscudoUrl(patch.getEscudoUrl().trim());
        if (patch.getStatus() != null) c.setStatus(patch.getStatus().trim());
        Campeonato saved = repo.save(c);
        replicarParaPublic(saved);
        return saved;
    }

    @Transactional
    public void delete(UUID id) {
        Campeonato c = getOrThrow(id);
        repo.delete(c);
        removerDoPublic(id);
    }

    // -------------------------------------------------------------------------
    // Replicação para o schema public (lido pelo App Público via Supabase SDK)
    // -------------------------------------------------------------------------

    /**
     * Faz UPSERT de um campeonato em public.campeonatos_vitrine.
     * Chamado sempre que um campeonato é criado ou atualizado.
     */
    private void replicarParaPublic(Campeonato c) {
        String sql = """
                INSERT INTO public.campeonatos_vitrine (
                    campeonato_id, nome, slug, escudo_url,
                    data_inicio, data_fim, status, atualizado_em
                ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
                ON CONFLICT (campeonato_id) DO UPDATE SET
                    nome          = EXCLUDED.nome,
                    slug          = EXCLUDED.slug,
                    escudo_url    = EXCLUDED.escudo_url,
                    data_inicio   = EXCLUDED.data_inicio,
                    data_fim      = EXCLUDED.data_fim,
                    status        = EXCLUDED.status,
                    atualizado_em = NOW()
                """;
        try {
            jdbc.update(sql,
                    c.getId(),
                    c.getNome(),
                    null,
                    c.getEscudoUrl(),
                    c.getDataInicio(),
                    c.getDataFim(),
                    c.getStatus()
            );
            log.info("Campeonato {} replicado para public.campeonatos_vitrine", c.getId());
        } catch (Exception ex) {
            log.error("Falha ao replicar campeonato {} para public: {}", c.getId(), ex.getMessage());
            throw ex;
        }
    }

    private void removerDoPublic(UUID id) {
        jdbc.update("DELETE FROM public.campeonatos_vitrine WHERE campeonato_id = ?", id);
        log.info("Campeonato {} removido de public.campeonatos_vitrine", id);
    }
}
