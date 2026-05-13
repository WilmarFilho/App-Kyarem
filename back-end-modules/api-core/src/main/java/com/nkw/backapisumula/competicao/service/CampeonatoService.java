package com.nkw.backapisumula.competicao.service;

import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.common.outbox.EventPublisherService;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class CampeonatoService {

    private static final Logger log = LoggerFactory.getLogger(CampeonatoService.class);

    private final CampeonatoRepository repo;
    private final EventPublisherService eventPublisherService;

    public CampeonatoService(CampeonatoRepository repo, EventPublisherService eventPublisherService) {
        this.repo = repo;
        this.eventPublisherService = eventPublisherService;
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
        publishCampeonatoEvent(saved, "CampeonatoCriado");
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
        publishCampeonatoEvent(saved, "CampeonatoAtualizado");
        return saved;
    }

    @Transactional
    public void delete(UUID id) {
        Campeonato c = getOrThrow(id);
        repo.delete(c);
        eventPublisherService.publish("Campeonato", id.toString(), "CampeonatoExcluido", java.util.Map.of());
    }

    private void publishCampeonatoEvent(Campeonato campeonato, String eventType) {
        eventPublisherService.publish("Campeonato", campeonato.getId().toString(), eventType, java.util.Map.of(
                "campeonatoId", campeonato.getId().toString(),
                "status", campeonato.getStatus() == null ? "" : campeonato.getStatus()
        ));
        log.info("Campeonato {} enfileirado para projeção pública via outbox ({})", campeonato.getId(), eventType);
    }
}
