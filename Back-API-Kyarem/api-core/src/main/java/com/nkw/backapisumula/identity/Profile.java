package com.nkw.backapisumula.identity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "profiles", schema = "operational")
public class Profile {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "nome_exibicao")
    private String nomeExibicao;

    @Column(name = "nome_completo")
    private String nomeCompleto;

    private String email;

    private String telefone;

    @Column(name = "avatar_url")
    private String avatarUrl;

    private String status;

    @Transient
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

    public String getNomeCompleto() { return nomeCompleto; }
    public void setNomeCompleto(String nomeCompleto) { this.nomeCompleto = nomeCompleto; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getTelefone() { return telefone; }
    public void setTelefone(String telefone) { this.telefone = telefone; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public String getFotoUrl() { return avatarUrl; }
    public void setFotoUrl(String fotoUrl) { this.avatarUrl = fotoUrl; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public OffsetDateTime getAtualizadoEm() { return atualizadoEm; }
    public void setAtualizadoEm(OffsetDateTime atualizadoEm) { this.atualizadoEm = atualizadoEm; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
