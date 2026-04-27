package com.nkw.backapisumula.competicao;

import com.nkw.backapisumula.cadastros.Atletica;
import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "times_atletica", schema = "operational")
public class TimeAtletica {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atletica_id", nullable = false)
    private Atletica atletica;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "modalidade_id", nullable = false)
    private ModalidadeCatalogo modalidade;

    @Column(name = "nome_time", nullable = false)
    private String nomeTime;

    @Column(name = "criado_em", nullable = false)
    private OffsetDateTime criadoEm;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Atletica getAtletica() {
        return atletica;
    }

    public void setAtletica(Atletica atletica) {
        this.atletica = atletica;
    }

    public ModalidadeCatalogo getModalidade() {
        return modalidade;
    }

    public void setModalidade(ModalidadeCatalogo modalidade) {
        this.modalidade = modalidade;
    }

    public String getNomeTime() {
        return nomeTime;
    }

    public void setNomeTime(String nomeTime) {
        this.nomeTime = nomeTime;
    }

    public String getNome() {
        return nomeTime;
    }

    public void setNome(String nome) {
        this.nomeTime = nome;
    }

    public String getCategoria() {
        return null;
    }

    public String getGenero() {
        return modalidade != null ? modalidade.getGenero() : null;
    }

    public OffsetDateTime getCriadoEm() {
        return criadoEm;
    }

    public void setCriadoEm(OffsetDateTime criadoEm) {
        this.criadoEm = criadoEm;
    }
}
