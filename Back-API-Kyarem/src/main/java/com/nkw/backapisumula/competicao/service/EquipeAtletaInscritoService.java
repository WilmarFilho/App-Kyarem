package com.nkw.backapisumula.competicao.service;

import com.nkw.backapisumula.cadastros.repo.AtletaRepository;
import com.nkw.backapisumula.competicao.EquipeAtletaInscrito;
import com.nkw.backapisumula.competicao.repo.EquipeAtletaInscritoRepository;
import com.nkw.backapisumula.competicao.repo.EquipeRepository;
import jakarta.validation.constraints.NotNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class EquipeAtletaInscritoService {

    private final EquipeAtletaInscritoRepository repo;
    private final EquipeRepository equipeRepo;
    private final AtletaRepository atletaRepo;

    public EquipeAtletaInscritoService(EquipeAtletaInscritoRepository repo, EquipeRepository equipeRepo, AtletaRepository atletaRepo) {
        this.repo = repo;
        this.equipeRepo = equipeRepo;
        this.atletaRepo = atletaRepo;
    }

    public List<EquipeAtletaInscrito> listByEquipe(UUID equipeId) {
        return repo.findByEquipe_Id(equipeId);
    }

    public record AddInscritoCommand(
            @NotNull UUID atletaId,
            Integer numeroCamisa,
            Boolean ativo
    ) {}

    /**
     * Adiciona vários atletas a uma equipe em uma única operação (transação única).
     * Se algum item falhar (ex.: atleta inexistente, duplicado), nada é persistido.
     */
    @Transactional
    public List<EquipeAtletaInscrito> addBatch(UUID equipeId, List<AddInscritoCommand> itens) {
        var equipe = equipeRepo.findById(equipeId)
                .orElseThrow(() -> new IllegalArgumentException("Equipe não encontrada."));

        // validação rápida de duplicados no payload
        var duplicatedAtletaId = itens.stream()
                .collect(java.util.stream.Collectors.groupingBy(AddInscritoCommand::atletaId, java.util.stream.Collectors.counting()))
                .entrySet().stream()
                .filter(e -> e.getValue() > 1)
                .map(java.util.Map.Entry::getKey)
                .findFirst()
                .orElse(null);
        if (duplicatedAtletaId != null) {
            throw new IllegalArgumentException("Atleta repetido no payload: " + duplicatedAtletaId);
        }

        // carrega atletas e cria inscrições
        return itens.stream().map(cmd -> {
            var atleta = atletaRepo.findById(cmd.atletaId())
                    .orElseThrow(() -> new IllegalArgumentException("Atleta não encontrado: " + cmd.atletaId()));

            if (repo.existsByEquipe_IdAndAtleta_Id(equipeId, cmd.atletaId())) {
                throw new IllegalArgumentException("Atleta já inscrito nesta equipe: " + cmd.atletaId());
            }

            EquipeAtletaInscrito i = new EquipeAtletaInscrito();
            i.setEquipe(equipe);
            i.setAtleta(atleta);
            i.setNumeroCamisa(cmd.numeroCamisa());
            i.setAtivo(cmd.ativo() != null ? cmd.ativo() : Boolean.TRUE);
            return repo.save(i);
        }).toList();
    }

    public EquipeAtletaInscrito add(UUID equipeId, UUID atletaId, Integer numeroCamisa, Boolean ativo) {
        var equipe = equipeRepo.findById(equipeId)
                .orElseThrow(() -> new IllegalArgumentException("Equipe não encontrada."));
        var atleta = atletaRepo.findById(atletaId)
                .orElseThrow(() -> new IllegalArgumentException("Atleta não encontrado."));

        if (repo.existsByEquipe_IdAndAtleta_Id(equipeId, atletaId)) {
            throw new IllegalArgumentException("Atleta já inscrito nesta equipe.");
        }

        EquipeAtletaInscrito i = new EquipeAtletaInscrito();
        i.setEquipe(equipe);
        i.setAtleta(atleta);
        i.setNumeroCamisa(numeroCamisa);
        i.setAtivo(ativo != null ? ativo : Boolean.TRUE);
        return repo.save(i);
    }

    public void remove(UUID equipeId, UUID inscritoId) {
        EquipeAtletaInscrito i = repo.findById(inscritoId)
                .orElseThrow(() -> new IllegalArgumentException("Inscrição não encontrada."));
        if (i.getEquipe() == null || i.getEquipe().getId() == null || !i.getEquipe().getId().equals(equipeId)) {
            throw new IllegalArgumentException("Inscrição não pertence à equipe informada.");
        }
        repo.delete(i);
    }
}
