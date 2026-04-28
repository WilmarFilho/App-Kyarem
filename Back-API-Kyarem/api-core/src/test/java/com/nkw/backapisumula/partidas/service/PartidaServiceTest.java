package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.cadastros.Esporte;
import com.nkw.backapisumula.common.outbox.EventPublisherService;
import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.CampeonatoModalidade;
import com.nkw.backapisumula.competicao.CampeonatoTime;
import com.nkw.backapisumula.competicao.ModalidadeCatalogo;
import com.nkw.backapisumula.competicao.repo.CampeonatoModalidadeRepository;
import com.nkw.backapisumula.competicao.repo.CampeonatoTimeRepository;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import com.nkw.backapisumula.storage.SupabaseStorageService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * Testes unitários do PartidaService — lógica de negócio crítica (máquina de
 * estados).
 * Usa Mockito: nenhum banco de dados, nenhum contexto Spring.
 *
 * Refatorado em 2026-04 para usar o novo modelo de domínio:
 * Equipe → CampeonatoTime
 * Modalidade → CampeonatoModalidade (+ ModalidadeCatalogo)
 * EquipeRepository → CampeonatoTimeRepository
 * ModalidadeRepository → CampeonatoModalidadeRepository
 * + adicionado mock de EventPublisherService (obrigatório no construtor)
 */
@ExtendWith(MockitoExtension.class)
class PartidaServiceTest {

    // ── Mocks dos repositórios e serviços externos ──────────────────────────
    @Mock
    private PartidaRepository repo;
    @Mock
    private CampeonatoModalidadeRepository modalidadeRepo;
    @Mock
    private CampeonatoTimeRepository equipeRepo;
    @Mock
    private PartidaArbitroRepository partidaArbitroRepo;
    @Mock
    private EventoPartidaRepository eventoRepo;
    @Mock
    private SupabaseStorageService supabaseStorageService;
    @Mock
    private SumulaOficialPdfService sumulaOficialPdfService;
    @Mock
    private EventPublisherService eventPublisherService;

    @InjectMocks
    private PartidaService service;

    // ── IDs fixos para os testes ────────────────────────────────────────────
    private static final UUID PARTIDA_ID = UUID.fromString("aaaaaaaa-0000-0000-0000-000000000001");
    private static final UUID EQUIPE_A_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000002");
    private static final UUID EQUIPE_B_ID = UUID.fromString("cccccccc-0000-0000-0000-000000000003");
    private static final UUID MODALIDADE_ID = UUID.fromString("dddddddd-0000-0000-0000-000000000004");
    private static final UUID CAMPEONATO_ID = UUID.fromString("eeeeeeee-0000-0000-0000-000000000005");
    private static final UUID USUARIO_ID = UUID.fromString("ffffffff-0000-0000-0000-000000000006");

    // ── Helpers para montar entidades ────────────────────────────────────────

    private Campeonato campeonato() {
        Campeonato c = new Campeonato();
        c.setId(CAMPEONATO_ID);
        c.setNome("Copa Kyarem 2025");
        return c;
    }

    private CampeonatoModalidade campeonatoModalidade() {
        Esporte esporte = new Esporte();
        esporte.setId(UUID.randomUUID());
        esporte.setNome("Futsal");

        ModalidadeCatalogo catalogo = new ModalidadeCatalogo();
        catalogo.setId(UUID.randomUUID());
        catalogo.setNome("Futsal Masculino");
        catalogo.setEsporte(esporte);

        CampeonatoModalidade m = new CampeonatoModalidade();
        m.setId(MODALIDADE_ID);
        m.setModalidade(catalogo);
        m.setCampeonato(campeonato());
        return m;
    }

    private CampeonatoTime campeonatoTime(UUID id) {
        CampeonatoTime ct = new CampeonatoTime();
        ct.setId(id);
        ct.setNomeExibicao("Time " + id.toString().substring(0, 4));
        ct.setCampeonatoModalidade(campeonatoModalidade());
        ct.setCampeonato(campeonato());
        ct.setCampeonatoAtleticaId(UUID.randomUUID());
        return ct;
    }

    private Partida partida(String status) {
        Partida p = new Partida();
        p.setId(PARTIDA_ID);
        p.setStatus(status);
        p.setEquipeA(campeonatoTime(EQUIPE_A_ID)); // alias: setEquipeA(CampeonatoTime)
        p.setEquipeB(campeonatoTime(EQUIPE_B_ID)); // alias: setEquipeB(CampeonatoTime)
        p.setModalidade(campeonatoModalidade()); // alias: setModalidade(CampeonatoModalidade)
        p.setPlacarA(0);
        p.setPlacarB(0);
        return p;
    }

    // ════════════════════════════════════════════════════════════════════════
    // create()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void create_equipesIguais_lancaIllegalStateException() {
        assertThrows(IllegalStateException.class, () -> service.create(MODALIDADE_ID, EQUIPE_A_ID, EQUIPE_A_ID,
                null, "Ginásio A", "Masculino", "Grupos"));
    }

    @Test
    void create_modalidadeNaoEncontrada_lancaIllegalStateException() {
        when(modalidadeRepo.findById(MODALIDADE_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalStateException.class, () -> service.create(MODALIDADE_ID, EQUIPE_A_ID, EQUIPE_B_ID,
                null, null, null, null));
    }

    @Test
    void create_equipeANaoEncontrada_lancaIllegalStateException() {
        when(modalidadeRepo.findById(MODALIDADE_ID)).thenReturn(Optional.of(campeonatoModalidade()));
        when(equipeRepo.findById(EQUIPE_A_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalStateException.class, () -> service.create(MODALIDADE_ID, EQUIPE_A_ID, EQUIPE_B_ID,
                null, null, null, null));
    }

    @Test
    void create_sucesso_retornaPartidaComStatusAgendada() {
        CampeonatoTime eqA = campeonatoTime(EQUIPE_A_ID);
        CampeonatoTime eqB = campeonatoTime(EQUIPE_B_ID);
        Partida esperada = partida("agendada");

        when(modalidadeRepo.findById(MODALIDADE_ID)).thenReturn(Optional.of(campeonatoModalidade()));
        when(equipeRepo.findById(EQUIPE_A_ID)).thenReturn(Optional.of(eqA));
        when(equipeRepo.findById(EQUIPE_B_ID)).thenReturn(Optional.of(eqB));
        when(repo.save(any(Partida.class))).thenReturn(esperada);
        // EventPublisherService.publish é void — sem stubbing necessário
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        Partida resultado = service.create(MODALIDADE_ID, EQUIPE_A_ID, EQUIPE_B_ID,
                null, "Ginásio A", "Masculino", "Fase de Grupos");

        assertNotNull(resultado);
        assertEquals("agendada", resultado.getStatus());
        verify(repo, times(1)).save(any(Partida.class));
    }

    @Test
    void create_equipesDeModalidadesDiferentes_lancaIllegalStateException() {
        // eqB pertence a uma modalidade com ID diferente
        CampeonatoModalidade outraModal = campeonatoModalidade();
        outraModal.setId(UUID.randomUUID());

        CampeonatoTime eqA = campeonatoTime(EQUIPE_A_ID);

        CampeonatoTime eqB = campeonatoTime(EQUIPE_B_ID);
        eqB.setCampeonatoModalidade(outraModal);

        when(modalidadeRepo.findById(MODALIDADE_ID)).thenReturn(Optional.of(campeonatoModalidade()));
        when(equipeRepo.findById(EQUIPE_A_ID)).thenReturn(Optional.of(eqA));
        when(equipeRepo.findById(EQUIPE_B_ID)).thenReturn(Optional.of(eqB));

        assertThrows(IllegalStateException.class, () -> service.create(MODALIDADE_ID, EQUIPE_A_ID, EQUIPE_B_ID,
                null, null, null, null));
    }

    // ════════════════════════════════════════════════════════════════════════
    // start()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void start_partidaAgendada_mudaStatusParaPrimeiroTempo() {
        Partida p = partida("agendada");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        Partida resultado = service.start(PARTIDA_ID, USUARIO_ID, false);

        assertEquals("1° tempo", resultado.getStatus());
        assertNotNull(resultado.getIniciadaEm());
    }

    @Test
    void start_partidaAgendada_admin_naoVerificaAtribuicao() {
        Partida p = partida("agendada");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        // isArbitroOnly = false → não deve checar existsByPartida_IdAndArbitro_Id
        service.start(PARTIDA_ID, USUARIO_ID, false);

        verify(partidaArbitroRepo, never()).existsByPartida_IdAndArbitro_Id(any(), any());
    }

    @Test
    void start_partidaEmAndamento_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("1° tempo")));

        assertThrows(IllegalStateException.class,
                () -> service.start(PARTIDA_ID, USUARIO_ID, false));
    }

    @Test
    void start_partidaFinalizada_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("finalizada")));

        assertThrows(IllegalStateException.class,
                () -> service.start(PARTIDA_ID, USUARIO_ID, false));
    }

    @Test
    void start_partidaFechada_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("fechada")));

        assertThrows(IllegalStateException.class,
                () -> service.start(PARTIDA_ID, USUARIO_ID, false));
    }

    @Test
    void start_arbitroNaoAtribuido_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("agendada")));
        when(partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, USUARIO_ID))
                .thenReturn(false);

        assertThrows(IllegalStateException.class,
                () -> service.start(PARTIDA_ID, USUARIO_ID, true)); // isArbitroOnly = true
    }

    @Test
    void start_arbitroAtribuido_sucesso() {
        Partida p = partida("agendada");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));
        when(partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, USUARIO_ID))
                .thenReturn(true);
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        Partida resultado = service.start(PARTIDA_ID, USUARIO_ID, true);

        assertEquals("1° tempo", resultado.getStatus());
    }

    // ════════════════════════════════════════════════════════════════════════
    // end()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void end_partidaFinalizada_mudaParaFechada() throws Exception {
        Partida p = partida("finalizada");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));
        when(eventoRepo.findByPartidaIdWithDetails(PARTIDA_ID)).thenReturn(Collections.emptyList());
        when(partidaArbitroRepo.findByPartidaIdWithArbitro(PARTIDA_ID)).thenReturn(Collections.emptyList());
        when(sumulaOficialPdfService.gerarPdf(PARTIDA_ID)).thenReturn(new byte[] { 1, 2, 3 });
        when(supabaseStorageService.getPublicUrl(any())).thenReturn("http://fake.url/sumula.pdf");
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        Partida resultado = service.end(PARTIDA_ID, USUARIO_ID, false);

        assertEquals("fechada", resultado.getStatus());
        assertNotNull(resultado.getEncerradaEm());
        assertNotNull(resultado.getSnapshotSumula());
        assertNotNull(resultado.getHashIntegridade());
        assertEquals("http://fake.url/sumula.pdf", resultado.getSumulaPdfUrl());
    }

    @Test
    void end_partidaNaoFinalizada_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("1° tempo")));

        assertThrows(IllegalStateException.class,
                () -> service.end(PARTIDA_ID, USUARIO_ID, false));
    }

    @Test
    void end_partidaJaFechada_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("fechada")));

        assertThrows(IllegalStateException.class,
                () -> service.end(PARTIDA_ID, USUARIO_ID, false));
    }

    @Test
    void end_arbitroNaoAtribuido_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("finalizada")));
        when(partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, USUARIO_ID))
                .thenReturn(false);

        assertThrows(IllegalStateException.class,
                () -> service.end(PARTIDA_ID, USUARIO_ID, true));
    }

    // ════════════════════════════════════════════════════════════════════════
    // updateStatus()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void updateStatus_transicaoValida_atualizaStatus() {
        Partida p = partida("1° tempo");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        Partida resultado = service.updateStatus(PARTIDA_ID, USUARIO_ID, false, "intervalo", null);

        assertEquals("intervalo", resultado.getStatus());
    }

    @Test
    void updateStatus_tentarUsarFechada_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("1° tempo")));

        // "fechada" é reservado para o endpoint /end
        assertThrows(IllegalStateException.class,
                () -> service.updateStatus(PARTIDA_ID, USUARIO_ID, false, "fechada", null));
    }

    @Test
    void updateStatus_partidaJaFinalizada_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("finalizada")));

        // Não pode reabrir partida já encerrada
        assertThrows(IllegalStateException.class,
                () -> service.updateStatus(PARTIDA_ID, USUARIO_ID, false, "intervalo", null));
    }

    @Test
    void updateStatus_statusInvalido_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida("1° tempo")));

        assertThrows(IllegalStateException.class,
                () -> service.updateStatus(PARTIDA_ID, USUARIO_ID, false, "zumbi", null));
    }

    @Test
    void updateStatus_pausada_salvaStatusAntesPausa() {
        Partida p = partida("2° tempo");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        Partida resultado = service.updateStatus(PARTIDA_ID, USUARIO_ID, false,
                "pausada", "2° tempo");

        assertEquals("pausada", resultado.getStatus());
        assertEquals("2° tempo", resultado.getStatusAntesPausa());
    }

    @Test
    void updateStatus_normalizacaoDeStatus_funcionaCorretamente() {
        // "prorrogacao" (sem acento) deve ser normalizado para "prorrogação"
        Partida p = partida("2° tempo");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        Partida resultado = service.updateStatus(PARTIDA_ID, USUARIO_ID, false,
                "prorrogacao", null);

        assertEquals("prorrogação", resultado.getStatus());
    }

    @Test
    void updateStatus_penaltis_semAcento_normalizaCorretamente() {
        Partida p = partida("prorrogação");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        Partida resultado = service.updateStatus(PARTIDA_ID, USUARIO_ID, false,
                "penaltis", null);

        assertEquals("pênaltis", resultado.getStatus());
    }

    // ════════════════════════════════════════════════════════════════════════
    // delete()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void delete_partidaExistente_chamaRepositoryDelete() {
        Partida p = partida("agendada");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));
        doNothing().when(eventPublisherService).publish(anyString(), anyString(), anyString(), any(Map.class));

        service.delete(PARTIDA_ID);

        verify(repo, times(1)).delete(p);
    }

    @Test
    void delete_partidaNaoEncontrada_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalStateException.class,
                () -> service.delete(PARTIDA_ID));
    }

    // ════════════════════════════════════════════════════════════════════════
    // list()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void list_semFiltros_retornaTodasAsPartidas() {
        when(repo.findAll()).thenReturn(List.of(partida("agendada"), partida("finalizada")));

        List<Partida> resultado = service.list(null, null);

        assertEquals(2, resultado.size());
        verify(repo).findAll();
    }

    @Test
    void list_comModalidadeId_usaQueryCorreta() {
        when(repo.findByCampeonatoModalidade_Id(MODALIDADE_ID)).thenReturn(List.of(partida("agendada")));

        List<Partida> resultado = service.list(MODALIDADE_ID, null);

        assertEquals(1, resultado.size());
        verify(repo).findByCampeonatoModalidade_Id(MODALIDADE_ID);
    }

    @Test
    void list_statusInvalido_naoValidaNoService_passaParaRepository() {
        // list() no SERVICE não valida o status (quem valida é o controller).
        when(repo.findByStatus("status_invalido")).thenReturn(List.of());

        List<Partida> resultado = service.list(null, "status_invalido");

        assertTrue(resultado.isEmpty()); // não lança exceção
        verify(repo).findByStatus("status_invalido");
    }

    // ════════════════════════════════════════════════════════════════════════
    // getOrThrow()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void getOrThrow_partidaExistente_retornaPartida() {
        Partida p = partida("agendada");
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.of(p));

        Partida resultado = service.getOrThrow(PARTIDA_ID);

        assertNotNull(resultado);
        assertEquals(PARTIDA_ID, resultado.getId());
    }

    @Test
    void getOrThrow_partidaNaoEncontrada_lancaIllegalStateException() {
        when(repo.findById(PARTIDA_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalStateException.class,
                () -> service.getOrThrow(PARTIDA_ID));
    }
}
