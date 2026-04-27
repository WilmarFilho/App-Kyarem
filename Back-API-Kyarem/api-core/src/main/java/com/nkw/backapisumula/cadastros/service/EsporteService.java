package com.nkw.backapisumula.cadastros.service;

import com.nkw.backapisumula.cadastros.Esporte;
import com.nkw.backapisumula.cadastros.repo.EsporteRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class EsporteService {

    private final EsporteRepository repo;

    public EsporteService(EsporteRepository repo) {
        this.repo = repo;
    }

    public List<Esporte> list() {
        return repo.findAll();
    }

    public Esporte getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalArgumentException("Esporte não encontrado."));
    }

    public Esporte create(String nome) {
        repo.findByNomeIgnoreCase(nome).ifPresent(e -> {
            throw new IllegalArgumentException("Já existe um esporte com esse nome.");
        });
        Esporte e = new Esporte();
        e.setNome(nome.trim());
        return repo.save(e);
    }
}
