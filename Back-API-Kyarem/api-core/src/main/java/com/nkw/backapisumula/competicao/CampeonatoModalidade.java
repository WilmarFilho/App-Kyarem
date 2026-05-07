package com.nkw.backapisumula.competicao;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

@Entity
@Table(name = "campeonato_modalidades", schema = "operational")
public class CampeonatoModalidade {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_id", nullable = false)
    private Campeonato campeonato;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "modalidade_catalogo_id", nullable = false)
    private ModalidadeCatalogo modalidade;

    @Column(name = "nome_exibicao")
    private String nomeExibicao;

    @Column(name = "categoria")
    private String categoria;

    @Column(name = "genero")
    private String genero;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "regras_json", columnDefinition = "jsonb")
    private JsonNode regrasJson;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "formato_fases_json", columnDefinition = "jsonb")
    private JsonNode formatoFasesJson;

    @Column(name = "status", nullable = false)
    private String status = "ATIVA";

    // Getters and Setters

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Campeonato getCampeonato() { return campeonato; }
    public void setCampeonato(Campeonato campeonato) { this.campeonato = campeonato; }

    public ModalidadeCatalogo getModalidade() { return modalidade; }
    public void setModalidade(ModalidadeCatalogo modalidade) { this.modalidade = modalidade; }

    public String getNomeExibicao() { return nomeExibicao; }
    public void setNomeExibicao(String nomeExibicao) { this.nomeExibicao = nomeExibicao; }

    public String getCategoria() { return categoria; }
    public void setCategoria(String categoria) { this.categoria = categoria; }

    public String getGenero() { return genero; }
    public void setGenero(String genero) { this.genero = genero; }

    public JsonNode getRegrasJson() { return regrasJson; }
    public void setRegrasJson(JsonNode regrasJson) { this.regrasJson = regrasJson; }

    public JsonNode getFormatoFasesJson() { return formatoFasesJson; }
    public void setFormatoFasesJson(JsonNode formatoFasesJson) { this.formatoFasesJson = formatoFasesJson; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCampeonatoNome() {
        return campeonato != null ? campeonato.getNome() : null;
    }

    public String getNome() {
        return modalidade != null ? modalidade.getNome() : null;
    }

    public com.nkw.backapisumula.cadastros.Esporte getEsporte() {
        return modalidade != null ? modalidade.getEsporte() : null;
    }

    public JsonNode getRegrasEfetivasJson() {
        return ModalidadeRules.resolveEffectiveRules(
                modalidade != null ? modalidade.getMotorRegras() : null,
                modalidade != null ? modalidade.getMotorConfigsDefault() : null,
                regrasJson
        );
    }

    public Integer getTempoPartidaMinutos() {
        return getRegrasEfetivasJson().path("tempoPartidaMinutos").asInt(20);
    }

    public Boolean getPermiteProrrogacao() {
        return getRegrasEfetivasJson().path("permiteProrrogacao").asBoolean(false);
    }

    public Boolean getPermitePenaltis() {
        return getRegrasEfetivasJson().path("permitePenaltis").asBoolean(false);
    }
}
