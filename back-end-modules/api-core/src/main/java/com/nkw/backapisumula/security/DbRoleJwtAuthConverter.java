package com.nkw.backapisumula.security;

import com.nkw.backapisumula.identity.repo.ProfileRepository;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Converte um Jwt do Supabase em Authentication usando os papeis globais e
 * contextuais persistidos no banco.
 *
 * - JWT: autentica e fornece o subject (sub) = auth.users.id
 * - DB: determina as authorities de autorização (admin, referee, president, etc.)
 */
public class DbRoleJwtAuthConverter implements Converter<Jwt, AbstractAuthenticationToken> {

    private final ProfileRepository profileRepository;

    public DbRoleJwtAuthConverter(ProfileRepository profileRepository) {
        this.profileRepository = profileRepository;
    }

    @Override
    public AbstractAuthenticationToken convert(Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());

        List<String> authorities = profileRepository.findRolesByUserId(userId).stream()
                .map(this::mapRoleToAuthority)
                .distinct()
                .toList();

        List<SimpleGrantedAuthority> grantedAuthorities = authorities.isEmpty()
                ? List.of(new SimpleGrantedAuthority("ROLE_user"))
                : authorities.stream().map(SimpleGrantedAuthority::new).toList();

        return new JwtAuthenticationToken(
                jwt,
                grantedAuthorities,
                jwt.getSubject()
        );
    }

    private String mapRoleToAuthority(String rawRole) {
        if (rawRole == null || rawRole.isBlank()) {
            return "ROLE_user";
        }

        String role = rawRole.trim().toUpperCase(Locale.ROOT);
        return switch (role) {
            case "ADMIN", "ADMIN_PLATAFORMA" -> "ROLE_admin";
            case "ORGANIZADOR", "DIRECTOR" -> "ROLE_director";
            case "PRESIDENTE_ATLETICA", "PRESIDENT" -> "ROLE_president";
            case "ARBITRO_COMUM", "REFEREE" -> "ROLE_referee";
            case "ALUNO", "ATHLETE" -> "ROLE_athlete";
            case "PUBLICO_LEITURA", "USER" -> "ROLE_user";
            default -> "ROLE_" + rawRole.trim().toLowerCase(Locale.ROOT);
        };
    }
}
