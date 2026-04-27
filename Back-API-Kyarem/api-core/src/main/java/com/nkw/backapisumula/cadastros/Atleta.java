package com.nkw.backapisumula.cadastros;

import com.nkw.backapisumula.identity.Profile;
import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "atletas", schema = "operational")
public class Atleta {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private Profile user;

    @Column(name = "nome_competicao")
    private String nomeCompeticao;

    @Column(name = "foto_url")
    private String fotoUrl;

    @Column(name = "data_nascimento")
    private LocalDate dataNascimento;

    private String genero;

    private Boolean ativo = true;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }


    public Profile getUser() { return user; }
    public void setUser(Profile user) { this.user = user; }

    public String getNomeCompeticao() { return nomeCompeticao; }
    public void setNomeCompeticao(String nomeCompeticao) { this.nomeCompeticao = nomeCompeticao; }

    public String getNome() { return nomeCompeticao; }
    public void setNome(String nome) { this.nomeCompeticao = nome; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }

    public String getFotoUrl() { return fotoUrl; }
    public void setFotoUrl(String fotoUrl) { this.fotoUrl = fotoUrl; }

    public LocalDate getDataNascimento() { return dataNascimento; }
    public void setDataNascimento(LocalDate dataNascimento) { this.dataNascimento = dataNascimento; }

    public String getGenero() { return genero; }
    public void setGenero(String genero) { this.genero = genero; }

    public Boolean getAtivo() { return ativo; }
    public void setAtivo(Boolean ativo) { this.ativo = ativo; }
}
