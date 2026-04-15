package com.nkw.backapisumula.identity.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.UUID;

/**
 * Cria usuários via Supabase Auth Admin API (requer service_role key).
 * O profile é criado automaticamente via trigger no banco.
 */
@Service
public class SupabaseAdminUserService {

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.key}")
    private String supabaseServiceRoleKey;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * Cria um novo usuário no Supabase Auth e retorna o UUID gerado.
     * O trigger do banco cuida de criar o registro em profiles.
     *
     * @param email       e-mail do novo usuário
     * @param password    senha inicial
     * @param nomeExibicao nome de exibição (será gravado no profile via trigger ou update manual)
     * @param role        role a ser definido no profile (ex: "presidente_atletica")
     * @return UUID do usuário criado
     */
    @SuppressWarnings("unchecked")
    public UUID createAuthUser(String email, String password, String nomeExibicao, String role) {
        String url = supabaseUrl + "/auth/v1/admin/users";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(supabaseServiceRoleKey);
        headers.set("apikey", supabaseServiceRoleKey);

        Map<String, Object> body = Map.of(
                "email", email,
                "password", password,
                "email_confirm", true,
                "user_metadata", Map.of(
                        "nome_exibicao", nomeExibicao,
                        "role", role
                )
        );

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
        ResponseEntity<Map> response = restTemplate.postForEntity(url, request, Map.class);

        if (response.getStatusCode() == HttpStatus.OK || response.getStatusCode() == HttpStatus.CREATED) {
            Map<String, Object> responseBody = response.getBody();
            if (responseBody == null || responseBody.get("id") == null) {
                throw new IllegalStateException("Supabase não retornou o ID do usuário criado.");
            }
            return UUID.fromString(responseBody.get("id").toString());
        }

        throw new IllegalStateException("Erro ao criar usuário no Supabase Auth: " + response.getStatusCode());
    }
}
