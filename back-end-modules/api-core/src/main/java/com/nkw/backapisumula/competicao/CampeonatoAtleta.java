package com.nkw.backapisumula.competicao;

import com.nkw.backapisumula.cadastros.Atleta;
import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "campeonato_atletas", schema = "operational")
public class CampeonatoAtleta {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_time_id", nullable = false)
    private CampeonatoTime campeonatoTime;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atleta_id", nullable = false)
    private Atleta atleta;

    private String status;

    @Column(name = "numero_camisa")
    private Integer numeroCamisa;

    @Column(name = "is_capitao")
    private Boolean isCapitao = false;

    @Column(name = "is_goleiro")
    private Boolean isGoleiro = false;

    @Column(name = "inscrito_em")
    private OffsetDateTime inscritoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public CampeonatoTime getCampeonatoTime() { return campeonatoTime; }
    public void setCampeonatoTime(CampeonatoTime campeonatoTime) { this.campeonatoTime = campeonatoTime; }

    public Atleta getAtleta() { return atleta; }
    public void setAtleta(Atleta atleta) { this.atleta = atleta; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getNumeroCamisa() { return numeroCamisa; }
    public void setNumeroCamisa(Integer numeroCamisa) { this.numeroCamisa = numeroCamisa; }

    public Boolean getIsCapitao() { return isCapitao; }
    public void setIsCapitao(Boolean isCapitao) { this.isCapitao = isCapitao; }

    public Boolean getIsGoleiro() { return isGoleiro; }
    public void setIsGoleiro(Boolean isGoleiro) { this.isGoleiro = isGoleiro; }

    public OffsetDateTime getInscritoEm() { return inscritoEm; }
    public void setInscritoEm(OffsetDateTime inscritoEm) { this.inscritoEm = inscritoEm; }
}
