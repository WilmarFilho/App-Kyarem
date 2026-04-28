package com.nkw.backapisumula.common.log;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ApplicationLogQueryServiceTest {

    @Mock
    private ApplicationLogRepository repository;

    @InjectMocks
    private ApplicationLogQueryService service;

    @Test
    void list_semLimiteInformado_usaLimitePadraoEOrdenaPorDataDesc() {
        when(repository.findAll(any(Specification.class), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(new ApplicationLog())));

        service.list("error", "INTERNAL", 500, UUID.randomUUID(), "req-1", "/api", "ApiExceptionHandler", null, null,
                null);

        ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
        verify(repository).findAll(any(Specification.class), pageableCaptor.capture());

        Pageable pageable = pageableCaptor.getValue();
        assertEquals(50, pageable.getPageSize());
        assertEquals("criadoEm: DESC", pageable.getSort().toString());
    }

    @Test
    void list_nivelInvalido_lancaErro() {
        IllegalArgumentException ex = assertThrows(
                IllegalArgumentException.class,
                () -> service.list("verbose", null, null, null, null, null, null, null, null, 10));

        assertTrue(ex.getMessage().contains("Nivel de log invalido"));
    }

    @Test
    void getOrThrow_quandoNaoExiste_lanca404() {
        UUID id = UUID.randomUUID();
        when(repository.findById(id)).thenReturn(Optional.empty());

        ResponseStatusException ex = assertThrows(ResponseStatusException.class, () -> service.getOrThrow(id));

        assertEquals(404, ex.getStatusCode().value());
    }
}
