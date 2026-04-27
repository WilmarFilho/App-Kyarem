package com.nkw.backapisumula.cadastros;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "atleticas", schema = "operational")
public class Atletica {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(nullable = false)
    private String nome;

    private String sigla;

    private String slug;

    @Column(name = "cor_principal")
    private String corPrincipal;

    @Column(name = "escudo_url")
    private String escudoUrl;

    @Column(name = "criado_por", columnDefinition = "uuid")
    private UUID criadoPor;

    private String status;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getSigla() { return sigla; }
    public void setSigla(String sigla) { this.sigla = sigla; }

    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }

    public String getCorPrincipal() { return corPrincipal; }
    public void setCorPrincipal(String corPrincipal) { this.corPrincipal = corPrincipal; }

    public String getEscudoUrl() { return escudoUrl; }
    public void setEscudoUrl(String escudoUrl) { this.escudoUrl = escudoUrl; }

    public UUID getCriadoPor() { return criadoPor; }
    public void setCriadoPor(UUID criadoPor) { this.criadoPor = criadoPor; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
