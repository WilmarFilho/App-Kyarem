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

        String role = profileRepository.findById(userId)
                .map(p -> p.getRole() == null ? "" : p.getRole().trim())
                .filter(s -> !s.isBlank())
                .orElse("aluno");

        String authority = "ROLE_" + role.toLowerCase(Locale.ROOT);

        return new JwtAuthenticationToken(
                jwt,
                List.of(new SimpleGrantedAuthority(authority)),
                jwt.getSubject()
        );
    }
}
