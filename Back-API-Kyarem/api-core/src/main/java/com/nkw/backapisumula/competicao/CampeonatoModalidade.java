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
    @JoinColumn(name = "modalidade_id", nullable = false)
    private ModalidadeCatalogo modalidade;

    @Column(name = "fase_atual")
    private String faseAtual;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "configuracoes_especificas", columnDefinition = "jsonb")
    private JsonNode configuracoesEspecificas;

    // Getters and Setters

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Campeonato getCampeonato() {
        return campeonato;
    }

    public void setCampeonato(Campeonato campeonato) {
        this.campeonato = campeonato;
    }

    public ModalidadeCatalogo getModalidade() {
        return modalidade;
    }

    public void setModalidade(ModalidadeCatalogo modalidade) {
        this.modalidade = modalidade;
    }

    public String getFaseAtual() {
        return faseAtual;
    }

    public void setFaseAtual(String faseAtual) {
        this.faseAtual = faseAtual;
    }

    public JsonNode getConfiguracoesEspecificas() {
        return configuracoesEspecificas;
    }

    public void setConfiguracoesEspecificas(JsonNode configuracoesEspecificas) {
        this.configuracoesEspecificas = configuracoesEspecificas;
    }

    public String getCampeonatoNome() {
        return campeonato != null ? campeonato.getNome() : null;
    }

    public String getNome() {
        return modalidade != null ? modalidade.getNome() : null;
    }

    public com.nkw.backapisumula.cadastros.Esporte getEsporte() {
        return modalidade != null ? modalidade.getEsporte() : null;
    }

    public Integer getTempoPartidaMinutos() {
        if (configuracoesEspecificas != null && configuracoesEspecificas.has("tempoPartidaMinutos")) {
            return configuracoesEspecificas.path("tempoPartidaMinutos").asInt(20);
        }
        if (modalidade != null && modalidade.getMotorConfigsDefault() != null
                && modalidade.getMotorConfigsDefault().has("tempoPartidaMinutos")) {
            return modalidade.getMotorConfigsDefault().path("tempoPartidaMinutos").asInt(20);
        }
        return 20;
    }
}
