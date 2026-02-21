package com.nkw.backapisumula.partidas;

import com.fasterxml.jackson.databind.JsonNode;
import com.nkw.backapisumula.competicao.Equipe;
import com.nkw.backapisumula.competicao.Modalidade;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "partidas")
public class Partida {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "modalidade_id")
    private Modalidade modalidade;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "equipe_a_id")
    private Equipe equipeA;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "equipe_b_id")
    private Equipe equipeB;

    private String status;

    @Column(name = "iniciada_em")
    private OffsetDateTime iniciadaEm;

    private String local;

    @Column(name = "placar_a")
    private Integer placarA;

    @Column(name = "placar_b")
    private Integer placarB;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "snapshot_sumula", columnDefinition = "jsonb")
    private JsonNode snapshotSumula;

    @Column(name = "sumula_pdf_url")
    private String sumulaPdfUrl;

    @Column(name = "hash_integridade")
    private String hashIntegridade;

    @Column(name = "encerrada_em")
    private OffsetDateTime encerradaEm;

    @Column(name = "criado_em", updatable = false, insertable = false)
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Modalidade getModalidade() { return modalidade; }
    public void setModalidade(Modalidade modalidade) { this.modalidade = modalidade; }

    public Equipe getEquipeA() { return equipeA; }
    public void setEquipeA(Equipe equipeA) { this.equipeA = equipeA; }

    public Equipe getEquipeB() { return equipeB; }
    public void setEquipeB(Equipe equipeB) { this.equipeB = equipeB; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public OffsetDateTime getIniciadaEm() { return iniciadaEm; }
    public void setIniciadaEm(OffsetDateTime iniciadaEm) { this.iniciadaEm = iniciadaEm; }

    public String getLocal() { return local; }
    public void setLocal(String local) { this.local = local; }

    public Integer getPlacarA() { return placarA; }
    public void setPlacarA(Integer placarA) { this.placarA = placarA; }

    public Integer getPlacarB() { return placarB; }
    public void setPlacarB(Integer placarB) { this.placarB = placarB; }

    public JsonNode getSnapshotSumula() { return snapshotSumula; }
    public void setSnapshotSumula(JsonNode snapshotSumula) { this.snapshotSumula = snapshotSumula; }

    public String getSumulaPdfUrl() { return sumulaPdfUrl; }
    public void setSumulaPdfUrl(String sumulaPdfUrl) { this.sumulaPdfUrl = sumulaPdfUrl; }

    public String getHashIntegridade() { return hashIntegridade; }
    public void setHashIntegridade(String hashIntegridade) { this.hashIntegridade = hashIntegridade; }

    public OffsetDateTime getEncerradaEm() { return encerradaEm; }
    public void setEncerradaEm(OffsetDateTime encerradaEm) { this.encerradaEm = encerradaEm; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
