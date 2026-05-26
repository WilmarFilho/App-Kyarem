package com.nkw.backapisumula.social.api;

import com.nkw.backapisumula.social.service.FavoriteService;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/favorites")
@PreAuthorize("isAuthenticated()")
public class FavoriteController {

    private final FavoriteService favoriteService;

    public FavoriteController(FavoriteService favoriteService) {
        this.favoriteService = favoriteService;
    }

    /** Lista todos os favoritos do usuário autenticado. */
    @GetMapping
    public List<FavoriteService.FavoriteView> list(@AuthenticationPrincipal Jwt jwt) {
        return favoriteService.listFavorites(currentUserId(jwt));
    }

    /**
     * Verifica se um item é favorito.
     * Passe exatamente um dos parâmetros: partidaId, campeonatoId ou atleticaId.
     */
    @GetMapping("/check")
    public FavoriteCheckResponse check(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) UUID partidaId,
            @RequestParam(required = false) UUID campeonatoId,
            @RequestParam(required = false) UUID atleticaId
    ) {
        boolean favorited = favoriteService.isFavorite(currentUserId(jwt), partidaId, campeonatoId, atleticaId);
        return new FavoriteCheckResponse(favorited);
    }

    /**
     * Alterna (adiciona ou remove) um favorito.
     * Passe exatamente um dos campos no body: partidaId, campeonatoId ou atleticaId.
     */
    @PostMapping("/toggle")
    @ResponseStatus(HttpStatus.OK)
    public FavoriteService.FavoriteView toggle(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody ToggleFavoriteRequest request
    ) {
        return favoriteService.toggle(
                currentUserId(jwt),
                request.partidaId(),
                request.campeonatoId(),
                request.atleticaId()
        );
    }

    private UUID currentUserId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }

    public record ToggleFavoriteRequest(
            UUID partidaId,
            UUID campeonatoId,
            UUID atleticaId
    ) {}

    public record FavoriteCheckResponse(boolean favorited) {}
}
