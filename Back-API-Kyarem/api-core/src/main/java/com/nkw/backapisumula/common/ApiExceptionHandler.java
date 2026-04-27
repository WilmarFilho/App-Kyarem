package com.nkw.backapisumula.common;

import com.nkw.backapisumula.common.log.ApplicationLogService;
import com.nkw.backapisumula.common.log.RequestCorrelationFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {

    private final ApplicationLogService applicationLogService;

    public ApiExceptionHandler(ApplicationLogService applicationLogService) {
        this.applicationLogService = applicationLogService;
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ProblemDetail handleIllegalArgument(IllegalArgumentException ex, HttpServletRequest request) {
        applicationLogService.warn(
                "REQUEST",
                "ApiExceptionHandler",
                "Requisicao invalida",
                HttpStatus.BAD_REQUEST.value(),
                request,
                ex,
                details("message", ex.getMessage())
        );

        return problemDetail(HttpStatus.BAD_REQUEST, "Requisicao invalida", ex.getMessage(), request);
    }

    @ExceptionHandler(IllegalStateException.class)
    public ProblemDetail handleIllegalState(IllegalStateException ex, HttpServletRequest request) {
        applicationLogService.warn(
                "BUSINESS",
                "ApiExceptionHandler",
                "Conflito de regra de negocio",
                HttpStatus.CONFLICT.value(),
                request,
                ex,
                details("message", ex.getMessage())
        );

        return problemDetail(HttpStatus.CONFLICT, "Conflito", ex.getMessage(), request);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        applicationLogService.warn(
                "VALIDATION",
                "ApiExceptionHandler",
                "Falha de validacao da requisicao",
                HttpStatus.BAD_REQUEST.value(),
                request,
                ex,
                validationDetails(ex)
        );

        return problemDetail(
                HttpStatus.BAD_REQUEST,
                "Validacao",
                "Existem campos invalidos na requisicao.",
                request
        );
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ProblemDetail handleConstraintViolation(ConstraintViolationException ex, HttpServletRequest request) {
        applicationLogService.warn(
                "VALIDATION",
                "ApiExceptionHandler",
                "Falha de validacao por constraint",
                HttpStatus.BAD_REQUEST.value(),
                request,
                ex,
                constraintDetails(ex)
        );

        return problemDetail(HttpStatus.BAD_REQUEST, "Validacao", ex.getMessage(), request);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ProblemDetail handleUnreadableMessage(HttpMessageNotReadableException ex, HttpServletRequest request) {
        applicationLogService.warn(
                "REQUEST",
                "ApiExceptionHandler",
                "JSON invalido na requisicao",
                HttpStatus.BAD_REQUEST.value(),
                request,
                ex,
                details("message", ex.getMostSpecificCause() != null ? ex.getMostSpecificCause().getMessage() : ex.getMessage())
        );

        return problemDetail(
                HttpStatus.BAD_REQUEST,
                "JSON invalido",
                "Nao foi possivel interpretar o corpo da requisicao.",
                request
        );
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ProblemDetail handleAccessDenied(AccessDeniedException ex, HttpServletRequest request) {
        applicationLogService.warn(
                "SECURITY",
                "ApiExceptionHandler",
                "Acesso negado",
                HttpStatus.FORBIDDEN.value(),
                request,
                ex,
                details("message", ex.getMessage())
        );

        return problemDetail(
                HttpStatus.FORBIDDEN,
                "Acesso negado",
                "Voce nao tem permissao para esta operacao.",
                request
        );
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ProblemDetail handleResponseStatus(ResponseStatusException ex, HttpServletRequest request) {
        HttpStatus status = HttpStatus.valueOf(ex.getStatusCode().value());

        if (status.is5xxServerError()) {
            applicationLogService.error(
                    "HTTP",
                    "ApiExceptionHandler",
                    ex.getReason() != null ? ex.getReason() : "Erro HTTP",
                    status.value(),
                    request,
                    ex,
                    details("message", ex.getMessage())
            );
        } else {
            applicationLogService.warn(
                    "HTTP",
                    "ApiExceptionHandler",
                    ex.getReason() != null ? ex.getReason() : "Erro HTTP",
                    status.value(),
                    request,
                    ex,
                    details("message", ex.getMessage())
            );
        }

        return problemDetail(
                status,
                status.getReasonPhrase(),
                ex.getReason() != null ? ex.getReason() : status.getReasonPhrase(),
                request
        );
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleUnexpected(Exception ex, HttpServletRequest request) {
        applicationLogService.error(
                "INTERNAL",
                "ApiExceptionHandler",
                "Erro inesperado no back-end",
                HttpStatus.INTERNAL_SERVER_ERROR.value(),
                request,
                ex,
                unexpectedDetails(ex)
        );

        return problemDetail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "Erro interno",
                "Ocorreu um erro inesperado no servidor.",
                request
        );
    }

    private ProblemDetail problemDetail(HttpStatus status, String title, String detail, HttpServletRequest request) {
        ProblemDetail pd = ProblemDetail.forStatus(status);
        pd.setTitle(title);
        pd.setDetail(detail);

        String requestId = resolveRequestId(request);
        if (requestId != null) {
            pd.setProperty("requestId", requestId);
        }

        return pd;
    }

    private Map<String, Object> validationDetails(MethodArgumentNotValidException ex) {
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("object", ex.getBindingResult().getObjectName());

        List<Map<String, Object>> fieldErrors = new ArrayList<>();
        ex.getBindingResult().getFieldErrors().forEach(fieldError -> {
            Map<String, Object> field = new LinkedHashMap<>();
            field.put("field", fieldError.getField());
            field.put("message", fieldError.getDefaultMessage());
            fieldErrors.add(field);
        });

        List<Map<String, Object>> globalErrors = new ArrayList<>();
        ex.getBindingResult().getGlobalErrors().forEach(globalError -> {
            Map<String, Object> error = new LinkedHashMap<>();
            error.put("object", globalError.getObjectName());
            error.put("message", globalError.getDefaultMessage());
            globalErrors.add(error);
        });

        details.put("fieldErrors", fieldErrors);
        details.put("globalErrors", globalErrors);
        return details;
    }

    private Map<String, Object> constraintDetails(ConstraintViolationException ex) {
        Map<String, Object> details = new LinkedHashMap<>();
        List<Map<String, Object>> violations = new ArrayList<>();

        ex.getConstraintViolations().forEach(violation -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("property", violation.getPropertyPath() != null ? violation.getPropertyPath().toString() : null);
            item.put("message", violation.getMessage());
            violations.add(item);
        });

        details.put("violations", violations);
        return details;
    }

    private Map<String, Object> unexpectedDetails(Exception ex) {
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("message", ex.getMessage());

        Throwable rootCause = ex;
        while (rootCause.getCause() != null && rootCause.getCause() != rootCause) {
            rootCause = rootCause.getCause();
        }

        if (rootCause != ex) {
            details.put("rootCause", rootCause.getMessage());
        }

        return details;
    }

    private Map<String, Object> details(String key, Object value) {
        Map<String, Object> details = new LinkedHashMap<>();
        details.put(key, value);
        return details;
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
        if (header == null || header.isBlank()) {
            return null;
        }

        return header.trim();
    }
}
