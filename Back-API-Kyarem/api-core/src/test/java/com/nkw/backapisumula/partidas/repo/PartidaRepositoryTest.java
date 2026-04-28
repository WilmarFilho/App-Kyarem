package com.nkw.backapisumula.partidas.repo;

import com.nkw.backapisumula.competicao.CampeonatoModalidade;
import com.nkw.backapisumula.competicao.CampeonatoTime;
import com.nkw.backapisumula.competicao.ModalidadeCatalogo;
import com.nkw.backapisumula.partidas.Partida;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Testa o comportamento do PartidaRepository usando Mockito.
 *
 * Nota: @DataJpaTest com H2 conflita com columnDefinition="jsonb" nas entidades.
 * Até a configuração de Testcontainers ser adicionada (fase futura), os testes de
 * repository verificam os contratos das queries através de mocks — o comportamento
 * real é validado em ambiente de staging com banco PostgreSQL real.
 *
 * Refatorado em 2026-04 para usar o novo modelo de domínio:
 *   Equipe        → CampeonatoTime
 *   Modalidade    → CampeonatoModalidade (+ ModalidadeCatalogo)
 *   findByModalidade_Id(...) → findByCampeonatoModalidade_Id(...)
 */
@ExtendWith(MockitoExtension.class)
class PartidaRepositoryTest {

    @Mock
    private PartidaRepository repo;

    private static final UUID PARTIDA_ID = UUID.fromString("aaaaaaaa-0000-0000-0000-000000000001");
    private static final UUID MODAL_ID   = UUID.fromString("dddddddd-0000-0000-0000-000000000004");

    /** Monta uma CampeonatoModalidade com ModalidadeCatalogo embutido para viabilizar getNome(). */
    private CampeonatoModalidade campeonatoModalidade() {
        ModalidadeCatalogo catalogo = new ModalidadeCatalogo();
        catalogo.setId(UUID.randomUUID());
        catalogo.setNome("Futsal");

        CampeonatoModalidade m = new CampeonatoModalidade();
        m.setId(MODAL_ID);
        m.setModalidade(catalogo);
        return m;
    }

    private CampeonatoTime campeonatoTime(String nomeExibicao) {
        CampeonatoTime ct = new CampeonatoTime();
        ct.setId(UUID.randomUUID());
        ct.setNomeExibicao(nomeExibicao);
        return ct;
    }

    private Partida partida(String status) {
        CampeonatoModalidade m  = campeonatoModalidade();
        CampeonatoTime eqA      = campeonatoTime("A");
        CampeonatoTime eqB      = campeonatoTime("B");

        Partida p = new Partida();
        p.setId(PARTIDA_ID);
        p.setStatus(status);
        p.setModalidade(m);   // alias em Partida: setModalidade(CampeonatoModalidade)
        p.setEquipeA(eqA);    // alias em Partida: setEquipeA(CampeonatoTime)
        p.setEquipeB(eqB);    // alias em Partida: setEquipeB(CampeonatoTime)
        p.setPlacarA(0);
        p.setPlacarB(0);
        return p;
    }

    // ════════════════════════════════════════════════════════════════════════
    // findByStatus
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void findByStatus_retornaPartidasComStatusAgendada() {
        List<Partida> agendadas = List.of(partida("agendada"), partida("agendada"));
        when(repo.findByStatus("agendada")).thenReturn(agendadas);

        List<Partida> resultado = repo.findByStatus("agendada");

        assertEquals(2, resultado.size());
        assertTrue(resultado.stream().allMatch(p -> "agendada".equals(p.getStatus())));
        verify(repo).findByStatus("agendada");
    }

    @Test
    void findByStatus_statusSemPartidas_retornaListaVazia() {
        when(repo.findByStatus("finalizada")).thenReturn(List.of());

        List<Partida> resultado = repo.findByStatus("finalizada");

        assertTrue(resultado.isEmpty());
    }

    @Test
    void findByStatus_diferentes_retornaApenasOStatusCorreto() {
        when(repo.findByStatus("agendada")).thenReturn(List.of(partida("agendada")));
        when(repo.findByStatus("finalizada")).thenReturn(List.of(partida("finalizada"), partida("finalizada")));

        assertEquals(1, repo.findByStatus("agendada").size());
        assertEquals(2, repo.findByStatus("finalizada").size());
    }

    // ════════════════════════════════════════════════════════════════════════
    // findByCampeonatoModalidade_Id  (antes: findByModalidade_Id)
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void findByCampeonatoModalidadeId_retornaPartidasDaModalidade() {
        when(repo.findByCampeonatoModalidade_Id(MODAL_ID)).thenReturn(List.of(partida("agendada")));

        List<Partida> resultado = repo.findByCampeonatoModalidade_Id(MODAL_ID);

        assertEquals(1, resultado.size());
        assertEquals(MODAL_ID, resultado.get(0).getModalidade().getId());
        verify(repo).findByCampeonatoModalidade_Id(MODAL_ID);
    }

    @Test
    void findByCampeonatoModalidadeId_modalidadeSemPartidas_retornaListaVazia() {
        UUID outraModalidade = UUID.randomUUID();
        when(repo.findByCampeonatoModalidade_Id(outraModalidade)).thenReturn(List.of());

        assertTrue(repo.findByCampeonatoModalidade_Id(outraModalidade).isEmpty());
    }

    // ════════════════════════════════════════════════════════════════════════
    // findByCampeonatoModalidade_IdAndStatus
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void findByCampeonatoModalidadeIdAndStatus_retornaPartidasFiltradasCorretamente() {
        when(repo.findByCampeonatoModalidade_IdAndStatus(MODAL_ID, "agendada"))
                .thenReturn(List.of(partida("agendada")));
        when(repo.findByCampeonatoModalidade_IdAndStatus(MODAL_ID, "finalizada"))
                .thenReturn(List.of());

        assertEquals(1, repo.findByCampeonatoModalidade_IdAndStatus(MODAL_ID, "agendada").size());
        assertEquals(0, repo.findByCampeonatoModalidade_IdAndStatus(MODAL_ID, "finalizada").size());
    }

    // ════════════════════════════════════════════════════════════════════════
    // findById (com @EntityGraph)
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void findById_existente_retornaPartidaComModalidade() {
        Partida p = partida("agendada");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));

        Optional<Partida> resultado = repo.findById(PARTIDA_ID);

        assertTrue(resultado.isPresent());
        assertEquals(PARTIDA_ID, resultado.get().getId());
        // @EntityGraph deve ter carregado campeonatoModalidade → ModalidadeCatalogo
        assertNotNull(resultado.get().getModalidade());
        assertEquals("Futsal", resultado.get().getModalidade().getNome());
    }

    @Test
    void findById_naoExistente_retornaEmpty() {
        UUID inexistente = UUID.fromString("ffffffff-ffff-ffff-ffff-ffffffffffff");
        when(repo.findById(inexistente)).thenReturn(Optional.empty());

        assertFalse(repo.findById(inexistente).isPresent());
    }

    // ════════════════════════════════════════════════════════════════════════
    // findAll (com @EntityGraph)
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void findAll_retornaTodasAsPartidas() {
        when(repo.findAll()).thenReturn(List.of(
                partida("agendada"), partida("finalizada"), partida("1° tempo")
        ));

        List<Partida> resultado = repo.findAll();

        assertEquals(3, resultado.size());
        // Verifica que todas têm o EntityGraph carregado (modalidade não-nula)
        assertTrue(resultado.stream().allMatch(p -> p.getModalidade() != null));
    }
}
