package com.nkw.backapisumula.shared.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

@Documented
@Constraint(validatedBy = JsonObjectValidator.class)
@Target({ ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT })
@Retention(RetentionPolicy.RUNTIME)
public @interface JsonObject {

    String message() default "regrasJson deve ser um objeto JSON (ex: { \"chave\": \"valor\" })";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

    /**
     * Se true, permite null (para updates parciais). Se false, null é inválido.
     */
    boolean allowNull() default false;
}
