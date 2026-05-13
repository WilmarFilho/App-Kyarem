package com.nkw.backapisumula.competicao;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import com.fasterxml.jackson.databind.node.NullNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

public final class ModalidadeRules {

    private static final JsonNodeFactory JSON = JsonNodeFactory.instance;

    private ModalidadeRules() {
    }

    public static ObjectNode normalizeCatalogRules(JsonNode rawRules, String motorRegras) {
        ObjectNode normalized = defaultRulesForMotor(motorRegras);
        mergeInto(normalized, rawRules);
        normalized.set("eventosPermitidos", NullNode.instance);
        return normalized;
    }

    public static ObjectNode normalizeChampionshipRules(JsonNode rawRules) {
        ObjectNode normalized = JSON.objectNode();
        mergeInto(normalized, rawRules);
        return normalized;
    }

    public static ObjectNode resolveEffectiveRules(String motorRegras, JsonNode catalogRules,
            JsonNode championshipRules) {
        ObjectNode effective = defaultRulesForMotor(motorRegras);
        mergeInto(effective, catalogRules);
        mergeInto(effective, championshipRules);
        if (!effective.has("eventosPermitidos")) {
            effective.set("eventosPermitidos", NullNode.instance);
        }
        return effective;
    }

    public static ObjectNode defaultRulesForMotor(String motorRegras) {
        ObjectNode rules = baseTemplate();
        String motor = motorRegras == null ? "" : motorRegras.trim().toUpperCase();

        switch (motor) {
            case "VOLEI_V1" -> {
                rules.put("tempoPartidaMinutos", 0);
                rules.put("periodos", 3);
                rules.put("cronometroParado", false);
                rules.put("tipoPontuacao", "SETS");
                rules.put("setsParaVencer", 3);
                rules.put("pontosPorSet", 25);
                rules.set("faltasColetivasLimite", NullNode.instance);
            }
            case "BASQUETE_V1" -> {
                rules.put("tempoPartidaMinutos", 40);
                rules.put("periodos", 4);
                rules.put("cronometroParado", true);
                rules.put("tipoPontuacao", "PONTOS");
                rules.set("setsParaVencer", NullNode.instance);
                rules.set("pontosPorSet", NullNode.instance);
                rules.set("faltasColetivasLimite", NullNode.instance);
            }
            case "HANDEBOL_V1" -> {
                rules.put("tempoPartidaMinutos", 60);
                rules.put("periodos", 2);
                rules.put("cronometroParado", true);
                rules.put("tipoPontuacao", "GOLS");
                rules.set("setsParaVencer", NullNode.instance);
                rules.set("pontosPorSet", NullNode.instance);
                rules.set("faltasColetivasLimite", NullNode.instance);
            }
            case "SOCIETY_V1" -> {
                rules.put("tempoPartidaMinutos", 50);
                rules.put("periodos", 2);
                rules.put("cronometroParado", false);
                rules.put("tipoPontuacao", "GOLS");
                rules.set("setsParaVencer", NullNode.instance);
                rules.set("pontosPorSet", NullNode.instance);
                rules.set("faltasColetivasLimite", NullNode.instance);
            }
            case "FUTEBOL_CAMPO_V1" -> {
                rules.put("tempoPartidaMinutos", 90);
                rules.put("periodos", 2);
                rules.put("cronometroParado", false);
                rules.put("tipoPontuacao", "GOLS");
                rules.set("setsParaVencer", NullNode.instance);
                rules.set("pontosPorSet", NullNode.instance);
                rules.set("faltasColetivasLimite", NullNode.instance);
            }
            case "GENERICO_V1" -> {
                rules.put("tempoPartidaMinutos", 20);
                rules.put("periodos", 2);
                rules.put("cronometroParado", true);
                rules.put("tipoPontuacao", "GOLS");
                rules.set("setsParaVencer", NullNode.instance);
                rules.set("pontosPorSet", NullNode.instance);
                rules.set("faltasColetivasLimite", NullNode.instance);
            }
            case "FUTSAL_V1" -> {
                rules.put("tempoPartidaMinutos", 20);
                rules.put("periodos", 2);
                rules.put("cronometroParado", true);
                rules.put("tipoPontuacao", "GOLS");
                rules.set("setsParaVencer", NullNode.instance);
                rules.set("pontosPorSet", NullNode.instance);
                rules.put("faltasColetivasLimite", 5);
            }
            default -> {
                rules.put("tempoPartidaMinutos", 20);
                rules.put("periodos", 2);
                rules.put("cronometroParado", true);
                rules.put("tipoPontuacao", "GOLS");
                rules.set("setsParaVencer", NullNode.instance);
                rules.set("pontosPorSet", NullNode.instance);
                rules.put("faltasColetivasLimite", 5);
            }
        }

        return rules;
    }

    private static ObjectNode baseTemplate() {
        ObjectNode rules = JSON.objectNode();
        rules.put("tempoPartidaMinutos", 20);
        rules.put("periodos", 2);
        rules.put("cronometroParado", true);
        rules.put("tipoPontuacao", "GOLS");
        rules.set("setsParaVencer", NullNode.instance);
        rules.set("pontosPorSet", NullNode.instance);
        rules.put("faltasColetivasLimite", 5);
        rules.put("permiteProrrogacao", false);
        rules.put("permitePenaltis", false);
        rules.set("eventosPermitidos", NullNode.instance);
        return rules;
    }

    private static void mergeInto(ObjectNode target, JsonNode source) {
        if (source == null || !source.isObject()) {
            return;
        }

        source.properties().forEach(entry -> {
            JsonNode value = entry.getValue();
            if (value != null && value.isObject() && target.has(entry.getKey())
                    && target.get(entry.getKey()).isObject()) {
                mergeInto((ObjectNode) target.get(entry.getKey()), value);
            } else {
                target.set(entry.getKey(), value == null ? NullNode.instance : value.deepCopy());
            }
        });
    }
}
