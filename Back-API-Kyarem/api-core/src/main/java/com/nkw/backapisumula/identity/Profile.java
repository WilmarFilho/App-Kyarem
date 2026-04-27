package com.nkw.backapisumula.identity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "profiles")
public class Profile {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "nome_exibicao")
    private String nomeExibicao;

    @Column(name = "foto_url")
    private String fotoUrl;

    private String telefone;

    @Column(nullable = false)
    private String role;

    @Column(name = "atualizado_em")
    private OffsetDateTime atualizadoEm;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    // getters/setters

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getNomeExibicao() { return nomeExibicao; }
    public void setNomeExibicao(String nomeExibicao) { this.nomeExibicao = nomeExibicao; }

    public String getFotoUrl() { return fotoUrl; }
    public void setFotoUrl(String fotoUrl) { this.fotoUrl = fotoUrl; }

    public String getTelefone() { return telefone; }
    public void setTelefone(String telefone) { this.telefone = telefone; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public OffsetDateTime getAtualizadoEm() { return atualizadoEm; }
    public void setAtualizadoEm(OffsetDateTime atualizadoEm) { this.atualizadoEm = atualizadoEm; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
