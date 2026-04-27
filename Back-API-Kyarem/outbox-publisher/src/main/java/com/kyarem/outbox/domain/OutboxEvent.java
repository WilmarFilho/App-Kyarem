package com.kyarem.outbox.domain;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Espelha a tabela operational.outbox_events.
 * O outbox-publisher apenas lê e marca como publicado — nunca escreve novos eventos.
 */
@Entity
@Table(name = "outbox_events", schema = "operational")
public class OutboxEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(name = "aggregate_type", nullable = false)
    private String aggregateType;

    @Column(name = "aggregate_id", nullable = false)
    private String aggregateId;

    @Column(name = "event_type", nullable = false)
    private String eventType;

    @Column(name = "payload_json", columnDefinition = "text")
    private String payloadJson;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    @Column(name = "published_at")
    private Instant publishedAt;

    @Column(name = "status", nullable = false)
    private String status; // PENDING | PUBLISHED | FAILED

    @Column(name = "retry_count")
    private int retryCount;

    // ── Getters ──────────────────────────────────────────────────────────────

    public String getId()            { return id; }
    public String getAggregateType() { return aggregateType; }
    public String getAggregateId()   { return aggregateId; }
    public String getEventType()     { return eventType; }
    public String getPayloadJson()   { return payloadJson; }
    public Instant getOccurredAt()   { return occurredAt; }
    public String getStatus()        { return status; }
    public int getRetryCount()       { return retryCount; }

    // ── Setters (apenas os que o publisher precisa modificar) ─────────────────

    public void setPublishedAt(Instant publishedAt) { this.publishedAt = publishedAt; }
    public void setStatus(String status)            { this.status = status; }
    public void setRetryCount(int retryCount)       { this.retryCount = retryCount; }
}
