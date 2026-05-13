package com.kyarem.outbox.service;

import com.kyarem.outbox.domain.OutboxEvent;
import com.kyarem.outbox.repository.OutboxEventRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Publica eventos da outbox no RabbitMQ de forma confiável.
 *
 * Fluxo:
 *  1. Poll em outbox_events WHERE status = 'PENDING'
 *  2. Publica no exchange kyarem.events com routing_key = event_type
 *  3. Marca como PUBLISHED (ou FAILED em caso de erro)
 *  4. Retry automático para eventos FAILED (max 3 tentativas)
 */
@Service
public class OutboxPublisherService {

    private static final Logger log = LoggerFactory.getLogger(OutboxPublisherService.class);

    private static final String EXCHANGE = "kyarem.events";

    private final OutboxEventRepository repository;
    private final RabbitTemplate rabbitTemplate;

    public OutboxPublisherService(OutboxEventRepository repository,
                                   RabbitTemplate rabbitTemplate) {
        this.repository = repository;
        this.rabbitTemplate = rabbitTemplate;
    }

    /**
     * Processa eventos pendentes a cada 2 segundos.
     */
    @Scheduled(fixedDelayString = "${outbox.poll-interval-ms:2000}")
    @Transactional
    public void publishPendingEvents() {
        List<OutboxEvent> pending = repository.findPendingEvents();
        if (pending.isEmpty()) return;

        log.info("[outbox-publisher] Processando {} eventos pendentes", pending.size());
        pending.forEach(this::publish);
    }

    /**
     * Retenta eventos que falharam a cada 30 segundos.
     */
    @Scheduled(fixedDelayString = "${outbox.retry-interval-ms:30000}")
    @Transactional
    public void retryFailedEvents() {
        List<OutboxEvent> retryable = repository.findRetryableEvents();
        if (retryable.isEmpty()) return;

        log.info("[outbox-publisher] Retentando {} eventos com falha", retryable.size());
        retryable.forEach(this::publish);
    }

    private void publish(OutboxEvent event) {
        // A routing key é o eventType em lowercase com pontos
        // Ex: MatchScoreUpdated → match.score.updated
        String routingKey = toRoutingKey(event.getEventType());
        log.info("[outbox-publisher] Publicando evento: outboxEventId={}, aggregateType={}, aggregateId={}, eventType={}, routingKey={}, payload={}",
                event.getId(),
                event.getAggregateType(),
                event.getAggregateId(),
                event.getEventType(),
                routingKey,
                event.getPayloadJson());

        try {
            rabbitTemplate.convertAndSend(EXCHANGE, routingKey, event.getPayloadJson());
            event.setStatus("PUBLISHED");
            event.setPublishedAt(Instant.now());
            log.info("[outbox-publisher] Evento publicado com sucesso: outboxEventId={}, routingKey={}, publishedAt={}",
                    event.getId(),
                    routingKey,
                    event.getPublishedAt());
        } catch (Exception ex) {
            log.error("[outbox-publisher] Falha ao publicar evento: outboxEventId={}, aggregateType={}, aggregateId={}, eventType={}, routingKey={}, erro={}",
                    event.getId(),
                    event.getAggregateType(),
                    event.getAggregateId(),
                    event.getEventType(),
                    routingKey,
                    ex.getMessage(),
                    ex);
            event.setStatus("FAILED");
            event.setRetryCount(event.getRetryCount() + 1);
        }

        repository.save(event);
    }

    /**
     * Converte eventType (PascalCase) → routing_key (snake.case)
     * Ex: MatchScoreUpdated → match.score.updated
     */
    private String toRoutingKey(String eventType) {
        return eventType
                .replaceAll("([A-Z])", ".$1")
                .toLowerCase()
                .replaceFirst("^\\.", "");
    }
}
