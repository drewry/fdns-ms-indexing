# build stage
FROM maven:3.5.3-jdk-8 as builder

ARG OBJECT_URL
ARG INDEXING_PORT
ARG INDEXING_ELASTIC_HOST
ARG INDEXING_ELASTIC_PORT
ARG INDEXING_ELASTIC_PROTOCOL

ENV OBJECT_URL ${OBJECT_URL}
ENV INDEXING_PORT ${INDEXING_PORT}
ENV INDEXING_ELASTIC_HOST ${INDEXING_ELASTIC_HOST}
ENV INDEXING_ELASTIC_PORT ${INDEXING_ELASTIC_PORT}
ENV INDEXING_ELASTIC_PROTOCOL ${INDEXING_ELASTIC_PROTOCOL}

RUN mkdir -p /usr/src/app
COPY pom.xml /usr/src/app
WORKDIR /usr/src/app
RUN mvn dependency:resolve
COPY . /usr/src/app
RUN mvn clean package

# run stage
FROM openjdk:8-jre-alpine

ARG INDEXING_PORT
ARG INDEXING_ELASTIC_HOST
ARG INDEXING_ELASTIC_PORT
ARG INDEXING_ELASTIC_PROTOCOL
ARG OBJECT_URL
ARG INDEXING_FLUENTD_HOST
ARG INDEXING_FLUENTD_PORT
ARG INDEXING_PROXY_HOSTNAME
ARG OAUTH2_ACCESS_TOKEN_URI
ARG OAUTH2_PROTECTED_URIS
ARG OAUTH2_CLIENT_ID
ARG OAUTH2_CLIENT_SECRET
ARG SSL_VERIFYING_DISABLE

ENV INDEXING_PORT ${INDEXING_PORT}
ENV INDEXING_ELASTIC_HOST ${INDEXING_ELASTIC_HOST}
ENV INDEXING_ELASTIC_PORT ${INDEXING_ELASTIC_PORT}
ENV INDEXING_ELASTIC_PROTOCOL ${INDEXING_ELASTIC_PROTOCOL}
ENV OBJECT_URL ${OBJECT_URL}
ENV INDEXING_FLUENTD_HOST ${INDEXING_FLUENTD_HOST}
ENV INDEXING_FLUENTD_PORT ${INDEXING_FLUENTD_PORT}
ENV INDEXING_PROXY_HOSTNAME ${INDEXING_PROXY_HOSTNAME}
ENV OAUTH2_ACCESS_TOKEN_URI ${OAUTH2_ACCESS_TOKEN_URI}
ENV OAUTH2_PROTECTED_URIS ${OAUTH2_PROTECTED_URIS}
ENV OAUTH2_CLIENT_ID ${OAUTH2_CLIENT_ID}
ENV OAUTH2_CLIENT_SECRET ${OAUTH2_CLIENT_SECRET}
ENV SSL_VERIFYING_DISABLE ${SSL_VERIFYING_DISABLE}

COPY --from=builder /usr/src/app/target/fdns-ms-indexing-*.jar /app.jar

# pull latest
RUN apk update && apk upgrade --no-cache

# don't run as root user
RUN chown 1001:0 /app.jar
RUN chmod g+rwx /app.jar
USER 1001

ENTRYPOINT java -Dserver.tomcat.protocol-header=x-forwarded-proto -Dserver.tomcat.remote-ip-header=x-forwarded-for -jar /app.jar