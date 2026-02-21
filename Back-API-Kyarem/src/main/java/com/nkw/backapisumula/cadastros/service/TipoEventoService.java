package com.nkw.backapisumula.cadastros.service;

import com.nkw.backapisumula.cadastros.Esporte;
import com.nkw.backapisumula.cadastros.TipoEvento;
import com.nkw.backapisumula.cadastros.repo.TipoEventoRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class TipoEventoService {

    private final TipoEventoRepository repo;

    public TipoEventoService(TipoEventoRepository repo) {
        this.repo = repo;
    }

    public List<TipoEvento> listByEsporte(UUID esporteId) {
        return repo.findAllByEsporte_IdOrderByNomeAsc(esporteId);
    }

    public TipoEvento create(Esporte esporte, String nome) {
        TipoEvento te = new TipoEvento();
        te.setEsporte(esporte);
        te.setNome(nome.trim());
        return repo.save(te);
    }
}
