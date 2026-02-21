package com.nkw.backapisumula.cadastros.service;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.repo.AtleticaRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class AtleticaService {

    private final AtleticaRepository repo;

    public AtleticaService(AtleticaRepository repo) {
        this.repo = repo;
    }

    public List<Atletica> list() {
        return repo.findAll();
    }

    public Atletica getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalArgumentException("Atlética não encontrada."));
    }

    public Atletica create(Atletica atletica) {
        atletica.setNome(atletica.getNome().trim());
        if (atletica.getSigla() != null) atletica.setSigla(atletica.getSigla().trim());
        return repo.save(atletica);
    }

    public Atletica update(UUID id, Atletica patch) {
        Atletica a = getOrThrow(id);
        if (patch.getNome() != null) a.setNome(patch.getNome().trim());
        if (patch.getSigla() != null) a.setSigla(patch.getSigla().trim());
        if (patch.getCorPrincipal() != null) a.setCorPrincipal(patch.getCorPrincipal());
        if (patch.getEscudoUrl() != null) a.setEscudoUrl(patch.getEscudoUrl());
        if (patch.getPresidenteId() != null) a.setPresidenteId(patch.getPresidenteId());
        return repo.save(a);
    }
}
