package com.nkw.backapisumula.competicao;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "equipes_staff", schema = "operational")
public class EquipeStaff {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campeonato_time_id", nullable = false)
    private CampeonatoTime campeonatoTime;

    @Column(name = "user_id")
    private UUID userId;

    private String nome;

    private String cargo;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public CampeonatoTime getCampeonatoTime() { return campeonatoTime; }
    public void setCampeonatoTime(CampeonatoTime campeonatoTime) { this.campeonatoTime = campeonatoTime; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getCargo() { return cargo; }
    public void setCargo(String cargo) { this.cargo = cargo; }

    public OffsetDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(OffsetDateTime criadoEm) { this.criadoEm = criadoEm; }
}
