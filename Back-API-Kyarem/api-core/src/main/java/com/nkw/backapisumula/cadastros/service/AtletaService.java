package com.nkw.backapisumula.cadastros.service;

import com.nkw.backapisumula.cadastros.Atleta;
import com.nkw.backapisumula.cadastros.repo.AtletaRepository;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class AtletaService {

    private final AtletaRepository repo;

    public AtletaService(AtletaRepository repo) {
        this.repo = repo;
    }

    public List<Atleta> listAll() {
        return repo.findAll();
    }

    public Atleta getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalArgumentException("Atleta não encontrado."));
    }

    public Atleta create(String nome, String fotoUrl) {
        Atleta a = new Atleta();
        a.setNome(nome.trim());
        if (fotoUrl != null && !fotoUrl.isBlank()) a.setFotoUrl(fotoUrl.trim());
        a.setCriadoEm(OffsetDateTime.now());
        return repo.save(a);
    }

    public Atleta update(UUID id, String nome) {
        Atleta a = getOrThrow(id);
        a.setNome(nome.trim());
        return repo.save(a);
    }

    public void delete(UUID id) {
        repo.deleteById(id);
    }
}
