package com.nkw.backapisumula.competicao;

import com.fasterxml.jackson.databind.JsonNode;
import com.nkw.backapisumula.cadastros.Esporte;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

@Entity
@Table(name = "modalidades_catalogo", schema = "operational")
public class ModalidadeCatalogo {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "esporte_id", nullable = false)
    private Esporte esporte;

    @Column(nullable = false)
    private String nome;

    @Column(name = "codigo", nullable = false)
    private String slug;

    @Column(name = "descricao")
    private String genero;

    @Column(name = "motor_regras", nullable = false)
    private String motorRegras;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "regras_base_json", columnDefinition = "jsonb")
    private JsonNode motorConfigsDefault;

    @Column(nullable = false)
    private Boolean ativo = true;

    // Getters and Setters

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Esporte getEsporte() {
        return esporte;
    }

    public void setEsporte(Esporte esporte) {
        this.esporte = esporte;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getSlug() {
        return slug;
    }

    public void setSlug(String slug) {
        this.slug = slug;
    }

    public String getGenero() {
        return genero;
    }

    public void setGenero(String genero) {
        this.genero = genero;
    }

    public String getMotorRegras() {
        if (motorRegras != null && !motorRegras.isBlank()) {
            return motorRegras;
        }
        if (slug == null) {
            return null;
        }
        return switch (slug.trim().toLowerCase()) {
            case "futsal", "futsal_masculino", "futsal_feminino", "futsal_misto" -> "FUTSAL_V1";
            case "quadra", "quadra_masculino", "quadra_feminino", "areia", "areia_misto" -> "VOLEI_V1";
            case "basquete", "basquete_masculino", "basquete_feminino" -> "BASQUETE_V1";
            case "handebol", "handebol_masculino", "handebol_feminino" -> "HANDEBOL_V1";
            case "society", "society_masculino" -> "SOCIETY_V1";
            case "campo", "campo_masculino" -> "FUTEBOL_CAMPO_V1";
            default -> null;
        };
    }

    public void setMotorRegras(String motorRegras) {
        this.motorRegras = motorRegras;
    }

    public JsonNode getMotorConfigsDefault() {
        return ModalidadeRules.normalizeCatalogRules(motorConfigsDefault, getMotorRegras());
    }

    public void setMotorConfigsDefault(JsonNode motorConfigsDefault) {
        this.motorConfigsDefault = motorConfigsDefault;
    }

    public Boolean getAtivo() {
        return ativo;
    }

    public void setAtivo(Boolean ativo) {
        this.ativo = ativo;
    }

}
