package com.nkw.backapisumula.competicao;

import com.fasterxml.jackson.databind.JsonNode;
import com.nkw.backapisumula.cadastros.Esporte;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "modalidades")
public class Modalidade {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_id")
    private Campeonato campeonato;

    @Column(name = "campeonato_nome")
    private String campeonatoNome;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "esporte_id")
    private Esporte esporte;

    @Column(nullable = false)
    private String nome;

    @Column(name = "tempo_partida_minutos")
    private Integer tempoPartidaMinutos;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "regras_json", columnDefinition = "jsonb")
    private JsonNode regrasJson;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Campeonato getCampeonato() { return campeonato; }
    public void setCampeonato(Campeonato campeonato) { this.campeonato = campeonato; }

    public String getCampeonatoNome() { return campeonatoNome; }
    public void setCampeonatoNome(String campeonatoNome) { this.campeonatoNome = campeonatoNome; }

    public Esporte getEsporte() { return esporte; }
    public void setEsporte(Esporte esporte) { this.esporte = esporte; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public Integer getTempoPartidaMinutos() { return tempoPartidaMinutos; }
    public void setTempoPartidaMinutos(Integer tempoPartidaMinutos) { this.tempoPartidaMinutos = tempoPartidaMinutos; }

    public JsonNode getRegrasJson() { return regrasJson; }
    public void setRegrasJson(JsonNode regrasJson) { this.regrasJson = regrasJson; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
