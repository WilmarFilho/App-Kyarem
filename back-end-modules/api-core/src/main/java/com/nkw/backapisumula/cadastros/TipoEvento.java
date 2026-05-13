package com.nkw.backapisumula.cadastros;

import jakarta.persistence.*;
import com.nkw.backapisumula.competicao.ModalidadeCatalogo;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.UUID;

@Entity
@Table(name = "tipos_eventos", schema = "operational")
public class TipoEvento {

    @Id
    @GeneratedValue
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "modalidade_catalogo_id", nullable = false)
    private ModalidadeCatalogo modalidadeCatalogo;

    @Column(nullable = false)
    private String codigo;

    @Column(nullable = false)
    private String nome;

    @Column(nullable = false)
    private String escopo;

    @Column(name = "impacta_placar", nullable = false)
    private Boolean impactaPlacar = false;

    @Column(name = "pontos_pro")
    private Integer pontosPro;

    @Column(name = "pontos_contra")
    private Integer pontosContra;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "payload_schema_json", columnDefinition = "jsonb")
    private JsonNode payloadSchemaJson;

    @Column(name = "ordem_exibicao")
    private Integer ordemExibicao;

    @Column(nullable = false)
    private Boolean ativo = true;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public ModalidadeCatalogo getModalidadeCatalogo() { return modalidadeCatalogo; }
    public void setModalidadeCatalogo(ModalidadeCatalogo modalidadeCatalogo) { this.modalidadeCatalogo = modalidadeCatalogo; }

    public String getCodigo() { return codigo; }
    public void setCodigo(String codigo) { this.codigo = codigo; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getEscopo() { return escopo; }
    public void setEscopo(String escopo) { this.escopo = escopo; }

    public Boolean getImpactaPlacar() { return impactaPlacar; }
    public void setImpactaPlacar(Boolean impactaPlacar) { this.impactaPlacar = impactaPlacar; }

    public Integer getPontosPro() { return pontosPro; }
    public void setPontosPro(Integer pontosPro) { this.pontosPro = pontosPro; }

    public Integer getPontosContra() { return pontosContra; }
    public void setPontosContra(Integer pontosContra) { this.pontosContra = pontosContra; }

    public JsonNode getPayloadSchemaJson() { return payloadSchemaJson; }
    public void setPayloadSchemaJson(JsonNode payloadSchemaJson) { this.payloadSchemaJson = payloadSchemaJson; }

    public Integer getOrdemExibicao() { return ordemExibicao; }
    public void setOrdemExibicao(Integer ordemExibicao) { this.ordemExibicao = ordemExibicao; }

    public Boolean getAtivo() { return ativo; }
    public void setAtivo(Boolean ativo) { this.ativo = ativo; }
}
