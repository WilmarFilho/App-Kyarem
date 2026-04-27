package com.nkw.backapisumula.partidas;

import com.fasterxml.jackson.databind.JsonNode;
import com.nkw.backapisumula.cadastros.Atleta;
import com.nkw.backapisumula.cadastros.TipoEvento;
import com.nkw.backapisumula.competicao.CampeonatoTime;
import com.nkw.backapisumula.identity.Profile;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "eventos_partida", schema = "operational")
public class EventoPartida {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partida_id", nullable = false)
    private Partida partida;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tipo_evento_id", nullable = false)
    private TipoEvento tipoEvento;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "time_id")
    private CampeonatoTime campeonatoTime;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atleta_id")
    private Atleta atleta;

    private String periodo;

    @Column(name = "minuto_segundo")
    private String minutoSegundo;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "dados_extras", columnDefinition = "jsonb")
    private JsonNode dadosExtras;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "criado_por_user_id", nullable = false)
    private Profile criadoPorUser;

    @Column(name = "criado_em", insertable = false, updatable = false)
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Partida getPartida() { return partida; }
    public void setPartida(Partida partida) { this.partida = partida; }

    public TipoEvento getTipoEvento() { return tipoEvento; }
    public void setTipoEvento(TipoEvento tipoEvento) { this.tipoEvento = tipoEvento; }

    public CampeonatoTime getCampeonatoTime() { return campeonatoTime; }
    public void setCampeonatoTime(CampeonatoTime campeonatoTime) { this.campeonatoTime = campeonatoTime; }

    public Atleta getAtleta() { return atleta; }
    public void setAtleta(Atleta atleta) { this.atleta = atleta; }

    public String getPeriodo() { return periodo; }
    public void setPeriodo(String periodo) { this.periodo = periodo; }

    public String getMinutoSegundo() { return minutoSegundo; }
    public void setMinutoSegundo(String minutoSegundo) { this.minutoSegundo = minutoSegundo; }

    public JsonNode getDadosExtras() { return dadosExtras; }
    public void setDadosExtras(JsonNode dadosExtras) { this.dadosExtras = dadosExtras; }

    public Profile getCriadoPorUser() { return criadoPorUser; }
    public void setCriadoPorUser(Profile criadoPorUser) { this.criadoPorUser = criadoPorUser; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
