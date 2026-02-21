package com.nkw.backapisumula.competicao;

import com.nkw.backapisumula.cadastros.Atletica;
import jakarta.persistence.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "equipes")
public class Equipe {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atletica_id")
    private Atletica atletica;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_id")
    private Campeonato campeonato;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "modalidade_id")
    private Modalidade modalidade;

    @Column(name = "nome_equipe", nullable = false)
    private String nomeEquipe;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Atletica getAtletica() { return atletica; }
    public void setAtletica(Atletica atletica) { this.atletica = atletica; }

    public Campeonato getCampeonato() { return campeonato; }
    public void setCampeonato(Campeonato campeonato) { this.campeonato = campeonato; }

    public Modalidade getModalidade() { return modalidade; }
    public void setModalidade(Modalidade modalidade) { this.modalidade = modalidade; }

    public String getNomeEquipe() { return nomeEquipe; }
    public void setNomeEquipe(String nomeEquipe) { this.nomeEquipe = nomeEquipe; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
