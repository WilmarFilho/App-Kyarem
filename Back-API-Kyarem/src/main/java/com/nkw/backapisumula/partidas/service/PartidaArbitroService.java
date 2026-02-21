package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.PartidaArbitro;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import org.springframework.stereotype.Service;

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

    public PartidaArbitro add(UUID partidaId, UUID arbitroId, String funcao) {
        if (repo.existsByPartida_IdAndArbitro_Id(partidaId, arbitroId)) {
            throw new IllegalStateException("Árbitro já atribuído a esta partida.");
        }

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        Profile arbitro = profileRepo.findById(arbitroId)
                .orElseThrow(() -> new IllegalStateException("Perfil do árbitro não encontrado."));

        PartidaArbitro pa = new PartidaArbitro();
        pa.setPartida(partida);
        pa.setArbitro(arbitro);
        pa.setFuncao(funcao);

        // OBS: seu banco tem trigger fn_valida_role_arbitro, então se o role não for permitido, o INSERT falha.
        return repo.save(pa);
    }

    public void remove(UUID partidaArbitroId) {
        if (!repo.existsById(partidaArbitroId)) {
            throw new IllegalStateException("Registro de arbitragem não encontrado.");
        }
        repo.deleteById(partidaArbitroId);
    }
}
