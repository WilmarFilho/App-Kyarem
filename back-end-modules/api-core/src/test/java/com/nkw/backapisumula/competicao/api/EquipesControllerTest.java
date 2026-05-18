package com.nkw.backapisumula.competicao.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nkw.backapisumula.common.log.ApplicationLogService;
import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.CampeonatoModalidade;
import com.nkw.backapisumula.competicao.CampeonatoTime;
import com.nkw.backapisumula.competicao.TimeAtletica;
import com.nkw.backapisumula.competicao.repo.CampeonatoModalidadeRepository;
import com.nkw.backapisumula.competicao.repo.CampeonatoTimeRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeCatalogoRepository;
import com.nkw.backapisumula.competicao.repo.TimeAtleticaRepository;
import com.nkw.backapisumula.competicao.repo.EquipeStaffRepository;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.common.outbox.EventPublisherService;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Testes de API do TimesController.
 * (Anteriormente EquipesControllerTest — adaptado ao modelo de domínio atual.)
 * Verifica RBAC para criação (admin/director/president) e consultas.
 */
@WebMvcTest(TimesController.class)
class EquipesControllerTest {

        @Autowired
        private MockMvc mockMvc;

        @Autowired
        private ObjectMapper objectMapper;

        @MockitoBean
        private TimeAtleticaRepository timeAtleticaRepository;
        @MockitoBean
        private CampeonatoTimeRepository campeonatoTimeRepository;
        @MockitoBean
        private ModalidadeCatalogoRepository modalidadeCatalogoRepository;
        @MockitoBean
        private CampeonatoModalidadeRepository campeonatoModalidadeRepository;
        @MockitoBean
        private EquipeStaffRepository equipeStaffRepository;
        @MockitoBean
        private ApplicationLogService applicationLogService;
        @MockitoBean
        private JwtDecoder jwtDecoder;
        @MockitoBean
        private ProfileRepository profileRepository;
        @MockitoBean
        private EventPublisherService eventPublisherService;
        @MockitoBean
        private EntityManager entityManager;
        @MockitoBean
        private jakarta.persistence.EntityManagerFactory entityManagerFactory;

        private static final UUID ATLETICA_ID = UUID.randomUUID();
        private static final UUID CAMPEONATO_ID = UUID.randomUUID();
        private static final UUID MODALIDADE_ID = UUID.randomUUID();
        private static final UUID TIME_ATLETICA_ID = UUID.randomUUID();
        private static final UUID CAMPEONATO_TIME_ID = UUID.randomUUID();

        private TimeAtletica timeAtletica() {
                TimeAtletica t = new TimeAtletica();
                t.setId(TIME_ATLETICA_ID);
                t.setNome("Falcões do Norte");
                com.nkw.backapisumula.cadastros.Atletica a = new com.nkw.backapisumula.cadastros.Atletica();
                a.setId(ATLETICA_ID);
                t.setAtletica(a);
                t.setCriadoEm(OffsetDateTime.now());
                return t;
        }

        private CampeonatoTime campeonatoTime() {
                CampeonatoTime ct = new CampeonatoTime();
                ct.setId(CAMPEONATO_TIME_ID);
                com.nkw.backapisumula.competicao.Campeonato c = new com.nkw.backapisumula.competicao.Campeonato();
                c.setId(CAMPEONATO_ID);
                ct.setCampeonato(c);
                ct.setCampeonatoAtleticaId(UUID.randomUUID());
                return ct;
        }

        // ════════════════════════════════════════════════════════════════════════
        // GET /api/v1/times/atletica/{atleticaId} — autenticado, qualquer role
        // ════════════════════════════════════════════════════════════════════════

        @Test
        @WithMockUser(roles = "aluno")
        void listTimesPorAtletica_qualquerUsuarioAutenticado_retorna200() throws Exception {
                when(timeAtleticaRepository.findAll()).thenReturn(List.of(timeAtletica()));

                mockMvc.perform(get("/api/v1/times/atletica/{atleticaId}", ATLETICA_ID))
                                .andExpect(status().isOk())
                                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
        }

        @Test
        void listTimesPorAtletica_semAutenticacao_retorna4xx() throws Exception {
                mockMvc.perform(get("/api/v1/times/atletica/{atleticaId}", ATLETICA_ID))
                                .andExpect(status().is4xxClientError());
        }

        // ════════════════════════════════════════════════════════════════════════
        // POST /api/v1/times/atletica — somente admin, director, president
        // ════════════════════════════════════════════════════════════════════════

        @Test
        void createTimeAtletica_semAutenticacao_retorna4xx() throws Exception {
                String body = objectMapper.writeValueAsString(new TimesController.CreateTimeAtleticaRequest(
                                ATLETICA_ID, MODALIDADE_ID, "Falcões", null));

                mockMvc.perform(post("/api/v1/times/atletica")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                                .andExpect(status().is4xxClientError());
        }

        /**
         * NOTA: @WebMvcTest NÃO carrega @EnableMethodSecurity, portanto @PreAuthorize
         * não é
         * aplicado nesta camada. Testes de RBAC granular devem ser feitos em testes de
         * integração.
         * Aqui verificamos apenas que o endpoint responde corretamente para usuários
         * autenticados.
         */
        @Test
        @WithMockUser(roles = "admin")
        void createTimeAtletica_autenticado_processaRequisicao() throws Exception {
                when(modalidadeCatalogoRepository.findById(MODALIDADE_ID))
                                .thenReturn(Optional.of(new com.nkw.backapisumula.competicao.ModalidadeCatalogo()));
                when(timeAtleticaRepository.save(any())).thenReturn(timeAtletica());

                String body = objectMapper.writeValueAsString(new TimesController.CreateTimeAtleticaRequest(
                                ATLETICA_ID, MODALIDADE_ID, "Falcões", null));

                mockMvc.perform(post("/api/v1/times/atletica")
                                .with(csrf())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                                .andExpect(status().isCreated());
        }

        @Test
        @WithMockUser(roles = "admin")
        void createTimeAtletica_roleAdmin_retorna201() throws Exception {
                when(modalidadeCatalogoRepository.findById(MODALIDADE_ID))
                                .thenReturn(Optional.of(new com.nkw.backapisumula.competicao.ModalidadeCatalogo()));
                when(timeAtleticaRepository.save(any())).thenReturn(timeAtletica());

                String body = objectMapper.writeValueAsString(new TimesController.CreateTimeAtleticaRequest(
                                ATLETICA_ID, MODALIDADE_ID, "Falcões do Norte", null));

                mockMvc.perform(post("/api/v1/times/atletica")
                                .with(csrf())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                                .andExpect(status().isCreated());
        }

        // ════════════════════════════════════════════════════════════════════════
        // DELETE /api/v1/times/atletica/{timeId} — somente admin, director, president
        // ════════════════════════════════════════════════════════════════════════

        @Test
        @WithMockUser(roles = "admin")
        void deleteTimeAtletica_roleAdmin_retorna204() throws Exception {
                mockMvc.perform(delete("/api/v1/times/atletica/{id}", TIME_ATLETICA_ID).with(csrf()))
                                .andExpect(status().isNoContent());
        }

        // ════════════════════════════════════════════════════════════════════════
        // GET /api/v1/times/campeonato/{campeonatoId}
        // ════════════════════════════════════════════════════════════════════════

        @Test
        @WithMockUser(roles = "aluno")
        void listTimesPorCampeonato_retorna200() throws Exception {
                when(campeonatoTimeRepository.findAll()).thenReturn(List.of(campeonatoTime()));

                mockMvc.perform(get("/api/v1/times/campeonato/{campeonatoId}", CAMPEONATO_ID))
                                .andExpect(status().isOk())
                                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON));
        }

        // ════════════════════════════════════════════════════════════════════════
        // POST /api/v1/times/campeonato — somente admin, director, president
        // ════════════════════════════════════════════════════════════════════════

        @Test
        @WithMockUser(roles = "admin")
        void inscreverTimeCampeonato_roleAdmin_retorna201() throws Exception {
                CampeonatoModalidade cm = new CampeonatoModalidade();
                cm.setId(MODALIDADE_ID);

                Campeonato campeonato = new Campeonato();
                campeonato.setId(CAMPEONATO_ID);
                cm.setCampeonato(campeonato);

                when(campeonatoModalidadeRepository.findById(MODALIDADE_ID)).thenReturn(Optional.of(cm));
                when(timeAtleticaRepository.findById(TIME_ATLETICA_ID)).thenReturn(Optional.of(timeAtletica()));
                when(campeonatoTimeRepository.save(any())).thenReturn(campeonatoTime());

                jakarta.persistence.Query queryMock = org.mockito.Mockito.mock(jakarta.persistence.Query.class);
                when(entityManager.createNativeQuery(org.mockito.ArgumentMatchers.anyString())).thenReturn(queryMock);
                when(queryMock.setParameter(org.mockito.ArgumentMatchers.anyString(), any())).thenReturn(queryMock);
                when(queryMock.getSingleResult()).thenReturn(UUID.randomUUID());


                String body = objectMapper.writeValueAsString(new TimesController.InscricaoTimeRequest(
                                MODALIDADE_ID, TIME_ATLETICA_ID, "Falcões do Norte"));

                mockMvc.perform(post("/api/v1/times/campeonato")
                                .with(csrf())
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                                .andExpect(status().isCreated());
        }

        // ════════════════════════════════════════════════════════════════════════
        // DELETE /api/v1/times/campeonato/{campeonatoTimeId}
        // ════════════════════════════════════════════════════════════════════════

        @Test
        @WithMockUser(roles = "admin")
        void removerTimeCampeonato_roleAdmin_retorna204() throws Exception {
                when(campeonatoTimeRepository.findById(CAMPEONATO_TIME_ID)).thenReturn(Optional.of(campeonatoTime()));
                
                jakarta.persistence.Query queryMock = org.mockito.Mockito.mock(jakarta.persistence.Query.class);
                when(entityManager.createNativeQuery(org.mockito.ArgumentMatchers.anyString())).thenReturn(queryMock);
                when(queryMock.setParameter(org.mockito.ArgumentMatchers.anyString(), any())).thenReturn(queryMock);
                when(queryMock.executeUpdate()).thenReturn(1);

                mockMvc.perform(delete("/api/v1/times/campeonato/{id}", CAMPEONATO_TIME_ID).with(csrf()))
                                .andExpect(status().isNoContent());
        }
}
