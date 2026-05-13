package com.nkw.backapisumula.competicao.service;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

/**
 * Placeholder para testes do serviço de equipes.
 *
 * O EquipeService original foi substituído durante a refatoração do domínio.
 * A lógica de gestão de equipes (times) agora é tratada diretamente pelos
 * repositórios JPA via TimesController:
 *   - TimeAtleticaRepository  → times de uma atlética
 *   - CampeonatoTimeRepository → times inscritos em um campeonato
 *
 * TODO: Se um serviço dedicado (ex.: CampeonatoTimeService) for criado no futuro,
 *       mover estes testes para a nova classe de testes correspondente.
 */
@Disabled("EquipeService foi removido durante a refatoração — lógica movida para TimesController. " +
          "Crie CampeonatoTimeService e ajuste estes testes quando a camada de serviço for reimplementada.")
class EquipeServiceTest {

    @Test
    void placeholder_paraEvitarClasseVazia() {
        // Este arquivo é um placeholder.
        // Veja o Javadoc da classe para entender o contexto.
    }
}
