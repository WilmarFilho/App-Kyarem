package com.nkw.backapisumula.partidas;

import com.nkw.backapisumula.identity.Profile;
import jakarta.persistence.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "partida_arbitros")
public class PartidaArbitro {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partida_id")
    private Partida partida;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "arbitro_id")
    private Profile arbitro;

    @Column(nullable = false)
    private String funcao;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Partida getPartida() { return partida; }
    public void setPartida(Partida partida) { this.partida = partida; }

    public Profile getArbitro() { return arbitro; }
    public void setArbitro(Profile arbitro) { this.arbitro = arbitro; }

    public String getFuncao() { return funcao; }
    public void setFuncao(String funcao) { this.funcao = funcao; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
