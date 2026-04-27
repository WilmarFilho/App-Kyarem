package com.nkw.backapisumula.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class SupabaseStorageService {

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.key}")
    private String supabaseKey;

    @Value("${supabase.bucket.sumulas}")
    private String sumulasBucket;

    private final RestTemplate restTemplate = new RestTemplate();

    public void uploadPdf(String fileName, byte[] content) {
        String url = String.format("%s/storage/v1/object/%s/%s", supabaseUrl, sumulasBucket, fileName);

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(supabaseKey);
        headers.set("apikey", supabaseKey);
        headers.setContentType(MediaType.APPLICATION_PDF);

        HttpEntity<byte[]> entity = new HttpEntity<>(content, headers);
        
        restTemplate.exchange(url, HttpMethod.POST, entity, Void.class);
    }

    public String getPublicUrl(String fileName) {
        return String.format("%s/storage/v1/object/public/%s/%s", supabaseUrl, sumulasBucket, fileName);
    }
}
