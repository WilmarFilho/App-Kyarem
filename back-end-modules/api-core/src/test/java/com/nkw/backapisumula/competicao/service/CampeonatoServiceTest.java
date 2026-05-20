package com.nkw.backapisumula.competicao.service;

import com.nkw.backapisumula.common.outbox.EventPublisherService;
import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CampeonatoServiceTest {

    @Mock
    private CampeonatoRepository repo;

    @Mock
    private EventPublisherService eventPublisherService;

    @InjectMocks
    private CampeonatoService service;

    @Test
    void delete_publicaEventoSomenteDepoisDoFlushDaExclusao() {
        UUID campeonatoId = UUID.fromString("aaaaaaaa-1111-2222-3333-444444444444");
        Campeonato campeonato = new Campeonato();
        campeonato.setId(campeonatoId);

        when(repo.findById(campeonatoId)).thenReturn(Optional.of(campeonato));

        service.delete(campeonatoId);

        var inOrder = inOrder(repo, eventPublisherService);
        inOrder.verify(repo).findById(campeonatoId);
        inOrder.verify(repo).delete(campeonato);
        inOrder.verify(repo).flush();
        inOrder.verify(eventPublisherService)
                .publish("Campeonato", campeonatoId.toString(), "CampeonatoExcluido", java.util.Map.of());
        verify(repo).flush();
    }
}
