package com.nkw.backapisumula.common.log;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Map;
import java.util.UUID;

@Service
public class ApplicationLogService {

    private static final Logger logger = LoggerFactory.getLogger(ApplicationLogService.class);
    private static final int DEFAULT_TEXT_LIMIT = 4_000;
    private static final int STACK_TRACE_LIMIT = 20_000;

    private final ApplicationLogRepository repository;
    private final ObjectMapper objectMapper;

    public ApplicationLogService(ApplicationLogRepository repository, ObjectMapper objectMapper) {
        this.repository = repository;
        this.objectMapper = objectMapper;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void warn(String category,
                     String source,
                     String message,
                     Integer statusCode,
                     HttpServletRequest request,
                     Throwable exception,
                     Map<String, ?> details) {
        log(ApplicationLogLevel.WARN, category, source, message, statusCode, request, exception, details);
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void error(String category,
                      String source,
                      String message,
                      Integer statusCode,
                      HttpServletRequest request,
                      Throwable exception,
                      Map<String, ?> details) {
        log(ApplicationLogLevel.ERROR, category, source, message, statusCode, request, exception, details);
    }

    private void log(ApplicationLogLevel level,
                     String category,
                     String source,
                     String message,
                     Integer statusCode,
                     HttpServletRequest request,
                     Throwable exception,
                     Map<String, ?> details) {
        try {
            ApplicationLog entry = new ApplicationLog();
            entry.setLevel(level);
            entry.setCategory(truncate(category, 100));
            entry.setSource(truncate(resolveSource(source, exception), 255));
            entry.setMessage(truncate(message, DEFAULT_TEXT_LIMIT));
            entry.setStatusCode(statusCode);
            entry.setExceptionClass(exception != null ? truncate(exception.getClass().getName(), 255) : null);
            entry.setStackTrace(level == ApplicationLogLevel.ERROR ? truncate(stackTraceOf(exception), STACK_TRACE_LIMIT) : null);
            entry.setDetails(toJson(details));
            entry.setHttpMethod(request != null ? truncate(request.getMethod(), 16) : null);
            entry.setPath(request != null ? truncate(request.getRequestURI(), 512) : null);
            entry.setRequestId(truncate(resolveRequestId(request), 120));
            entry.setIpAddress(truncate(resolveIpAddress(request), 120));
            entry.setUserAgent(request != null ? truncate(request.getHeader("User-Agent"), 1000) : null);
            entry.setUserId(resolveUserId());

            repository.save(entry);
        } catch (Exception persistenceError) {
            logger.error("Falha ao persistir log de aplicacao [{}] {}.", category, message, persistenceError);
        }
    }

    private JsonNode toJson(Map<String, ?> details) {
        if (details == null || details.isEmpty()) {
            return null;
        }
        return objectMapper.valueToTree(details);
    }

    private String resolveSource(String source, Throwable exception) {
        if (source != null && !source.isBlank()) {
            return source.trim();
        }

        if (exception == null) {
            return null;
        }

        for (StackTraceElement element : exception.getStackTrace()) {
            if (element.getClassName().startsWith("com.nkw.backapisumula")) {
                return element.getClassName() + ":" + element.getLineNumber();
            }
        }

        return exception.getClass().getName();
    }

    private String resolveRequestId(HttpServletRequest request) {
        if (request == null) {
            return null;
        }

        Object attribute = request.getAttribute(RequestCorrelationFilter.REQUEST_ID_ATTRIBUTE);
        if (attribute instanceof String requestId && !requestId.isBlank()) {
            return requestId;
        }

        String header = request.getHeader(RequestCorrelationFilter.REQUEST_ID_HEADER);
        if (header != null && !header.isBlank()) {
            return header.trim();
        }

        return null;
    }

    private String resolveIpAddress(HttpServletRequest request) {
        if (request == null) {
            return null;
        }

        String forwardedFor = normalize(request.getHeader("X-Forwarded-For"));
        if (forwardedFor != null) {
            int separator = forwardedFor.indexOf(',');
            return separator >= 0 ? forwardedFor.substring(0, separator).trim() : forwardedFor;
        }

        String realIp = normalize(request.getHeader("X-Real-IP"));
        if (realIp != null) {
            return realIp;
        }

        return normalize(request.getRemoteAddr());
    }

    private UUID resolveUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }

        Object principal = authentication.getPrincipal();
        if (principal instanceof Jwt jwt) {
            return parseUuid(jwt.getSubject());
        }

        return parseUuid(authentication.getName());
    }

    private UUID parseUuid(String rawValue) {
        if (rawValue == null || rawValue.isBlank()) {
            return null;
        }

        try {
            return UUID.fromString(rawValue.trim());
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }

    private String stackTraceOf(Throwable exception) {
        if (exception == null) {
            return null;
        }

        StringWriter stringWriter = new StringWriter();
        PrintWriter printWriter = new PrintWriter(stringWriter);
        exception.printStackTrace(printWriter);
        return stringWriter.toString();
    }

    private String truncate(String value, int maxLength) {
        if (value == null) {
            return null;
        }

        return value.length() <= maxLength ? value : value.substring(0, maxLength);
    }

    private String normalize(String value) {
        if (value == null) {
            return null;
        }

        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
