package com.kyarem.outbox.repository;

import com.kyarem.outbox.domain.OutboxEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OutboxEventRepository extends JpaRepository<OutboxEvent, String> {

    /**
     * Busca até 50 eventos pendentes, ordenados por data de ocorrência.
     * O LIMIT evita processar um backlog enorme de uma só vez.
     */
    @Query(value = """
            SELECT * FROM operational.outbox_events
            WHERE status = 'PENDING'
            ORDER BY occurred_at ASC
            LIMIT 50
            """, nativeQuery = true)
    List<OutboxEvent> findPendingEvents();

    /**
     * Busca eventos que falharam e ainda podem ser retentados (max 3 tentativas).
     */
    @Query(value = """
            SELECT * FROM operational.outbox_events
            WHERE status = 'FAILED' AND retry_count < 3
            ORDER BY occurred_at ASC
            LIMIT 20
            """, nativeQuery = true)
    List<OutboxEvent> findRetryableEvents();
}
