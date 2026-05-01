package com.nkw.backapisumula.cadastros.service;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.AtleticaMembro;
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

    private static final String STATUS_ATIVO = "ATIVO";

    private final AtleticaMembroRepository membroRepository;
    private final AtleticaRepository atleticaRepository;
    private final ProfileRepository profileRepository;
    private final SupabaseAdminUserService adminUserService;
    private final UsuarioRoleGlobalRepository usuarioRoleGlobalRepository;

    public AtleticaMembroService(
            AtleticaMembroRepository membroRepository,
            AtleticaRepository atleticaRepository,
            ProfileRepository profileRepository,
            SupabaseAdminUserService adminUserService,
            UsuarioRoleGlobalRepository usuarioRoleGlobalRepository
    ) {
        this.membroRepository = membroRepository;
        this.atleticaRepository = atleticaRepository;
        this.profileRepository = profileRepository;
        this.adminUserService = adminUserService;
        this.usuarioRoleGlobalRepository = usuarioRoleGlobalRepository;
    }

    public List<AtleticaMembro> list(UUID atleticaId) {
        return membroRepository.findByAtletica_IdOrderByCriadoEmAsc(atleticaId).stream()
                .filter(membro -> isSupportedPapel(membro.getPapelCodigo()))
                .toList();
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

        String normalizedPapel = normalizePapel(papelCodigo);
        validatePapel(normalizedPapel);
        validatePresidentConstraint(atleticaId, normalizedPapel);

        if (membroRepository.existsByAtletica_IdAndUser_IdAndPapelCodigoAndStatus(
                atleticaId,
                userId,
                normalizedPapel,
                STATUS_ATIVO
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
        } else {
            profile.setNomeExibicao(nomeExibicao);
            profile.setEmail(email);
            profile.setStatus("ATIVO");
            profile.setAtualizadoEm(OffsetDateTime.now());
            profileRepository.save(profile);
        }

        ensureUserGlobalRole(userId);

        return associateExistingUser(atleticaId, userId, papelCodigo, actorUserId);
    }

    private AtleticaMembro saveMember(Atletica atletica, Profile profile, String papelCodigo, UUID actorUserId) {
        AtleticaMembro membro = new AtleticaMembro();
        membro.setAtletica(atletica);
        membro.setUser(profile);
        membro.setPapelCodigo(papelCodigo);
        membro.setStatus(STATUS_ATIVO);
        membro.setCriadoPor(actorUserId);
        membro.setCriadoEm(OffsetDateTime.now());
        membro.setIniciadoEm(OffsetDateTime.now());
        return membroRepository.save(membro);
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
            throw new IllegalStateException("Somente PRESIDENT e DIRECTOR podem ser geridos por este fluxo.");
        }
    }

    private boolean isSupportedPapel(String papelCodigo) {
        return "PRESIDENT".equalsIgnoreCase(papelCodigo) || "DIRECTOR".equalsIgnoreCase(papelCodigo);
    }

    private String normalizePapel(String papelCodigo) {
        return papelCodigo == null ? "" : papelCodigo.trim().toUpperCase(Locale.ROOT);
    }

    private void validatePresidentConstraint(UUID atleticaId, String papelCodigo) {
        if ("PRESIDENT".equalsIgnoreCase(papelCodigo)
                && membroRepository.existsByAtletica_IdAndPapelCodigoAndStatus(atleticaId, "PRESIDENT", STATUS_ATIVO)) {
            throw new IllegalStateException("Essa atlética já possui um presidente ativo.");
        }
    }
}
