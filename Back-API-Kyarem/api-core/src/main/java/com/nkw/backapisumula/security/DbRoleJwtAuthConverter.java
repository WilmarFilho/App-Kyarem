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
 * Converte um Jwt do Supabase em Authentication, usando o role de negócio do banco:
 * public.profiles.role.
 *
 * - JWT: autentica e fornece o subject (sub) = auth.users.id
 * - DB: determina a role de autorização (admin, arbitro, presidente_atletica, etc.)
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
            case "ORGANIZADOR" -> "ROLE_delegado";
            case "ARBITRO_COMUM", "REFEREE" -> "ROLE_arbitro";
            default -> "ROLE_" + rawRole.trim().toLowerCase(Locale.ROOT);
        };
    }
}
