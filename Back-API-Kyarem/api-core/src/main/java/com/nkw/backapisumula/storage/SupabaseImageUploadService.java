package com.nkw.backapisumula.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class SupabaseImageUploadService {

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.key}")
    private String supabaseKey;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * Faz upload de uma imagem para o Supabase Storage (upsert).
     *
     * @param bucket      nome do bucket (ex: "avatars")
     * @param path        caminho dentro do bucket (ex: "campeonatos/uuid.jpg")
     * @param content     bytes da imagem
     * @param contentType tipo MIME (ex: "image/jpeg")
     */
    public void uploadImage(String bucket, String path, byte[] content, String contentType) {
        String url = String.format("%s/storage/v1/object/%s/%s", supabaseUrl, bucket, path);

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(supabaseKey);
        headers.set("apikey", supabaseKey);
        headers.setContentType(MediaType.parseMediaType(contentType));
        headers.set("x-upsert", "true");

        HttpEntity<byte[]> entity = new HttpEntity<>(content, headers);
        restTemplate.exchange(url, HttpMethod.POST, entity, Void.class);
    }

    /**
     * Retorna a URL pública de um arquivo no Supabase Storage.
     */
    public String getPublicUrl(String bucket, String path) {
        return String.format("%s/storage/v1/object/public/%s/%s", supabaseUrl, bucket, path);
    }
}
