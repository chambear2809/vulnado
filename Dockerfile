FROM maven:3.8.8-eclipse-temurin-11

RUN apt-get update && \
    apt-get install --no-install-recommends build-essential cowsay netcat-openbsd -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY . .
RUN mvn -B -DskipTests package

EXPOSE 8080

CMD ["java", "-jar", "target/vulnado-0.0.1-SNAPSHOT.jar"]
