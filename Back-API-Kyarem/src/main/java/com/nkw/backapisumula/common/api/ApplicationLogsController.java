package com.nkw.backapisumula.common.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.nkw.backapisumula.common.log.ApplicationLog;
import com.nkw.backapisumula.common.log.ApplicationLogQueryService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/logs")
public class ApplicationLogsController {

    private final ApplicationLogQueryService queryService;

    public ApplicationLogsController(ApplicationLogQueryService queryService) {
        this.queryService = queryService;
    }

    @GetMapping
    @PreAuthorize("hasRole('admin')")
    public List<ApplicationLogSummaryResponse> list(
            @RequestParam(required = false) String level,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Integer statusCode,
            @RequestParam(required = false) UUID userId,
            @RequestParam(required = false) String requestId,
            @RequestParam(required = false) String path,
            @RequestParam(required = false) String source,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to,
            @RequestParam(required = false) Integer limit
    ) {
        return queryService.list(level, category, statusCode, userId, requestId, path, source, from, to, limit)
                .stream()
                .map(ApplicationLogSummaryResponse::from)
                .toList();
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('admin')")
    public ApplicationLogDetailResponse get(@PathVariable UUID id) {
        return ApplicationLogDetailResponse.from(queryService.getOrThrow(id));
    }

    public record ApplicationLogSummaryResponse(
            UUID id,
            String level,
            String category,
            String message,
            String source,
            String exceptionClass,
            JsonNode details,
            String httpMethod,
            String path,
            Integer statusCode,
            UUID userId,
            String requestId,
            String ipAddress,
            String userAgent,
            OffsetDateTime criadoEm
    ) {
        public static ApplicationLogSummaryResponse from(ApplicationLog log) {
            return new ApplicationLogSummaryResponse(
                    log.getId(),
                    log.getLevel() != null ? log.getLevel().name() : null,
                    log.getCategory(),
                    log.getMessage(),
                    log.getSource(),
                    log.getExceptionClass(),
                    log.getDetails(),
                    log.getHttpMethod(),
                    log.getPath(),
                    log.getStatusCode(),
                    log.getUserId(),
                    log.getRequestId(),
                    log.getIpAddress(),
                    log.getUserAgent(),
                    log.getCriadoEm()
            );
        }
    }

    public record ApplicationLogDetailResponse(
            UUID id,
            String level,
            String category,
            String message,
            String source,
            String exceptionClass,
            String stackTrace,
            JsonNode details,
            String httpMethod,
            String path,
            Integer statusCode,
            UUID userId,
            String requestId,
            String ipAddress,
            String userAgent,
            OffsetDateTime criadoEm
    ) {
        public static ApplicationLogDetailResponse from(ApplicationLog log) {
            return new ApplicationLogDetailResponse(
                    log.getId(),
                    log.getLevel() != null ? log.getLevel().name() : null,
                    log.getCategory(),
                    log.getMessage(),
                    log.getSource(),
                    log.getExceptionClass(),
                    log.getStackTrace(),
                    log.getDetails(),
                    log.getHttpMethod(),
                    log.getPath(),
                    log.getStatusCode(),
                    log.getUserId(),
                    log.getRequestId(),
                    log.getIpAddress(),
                    log.getUserAgent(),
                    log.getCriadoEm()
            );
        }
    }
}
