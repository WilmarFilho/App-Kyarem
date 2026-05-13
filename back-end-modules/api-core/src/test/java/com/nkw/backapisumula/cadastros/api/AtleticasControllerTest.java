package com.nkw.backapisumula.cadastros.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.service.AtleticaMembroService;
import com.nkw.backapisumula.cadastros.service.AtleticaService;
import com.nkw.backapisumula.common.log.ApplicationLogService;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.storage.SupabaseImageUploadService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AtleticasController.class)
class AtleticasControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean private AtleticaService service;
    @MockBean private AtleticaMembroService membroService;
    @MockBean private SupabaseImageUploadService imageUploadService;
    @MockBean private ApplicationLogService applicationLogService;
    @MockBean private JwtDecoder jwtDecoder;
    @MockBean private ProfileRepository profileRepository;

    @Test
    void create_roleAdmin_preencheCriadoPorNoPayload() throws Exception {
        UUID actorId = UUID.fromString("11111111-1111-1111-1111-111111111111");
        UUID atleticaId = UUID.fromString("22222222-2222-2222-2222-222222222222");

        Atletica persisted = new Atletica();
        persisted.setId(atleticaId);
        persisted.setNome("Atlética Teste");
        persisted.setSigla("AT");
        persisted.setCorPrincipal("#009688");
        persisted.setStatus("ATIVA");

        when(service.create(any())).thenReturn(persisted);

        String body = objectMapper.writeValueAsString(
                new AtleticasController.CreateAtleticaRequest(
                        "Atlética Teste",
                        "AT",
                        "#009688",
                        null,
                        "ATIVA"
                )
        );

        mockMvc.perform(post("/api/v1/atleticas")
                        .with(jwt().jwt(jwt -> jwt.subject(actorId.toString()))
                                .authorities(new SimpleGrantedAuthority("ROLE_admin")))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(atleticaId.toString()))
                .andExpect(jsonPath("$.nome").value("Atlética Teste"));

        ArgumentCaptor<Atletica> captor = ArgumentCaptor.forClass(Atletica.class);
        verify(service).create(captor.capture());
        assertThat(captor.getValue().getCriadoPor()).isEqualTo(actorId);
    }
}
