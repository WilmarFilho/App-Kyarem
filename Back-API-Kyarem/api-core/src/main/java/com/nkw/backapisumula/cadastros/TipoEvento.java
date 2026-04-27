package com.nkw.backapisumula.cadastros;

import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "tipos_eventos")
public class TipoEvento {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "esporte_id", nullable = false)
    private Esporte esporte;

    @Column(nullable = false)
    private String nome;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Esporte getEsporte() { return esporte; }
    public void setEsporte(Esporte esporte) { this.esporte = esporte; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }
}
