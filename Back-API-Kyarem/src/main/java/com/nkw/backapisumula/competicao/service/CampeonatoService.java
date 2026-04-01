package com.nkw.backapisumula.competicao.service;

import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class CampeonatoService {

    private final CampeonatoRepository repo;

    public CampeonatoService(CampeonatoRepository repo) {
        this.repo = repo;
    }

    public List<Campeonato> list() {
        return repo.findAll();
    }

    public Campeonato getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalArgumentException("Campeonato não encontrado."));
    }

    public Campeonato create(Campeonato c) {
        c.setNome(c.getNome().trim());
        if (c.getNivelCampeonato() != null) c.setNivelCampeonato(c.getNivelCampeonato().trim());
        if (c.getEscudoUrl() != null) c.setEscudoUrl(c.getEscudoUrl().trim());
        c.setCriadoEm(OffsetDateTime.now());
        return repo.save(c);
    }

    public Campeonato update(UUID id, Campeonato patch) {
        Campeonato c = getOrThrow(id);
        if (patch.getNome() != null) c.setNome(patch.getNome().trim());
        if (patch.getNivelCampeonato() != null) c.setNivelCampeonato(patch.getNivelCampeonato().trim());
        if (patch.getDataInicio() != null) c.setDataInicio(patch.getDataInicio());
        if (patch.getDataFim() != null) c.setDataFim(patch.getDataFim());
        if (patch.getEscudoUrl() != null) c.setEscudoUrl(patch.getEscudoUrl().trim());
        return repo.save(c);
    }

    public void delete(UUID id) {
        Campeonato c = getOrThrow(id);
        repo.delete(c);
    }
}
