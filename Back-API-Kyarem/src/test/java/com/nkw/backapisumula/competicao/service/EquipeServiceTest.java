package com.nkw.backapisumula.competicao.service;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.repo.AtleticaRepository;
import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.Equipe;
import com.nkw.backapisumula.competicao.Modalidade;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import com.nkw.backapisumula.competicao.repo.EquipeRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Testes unitários do EquipeService — criação, atualização e listagem de equipes.
 */
@ExtendWith(MockitoExtension.class)
class EquipeServiceTest {

    @Mock private EquipeRepository repo;
    @Mock private AtleticaRepository atleticaRepo;
    @Mock private CampeonatoRepository campeonatoRepo;
    @Mock private ModalidadeRepository modalidadeRepo;

    @InjectMocks
    private EquipeService service;

    private static final UUID EQUIPE_ID      = UUID.fromString("aaaaaaaa-1111-0000-0000-000000000001");
    private static final UUID ATLETICA_ID    = UUID.fromString("bbbbbbbb-2222-0000-0000-000000000002");
    private static final UUID CAMPEONATO_ID  = UUID.fromString("cccccccc-3333-0000-0000-000000000003");
    private static final UUID MODALIDADE_ID  = UUID.fromString("dddddddd-4444-0000-0000-000000000004");

    private Atletica atletica() {
        Atletica a = new Atletica();
        a.setId(ATLETICA_ID);
        a.setNome("Atlética Teste");
        return a;
    }

    private Campeonato campeonato() {
        Campeonato c = new Campeonato();
        c.setId(CAMPEONATO_ID);
        c.setNome("Copa Kyarem");
        return c;
    }

    private Modalidade modalidade() {
        Modalidade m = new Modalidade();
        m.setId(MODALIDADE_ID);
        m.setNome("Futsal Masculino");
        return m;
    }

    private Equipe equipe() {
        Equipe e = new Equipe();
        e.setId(EQUIPE_ID);
        e.setNomeEquipe("Falcões do Norte");
        e.setAtletica(atletica());
        e.setCampeonato(campeonato());
        e.setModalidade(modalidade());
        return e;
    }

    // ════════════════════════════════════════════════════════════════════════
    // create()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void create_dadosValidos_retornaEquipeCriada() {
        when(atleticaRepo.findById(ATLETICA_ID)).thenReturn(Optional.of(atletica()));
        when(campeonatoRepo.findById(CAMPEONATO_ID)).thenReturn(Optional.of(campeonato()));
        when(modalidadeRepo.findById(MODALIDADE_ID)).thenReturn(Optional.of(modalidade()));
        when(repo.save(any(Equipe.class))).thenReturn(equipe());

        Equipe resultado = service.create(ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "Falcões do Norte");

        assertNotNull(resultado);
        assertEquals("Falcões do Norte", resultado.getNomeEquipe());
        verify(repo).save(any(Equipe.class));
    }

    @Test
    void create_atleticaNaoEncontrada_lancaIllegalArgumentException() {
        when(atleticaRepo.findById(ATLETICA_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> service.create(ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "Equipe X"));
    }

    @Test
    void create_campeonatoNaoEncontrado_lancaIllegalArgumentException() {
        when(atleticaRepo.findById(ATLETICA_ID)).thenReturn(Optional.of(atletica()));
        when(campeonatoRepo.findById(CAMPEONATO_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> service.create(ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "Equipe X"));
    }

    @Test
    void create_modalidadeNaoEncontrada_lancaIllegalArgumentException() {
        when(atleticaRepo.findById(ATLETICA_ID)).thenReturn(Optional.of(atletica()));
        when(campeonatoRepo.findById(CAMPEONATO_ID)).thenReturn(Optional.of(campeonato()));
        when(modalidadeRepo.findById(MODALIDADE_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> service.create(ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "Equipe X"));
    }

    @Test
    void create_nomeComEspacos_salvaComTrim() {
        when(atleticaRepo.findById(ATLETICA_ID)).thenReturn(Optional.of(atletica()));
        when(campeonatoRepo.findById(CAMPEONATO_ID)).thenReturn(Optional.of(campeonato()));
        when(modalidadeRepo.findById(MODALIDADE_ID)).thenReturn(Optional.of(modalidade()));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Equipe resultado = service.create(ATLETICA_ID, CAMPEONATO_ID, MODALIDADE_ID, "  Falcões  ");

        // O service faz .trim() antes de salvar
        assertEquals("Falcões", resultado.getNomeEquipe());
    }

    // ════════════════════════════════════════════════════════════════════════
    // update()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void update_apenasNome_mantémOutrosCampos() {
        Equipe existente = equipe();
        when(repo.findById(EQUIPE_ID)).thenReturn(Optional.of(existente));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        // Só atualiza o nome, os outros IDs são null
        Equipe resultado = service.update(EQUIPE_ID, null, null, null, "Novo Nome");

        assertEquals("Novo Nome", resultado.getNomeEquipe());
        // Atlética e campeonato devem permanecer inalterados
        assertEquals(ATLETICA_ID, resultado.getAtletica().getId());
        assertEquals(CAMPEONATO_ID, resultado.getCampeonato().getId());
    }

    @Test
    void update_equipeNaoEncontrada_lancaIllegalArgumentException() {
        when(repo.findById(EQUIPE_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> service.update(EQUIPE_ID, null, null, null, "Novo Nome"));
    }

    @Test
    void update_comNovaAtletica_atualizaAtletica() {
        UUID novaAtleticaId = UUID.randomUUID();
        Atletica novaAtletica = new Atletica();
        novaAtletica.setId(novaAtleticaId);
        novaAtletica.setNome("Nova Atlética");

        when(repo.findById(EQUIPE_ID)).thenReturn(Optional.of(equipe()));
        when(atleticaRepo.findById(novaAtleticaId)).thenReturn(Optional.of(novaAtletica));
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Equipe resultado = service.update(EQUIPE_ID, novaAtleticaId, null, null, null);

        assertEquals(novaAtleticaId, resultado.getAtletica().getId());
    }

    // ════════════════════════════════════════════════════════════════════════
    // list()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void list_semFiltros_retornaTodasAsEquipes() {
        when(repo.findAll()).thenReturn(List.of(equipe()));

        List<Equipe> resultado = service.list(null, null, null);

        assertEquals(1, resultado.size());
        verify(repo).findAll();
    }

    @Test
    void list_comCampeonatoId_usaQueryCorreta() {
        when(repo.findByCampeonato_Id(CAMPEONATO_ID)).thenReturn(List.of(equipe()));

        List<Equipe> resultado = service.list(CAMPEONATO_ID, null, null);

        assertEquals(1, resultado.size());
        verify(repo).findByCampeonato_Id(CAMPEONATO_ID);
    }

    @Test
    void list_comCampeonatoEModalidade_usaQueryCorreta() {
        when(repo.findByCampeonato_IdAndModalidade_Id(CAMPEONATO_ID, MODALIDADE_ID))
                .thenReturn(List.of(equipe()));

        List<Equipe> resultado = service.list(CAMPEONATO_ID, MODALIDADE_ID, null);

        assertEquals(1, resultado.size());
        verify(repo).findByCampeonato_IdAndModalidade_Id(CAMPEONATO_ID, MODALIDADE_ID);
    }

    // ════════════════════════════════════════════════════════════════════════
    // delete()
    // ════════════════════════════════════════════════════════════════════════

    @Test
    void delete_equipeExistente_deletaComSucesso() {
        Equipe e = equipe();
        when(repo.findById(EQUIPE_ID)).thenReturn(Optional.of(e));

        service.delete(EQUIPE_ID);

        verify(repo, times(1)).delete(e);
    }

    @Test
    void delete_equipeNaoEncontrada_lancaIllegalArgumentException() {
        when(repo.findById(EQUIPE_ID)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class,
                () -> service.delete(EQUIPE_ID));
    }
}
