package com.nkw.backapisumula.common.log;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class ApplicationLogQueryService {

    private static final int DEFAULT_LIMIT = 50;
    private static final int MAX_LIMIT = 200;

    private final ApplicationLogRepository repository;

    public ApplicationLogQueryService(ApplicationLogRepository repository) {
        this.repository = repository;
    }

    public List<ApplicationLog> list(String level,
                                     String category,
                                     Integer statusCode,
                                     UUID userId,
                                     String requestId,
                                     String path,
                                     String source,
                                     OffsetDateTime from,
                                     OffsetDateTime to,
                                     Integer limit) {
        validatePeriod(from, to);
        ApplicationLogLevel normalizedLevel = normalizeLevel(level);
        int normalizedLimit = normalizeLimit(limit);

        Specification<ApplicationLog> spec = Specification.where(hasLevel(normalizedLevel))
                .and(equalsIgnoreCase("category", category))
                .and(equalsValue("statusCode", statusCode))
                .and(equalsValue("userId", userId))
                .and(equalsIgnoreCase("requestId", requestId))
                .and(containsIgnoreCase("path", path))
                .and(containsIgnoreCase("source", source))
                .and(createdAtFrom(from))
                .and(createdAtTo(to));

        PageRequest pageRequest = PageRequest.of(
                0,
                normalizedLimit,
                Sort.by(Sort.Direction.DESC, "criadoEm")
        );

        return repository.findAll(spec, pageRequest).getContent();
    }

    public ApplicationLog getOrThrow(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Log nao encontrado."));
    }

    private ApplicationLogLevel normalizeLevel(String level) {
        if (level == null || level.isBlank()) {
            return null;
        }

        try {
            return ApplicationLogLevel.valueOf(level.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Nivel de log invalido. Use INFO, WARN ou ERROR.");
        }
    }

    private int normalizeLimit(Integer limit) {
        if (limit == null) {
            return DEFAULT_LIMIT;
        }

        if (limit < 1 || limit > MAX_LIMIT) {
            throw new IllegalArgumentException("Limite invalido. Use um valor entre 1 e 200.");
        }

        return limit;
    }

    private void validatePeriod(OffsetDateTime from, OffsetDateTime to) {
        if (from != null && to != null && from.isAfter(to)) {
            throw new IllegalArgumentException("Periodo invalido. O campo 'from' deve ser menor ou igual a 'to'.");
        }
    }

    private Specification<ApplicationLog> hasLevel(ApplicationLogLevel level) {
        if (level == null) {
            return null;
        }

        return (root, query, criteriaBuilder) -> criteriaBuilder.equal(root.get("level"), level);
    }

    private Specification<ApplicationLog> equalsIgnoreCase(String field, String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        return (root, query, criteriaBuilder) ->
                criteriaBuilder.equal(criteriaBuilder.lower(root.get(field)), value.trim().toLowerCase());
    }

    private Specification<ApplicationLog> containsIgnoreCase(String field, String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        String normalized = "%" + value.trim().toLowerCase() + "%";
        return (root, query, criteriaBuilder) ->
                criteriaBuilder.like(criteriaBuilder.lower(root.get(field)), normalized);
    }

    private Specification<ApplicationLog> equalsValue(String field, Object value) {
        if (value == null) {
            return null;
        }

        return (root, query, criteriaBuilder) -> criteriaBuilder.equal(root.get(field), value);
    }

    private Specification<ApplicationLog> createdAtFrom(OffsetDateTime from) {
        if (from == null) {
            return null;
        }

        return (root, query, criteriaBuilder) ->
                criteriaBuilder.greaterThanOrEqualTo(root.get("criadoEm"), from);
    }

    private Specification<ApplicationLog> createdAtTo(OffsetDateTime to) {
        if (to == null) {
            return null;
        }

        return (root, query, criteriaBuilder) ->
                criteriaBuilder.lessThanOrEqualTo(root.get("criadoEm"), to);
    }
}
