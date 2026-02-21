package com.nkw.backapisumula.partidas;

import com.nkw.backapisumula.cadastros.Atleta;
import com.nkw.backapisumula.cadastros.TipoEvento;
import com.nkw.backapisumula.competicao.Equipe;
import jakarta.persistence.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "eventos_partida")
public class EventoPartida {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partida_id")
    private Partida partida;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atleta_id")
    private Atleta atleta;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "equipe_id")
    private Equipe equipe;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tipo_evento_id")
    private TipoEvento tipoEvento;

    @Column(name = "tempo_cronometro")
    private String tempoCronometro;

    @Column(name = "descricao_detalhada")
    private String descricaoDetalhada;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Partida getPartida() { return partida; }
    public void setPartida(Partida partida) { this.partida = partida; }

    public Atleta getAtleta() { return atleta; }
    public void setAtleta(Atleta atleta) { this.atleta = atleta; }

    public Equipe getEquipe() { return equipe; }
    public void setEquipe(Equipe equipe) { this.equipe = equipe; }

    public TipoEvento getTipoEvento() { return tipoEvento; }
    public void setTipoEvento(TipoEvento tipoEvento) { this.tipoEvento = tipoEvento; }

    public String getTempoCronometro() { return tempoCronometro; }
    public void setTempoCronometro(String tempoCronometro) { this.tempoCronometro = tempoCronometro; }

    public String getDescricaoDetalhada() { return descricaoDetalhada; }
    public void setDescricaoDetalhada(String descricaoDetalhada) { this.descricaoDetalhada = descricaoDetalhada; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
