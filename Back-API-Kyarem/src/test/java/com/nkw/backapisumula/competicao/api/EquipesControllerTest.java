package com.nkw.backapisumula.competicao.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nkw.backapisumula.competicao.Equipe;
import com.nkw.backapisumula.competicao.service.EquipeAtletaInscritoService;
import com.nkw.backapisumula.competicao.service.EquipeService;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Testes de API do EquipesController.
 * Verifica RBAC para criação (admin/delegado/presidente_atletica) e consultas.
 */
@WebMvcTest(EquipesController.class)
class EquipesControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean private EquipeService service;
    @MockBean private EquipeAtletaInscritoService inscritosService;
    @MockBean private JwtDecoder jwtDecoder;
    @MockBean private ProfileRepository profileRepository;

    private static final UUID EQUIPE_ID     = UUID.randomUUID();
    private static final UUID ATLETICA_ID   = UUID.randomUUID();
    private static final UUID CAMPEONATO_ID = UUID.randomUUID();
    private static final UUID MODALIDADE_ID = UUID.randomUUID();

    private Equipe equipe() {
        Equipe e = new Equipe();
        e.setId(EQUIPE_ID);
        e.setNomeEquipe("Falcões do Norte");
        return e;
    }

    // ════════════════════════════════════════════════════════════════════════
    // GET /api/v1/equipes — autenticado, qualquer role
    // ════════════════════════════════════════════════════════════════════════

    @Test
    @WithMockUser(roles = "aluno")
    void list_qualquerUsuarioAutenticado_retorna200() throws Exception {
        when(service.list(any(), any(), any())).thenReturn(List.of(equipe()));

        mockMvc.perform(get("/api/v1/equipes"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
    }

    @Test
    void list_semAutenticacao_retorna4xx() throws Exception {
        mockMvc.perform(get("/api/v1/equipes"))
                .andExpect(status().is4xxClientError());
    }

    @Test
    @WithMockUser(roles = "admin")
    void list_comFiltros_retorna200() throws Exception {
        when(service.list(CAMPEONATO_ID, MODALIDADE_ID, null)).thenReturn(List.of(equipe()));

        mockMvc.perform(get("/api/v1/equipes")
                        .param("campeonatoId", CAMPEONATO_ID.toString())
                        .param("modalidadeId", MODALIDADE_ID.toString()))
                .andExpect(status().isOk());
    }

    // ════════════════════════════════════════════════════════════════════════
    // POST /api/v1/equipes — somente admin, delegado, presidente_atletica
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void create_semAutenticacao_retorna403() throws Exception {
        String body = objectMapper.writeValueAsString(new EquipesController.CreateEquipeRequest(
                ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "Falcões"));

        mockMvc.perform(post("/api/v1/equipes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "aluno")
    void create_roleAluno_retorna403() throws Exception {
        String body = objectMapper.writeValueAsString(new EquipesController.CreateEquipeRequest(
                ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "Falcões"));

        mockMvc.perform(post("/api/v1/equipes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "arbitro")
    void create_roleArbitro_retorna403() throws Exception {
        String body = objectMapper.writeValueAsString(new EquipesController.CreateEquipeRequest(
                ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "Falcões"));

        mockMvc.perform(post("/api/v1/equipes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "admin")
    void create_roleAdmin_retorna201() throws Exception {
        when(service.create(any(), any(), any(), any())).thenReturn(equipe());

        String body = objectMapper.writeValueAsString(new EquipesController.CreateEquipeRequest(
                ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "Falcões do Norte"));

        mockMvc.perform(post("/api/v1/equipes")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated());
    }

    @Test
    @WithMockUser(roles = "presidente_atletica")
    void create_rolePresidenteAtletica_retorna201() throws Exception {
        when(service.create(any(), any(), any(), any())).thenReturn(equipe());

        String body = objectMapper.writeValueAsString(new EquipesController.CreateEquipeRequest(
                ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "Minha Equipe"));

        mockMvc.perform(post("/api/v1/equipes")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated());
    }

    @Test
    @WithMockUser(roles = "admin")
    void create_semNomeEquipe_retorna400() throws Exception {
        String body = """
                {
                  "atleticaId": "%s",
                  "campeonatoId": "%s",
                  "modalidadeId": "%s",
                  "nomeEquipe": ""
                }
                """.formatted(ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID);

        mockMvc.perform(post("/api/v1/equipes")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    // ════════════════════════════════════════════════════════════════════════
    // DELETE /api/v1/equipes/{id} — somente admin, delegado, presidente_atletica
    // ════════════════════════════════════════════════════════════════════════

    @Test
    @WithMockUser(roles = "aluno")
    void delete_roleAluno_retorna403() throws Exception {
        mockMvc.perform(delete("/api/v1/equipes/{id}", EQUIPE_ID))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "delegado")
    void delete_roleDelegado_retorna204() throws Exception {
        mockMvc.perform(delete("/api/v1/equipes/{id}", EQUIPE_ID).with(csrf()))
                .andExpect(status().isNoContent());
    }

    // ════════════════════════════════════════════════════════════════════════
    // GET /api/v1/equipes/{id}
    // ════════════════════════════════════════════════════════════════════════

    @Test
    @WithMockUser(roles = "aluno")
    void get_equipeExistente_retorna200() throws Exception {
        when(service.getOrThrow(EQUIPE_ID)).thenReturn(equipe());

        mockMvc.perform(get("/api/v1/equipes/{id}", EQUIPE_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(EQUIPE_ID.toString()));
    }
}
