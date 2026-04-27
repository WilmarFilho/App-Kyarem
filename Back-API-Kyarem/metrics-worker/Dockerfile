# syntax=docker/dockerfile:1

FROM gradle:8.10.2-jdk21 AS build
WORKDIR /home/gradle/project
COPY --chown=gradle:gradle . .
RUN chmod +x ./gradlew && ./gradlew :metrics-worker:bootJar --no-daemon --stacktrace -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /home/gradle/project/metrics-worker/build/libs/*.jar /app/app.jar
EXPOSE 8087
ENV JAVA_OPTS=""
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
