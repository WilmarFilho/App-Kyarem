package com.nkw.backapisumula.competicao.service;

import com.nkw.backapisumula.cadastros.repo.EsporteRepository;
import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.Modalidade;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class ModalidadeService {

    private final ModalidadeRepository repo;
    private final CampeonatoRepository campeonatoRepo;
    private final EsporteRepository esporteRepo;

    public ModalidadeService(ModalidadeRepository repo, CampeonatoRepository campeonatoRepo, EsporteRepository esporteRepo) {
        this.repo = repo;
        this.campeonatoRepo = campeonatoRepo;
        this.esporteRepo = esporteRepo;
    }

    public List<Modalidade> listByCampeonato(UUID campeonatoId) {
        return repo.findByCampeonato_Id(campeonatoId);
    }

    public Modalidade getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalArgumentException("Modalidade não encontrada."));
    }

    public Modalidade create(UUID campeonatoId, UUID esporteId, Modalidade m) {
        Campeonato campeonato = campeonatoRepo.findById(campeonatoId)
                .orElseThrow(() -> new IllegalArgumentException("Campeonato não encontrado."));
        var esporte = esporteRepo.findById(esporteId)
                .orElseThrow(() -> new IllegalArgumentException("Esporte não encontrado."));

        m.setCampeonato(campeonato);
        m.setCampeonatoNome(campeonato.getNome());
        m.setEsporte(esporte);
        m.setNome(m.getNome().trim());
        if (m.getTempoPartidaMinutos() == null) m.setTempoPartidaMinutos(40);
        return repo.save(m);
    }

    public Modalidade update(UUID id, Modalidade patch, UUID campeonatoId, UUID esporteId) {
        Modalidade m = getOrThrow(id);

        if (campeonatoId != null) {
            Campeonato campeonato = campeonatoRepo.findById(campeonatoId)
                    .orElseThrow(() -> new IllegalArgumentException("Campeonato não encontrado."));
            m.setCampeonato(campeonato);
            m.setCampeonatoNome(campeonato.getNome());
        }

        if (esporteId != null) {
            var esporte = esporteRepo.findById(esporteId)
                    .orElseThrow(() -> new IllegalArgumentException("Esporte não encontrado."));
            m.setEsporte(esporte);
        }

        if (patch.getNome() != null) m.setNome(patch.getNome().trim());
        if (patch.getTempoPartidaMinutos() != null) m.setTempoPartidaMinutos(patch.getTempoPartidaMinutos());
        if (patch.getRegrasJson() != null) m.setRegrasJson(patch.getRegrasJson());

        return repo.save(m);
    }
}
