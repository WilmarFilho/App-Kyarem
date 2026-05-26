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
        return repo.findAllByModalidadeCatalogo_IdOrderByOrdemExibicaoAscNomeAsc(modalidadeCatalogoId);
    }

    /**
     * Cria um novo tipo de evento para a modalidade informada.
     * Todos os campos são opcionais exceto nome; quando não informados, usam defaults seguros.
     */
    public TipoEvento create(UUID modalidadeCatalogoId, CreateTipoEventoData data) {
        ModalidadeCatalogo modalidade = modalidadeRepo.findById(modalidadeCatalogoId)
                .orElseThrow(() -> new IllegalArgumentException("Modalidade catálogo não encontrada."));

        TipoEvento te = new TipoEvento();
        te.setModalidadeCatalogo(modalidade);
        te.setNome(data.nome().trim());

        // Código: gerado a partir do nome se não informado
        String codigo = data.codigo() != null && !data.codigo().isBlank()
                ? data.codigo().trim().toUpperCase()
                : data.nome().trim().toUpperCase().replaceAll("\\s+", "_").replaceAll("[^A-Z0-9_]", "");
        te.setCodigo(codigo);

        // Escopo: default ATLETA para compatibilidade retroativa
        String escopo = data.escopo() != null && !data.escopo().isBlank() ? data.escopo().trim().toUpperCase() : "ATLETA";
        if (!escopo.equals("PARTIDA") && !escopo.equals("EQUIPE") && !escopo.equals("ATLETA")) {
            throw new IllegalArgumentException("Escopo inválido: " + escopo + ". Use PARTIDA, EQUIPE ou ATLETA.");
        }
        te.setEscopo(escopo);

        te.setImpactaPlacar(data.impactaPlacar() != null ? data.impactaPlacar() : false);
        te.setPontosPro(data.pontosPro());
        te.setPontosContra(data.pontosContra());
        te.setOrdemExibicao(data.ordemExibicao());
        te.setAtivo(true);

        return repo.save(te);
    }

    /**
     * Remove um tipo de evento pelo ID.
     * Verifica se o tipo de evento pertence à modalidade informada antes de deletar.
     */
    public void delete(UUID modalidadeCatalogoId, UUID tipoEventoId) {
        TipoEvento te = repo.findById(tipoEventoId)
                .orElseThrow(() -> new IllegalArgumentException("Tipo de evento não encontrado."));
        if (te.getModalidadeCatalogo() == null
                || !modalidadeCatalogoId.equals(te.getModalidadeCatalogo().getId())) {
            throw new IllegalArgumentException("Tipo de evento não pertence à modalidade informada.");
        }
        repo.delete(te);
    }

    /** DTO para criação de tipo de evento — todos os campos além de nome são opcionais. */
    public record CreateTipoEventoData(
            String codigo,
            String nome,
            String escopo,
            Boolean impactaPlacar,
            Integer pontosPro,
            Integer pontosContra,
            Integer ordemExibicao) {}
}
