package com.nkw.backapisumula.common.api;

import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import com.nkw.backapisumula.common.log.ApplicationLog;
import com.nkw.backapisumula.common.log.ApplicationLogLevel;
import com.nkw.backapisumula.common.log.ApplicationLogQueryService;
import com.nkw.backapisumula.common.log.ApplicationLogService;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.security.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.context.annotation.Import;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ApplicationLogsController.class)
@Import(SecurityConfig.class)
class ApplicationLogsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean private ApplicationLogQueryService queryService;
    @MockitoBean private ApplicationLogService applicationLogService;
    @MockitoBean private JwtDecoder jwtDecoder;
    @MockitoBean private ProfileRepository profileRepository;

    private static final UUID LOG_ID = UUID.fromString("aaaaaaaa-1111-2222-3333-444444444444");
    private static final UUID USER_ID = UUID.fromString("bbbbbbbb-1111-2222-3333-444444444444");

    private ApplicationLog applicationLog() {
        ApplicationLog log = new ApplicationLog();
        log.setId(LOG_ID);
        log.setLevel(ApplicationLogLevel.ERROR);
        log.setCategory("INTERNAL");
        log.setMessage("Erro inesperado no back-end");
        log.setSource("ApiExceptionHandler");
        log.setExceptionClass("java.lang.RuntimeException");
        log.setStackTrace("linha 1\nlinha 2");
        log.setDetails(JsonNodeFactory.instance.objectNode().put("requestId", "req-123"));
        log.setHttpMethod("GET");
        log.setPath("/api/v1/partidas");
        log.setStatusCode(500);
        log.setUserId(USER_ID);
        log.setRequestId("req-123");
        log.setIpAddress("127.0.0.1");
        log.setUserAgent("JUnit");
        log.setCriadoEm(OffsetDateTime.parse("2026-04-12T12:00:00Z"));
        return log;
    }

    @Test
    @WithMockUser(roles = "admin")
    void list_roleAdmin_retorna200ComResumo() throws Exception {
        when(queryService.list(eq("error"), eq("INTERNAL"), eq(500), eq(USER_ID), eq("req-123"), eq("/api/v1"), eq("ApiExceptionHandler"), any(), any(), eq(10)))
                .thenReturn(List.of(applicationLog()));

        mockMvc.perform(get("/api/v1/admin/logs")
                        .param("level", "error")
                        .param("category", "INTERNAL")
                        .param("statusCode", "500")
                        .param("userId", USER_ID.toString())
                        .param("requestId", "req-123")
                        .param("path", "/api/v1")
                        .param("source", "ApiExceptionHandler")
                        .param("from", "2026-04-01T00:00:00Z")
                        .param("to", "2026-04-12T23:59:59Z")
                        .param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$[0].id").value(LOG_ID.toString()))
                .andExpect(jsonPath("$[0].level").value("ERROR"))
                .andExpect(jsonPath("$[0].requestId").value("req-123"))
                .andExpect(jsonPath("$[0].stackTrace").doesNotExist());

        verify(queryService).list(eq("error"), eq("INTERNAL"), eq(500), eq(USER_ID), eq("req-123"), eq("/api/v1"), eq("ApiExceptionHandler"), any(), any(), eq(10));
    }

    @Test
    @WithMockUser(roles = "admin")
    void get_roleAdmin_retorna200ComDetalhe() throws Exception {
        when(queryService.getOrThrow(LOG_ID)).thenReturn(applicationLog());

        mockMvc.perform(get("/api/v1/admin/logs/{id}", LOG_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(LOG_ID.toString()))
                .andExpect(jsonPath("$.stackTrace").value("linha 1\nlinha 2"))
                .andExpect(jsonPath("$.details.requestId").value("req-123"));
    }

    @Test
    @WithMockUser(roles = "delegado")
    void list_roleNaoAdmin_retorna403() throws Exception {
        mockMvc.perform(get("/api/v1/admin/logs"))
                .andExpect(status().isForbidden());
    }
}
