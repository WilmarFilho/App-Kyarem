package com.nkw.backapisumula.cadastros;

import com.nkw.backapisumula.identity.Profile;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "atletica_membros", schema = "operational")
public class AtleticaMembro {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atletica_id", nullable = false)
    private Atletica atletica;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private Profile user;

    @Column(name = "papel_codigo", nullable = false)
    private String papelCodigo;

    @Column(nullable = false)
    private String status;

    @Column(name = "criado_por", columnDefinition = "uuid")
    private UUID criadoPor;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    @Column(name = "iniciado_em")
    private OffsetDateTime iniciadoEm;

    @Column(name = "encerrado_em")
    private OffsetDateTime encerradoEm;

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

    public Profile getUser() {
        return user;
    }

    public void setUser(Profile user) {
        this.user = user;
    }

    public String getPapelCodigo() {
        return papelCodigo;
    }

    public void setPapelCodigo(String papelCodigo) {
        this.papelCodigo = papelCodigo;
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

    public OffsetDateTime getIniciadoEm() {
        return iniciadoEm;
    }

    public void setIniciadoEm(OffsetDateTime iniciadoEm) {
        this.iniciadoEm = iniciadoEm;
    }

    public OffsetDateTime getEncerradoEm() {
        return encerradoEm;
    }

    public void setEncerradoEm(OffsetDateTime encerradoEm) {
        this.encerradoEm = encerradoEm;
    }
}
