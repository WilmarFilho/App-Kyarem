# syntax=docker/dockerfile:1

FROM gradle:8.10.2-jdk21 AS build
WORKDIR /home/gradle/project
COPY --chown=gradle:gradle . .
RUN gradle :projection-worker:bootJar --no-daemon -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /home/gradle/project/projection-worker/build/libs/*.jar /app/app.jar
EXPOSE 8086
ENV JAVA_OPTS=""
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
