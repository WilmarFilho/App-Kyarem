package com.nkw.backapisumula.competicao;

import jakarta.persistence.*;
import java.util.UUID;
import java.time.OffsetDateTime;

@Entity
@Table(name = "campeonato_times", schema = "operational")
public class CampeonatoTime {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_id", nullable = false)
    private Campeonato campeonato;

    @Column(name = "campeonato_atletica_id", nullable = false)
    private UUID campeonatoAtleticaId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_modalidade_id", nullable = false)
    private CampeonatoModalidade campeonatoModalidade;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "time_atletica_id", nullable = false)
    private TimeAtletica time;

    @Column(name = "nome_exibicao")
    private String nomeExibicao;

    @Column(name = "grupo")
    private String grupo;

    @Column(name = "seed")
    private Integer seed;

    @Column(name = "status", nullable = false)
    private String status = "CONFIRMADA";

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

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

    public UUID getCampeonatoAtleticaId() {
        return campeonatoAtleticaId;
    }

    public void setCampeonatoAtleticaId(UUID campeonatoAtleticaId) {
        this.campeonatoAtleticaId = campeonatoAtleticaId;
    }

    public CampeonatoModalidade getCampeonatoModalidade() {
        return campeonatoModalidade;
    }

    public void setCampeonatoModalidade(CampeonatoModalidade campeonatoModalidade) {
        this.campeonatoModalidade = campeonatoModalidade;
    }

    public TimeAtletica getTime() {
        return time;
    }

    public void setTime(TimeAtletica time) {
        this.time = time;
    }

    public String getNomeExibicao() {
        return nomeExibicao;
    }

    public void setNomeExibicao(String nomeExibicao) {
        this.nomeExibicao = nomeExibicao;
    }

    public String getGrupo() {
        return grupo;
    }

    public void setGrupo(String grupo) {
        this.grupo = grupo;
    }

    public Integer getSeed() {
        return seed;
    }

    public void setSeed(Integer seed) {
        this.seed = seed;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getNomeEquipe() {
        return nomeExibicao != null && !nomeExibicao.isBlank()
                ? nomeExibicao
                : (time != null ? time.getNome() : null);
    }

    public com.nkw.backapisumula.cadastros.Atletica getAtletica() {
        return time != null ? time.getAtletica() : null;
    }

    public OffsetDateTime getCriadoEm() {
        return criadoEm;
    }

    public void setCriadoEm(OffsetDateTime criadoEm) {
        this.criadoEm = criadoEm;
    }
}
