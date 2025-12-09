FROM alpine:latest

RUN apk add --no-cache bash tini curl && \
    curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-27.4.1.tgz | tar xz -C /tmp && \
    mv /tmp/docker/docker /usr/local/bin/ && \
    rm -rf /tmp/docker && \
    apk del curl

ENV NEXTCLOUD_EXEC_USER=www-data
ENV NEXTCLOUD_CONTAINER_NAME=
ENV NEXTCLOUD_PROJECT_NAME=
ENV NEXTCLOUD_CRON_MINUTE_INTERVAL=15
ENV NEXTCLOUD_EXEC_SHELL=bash
ENV NEXTCLOUD_EXEC_SHELL_ARGS=-c

COPY scripts/*.sh /
COPY scripts/cron-scripts-builtin /cron-scripts-builtin

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]

HEALTHCHECK --timeout=5s \
    CMD ["/healthcheck.sh"]
