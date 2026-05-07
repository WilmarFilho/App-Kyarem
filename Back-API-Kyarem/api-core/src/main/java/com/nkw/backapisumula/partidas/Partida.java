package com.nkw.backapisumula.partidas;

import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.CampeonatoModalidade;
import com.nkw.backapisumula.competicao.CampeonatoTime;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "partidas", schema = "operational")
public class Partida {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_id", nullable = false)
    private Campeonato campeonato;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_modalidade_id", nullable = false)
    private CampeonatoModalidade campeonatoModalidade;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_time_a_id")
    private CampeonatoTime campeonatoTimeA;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_time_b_id")
    private CampeonatoTime campeonatoTimeB;

    @Column(nullable = false)
    private String status = "AGENDADA";

    @Column(name = "periodo_antes_pausa")
    private String periodoAntesPausa;

    @Column(name = "agendado_para")
    private OffsetDateTime dataHoraAgendada;

    @Column(name = "iniciada_em")
    private OffsetDateTime dataHoraInicio;

    @Column(name = "encerrada_em")
    private OffsetDateTime dataHoraFim;

    @Column(name = "periodo_atual")
    private String periodoAtual;

    @Column(name = "placar_a", nullable = false)
    private Integer placarTimeA = 0;

    @Column(name = "placar_b", nullable = false)
    private Integer placarTimeB = 0;

    private String fase;

    private String categoria;

    @Column(length = 300)
    private String local;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "snapshot_sumula", columnDefinition = "jsonb")
    private JsonNode snapshotSumula;

    @Column(name = "sumula_pdf_url", length = 500)
    private String sumulaPdfUrl;

    @Column(name = "hash_integridade")
    private String hashIntegridade;

    @Version
    @Column(name = "versao_estado", nullable = false)
    private Long versaoEstado = 0L;

    @Column(name = "criado_por", columnDefinition = "uuid")
    private UUID criadoPor;

    @Column(name = "criado_em", updatable = false, insertable = false)
    private OffsetDateTime criadoEm;

    @Column(name = "atualizado_em")
    private OffsetDateTime atualizadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Campeonato getCampeonato() { return campeonato; }
    public void setCampeonato(Campeonato campeonato) { this.campeonato = campeonato; }

    public CampeonatoModalidade getCampeonatoModalidade() { return campeonatoModalidade; }
    public void setCampeonatoModalidade(CampeonatoModalidade campeonatoModalidade) { this.campeonatoModalidade = campeonatoModalidade; }

    public CampeonatoTime getCampeonatoTimeA() { return campeonatoTimeA; }
    public void setCampeonatoTimeA(CampeonatoTime campeonatoTimeA) { this.campeonatoTimeA = campeonatoTimeA; }

    public CampeonatoTime getCampeonatoTimeB() { return campeonatoTimeB; }
    public void setCampeonatoTimeB(CampeonatoTime campeonatoTimeB) { this.campeonatoTimeB = campeonatoTimeB; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getPeriodoAntesPausa() { return periodoAntesPausa; }
    public void setPeriodoAntesPausa(String periodoAntesPausa) { this.periodoAntesPausa = periodoAntesPausa; }

    /** @deprecated Use getPeriodoAntesPausa() */
    @Deprecated
    public String getStatusAntesPausa() { return periodoAntesPausa; }
    /** @deprecated Use setPeriodoAntesPausa() */
    @Deprecated
    public void setStatusAntesPausa(String v) { this.periodoAntesPausa = v; }

    public OffsetDateTime getDataHoraAgendada() { return dataHoraAgendada; }
    public void setDataHoraAgendada(OffsetDateTime dataHoraAgendada) { this.dataHoraAgendada = dataHoraAgendada; }

    public OffsetDateTime getDataHoraInicio() { return dataHoraInicio; }
    public void setDataHoraInicio(OffsetDateTime dataHoraInicio) { this.dataHoraInicio = dataHoraInicio; }

    public OffsetDateTime getDataHoraFim() { return dataHoraFim; }
    public void setDataHoraFim(OffsetDateTime dataHoraFim) { this.dataHoraFim = dataHoraFim; }

    public String getPeriodoAtual() { return periodoAtual; }
    public void setPeriodoAtual(String periodoAtual) { this.periodoAtual = periodoAtual; }

    public Integer getPlacarTimeA() { return placarTimeA; }
    public void setPlacarTimeA(Integer placarTimeA) { this.placarTimeA = placarTimeA; }

    public Integer getPlacarTimeB() { return placarTimeB; }
    public void setPlacarTimeB(Integer placarTimeB) { this.placarTimeB = placarTimeB; }

    public String getFase() { return fase; }
    public void setFase(String fase) { this.fase = fase; }

    public String getCategoria() { return categoria; }
    public void setCategoria(String categoria) { this.categoria = categoria; }

    public String getLocal() { return local; }
    public void setLocal(String local) { this.local = local; }

    public JsonNode getSnapshotSumula() { return snapshotSumula; }
    public void setSnapshotSumula(JsonNode snapshotSumula) { this.snapshotSumula = snapshotSumula; }

    public String getSumulaPdfUrl() { return sumulaPdfUrl; }
    public void setSumulaPdfUrl(String sumulaPdfUrl) { this.sumulaPdfUrl = sumulaPdfUrl; }

    public String getHashIntegridade() { return hashIntegridade; }
    public void setHashIntegridade(String hashIntegridade) { this.hashIntegridade = hashIntegridade; }

    public Long getVersaoEstado() { return versaoEstado; }
    public void setVersaoEstado(Long versaoEstado) { this.versaoEstado = versaoEstado; }

    public UUID getCriadoPor() { return criadoPor; }
    public void setCriadoPor(UUID criadoPor) { this.criadoPor = criadoPor; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }

    public OffsetDateTime getAtualizadoEm() { return atualizadoEm; }
    public void setAtualizadoEm(OffsetDateTime atualizadoEm) { this.atualizadoEm = atualizadoEm; }

    // Backward compatibility aliases
    public CampeonatoModalidade getModalidade() { return campeonatoModalidade; }
    public void setModalidade(CampeonatoModalidade modalidade) { this.campeonatoModalidade = modalidade; }

    public CampeonatoTime getEquipeA() { return campeonatoTimeA; }
    public void setEquipeA(CampeonatoTime equipeA) { this.campeonatoTimeA = equipeA; }

    public CampeonatoTime getEquipeB() { return campeonatoTimeB; }
    public void setEquipeB(CampeonatoTime equipeB) { this.campeonatoTimeB = equipeB; }

    public CampeonatoTime getTimeA() { return campeonatoTimeA; }
    public void setTimeA(CampeonatoTime timeA) { this.campeonatoTimeA = timeA; }

    public CampeonatoTime getTimeB() { return campeonatoTimeB; }
    public void setTimeB(CampeonatoTime timeB) { this.campeonatoTimeB = timeB; }

    public OffsetDateTime getAgendadoPara() { return dataHoraAgendada; }
    public void setAgendadoPara(OffsetDateTime agendadoPara) { this.dataHoraAgendada = agendadoPara; }

    public OffsetDateTime getIniciadaEm() { return dataHoraInicio; }
    public void setIniciadaEm(OffsetDateTime iniciadaEm) { this.dataHoraInicio = iniciadaEm; }

    public OffsetDateTime getEncerradaEm() { return dataHoraFim; }
    public void setEncerradaEm(OffsetDateTime encerradaEm) { this.dataHoraFim = encerradaEm; }

    public Integer getPlacarA() { return placarTimeA; }
    public void setPlacarA(Integer placarA) { this.placarTimeA = placarA; }

    public Integer getPlacarB() { return placarTimeB; }
    public void setPlacarB(Integer placarB) { this.placarTimeB = placarB; }
}

