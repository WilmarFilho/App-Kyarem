package com.nkw.backapisumula.competicao;

import com.nkw.backapisumula.cadastros.Atleta;
import jakarta.persistence.*;

import java.util.UUID;

@Entity
@Table(name = "equipe_atlet_inscritos")
public class EquipeAtletaInscrito {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "equipe_id")
    private Equipe equipe;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atleta_id")
    private Atleta atleta;

    @Column(name = "numero_camisa")
    private Integer numeroCamisa;

    private Boolean ativo;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Equipe getEquipe() { return equipe; }
    public void setEquipe(Equipe equipe) { this.equipe = equipe; }

    public Atleta getAtleta() { return atleta; }
    public void setAtleta(Atleta atleta) { this.atleta = atleta; }

    public Integer getNumeroCamisa() { return numeroCamisa; }
    public void setNumeroCamisa(Integer numeroCamisa) { this.numeroCamisa = numeroCamisa; }

    public Boolean getAtivo() { return ativo; }
    public void setAtivo(Boolean ativo) { this.ativo = ativo; }
}
