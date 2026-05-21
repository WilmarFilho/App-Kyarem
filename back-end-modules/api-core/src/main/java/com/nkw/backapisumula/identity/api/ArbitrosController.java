package com.nkw.backapisumula.identity.api;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.QuadroArbitro;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.identity.repo.QuadroArbitroRepository;
import com.nkw.backapisumula.identity.service.ProfileService;
import com.nkw.backapisumula.identity.service.SupabaseAdminUserService;
import com.nkw.backapisumula.partidas.PartidaArbitro;
import com.nkw.backapisumula.partidas.service.PartidaArbitroService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Lista árbitros ativos do quadro de arbitragem.
 *
 * Útil para telas administrativas (atribuição de arbitragem, filtros, etc.).
 */
@RestController
@RequestMapping("/api/v1/arbitros")
public class ArbitrosController {

    private final ProfileService profileService;
    private final PartidaArbitroService partidaArbitroService;
    private final QuadroArbitroRepository quadroArbitroRepository;
    private final SupabaseAdminUserService adminUserService;
    private final ProfileRepository profileRepository;

    public ArbitrosController(ProfileService profileService, PartidaArbitroService partidaArbitroService, QuadroArbitroRepository quadroArbitroRepository, SupabaseAdminUserService adminUserService, ProfileRepository profileRepository) {
        this.profileService = profileService;
        this.partidaArbitroService = partidaArbitroService;
        this.quadroArbitroRepository = quadroArbitroRepository;
        this.adminUserService = adminUserService;
        this.profileRepository = profileRepository;
    }

    /** Lista todos os árbitros cadastrados. */
    @GetMapping
    @PreAuthorize("hasAnyRole('admin','director')")
    public List<ArbitroResponse> list() {
        return profileService.listArbitros().stream().map(ArbitroResponse::from).toList();
    }

    /**
     * Retorna todas as partidas vinculadas a um árbitro específico.
     * Inclui partidas ativas (agendadas/em andamento) e encerradas (finalizada/fechada).
     * GET /api/v1/arbitros/{arbitroId}/partidas
     */
    @GetMapping("/{arbitroId}/partidas")
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public List<PartidaDoArbitroResponse> listarPartidasDoArbitro(@PathVariable UUID arbitroId) {
        return partidaArbitroService.listByArbitro(arbitroId)
                .stream()
                .map(PartidaDoArbitroResponse::from)
                .toList();
    }

    // ── Records de resposta ──────────────────────────────────────────────

    /**
     * Vincula um usuário existente ao quadro de arbitragem.
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    public void vincularExistente(@RequestBody VincularRequest req) {
        profileRepository.findById(req.userId())
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado."));

        quadroArbitroRepository.findByUserId(req.userId()).ifPresentOrElse(
                qa -> {
                    if (!"ATIVO".equals(qa.getStatus())) {
                        qa.setStatus("ATIVO");
                        quadroArbitroRepository.save(qa);
                    }
                },
                () -> {
                    QuadroArbitro qa = new QuadroArbitro();
                    qa.setId(UUID.randomUUID());
                    qa.setUserId(req.userId());
                    qa.setStatus("ATIVO");
                    qa.setCriadoEm(OffsetDateTime.now());
                    quadroArbitroRepository.save(qa);
                }
        );
    }

    /**
     * Cria um novo usuário auth e já o vincula ao quadro de arbitragem.
     */
    @PostMapping("/criar")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    public ArbitroResponse criarEAssociar(@Valid @RequestBody CriarArbitroRequest req) {
        // 1. Cria o auth user
        UUID userId = adminUserService.createAuthUser(
                req.email(),
                req.senha(),
                req.nome(),
                null,
                "USER"
        );

        // 2. Aguarda o trigger criar o Profile
        Profile profile = null;
        for (int i = 0; i < 4; i++) {
            try { Thread.sleep(500); } catch (InterruptedException ignored) {}
            profile = profileRepository.findById(userId).orElse(null);
            if (profile != null) break;
        }

        if (profile == null) {
            throw new IllegalStateException("Falha ao criar o profile do usuário pelo trigger.");
        }

        // 3. Vincula ao quadro de arbitragem
        QuadroArbitro qa = new QuadroArbitro();
        qa.setId(UUID.randomUUID());
        qa.setUserId(userId);
        qa.setStatus("ATIVO");
        qa.setCriadoEm(OffsetDateTime.now());
        quadroArbitroRepository.save(qa);

        return ArbitroResponse.from(profile);
    }

    public record VincularRequest(UUID userId) {}

    public record CriarArbitroRequest(
            @NotBlank @Email String email,
            @NotBlank @Size(min = 6) String senha,
            @NotBlank String nome
    ) {}

    public record ArbitroResponse(
            UUID id,
            String nomeExibicao,
            String fotoUrl,
            String telefone,
            String role,
            OffsetDateTime criadoEm,
            OffsetDateTime atualizadoEm
    ) {
        public static ArbitroResponse from(Profile p) {
            return new ArbitroResponse(
                    p.getId(),
                    p.getNomeExibicao(),
                    p.getFotoUrl(),
                    p.getTelefone(),
                    p.getRole(),
                    p.getCriadoEm(),
                    p.getAtualizadoEm()
            );
        }
    }

    /**
     * Resposta enriquecida: dados do vínculo + dados resumidos da partida.
     * O campo {@code vinculoId} é o ID do registro em partida_arbitros,
     * necessário para desvincular (DELETE /partidas/{id}/arbitros/{vinculoId}).
     */
    public record PartidaDoArbitroResponse(
            UUID vinculoId,
            String funcao,
            OffsetDateTime vinculadoEm,
            UUID partidaId,
            String status,
            OffsetDateTime agendadaPara,
            OffsetDateTime iniciadaEm,
            OffsetDateTime encerradaEm,
            String local,
            String fase,
            String categoria,
            Integer placarA,
            Integer placarB,
            String equipeANome,
            String equipeBNome,
            String modalidadeNome
    ) {
        public static PartidaDoArbitroResponse from(PartidaArbitro pa) {
            var p = pa.getPartida();
            return new PartidaDoArbitroResponse(
                    pa.getId(),
                    pa.getFuncao(),
                    pa.getCriadoEm(),
                    p == null ? null : p.getId(),
                    p == null ? null : p.getStatus(),
                    p == null ? null : p.getAgendadoPara(),
                    p == null ? null : p.getIniciadaEm(),
                    p == null ? null : p.getEncerradaEm(),
                    p == null ? null : p.getLocal(),
                    p == null ? null : p.getFase(),
                    p == null ? null : p.getCategoria(),
                    p == null ? null : p.getPlacarA(),
                    p == null ? null : p.getPlacarB(),
                    (p == null || p.getEquipeA() == null) ? null : p.getEquipeA().getNomeEquipe(),
                    (p == null || p.getEquipeB() == null) ? null : p.getEquipeB().getNomeEquipe(),
                    (p == null || p.getModalidade() == null) ? null : p.getModalidade().getNome()
            );
        }
    }
}
