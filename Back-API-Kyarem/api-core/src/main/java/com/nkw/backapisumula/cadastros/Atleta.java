package com.nkw.backapisumula.cadastros;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "profiles", schema = "operational")
public class Atleta {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "nome_exibicao")
    private String nomeExibicao;

    @Column(name = "nome_completo")
    private String nomeCompleto;

    @Column(name = "avatar_url")
    private String fotoUrl;

    @Column(name = "data_nascimento")
    private LocalDate dataNascimento;

    private String genero;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getNomeCompeticao() { return getNome(); }
    public void setNomeCompeticao(String nomeCompeticao) { this.nomeExibicao = nomeCompeticao; }

    public String getNome() {
        if (nomeExibicao != null && !nomeExibicao.isBlank()) return nomeExibicao;
        return nomeCompleto;
    }
    public void setNome(String nome) { this.nomeExibicao = nome; }

    public String getFotoUrl() { return fotoUrl; }
    public void setFotoUrl(String fotoUrl) { this.fotoUrl = fotoUrl; }

    public LocalDate getDataNascimento() { return dataNascimento; }
    public void setDataNascimento(LocalDate dataNascimento) { this.dataNascimento = dataNascimento; }

    public String getGenero() { return genero; }
    public void setGenero(String genero) { this.genero = genero; }
}
