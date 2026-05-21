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
     * @param email        e-mail do novo usuário
     * @param password     senha inicial
     * @param nomeExibicao nome de exibição (será gravado no profile via trigger ou
     *                     update manual)
     * @param role         papel inicial colocado no metadata do usuário
     * @return UUID do usuário criado
     */
    public UUID createAuthUser(
            String email,
            String password,
            String nomeExibicao,
            String cpf,
            String role) {
        String url = supabaseUrl + "/auth/v1/admin/users";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(supabaseServiceRoleKey);
        headers.set("apikey", supabaseServiceRoleKey);

        Map<String, Object> userMetadata = new java.util.HashMap<>();
        userMetadata.put("nome_exibicao", nomeExibicao);
        userMetadata.put("role", role);
        if (cpf != null && !cpf.replaceAll("\\D", "").isBlank()) {
            userMetadata.put("cpf", cpf.replaceAll("\\D", ""));
        }

        Map<String, Object> body = Map.of(
                "email", email,
                "password", password,
                "email_confirm", true,
                "user_metadata", userMetadata);

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
        ResponseEntity<com.fasterxml.jackson.databind.JsonNode> response = restTemplate.postForEntity(url, request, com.fasterxml.jackson.databind.JsonNode.class);

        if (response.getStatusCode() == HttpStatus.OK || response.getStatusCode() == HttpStatus.CREATED) {
            com.fasterxml.jackson.databind.JsonNode responseBody = response.getBody();
            if (responseBody == null || !responseBody.hasNonNull("id")) {
                throw new IllegalStateException("Supabase não retornou o ID do usuário criado.");
            }
            return UUID.fromString(responseBody.get("id").asText());
        }

        throw new IllegalStateException("Erro ao criar usuário no Supabase Auth: " + response.getStatusCode());
    }
}
