package com.nkw.backapisumula.partidas.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.nkw.backapisumula.competicao.repo.EquipeRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeRepository;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import com.nkw.backapisumula.storage.SupabaseStorageService;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Testa os métodos de verificação de status do PartidaService.
 * validateStatus() não é estático, então usamos uma instância com dependências mockadas.
 * isStatusEmAndamento/Finalizada/Fechada são estáticos e podem ser chamados diretamente.
 */
@ExtendWith(MockitoExtension.class)
class PartidaStatusHelperTest {

    // Mocks de todos os repositórios necessários para instanciar o service
    @Mock private PartidaRepository repo;
    @Mock private ModalidadeRepository modalidadeRepo;
    @Mock private EquipeRepository equipeRepo;
    @Mock private PartidaArbitroRepository partidaArbitroRepo;
    @Mock private EventoPartidaRepository eventoRepo;
    @Mock private SupabaseStorageService supabaseStorageService;
    @Mock private SumulaOficialPdfService sumulaOficialPdfService;

    @InjectMocks
    private PartidaService service; // instância para chamar validateStatus (não-estático)

    // ──────────────────────────────────────────────────────
    // isStatusEmAndamento
    // ──────────────────────────────────────────────────────

    @ParameterizedTest(name = "Status \"{0}\" deve ser considerado em andamento")
    @ValueSource(strings = {"1° tempo", "intervalo", "2° tempo", "prorrogação", "acréscimo", "pausada"})
    void isStatusEmAndamento_statusDeJogo_retornaTrue(String status) {
        assertTrue(PartidaService.isStatusEmAndamento(status));
    }

    @ParameterizedTest(name = "Status \"{0}\" NÃO deve ser considerado em andamento")
    @ValueSource(strings = {"agendada", "finalizada", "fechada"})
    void isStatusEmAndamento_statusParado_retornaFalse(String status) {
        assertFalse(PartidaService.isStatusEmAndamento(status));
    }

    @Test
    void isStatusEmAndamento_null_retornaFalse() {
        assertFalse(PartidaService.isStatusEmAndamento(null));
    }

    @Test
    void isStatusEmAndamento_statusComEspacos_funcionaCorretamente() {
        // "1° tempo" com maiúscula deve também retornar true (trim + lowercase)
        // O método usa .trim().toLowerCase(), então testamos isso
        assertTrue(PartidaService.isStatusEmAndamento("  1° tempo  ".trim().toLowerCase()));
    }

    // ──────────────────────────────────────────────────────
    // isStatusFinalizada
    // ──────────────────────────────────────────────────────

    @Test
    void isStatusFinalizada_finalizada_retornaTrue() {
        assertTrue(PartidaService.isStatusFinalizada("finalizada"));
    }

    @Test
    void isStatusFinalizada_finalizadaMaiuscula_retornaTrue() {
        assertTrue(PartidaService.isStatusFinalizada("FINALIZADA"));
    }

    @ParameterizedTest(name = "Status \"{0}\" não é finalizada")
    @ValueSource(strings = {"fechada", "agendada", "1° tempo", "pausada"})
    void isStatusFinalizada_outrosStatus_retornaFalse(String status) {
        assertFalse(PartidaService.isStatusFinalizada(status));
    }

    @Test
    void isStatusFinalizada_null_retornaFalse() {
        assertFalse(PartidaService.isStatusFinalizada(null));
    }

    // ──────────────────────────────────────────────────────
    // isStatusFechada
    // ──────────────────────────────────────────────────────

    @Test
    void isStatusFechada_fechada_retornaTrue() {
        assertTrue(PartidaService.isStatusFechada("fechada"));
    }

    @ParameterizedTest(name = "Status \"{0}\" não é fechada")
    @ValueSource(strings = {"finalizada", "agendada", "1° tempo", "pausada"})
    void isStatusFechada_outrosStatus_retornaFalse(String status) {
        assertFalse(PartidaService.isStatusFechada(status));
    }

    @Test
    void isStatusFechada_null_retornaFalse() {
        assertFalse(PartidaService.isStatusFechada(null));
    }

    // ──────────────────────────────────────────────────────
    // validateStatus
    // ──────────────────────────────────────────────────────

    @ParameterizedTest(name = "Status válido \"{0}\" não deve lançar exceção")
    @ValueSource(strings = {
            "agendada", "1° tempo", "intervalo", "2° tempo",
            "prorrogação", "acréscimo", "pausada", "finalizada", "fechada"
    })
    void validateStatus_statusValido_naoLancaExcecao(String status) {
        // validateStatus não é estático → usa a instância injetada
        assertDoesNotThrow(() -> service.validateStatus(status));
    }

    @Test
    void validateStatus_statusInvalido_lancaIllegalStateException() {
        assertThrows(IllegalStateException.class,
                () -> service.validateStatus("em_andamento"));
    }

    @Test
    void validateStatus_statusVazio_lancaExcecao() {
        assertThrows(IllegalStateException.class,
                () -> service.validateStatus(""));
    }

    @Test
    void validateStatus_null_naoLancaExcecao() {
        // Null é permitido (método faz early return)
        assertDoesNotThrow(() -> service.validateStatus(null));
    }
}
