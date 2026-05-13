package com.nkw.backapisumula.competicao;

import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ModalidadeRulesTest {

    @Test
    void normalizeCatalogRules_garanteShapeCompletoEEventosNulos() {
        ObjectNode raw = JsonNodeFactory.instance.objectNode();
        raw.put("tempoPartidaMinutos", 25);

        ObjectNode normalized = ModalidadeRules.normalizeCatalogRules(raw, "FUTSAL_V1");

        assertThat(normalized.path("tempoPartidaMinutos").asInt()).isEqualTo(25);
        assertThat(normalized.path("periodos").asInt()).isEqualTo(2);
        assertThat(normalized.path("tipoPontuacao").asText()).isEqualTo("GOLS");
        assertThat(normalized.has("eventosPermitidos")).isTrue();
        assertThat(normalized.get("eventosPermitidos").isNull()).isTrue();
    }

    @Test
    void resolveEffectiveRules_aplicaOverrideDoCampeonatoSobreCatalogo() {
        ObjectNode catalog = JsonNodeFactory.instance.objectNode();
        catalog.put("tempoPartidaMinutos", 20);
        catalog.put("permiteProrrogacao", false);

        ObjectNode championship = JsonNodeFactory.instance.objectNode();
        championship.put("tempoPartidaMinutos", 15);
        championship.put("permiteProrrogacao", true);

        ObjectNode effective = ModalidadeRules.resolveEffectiveRules(
                "FUTSAL_V1",
                catalog,
                championship
        );

        assertThat(effective.path("tempoPartidaMinutos").asInt()).isEqualTo(15);
        assertThat(effective.path("permiteProrrogacao").asBoolean()).isTrue();
        assertThat(effective.path("permitePenaltis").asBoolean()).isFalse();
    }
}
