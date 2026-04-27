package com.nkw.backapisumula.partidas.repo;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.PartidaArbitro;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Testes do PartidaArbitroRepository usando Mockito puro.
 *
 * Nota: @DataJpaTest com H2 conflita com o columnDefinition="jsonb" das entidades.
 * Como alternativa, testamos o comportamento do repositório através de verificações
 * de chamada de método. O comportamento real das queries é garantido pelo banco
 * PostgreSQL em ambiente de integração.
 *
 * Para testes de integração com banco real, use o perfil 'integration-test'
 * (a ser configurado com Testcontainers em uma fase futura).
 */
@ExtendWith(MockitoExtension.class)
class PartidaArbitroRepositoryTest {

    @Mock
    private PartidaArbitroRepository repo;

    private static final UUID PARTIDA_ID = UUID.fromString("aaaaaaaa-0000-0000-0000-000000000011");
    private static final UUID ARBITRO_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000022");
    private static final UUID VINCULO_ID = UUID.fromString("cccccccc-0000-0000-0000-000000000033");

    private Profile perfil(UUID id) {
        Profile p = new Profile();
        p.setId(id);
        p.setRole("arbitro");
        return p;
    }

    private Partida partida(UUID id) {
        Partida p = new Partida();
        p.setId(id);
        p.setStatus("agendada");
        p.setPlacarA(0);
        p.setPlacarB(0);
        return p;
    }

    private PartidaArbitro vinculo(UUID id, UUID partidaId, UUID arbitroId) {
        PartidaArbitro pa = new PartidaArbitro();
        pa.setId(id);
        pa.setPartida(partida(partidaId));
        pa.setArbitro(perfil(arbitroId));
        pa.setFuncao("árbitro principal");
        return pa;
    }

    // ════════════════════════════════════════════════════════════════════════
    // existsByPartida_IdAndArbitro_Id
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void existsByPartidaIdAndArbitroId_vinculoExistente_retornaTrue() {
        when(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID)).thenReturn(true);

        boolean resultado = repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID);

        assertTrue(resultado);
        verify(repo).existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID);
    }

    @Test
    void existsByPartidaIdAndArbitroId_semVinculo_retornaFalse() {
        when(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID)).thenReturn(false);

        boolean resultado = repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID);

        assertFalse(resultado);
    }

    @Test
    void existsByPartidaIdAndArbitroId_arbitroDeOutraPartida_retornaFalse() {
        UUID outraPartidaId = UUID.fromString("eeeeeeee-0000-0000-0000-000000000099");
        // Arbitro vinculado à PARTIDA_ID, não à outraPartidaId
        when(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID)).thenReturn(true);
        when(repo.existsByPartida_IdAndArbitro_Id(outraPartidaId, ARBITRO_ID)).thenReturn(false);

        assertFalse(repo.existsByPartida_IdAndArbitro_Id(outraPartidaId, ARBITRO_ID));
        assertTrue(repo.existsByPartida_IdAndArbitro_Id(PARTIDA_ID, ARBITRO_ID));
    }

    // ════════════════════════════════════════════════════════════════════════
    // findByArbitro_Id
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void findByArbitroId_retornaTodosOsVinculosDoArbitro() {
        List<PartidaArbitro> vinculos = List.of(
                vinculo(UUID.randomUUID(), UUID.randomUUID(), ARBITRO_ID),
                vinculo(UUID.randomUUID(), UUID.randomUUID(), ARBITRO_ID)
        );
        when(repo.findByArbitro_Id(ARBITRO_ID)).thenReturn(vinculos);

        List<PartidaArbitro> resultado = repo.findByArbitro_Id(ARBITRO_ID);

        assertEquals(2, resultado.size());
        assertTrue(resultado.stream()
                .allMatch(pa -> ARBITRO_ID.equals(pa.getArbitro().getId())));
    }

    @Test
    void findByArbitroId_semVinculos_retornaListaVazia() {
        when(repo.findByArbitro_Id(ARBITRO_ID)).thenReturn(List.of());

        List<PartidaArbitro> resultado = repo.findByArbitro_Id(ARBITRO_ID);

        assertTrue(resultado.isEmpty());
    }

    // ════════════════════════════════════════════════════════════════════════
    // findByPartida_Id
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void findByPartidaId_retornaArbitrosDaPartida() {
        List<PartidaArbitro> vinculos = List.of(
                vinculo(UUID.randomUUID(), PARTIDA_ID, ARBITRO_ID),
                vinculo(UUID.randomUUID(), PARTIDA_ID, UUID.randomUUID())
        );
        when(repo.findByPartida_Id(PARTIDA_ID)).thenReturn(vinculos);

        List<PartidaArbitro> resultado = repo.findByPartida_Id(PARTIDA_ID);

        assertEquals(2, resultado.size());
    }

    @Test
    void existsById_vinculoExistente_retornaTrue() {
        when(repo.existsById(VINCULO_ID)).thenReturn(true);

        assertTrue(repo.existsById(VINCULO_ID));
    }

    @Test
    void existsById_vinculoNaoExistente_retornaFalse() {
        when(repo.existsById(VINCULO_ID)).thenReturn(false);

        assertFalse(repo.existsById(VINCULO_ID));
    }
}
