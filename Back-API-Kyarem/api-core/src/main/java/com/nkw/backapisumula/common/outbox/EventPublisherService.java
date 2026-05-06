package com.nkw.backapisumula.common.outbox;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class EventPublisherService {
    private static final Logger log = LoggerFactory.getLogger(EventPublisherService.class);

    private final OutboxEventRepository outboxEventRepository;
    private final ObjectMapper objectMapper;

    public EventPublisherService(OutboxEventRepository outboxEventRepository, ObjectMapper objectMapper) {
        this.outboxEventRepository = outboxEventRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void publish(String aggregateType, String aggregateId, String eventType, Object payload) {
        OutboxEvent event = new OutboxEvent();
        event.setId(UUID.randomUUID());
        event.setAggregateType(aggregateType);
        event.setAggregateId(aggregateId);
        event.setEventType(eventType);
        ObjectNode payloadNode = objectMapper.valueToTree(payload);
        payloadNode.put("aggregateId", aggregateId);
        payloadNode.put("aggregateType", aggregateType);
        payloadNode.put("eventType", eventType);
        event.setPayloadJson(payloadNode);
        event.setOccurredAt(OffsetDateTime.now());
        outboxEventRepository.save(event);
        log.info("[api-core] Evento registrado na outbox: outboxEventId={}, aggregateType={}, aggregateId={}, eventType={}, payload={}",
                event.getId(),
                aggregateType,
                aggregateId,
                eventType,
                payloadNode);
    }
}
