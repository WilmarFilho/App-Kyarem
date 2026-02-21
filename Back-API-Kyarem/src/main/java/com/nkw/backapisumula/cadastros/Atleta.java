package com.nkw.backapisumula.cadastros;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "atletas")
public class Atleta {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "atletica_id")
    private Atletica atletica;

    @Column(nullable = false)
    private String nome;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Atletica getAtletica() { return atletica; }
    public void setAtletica(Atletica atletica) { this.atletica = atletica; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
