package com.nkw.backapisumula.social.service;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.repo.AtleticaRepository;
import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.CampeonatoTime;
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
        if (partidaId != null)    return favoriteRepository.existsByUserIdAndPartida_Id(userId, partidaId);
        if (campeonatoId != null) return favoriteRepository.existsByUserIdAndCampeonato_Id(userId, campeonatoId);
        if (atleticaId != null)   return favoriteRepository.existsByUserIdAndAtletica_Id(userId, atleticaId);
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe partidaId, campeonatoId ou atleticaId.");
    }

    @Transactional
    public FavoriteView toggle(UUID userId, UUID partidaId, UUID campeonatoId, UUID atleticaId) {
        validateExactlyOne(partidaId, campeonatoId, atleticaId);

        if (partidaId != null) {
            Optional<UserFavorite> existing = favoriteRepository.findByUserIdAndPartida_Id(userId, partidaId);
            if (existing.isPresent()) {
                favoriteRepository.delete(existing.get());
                return FavoriteView.unfavorited(existing.get().getId(), userId, partidaId, null, null);
            }
            Partida partida = partidaRepository.findById(partidaId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Partida não encontrada."));
            return toView(save(userId, partida, null, null));
        }

        if (campeonatoId != null) {
            Optional<UserFavorite> existing = favoriteRepository.findByUserIdAndCampeonato_Id(userId, campeonatoId);
            if (existing.isPresent()) {
                favoriteRepository.delete(existing.get());
                return FavoriteView.unfavorited(existing.get().getId(), userId, null, campeonatoId, null);
            }
            Campeonato campeonato = campeonatoRepository.findById(campeonatoId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Campeonato não encontrado."));
            return toView(save(userId, null, campeonato, null));
        }

        // atleticaId != null
        Optional<UserFavorite> existing = favoriteRepository.findByUserIdAndAtletica_Id(userId, atleticaId);
        if (existing.isPresent()) {
            favoriteRepository.delete(existing.get());
            return FavoriteView.unfavorited(existing.get().getId(), userId, null, null, atleticaId);
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
        if (fav.getPartida() != null) {
            Partida p = fav.getPartida();
            return new FavoriteView(
                    fav.getId(),
                    fav.getUserId(),
                    p.getId(),
                    null,
                    null,
                    true,
                    // label fica como a modalidade da partida
                    p.getCampeonatoModalidade() != null && p.getCampeonatoModalidade().getModalidade() != null
                            ? p.getCampeonatoModalidade().getModalidade().getNome()
                            : "Partida",
                    // campeonato info
                    p.getCampeonato() != null ? p.getCampeonato().getId() : null,
                    p.getCampeonato() != null ? p.getCampeonato().getNome() : null,
                    p.getCampeonato() != null ? p.getCampeonato().getEscudoUrl() : null,
                    // esporte info
                    p.getCampeonatoModalidade() != null
                            && p.getCampeonatoModalidade().getModalidade() != null
                            && p.getCampeonatoModalidade().getModalidade().getEsporte() != null
                            ? p.getCampeonatoModalidade().getModalidade().getEsporte().getNome() : null,
                    // status / placar
                    p.getStatus(),
                    p.getPlacarA(),
                    p.getPlacarB(),
                    p.getAgendadoPara(),
                    p.getIniciadaEm(),
                    p.getEncerradaEm(),
                    p.getLocal(),
                    p.getCategoria(),
                    p.getFase(),
                    // time A
                    equipeNome(p.getCampeonatoTimeA()),
                    atleticaNome(p.getCampeonatoTimeA()),
                    atleticaEscudo(p.getCampeonatoTimeA()),
                    // time B
                    equipeNome(p.getCampeonatoTimeB()),
                    atleticaNome(p.getCampeonatoTimeB()),
                    atleticaEscudo(p.getCampeonatoTimeB())
            );
        }

        if (fav.getCampeonato() != null) {
            Campeonato c = fav.getCampeonato();
            return new FavoriteView(
                    fav.getId(), fav.getUserId(), null, c.getId(), null, true, c.getNome(),
                    c.getId(), c.getNome(), c.getEscudoUrl(),
                    null, c.getStatus(), null, null, null, null, null, null, null,
                    null, null, null, null,
                    null, null, null
            );
        }

        // atletica
        Atletica a = fav.getAtletica();
        return new FavoriteView(
                fav.getId(), fav.getUserId(), null, null, a.getId(), true, a.getNome(),
                null, null, null,
                null, null, null, null, null, null, null, null, null,
                null, null, null, null,
                null, null, null
        );
    }

    private String equipeNome(CampeonatoTime ct) {
        if (ct == null) return null;
        return ct.getNomeEquipe();
    }

    private String atleticaNome(CampeonatoTime ct) {
        if (ct == null || ct.getTime() == null || ct.getTime().getAtletica() == null) return null;
        return ct.getTime().getAtletica().getNome();
    }

    private String atleticaEscudo(CampeonatoTime ct) {
        if (ct == null || ct.getTime() == null || ct.getTime().getAtletica() == null) return null;
        return ct.getTime().getAtletica().getEscudoUrl();
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

    // ── View record ─────────────────────────────────────────────────────────────

    public record FavoriteView(
            UUID id,
            UUID userId,
            UUID partidaId,
            UUID campeonatoId,
            UUID atleticaId,
            boolean favorited,
            String label,
            // ── Partida / Campeonato common ──────────────────────────────────
            UUID campeonatoRefId,
            String campeonatoNome,
            String campeonatoEscudoUrl,
            // ── Partida specific ─────────────────────────────────────────────
            String esporteNome,
            String status,
            Integer placarA,
            Integer placarB,
            OffsetDateTime agendadoPara,
            OffsetDateTime iniciadaEm,
            OffsetDateTime encerradaEm,
            String local,
            String categoria,
            String fase,
            String timeA,
            String atleticaNomeA,
            String atleticaEscudoUrlA,
            String timeB,
            String atleticaNomeB,
            String atleticaEscudoUrlB
    ) {
        /** Resultado ao desfavoritar — sem dados de enriquecimento. */
        static FavoriteView unfavorited(UUID id, UUID userId, UUID partidaId, UUID campeonatoId, UUID atleticaId) {
            return new FavoriteView(id, userId, partidaId, campeonatoId, atleticaId,
                    false, null, null, null, null, null, null, null, null,
                    null, null, null, null, null, null, null, null, null, null, null, null);
        }
    }
}
