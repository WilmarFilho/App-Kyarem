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
    @JoinColumn(name = "modalidade_catalogo_id", nullable = false)
    private ModalidadeCatalogo modalidade;

    @Column(name = "nome", nullable = false)
    private String nome;

    @Column(name = "status")
    private String status = "ATIVO";

    @Column(name = "genero", nullable = false)
    private String genero;

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
        return nome;
    }

    public void setNomeTime(String nomeTime) {
        this.nome = nomeTime;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getCategoria() {
        return null;
    }

    public String getGenero() {
        return genero;
    }

    public void setGenero(String genero) {
        this.genero = genero;
    }

    public OffsetDateTime getCriadoEm() {
        return criadoEm;
    }

    public void setCriadoEm(OffsetDateTime criadoEm) {
        this.criadoEm = criadoEm;
    }
}
