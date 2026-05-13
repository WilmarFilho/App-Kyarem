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

    @Column(name = "categoria")
    private String categoria;

    @Column(name = "genero")
    private String genero;

    @Column(name = "status", nullable = false)
    private String status = "ATIVO";

    @Column(name = "criado_por")
    private UUID criadoPor;

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

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getCategoria() {
        return categoria;
    }

    public void setCategoria(String categoria) {
        this.categoria = categoria;
    }

    public String getGenero() {
        return genero;
    }

    public void setGenero(String genero) {
        this.genero = genero;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public UUID getCriadoPor() {
        return criadoPor;
    }

    public void setCriadoPor(UUID criadoPor) {
        this.criadoPor = criadoPor;
    }

    public OffsetDateTime getCriadoEm() {
        return criadoEm;
    }

    public void setCriadoEm(OffsetDateTime criadoEm) {
        this.criadoEm = criadoEm;
    }
}
