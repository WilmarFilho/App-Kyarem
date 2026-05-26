package com.nkw.backapisumula.social.service;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.repo.AtleticaRepository;
import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import com.nkw.backapisumula.social.UserFavorite;
import com.nkw.backapisumula.social.repo.UserFavoriteRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class FavoriteService {

    private final UserFavoriteRepository favoriteRepository;
    private final PartidaRepository partidaRepository;
    private final CampeonatoRepository campeonatoRepository;
    private final AtleticaRepository atleticaRepository;

    public FavoriteService(
            UserFavoriteRepository favoriteRepository,
            PartidaRepository partidaRepository,
            CampeonatoRepository campeonatoRepository,
            AtleticaRepository atleticaRepository
    ) {
        this.favoriteRepository = favoriteRepository;
        this.partidaRepository = partidaRepository;
        this.campeonatoRepository = campeonatoRepository;
        this.atleticaRepository = atleticaRepository;
    }

    @Transactional(readOnly = true)
    public List<FavoriteView> listFavorites(UUID userId) {
        return favoriteRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toView)
                .toList();
    }

    @Transactional(readOnly = true)
    public boolean isFavorite(UUID userId, UUID partidaId, UUID campeonatoId, UUID atleticaId) {
        if (partidaId != null)     return favoriteRepository.existsByUserIdAndPartida_Id(userId, partidaId);
        if (campeonatoId != null)  return favoriteRepository.existsByUserIdAndCampeonato_Id(userId, campeonatoId);
        if (atleticaId != null)    return favoriteRepository.existsByUserIdAndAtletica_Id(userId, atleticaId);
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe partidaId, campeonatoId ou atleticaId.");
    }

    @Transactional
    public FavoriteView toggle(UUID userId, UUID partidaId, UUID campeonatoId, UUID atleticaId) {
        validateExactlyOne(partidaId, campeonatoId, atleticaId);

        // Verify existence of the referenced entity
        if (partidaId != null) {
            Optional<UserFavorite> existing = favoriteRepository.findByUserIdAndPartida_Id(userId, partidaId);
            if (existing.isPresent()) {
                favoriteRepository.delete(existing.get());
                return new FavoriteView(existing.get().getId(), userId, partidaId, null, null, false, null);
            }
            Partida partida = partidaRepository.findById(partidaId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Partida não encontrada."));
            return toView(save(userId, partida, null, null));
        }

        if (campeonatoId != null) {
            Optional<UserFavorite> existing = favoriteRepository.findByUserIdAndCampeonato_Id(userId, campeonatoId);
            if (existing.isPresent()) {
                favoriteRepository.delete(existing.get());
                return new FavoriteView(existing.get().getId(), userId, null, campeonatoId, null, false, null);
            }
            Campeonato campeonato = campeonatoRepository.findById(campeonatoId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Campeonato não encontrado."));
            return toView(save(userId, null, campeonato, null));
        }

        // atleticaId != null
        Optional<UserFavorite> existing = favoriteRepository.findByUserIdAndAtletica_Id(userId, atleticaId);
        if (existing.isPresent()) {
            favoriteRepository.delete(existing.get());
            return new FavoriteView(existing.get().getId(), userId, null, null, atleticaId, false, null);
        }
        Atletica atletica = atleticaRepository.findById(atleticaId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Atlética não encontrada."));
        return toView(save(userId, null, null, atletica));
    }

    // ── Helpers ─────────────────────────────────────────────────────────────────

    private UserFavorite save(UUID userId, Partida partida, Campeonato campeonato, Atletica atletica) {
        UserFavorite fav = new UserFavorite();
        fav.setId(UUID.randomUUID());
        fav.setUserId(userId);
        fav.setPartida(partida);
        fav.setCampeonato(campeonato);
        fav.setAtletica(atletica);
        fav.setCreatedAt(OffsetDateTime.now());
        return favoriteRepository.save(fav);
    }

    private FavoriteView toView(UserFavorite fav) {
        String label = null;
        UUID partidaId = null;
        UUID campeonatoId = null;
        UUID atleticaId = null;

        if (fav.getPartida() != null) {
            partidaId = fav.getPartida().getId();
            label = "Partida";
        } else if (fav.getCampeonato() != null) {
            campeonatoId = fav.getCampeonato().getId();
            label = fav.getCampeonato().getNome();
        } else if (fav.getAtletica() != null) {
            atleticaId = fav.getAtletica().getId();
            label = fav.getAtletica().getNome();
        }

        return new FavoriteView(fav.getId(), fav.getUserId(), partidaId, campeonatoId, atleticaId, true, label);
    }

    private void validateExactlyOne(UUID partidaId, UUID campeonatoId, UUID atleticaId) {
        int count = (partidaId != null ? 1 : 0)
                + (campeonatoId != null ? 1 : 0)
                + (atleticaId != null ? 1 : 0);
        if (count != 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Informe exatamente um de: partidaId, campeonatoId ou atleticaId.");
        }
    }

    // ── View records ────────────────────────────────────────────────────────────

    public record FavoriteView(
            UUID id,
            UUID userId,
            UUID partidaId,
            UUID campeonatoId,
            UUID atleticaId,
            boolean favorited,
            String label
    ) {}
}
