package com.nkw.backapisumula.shared.validation;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class JsonObjectValidator implements ConstraintValidator<JsonObject, JsonNode> {

    private boolean allowNull;

    @Override
    public void initialize(JsonObject constraintAnnotation) {
        this.allowNull = constraintAnnotation.allowNull();
    }

    @Override
    public boolean isValid(JsonNode value, ConstraintValidatorContext context) {
        if (value == null) {
            return allowNull;
        }
        // Aceita apenas objeto JSON { ... }
        return value.isObject();
    }
}
