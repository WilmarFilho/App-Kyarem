package com.nkw.backapisumula.cadastros.service;

import com.nkw.backapisumula.cadastros.TipoEvento;
import com.nkw.backapisumula.cadastros.repo.TipoEventoRepository;
import com.nkw.backapisumula.competicao.ModalidadeCatalogo;
import com.nkw.backapisumula.competicao.repo.ModalidadeCatalogoRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class TipoEventoService {

    private final TipoEventoRepository repo;
    private final ModalidadeCatalogoRepository modalidadeRepo;

    public TipoEventoService(TipoEventoRepository repo, ModalidadeCatalogoRepository modalidadeRepo) {
        this.repo = repo;
        this.modalidadeRepo = modalidadeRepo;
    }

    public List<TipoEvento> listByModalidadeCatalogo(UUID modalidadeCatalogoId) {
        return repo.findAllByModalidadeCatalogo_IdOrderByNomeAsc(modalidadeCatalogoId);
    }

    public TipoEvento create(UUID modalidadeCatalogoId, String nome) {
        ModalidadeCatalogo modalidade = modalidadeRepo.findById(modalidadeCatalogoId)
                .orElseThrow(() -> new IllegalArgumentException("Modalidade catálogo não encontrada."));
        TipoEvento te = new TipoEvento();
        te.setModalidadeCatalogo(modalidade);
        te.setNome(nome.trim());
        return repo.save(te);
    }
}
