package com.nkw.backapisumula.cadastros;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "atleticas")
public class Atletica {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(nullable = false)
    private String nome;

    private String sigla;

    @Column(name = "cor_principal")
    private String corPrincipal;

    @Column(name = "escudo_url")
    private String escudoUrl;

    @Column(name = "presidente_id", columnDefinition = "uuid")
    private UUID presidenteId;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getSigla() { return sigla; }
    public void setSigla(String sigla) { this.sigla = sigla; }

    public String getCorPrincipal() { return corPrincipal; }
    public void setCorPrincipal(String corPrincipal) { this.corPrincipal = corPrincipal; }

    public String getEscudoUrl() { return escudoUrl; }
    public void setEscudoUrl(String escudoUrl) { this.escudoUrl = escudoUrl; }

    public UUID getPresidenteId() { return presidenteId; }
    public void setPresidenteId(UUID presidenteId) { this.presidenteId = presidenteId; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
