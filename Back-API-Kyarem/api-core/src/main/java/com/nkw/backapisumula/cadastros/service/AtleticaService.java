package com.nkw.backapisumula.cadastros.service;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.repo.AtleticaRepository;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
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
        atletica.setSlug(slugify(atletica.getNome()));
        atletica.setCriadoEm(java.time.OffsetDateTime.now());
        return repo.save(atletica);
    }

    public Atletica update(UUID id, Atletica patch) {
        Atletica a = getOrThrow(id);
        if (patch.getNome() != null) {
            a.setNome(patch.getNome().trim());
            a.setSlug(slugify(a.getNome()));
        }
        if (patch.getSigla() != null) a.setSigla(patch.getSigla().trim());
        if (patch.getCorPrincipal() != null) a.setCorPrincipal(patch.getCorPrincipal());
        if (patch.getEscudoUrl() != null) a.setEscudoUrl(patch.getEscudoUrl());
        if (patch.getStatus() != null) a.setStatus(patch.getStatus().trim());
        return repo.save(a);
    }

    public void delete(UUID id) {
        Atletica a = getOrThrow(id);
        repo.delete(a);
    }

    private String slugify(String value) {
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT)
                .trim()
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-+|-+$", "");

        if (normalized.isBlank()) {
            throw new IllegalArgumentException("Nome da atlética inválido para gerar slug.");
        }

        return normalized;
    }
}
