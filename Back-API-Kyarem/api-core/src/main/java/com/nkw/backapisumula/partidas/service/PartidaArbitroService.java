package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.PartidaArbitro;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class PartidaArbitroService {

    private final PartidaArbitroRepository repo;
    private final PartidaRepository partidaRepo;
    private final ProfileRepository profileRepo;

    public PartidaArbitroService(PartidaArbitroRepository repo, PartidaRepository partidaRepo, ProfileRepository profileRepo) {
        this.repo = repo;
        this.partidaRepo = partidaRepo;
        this.profileRepo = profileRepo;
    }

    public List<PartidaArbitro> list(UUID partidaId) {
        return repo.findByPartida_Id(partidaId);
    }

    /**
     * Retorna todos os vínculos de um árbitro específico,
     * com os dados completos da partida (equipeA, equipeB, modalidade).
     */
    public List<PartidaArbitro> listByArbitro(UUID arbitroId) {
        return repo.findByArbitro_Id(arbitroId);
    }

    public PartidaArbitro add(UUID partidaId, UUID arbitroId, String funcao, UUID actionUserId) {
        if (repo.existsByPartida_IdAndArbitro_Id(partidaId, arbitroId)) {
            throw new IllegalStateException("Árbitro já atribuído a esta partida.");
        }

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        if (partida.getCriadoPor() != null && !partida.getCriadoPor().equals(actionUserId)) {
            throw new IllegalStateException("Apenas o criador da partida pode adicionar ou remover árbitros.");
        }

        Profile arbitro = profileRepo.findById(arbitroId)
                .orElseThrow(() -> new IllegalStateException("Perfil do árbitro não encontrado."));

        boolean hasRefereeRole = profileRepo.findRolesByUserId(arbitroId).stream()
                .anyMatch(role -> "REFEREE".equalsIgnoreCase(role) || "ARBITRO_COMUM".equalsIgnoreCase(role));
        if (!hasRefereeRole) {
            throw new IllegalStateException("Usuário informado não possui papel contextual de REFEREE.");
        }

        PartidaArbitro pa = new PartidaArbitro();
        pa.setPartida(partida);
        pa.setArbitro(arbitro);
        pa.setFuncao(normalizeFuncao(funcao));
        pa.setAdicionadoPor(actionUserId);
        pa.setCriadoEm(OffsetDateTime.now());

        // OBS: seu banco tem trigger fn_valida_role_arbitro, então se o role não for permitido, o INSERT falha.
        return repo.save(pa);
    }

    public void remove(UUID partidaArbitroId, UUID actionUserId) {
        PartidaArbitro pa = repo.findById(partidaArbitroId)
                .orElseThrow(() -> new IllegalStateException("Registro de arbitragem não encontrado."));
                
        Partida partida = pa.getPartida();
        if (partida != null && partida.getCriadoPor() != null && !partida.getCriadoPor().equals(actionUserId)) {
            throw new IllegalStateException("Apenas o criador da partida pode adicionar ou remover árbitros.");
        }

        repo.deleteById(partidaArbitroId);
    }

    private String normalizeFuncao(String funcao) {
        if (funcao == null) {
            return "";
        }

        String normalized = funcao.trim().toUpperCase();
        return switch (normalized) {
            case "ÁRBITRO PRINCIPAL", "ARBITRO PRINCIPAL", "PRINCIPAL" -> "PRINCIPAL";
            case "ÁRBITRO ASSISTENTE", "ARBITRO ASSISTENTE", "ÁRBITRO AUXILIAR", "ARBITRO AUXILIAR", "AUXILIAR" -> "AUXILIAR";
            case "MESÁRIO", "MESARIO" -> "MESARIO";
            case "DELEGADO" -> "DELEGADO";
            case "CRONOMETRISTA" -> "CRONOMETRISTA";
            default -> normalized;
        };
    }
}
