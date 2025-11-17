# Multi-stage Dockerfile for Travel Management backend (single clean build)
FROM maven:3.8.8-openjdk-17 AS build
WORKDIR /app

# Copy project files and build
COPY pom.xml mvnw ./
COPY .mvn .mvn
COPY src ./src

# Build the application (skip tests for faster image builds)
RUN mvn -B -DskipTests package

FROM openjdk:17-jdk-slim
WORKDIR /app

# Copy jar built in the builder stage
COPY --from=build /app/target/*.jar travel-backend.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app/travel-backend.jar"]
