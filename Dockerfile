# Multi-stage Dockerfile for Travel Management backend
FROM maven:3.8.8-openjdk-17 AS build
WORKDIR /app

# Copy only what we need to leverage layer caching
COPY pom.xml mvnw ./
COPY .mvn .mvn
COPY src ./src

# Build the application (skip tests for faster build)
RUN mvn -B -DskipTests package

FROM openjdk:17-jdk-slim
WORKDIR /app

# Copy jar built in the builder stage
COPY --from=build /app/target/*.jar travel-backend.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app/travel-backend.jar"]
# ---------- Build stage ----------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml .
# Cache deps to speed up rebuilds
RUN --mount=type=cache,target=/root/.m2 mvn -B -DskipTests dependency:go-offline

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -DskipTests clean install package

# ---------- Run stage ----------
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

ENV JAVA_OPTS=""
EXPOSE 8081
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar app.jar"]
