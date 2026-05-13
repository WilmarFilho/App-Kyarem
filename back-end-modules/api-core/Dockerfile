# syntax=docker/dockerfile:1

# ──────────────────────────────────────────────────────────────
# BUILD STAGE
# ──────────────────────────────────────────────────────────────
FROM gradle:8.10.2-jdk21 AS build
WORKDIR /home/gradle/project

# Copia o projeto multi-módulo inteiro
COPY --chown=gradle:gradle . .

# Builda apenas o módulo api-core
RUN chmod +x ./gradlew && ./gradlew :api-core:bootJar --no-daemon --stacktrace -x test

# ──────────────────────────────────────────────────────────────
# RUNTIME STAGE
# ──────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=build /home/gradle/project/api-core/build/libs/*.jar /app/app.jar

EXPOSE 8080

ENV JAVA_OPTS=""

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
