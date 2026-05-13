package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.PartidaArbitro;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Testes unitários do PartidaArbitroService — atribuição e remoção de árbitros.
 */
@ExtendWith(MockitoExtension.class)
class PartidaArbitroServiceTest {

    @Mock private PartidaArbitroRepository repo;
    @Mock private PartidaRepository partidaRepo;
    @Mock private ProfileRepository profileRepo;

    @InjectMocks
    private PartidaArbitroService service;

    private static final UUID PARTIDA_ID        = UUID.fromString("aaaaaaaa-0000-0000-0000-000000000011");
    private static final UUID ARBITRO_ID        = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000022");
    private static final UUID VINCULO_ID        = UUID.fromString("cccccccc-0000-0000-0000-000000000033");
    private static final UUID ACTION_USER_ID    = UUID.fromString("dddddddd-0000-0000-0000-000000000044");

    private Partida partida() {
        Partida p = new Partida();
        p.setId(PARTIDA_ID);
        p.setStatus("agendada");
        p.setCriadoPor(ACTION_USER_ID);
        return p;
    }

    private Profile perfil() {
        Profile profile = new Profile();
        profile.setId(ARBITRO_ID);
        profile.setNomeExibicao("João Árbitro");
        profile.setRole("arbitro");
        return profile;
    }

    private PartidaArbitro vinculo() {
        PartidaArbitro pa = new PartidaArbitro();
        pa.setId(VINCULO_ID);
        pa.setPartida(partida());
        pa.setArbitro(perfil());
        pa.setFuncao("árbitro principal");
        return pa;
    }

    // ════════════════════════════════════════════════════════════════════════
    // add()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void add_arbitroAtribuicaoComSucesso_retornaVinculo() {
        when(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID)).thenReturn(false);
        when(partidaRepo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida()));
        when(profileRepo.findById(ARBITRO_ID)).thenReturn(Optional.of(perfil()));
        when(profileRepo.findRolesByUserId(ARBITRO_ID)).thenReturn(java.util.List.of("REFEREE"));
        when(repo.save(any(PartidaArbitro.class))).thenReturn(vinculo());

        PartidaArbitro resultado = service.add(PARTIDA_ID, ARBITRO_ID, "árbitro principal", ACTION_USER_ID);

        assertNotNull(resultado);
        assertEquals(VINCULO_ID, resultado.getId());
        assertEquals("árbitro principal", resultado.getFuncao());
        verify(repo, times(1)).save(any(PartidaArbitro.class));
    }

    @Test
    void add_arbitroJaAtribuido_lancaIllegalStateException() {
        when(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID)).thenReturn(true);

        assertThrows(IllegalStateException.class,
                () -> service.add(PARTIDA_ID, ARBITRO_ID, "árbitro principal", ACTION_USER_ID));

        // Garante que nada foi salvo
        verify(repo, never()).save(any());
    }

    @Test
    void add_partidaNaoEncontrada_lancaIllegalStateException() {
        when(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID)).thenReturn(false);
        when(partidaRepo.findById(PARTIDA_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalStateException.class,
                () -> service.add(PARTIDA_ID, ARBITRO_ID, "árbitro principal", ACTION_USER_ID));
    }

    @Test
    void add_perfilNaoEncontrado_lancaIllegalStateException() {
        when(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID)).thenReturn(false);
        when(partidaRepo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida()));
        when(profileRepo.findById(ARBITRO_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalStateException.class,
                () -> service.add(PARTIDA_ID, ARBITRO_ID, "árbitro principal", ACTION_USER_ID));
    }

    @Test
    void add_salvaComDadosCorretos() {
        when(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID)).thenReturn(false);
        when(partidaRepo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida()));
        when(profileRepo.findById(ARBITRO_ID)).thenReturn(Optional.of(perfil()));
        when(profileRepo.findRolesByUserId(ARBITRO_ID)).thenReturn(java.util.List.of("REFEREE"));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // Verifica que o objeto salvo tem os dados corretos preenchidos
        PartidaArbitro resultado = service.add(PARTIDA_ID, ARBITRO_ID, "fiscal", ACTION_USER_ID);

        assertEquals(PARTIDA_ID, resultado.getPartida().getId());
        assertEquals(ARBITRO_ID, resultado.getArbitro().getId());
        assertEquals("fiscal", resultado.getFuncao());
    }

    @Test
    void add_preencheAuditoriaENormalizaFuncao() {
        when(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID)).thenReturn(false);
        when(partidaRepo.findById(PARTIDA_ID)).thenReturn(Optional.of(partida()));
        when(profileRepo.findById(ARBITRO_ID)).thenReturn(Optional.of(perfil()));
        when(profileRepo.findRolesByUserId(ARBITRO_ID)).thenReturn(java.util.List.of("REFEREE"));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        PartidaArbitro resultado = service.add(PARTIDA_ID, ARBITRO_ID, "Árbitro Principal", ACTION_USER_ID);

        assertEquals("PRINCIPAL", resultado.getFuncao());
        assertEquals(ACTION_USER_ID, resultado.getAdicionadoPor());
        assertNotNull(resultado.getCriadoEm());
        assertTrue(resultado.getCriadoEm().isBefore(OffsetDateTime.now().plusSeconds(1)));
    }

    // ════════════════════════════════════════════════════════════════════════
    // remove()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void remove_vinculoExistente_deletaComSucesso() {
        when(repo.findById(VINCULO_ID)).thenReturn(Optional.of(vinculo()));

        service.remove(VINCULO_ID, ACTION_USER_ID);

        verify(repo, times(1)).deleteById(VINCULO_ID);
    }

    @Test
    void remove_vinculoNaoExistente_lancaIllegalStateException() {
        when(repo.findById(VINCULO_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalStateException.class,
                () -> service.remove(VINCULO_ID, ACTION_USER_ID));

        verify(repo, never()).deleteById(any());
    }
}
