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
    @JoinColumn(name = "equipe_id")
    private CampeonatoTime equipe;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atleta_id")
    private Atleta atleta;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atleta_sai_id")
    private Atleta atletaSai;

    private String periodo;

    @Column(name = "tempo_cronometro")
    private String tempoCronometro;

    @Column(name = "descricao_detalhada")
    private String descricaoDetalhada;

    @Column(name = "is_substitution")
    private Boolean isSubstitution = false;

    @Column(name = "local_evento_id", unique = true)
    private String localEventoId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "payload_json", columnDefinition = "jsonb")
    private JsonNode payloadJson;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "arbitro_user_id", nullable = false)
    private Profile arbitroUser;

    @Column(name = "criado_em", insertable = false, updatable = false)
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Partida getPartida() { return partida; }
    public void setPartida(Partida partida) { this.partida = partida; }

    public TipoEvento getTipoEvento() { return tipoEvento; }
    public void setTipoEvento(TipoEvento tipoEvento) { this.tipoEvento = tipoEvento; }

    public CampeonatoTime getEquipe() { return equipe; }
    public void setEquipe(CampeonatoTime equipe) { this.equipe = equipe; }

    public Atleta getAtleta() { return atleta; }
    public void setAtleta(Atleta atleta) { this.atleta = atleta; }

    public Atleta getAtletaSai() { return atletaSai; }
    public void setAtletaSai(Atleta atletaSai) { this.atletaSai = atletaSai; }

    public String getPeriodo() { return periodo; }
    public void setPeriodo(String periodo) { this.periodo = periodo; }

    public String getTempoCronometro() { return tempoCronometro; }
    public void setTempoCronometro(String tempoCronometro) { this.tempoCronometro = tempoCronometro; }

    public String getDescricaoDetalhada() { return descricaoDetalhada; }
    public void setDescricaoDetalhada(String descricaoDetalhada) { this.descricaoDetalhada = descricaoDetalhada; }

    public Boolean getIsSubstitution() { return isSubstitution; }
    public void setIsSubstitution(Boolean isSubstitution) { this.isSubstitution = isSubstitution; }

    public String getLocalEventoId() { return localEventoId; }
    public void setLocalEventoId(String localEventoId) { this.localEventoId = localEventoId; }

    public JsonNode getPayloadJson() { return payloadJson; }
    public void setPayloadJson(JsonNode payloadJson) { this.payloadJson = payloadJson; }

    public Profile getArbitroUser() { return arbitroUser; }
    public void setArbitroUser(Profile arbitroUser) { this.arbitroUser = arbitroUser; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }


}
