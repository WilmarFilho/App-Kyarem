package com.nkw.backapisumula.security;

import com.nkw.backapisumula.identity.repo.ProfileRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;

import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.oauth2.jwt.JwtDecoders;
import org.springframework.security.oauth2.jwt.JwtDecoder;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Value("${security.jwt.issuer}")
    private String issuer;

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http, ProfileRepository profileRepository) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .authorizeHttpRequests(auth -> auth
                        // Swagger liberado (dev)
                        .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        // health/info se usar actuator
                        .requestMatchers("/actuator/**").permitAll()

                        // leitura pública (se quiser permitir no MVP, pode ajustar depois)
                        .requestMatchers(HttpMethod.GET, "/api/v1/esportes/**").permitAll()

                        // resto precisa auth
                        .anyRequest().authenticated()
                )
                .oauth2ResourceServer(oauth2 -> oauth2
                        // JWT do Supabase autentica (sub = user id). O ROLE do app vem do public.profiles.role.
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(new DbRoleJwtAuthConverter(profileRepository)))
                );

        return http.build();
    }

    @Bean
    JwtDecoder jwtDecoder() {
        // Isso faz o Spring resolver JWKS automaticamente a partir do issuer
        return JwtDecoders.fromIssuerLocation(issuer);
    }
}
