package com.nkw.backapisumula.cadastros.service;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.AtleticaMembro;
import com.nkw.backapisumula.common.outbox.EventPublisherService;
import com.nkw.backapisumula.cadastros.repo.AtleticaMembroRepository;
import com.nkw.backapisumula.cadastros.repo.AtleticaRepository;
import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.UsuarioRoleGlobal;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.identity.repo.UsuarioRoleGlobalRepository;
import com.nkw.backapisumula.identity.service.SupabaseAdminUserService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class AtleticaMembroService {

    private static final String STATUS_CONVOCADO = "CONVOCADO";
    private static final String STATUS_ATIVO = "ATIVO";
    private static final String STATUS_RECUSADO = "RECUSADO";

    private final AtleticaMembroRepository membroRepository;
    private final AtleticaRepository atleticaRepository;
    private final ProfileRepository profileRepository;
    private final SupabaseAdminUserService adminUserService;
    private final UsuarioRoleGlobalRepository usuarioRoleGlobalRepository;
    private final EventPublisherService eventPublisherService;

    public AtleticaMembroService(
            AtleticaMembroRepository membroRepository,
            AtleticaRepository atleticaRepository,
            ProfileRepository profileRepository,
            SupabaseAdminUserService adminUserService,
            UsuarioRoleGlobalRepository usuarioRoleGlobalRepository,
            EventPublisherService eventPublisherService
    ) {
        this.membroRepository = membroRepository;
        this.atleticaRepository = atleticaRepository;
        this.profileRepository = profileRepository;
        this.adminUserService = adminUserService;
        this.usuarioRoleGlobalRepository = usuarioRoleGlobalRepository;
        this.eventPublisherService = eventPublisherService;
    }

    public List<AtleticaMembro> list(UUID atleticaId) {
        return membroRepository.findByAtletica_IdOrderByCriadoEmAsc(atleticaId).stream()
                .filter(membro -> isSupportedPapel(membro.getPapelCodigo()))
                .toList();
    }

    public List<AtleticaMembro> listByUser(UUID userId) {
        return membroRepository.findByUser_IdAndStatusOrderByCriadoEmAsc(userId, STATUS_ATIVO);
    }

    @Transactional
    public AtleticaMembro associateExistingUser(
            UUID atleticaId,
            UUID userId,
            String papelCodigo,
            UUID actorUserId
    ) {
        Atletica atletica = atleticaRepository.findById(atleticaId)
                .orElseThrow(() -> new IllegalStateException("Atlética não encontrada."));
        Profile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Usuário não encontrado."));

        return associateProfile(atletica, profile, papelCodigo, actorUserId);
    }

    @Transactional
    public AtleticaMembro associateExistingUserByEmail(
            UUID atleticaId,
            String email,
            String papelCodigo,
            UUID actorUserId
    ) {
        Atletica atletica = atleticaRepository.findById(atleticaId)
                .orElseThrow(() -> new IllegalStateException("Atlética não encontrada."));
        Profile profile = profileRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalStateException("Nenhum usuário encontrado com este e-mail."));

        return associateProfile(atletica, profile, papelCodigo, actorUserId);
    }

    private AtleticaMembro associateProfile(Atletica atletica, Profile profile, String papelCodigo, UUID actorUserId) {
        String normalizedPapel = normalizePapel(papelCodigo);
        validatePapel(normalizedPapel);
        validatePresidentConstraint(atletica.getId(), normalizedPapel);

        if (membroRepository.existsByAtletica_IdAndUser_IdAndPapelCodigoAndStatus(
                atletica.getId(),
                profile.getId(),
                normalizedPapel,
                STATUS_ATIVO
        ) || membroRepository.existsByAtletica_IdAndUser_IdAndPapelCodigoAndStatusIn(
                atletica.getId(),
                profile.getId(),
                normalizedPapel,
                List.of(STATUS_CONVOCADO, STATUS_ATIVO)
        )) {
            throw new IllegalStateException("Esse usuário já está vinculado a esta atlética com esse papel.");
        }

        return saveMember(atletica, profile, normalizedPapel, actorUserId);
    }

    @Transactional
    public AtleticaMembro createUserAndAssociate(
            UUID atleticaId,
            String nomeExibicao,
            String email,
            String senha,
            String papelCodigo,
            UUID actorUserId
    ) {
        UUID userId = adminUserService.createAuthUser(email, senha, nomeExibicao, "USER");

        Profile profile = null;
        for (int i = 0; i < 3; i++) {
            try {
                Thread.sleep(400);
            } catch (InterruptedException ignored) {
            }
            profile = profileRepository.findById(userId).orElse(null);
            if (profile != null) {
                break;
            }
        }

        if (profile == null) {
            profile = new Profile();
            profile.setId(userId);
            profile.setNomeExibicao(nomeExibicao);
            profile.setEmail(email);
            profile.setStatus("ATIVO");
            profile.setCriadoEm(OffsetDateTime.now());
            profile.setAtualizadoEm(OffsetDateTime.now());
            profileRepository.save(profile);
            publishProfileProjection(profile, "ProfileCriado");
        } else {
            profile.setNomeExibicao(nomeExibicao);
            profile.setEmail(email);
            profile.setStatus("ATIVO");
            profile.setAtualizadoEm(OffsetDateTime.now());
            profileRepository.save(profile);
            publishProfileProjection(profile, "ProfileAtualizado");
        }

        ensureUserGlobalRole(userId);

        return associateExistingUser(atleticaId, userId, papelCodigo, actorUserId);
    }

    @Transactional
    public void remove(UUID atleticaId, UUID membroId) {
        AtleticaMembro membro = membroRepository.findById(membroId)
                .orElseThrow(() -> new IllegalStateException("Vínculo não encontrado."));

        if (membro.getAtletica() == null || !atleticaId.equals(membro.getAtletica().getId())) {
            throw new IllegalStateException("O vínculo informado não pertence a esta atlética.");
        }

        if (!isSupportedPapel(membro.getPapelCodigo())) {
            throw new IllegalStateException("Este tipo de vínculo não pode ser gerenciado por este fluxo.");
        }

        publishAtleticaMembroProjection(membro, "AtleticaMembroRemovido");
        membroRepository.delete(membro);
    }

    private AtleticaMembro saveMember(Atletica atletica, Profile profile, String papelCodigo, UUID actorUserId) {
        AtleticaMembro membro = new AtleticaMembro();
        membro.setAtletica(atletica);
        membro.setUser(profile);
        membro.setPapelCodigo(papelCodigo);
        membro.setStatus(STATUS_CONVOCADO);
        membro.setCriadoPor(actorUserId);
        membro.setCriadoEm(OffsetDateTime.now());
        AtleticaMembro saved = membroRepository.save(membro);
        publishAtleticaMembroProjection(saved, "AtleticaMembroCriado");
        return saved;
    }

    private void ensureUserGlobalRole(UUID userId) {
        if (!usuarioRoleGlobalRepository.existsByUserIdAndRole(userId, "USER")) {
            UsuarioRoleGlobal role = new UsuarioRoleGlobal();
            role.setUserId(userId);
            role.setRole("USER");
            role.setCriadoEm(OffsetDateTime.now());
            usuarioRoleGlobalRepository.save(role);
        }
    }

    private void validatePapel(String papelCodigo) {
        if (!isSupportedPapel(papelCodigo)) {
            throw new IllegalStateException("Papel inválido ou não suportado por este fluxo.");
        }
    }

    private boolean isSupportedPapel(String papelCodigo) {
        return "PRESIDENT".equalsIgnoreCase(papelCodigo) 
            || "DIRECTOR".equalsIgnoreCase(papelCodigo)
            || "ATHLETE".equalsIgnoreCase(papelCodigo)
            || "COACH".equalsIgnoreCase(papelCodigo);
    }

    private String normalizePapel(String papelCodigo) {
        return papelCodigo == null ? "" : papelCodigo.trim().toUpperCase(Locale.ROOT);
    }

    private void validatePresidentConstraint(UUID atleticaId, String papelCodigo) {
        if ("PRESIDENT".equalsIgnoreCase(papelCodigo)
                && membroRepository.existsByAtletica_IdAndPapelCodigoAndStatusIn(
                        atleticaId,
                        "PRESIDENT",
                        List.of(STATUS_CONVOCADO, STATUS_ATIVO)
                )) {
            throw new IllegalStateException("Essa atlética já possui um presidente ativo ou convocado.");
        }
    }

    private void publishProfileProjection(Profile profile, String eventType) {
        eventPublisherService.publish("Profile", profile.getId().toString(), eventType, java.util.Map.of(
                "profileId", profile.getId().toString(),
                "status", profile.getStatus() == null ? "" : profile.getStatus()
        ));
    }

    private void publishAtleticaMembroProjection(AtleticaMembro membro, String eventType) {
        eventPublisherService.publish("AtleticaMembro", membro.getId().toString(), eventType, java.util.Map.of(
                "atleticaMembroId", membro.getId().toString(),
                "atleticaId", membro.getAtletica() != null ? membro.getAtletica().getId().toString() : "",
                "userId", membro.getUser() != null ? membro.getUser().getId().toString() : "",
                "papelCodigo", membro.getPapelCodigo() == null ? "" : membro.getPapelCodigo(),
                "status", membro.getStatus() == null ? "" : membro.getStatus()
        ));
    }
}
