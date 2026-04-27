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
    @JoinColumn(name = "campeonato_modalidade_id", nullable = false)
    private CampeonatoModalidade campeonatoModalidade;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "time_id", nullable = false)
    private TimeAtletica time;

    @Column(name = "status_inscricao", nullable = false)
    private String statusInscricao;

    @Column(name = "nome_personalizado")
    private String nomePersonalizado;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
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

    public String getStatusInscricao() {
        return statusInscricao;
    }

    public void setStatusInscricao(String statusInscricao) {
        this.statusInscricao = statusInscricao;
    }

    public Campeonato getCampeonato() {
        return campeonatoModalidade != null ? campeonatoModalidade.getCampeonato() : null;
    }

    public String getNomePersonalizado() {
        return nomePersonalizado;
    }

    public void setNomePersonalizado(String nomePersonalizado) {
        this.nomePersonalizado = nomePersonalizado;
    }

    public String getNomeEquipe() {
        return nomePersonalizado != null && !nomePersonalizado.isBlank()
                ? nomePersonalizado
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
