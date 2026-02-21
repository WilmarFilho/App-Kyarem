# syntax=docker/dockerfile:1

# -------- BUILD STAGE --------
FROM gradle:8.10.2-jdk21 AS build
WORKDIR /home/gradle/src

# Copiamos o projeto (evita baixar dependências toda hora se você usar cache de camadas)
COPY --chown=gradle:gradle . .

# Gera o bootJar (aplicação Spring Boot)
RUN gradle bootJar --no-daemon

# -------- RUNTIME STAGE --------
FROM eclipse-temurin:21-jre
WORKDIR /app

# Copia o jar gerado
COPY --from=build /home/gradle/src/build/libs/*.jar /app/app.jar

# Porta padrão (APP_PORT pode sobrescrever em runtime via env)
EXPOSE 8080

# Permite passar flags de JVM no docker-compose (JAVA_OPTS)
ENV JAVA_OPTS=""

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
