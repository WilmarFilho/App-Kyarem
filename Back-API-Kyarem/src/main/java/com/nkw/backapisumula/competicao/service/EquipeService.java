package com.nkw.backapisumula.competicao.service;

import com.nkw.backapisumula.cadastros.repo.AtleticaRepository;
import com.nkw.backapisumula.competicao.Equipe;
import com.nkw.backapisumula.competicao.Modalidade;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import com.nkw.backapisumula.competicao.repo.EquipeRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class EquipeService {

    private final EquipeRepository repo;
    private final AtleticaRepository atleticaRepo;
    private final CampeonatoRepository campeonatoRepo;
    private final ModalidadeRepository modalidadeRepo;

    public EquipeService(EquipeRepository repo, AtleticaRepository atleticaRepo, CampeonatoRepository campeonatoRepo, ModalidadeRepository modalidadeRepo) {
        this.repo = repo;
        this.atleticaRepo = atleticaRepo;
        this.campeonatoRepo = campeonatoRepo;
        this.modalidadeRepo = modalidadeRepo;
    }

    public List<Equipe> list(UUID campeonatoId, UUID modalidadeId, UUID atleticaId) {
        if (campeonatoId != null && modalidadeId != null && atleticaId != null) {
            return repo.findByCampeonato_IdAndModalidade_IdAndAtletica_Id(campeonatoId, modalidadeId, atleticaId);
        }
        if (campeonatoId != null && modalidadeId != null) {
            return repo.findByCampeonato_IdAndModalidade_Id(campeonatoId, modalidadeId);
        }
        if (campeonatoId != null && atleticaId != null) {
            return repo.findByCampeonato_IdAndAtletica_Id(campeonatoId, atleticaId);
        }
        if (modalidadeId != null && atleticaId != null) {
            return repo.findByModalidade_IdAndAtletica_Id(modalidadeId, atleticaId);
        }
        if (campeonatoId != null) return repo.findByCampeonato_Id(campeonatoId);
        if (modalidadeId != null) return repo.findByModalidade_Id(modalidadeId);
        if (atleticaId != null) return repo.findByAtletica_Id(atleticaId);
        return repo.findAll();
    }

    public Equipe getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalArgumentException("Equipe não encontrada."));
    }

    public Equipe create(UUID atleticaId, UUID campeonatoId, UUID modalidadeId, String nomeEquipe) {
        var atletica = atleticaRepo.findById(atleticaId)
                .orElseThrow(() -> new IllegalArgumentException("Atlética não encontrada."));
        var campeonato = campeonatoRepo.findById(campeonatoId)
                .orElseThrow(() -> new IllegalArgumentException("Campeonato não encontrado."));
        Modalidade modalidade = modalidadeRepo.findById(modalidadeId)
                .orElseThrow(() -> new IllegalArgumentException("Modalidade não encontrada."));

        Equipe e = new Equipe();
        e.setAtletica(atletica);
        e.setCampeonato(campeonato);
        e.setModalidade(modalidade);
        e.setNomeEquipe(nomeEquipe.trim());
        return repo.save(e);
    }

    public Equipe update(UUID id, UUID atleticaId, UUID campeonatoId, UUID modalidadeId, String nomeEquipe) {
        Equipe e = getOrThrow(id);

        if (atleticaId != null) {
            var atletica = atleticaRepo.findById(atleticaId)
                    .orElseThrow(() -> new IllegalArgumentException("Atlética não encontrada."));
            e.setAtletica(atletica);
        }
        if (campeonatoId != null) {
            var campeonato = campeonatoRepo.findById(campeonatoId)
                    .orElseThrow(() -> new IllegalArgumentException("Campeonato não encontrado."));
            e.setCampeonato(campeonato);
        }
        if (modalidadeId != null) {
            var modalidade = modalidadeRepo.findById(modalidadeId)
                    .orElseThrow(() -> new IllegalArgumentException("Modalidade não encontrada."));
            e.setModalidade(modalidade);
        }
        if (nomeEquipe != null) e.setNomeEquipe(nomeEquipe.trim());

        return repo.save(e);
    }
}
