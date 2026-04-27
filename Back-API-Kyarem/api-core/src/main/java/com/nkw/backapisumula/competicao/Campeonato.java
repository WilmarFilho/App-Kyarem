package com.nkw.backapisumula.competicao;

import jakarta.persistence.*;

import java.time.OffsetDateTime;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "campeonatos", schema = "operational")
public class Campeonato {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(nullable = false)
    private String nome;

    @Column(name = "nivel_campeonato")
    private String nivelCampeonato;

    @Column(name = "data_inicio")
    private LocalDate dataInicio;

    @Column(name = "data_fim")
    private LocalDate dataFim;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    @Column(name = "escudo_url")
    private String escudoUrl;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getNivelCampeonato() { return nivelCampeonato; }
    public void setNivelCampeonato(String nivelCampeonato) { this.nivelCampeonato = nivelCampeonato; }

    public LocalDate getDataInicio() { return dataInicio; }
    public void setDataInicio(LocalDate dataInicio) { this.dataInicio = dataInicio; }

    public LocalDate getDataFim() { return dataFim; }
    public void setDataFim(LocalDate dataFim) { this.dataFim = dataFim; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }

    public String getEscudoUrl() { return escudoUrl; }
    public void setEscudoUrl(String escudoUrl) { this.escudoUrl = escudoUrl; }
}
