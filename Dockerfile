# syntax=docker/dockerfile:1

FROM alpine:edge

ARG USER=stunnel

RUN set -eu && \
    apk --no-cache add \
    tini \
    bash \
    openssl \
    stunnel && \
    rm -rf /etc/stunnel/stunnel.conf && \
    rm -rf /tmp/* /var/cache/apk/*

COPY --chmod=755 stunnel.sh /usr/bin/stunnel.sh
RUN ln -sf /dev/stdout /var/log/stunnel.log

ENV TZ="UTC"
ENV PUID="1000"
ENV PGID="1000"
ENV LISTEN_PORT: "853"
ENV CONNECT_PORT: "53"
ENV CONNECT_HOST: "10.0.0.1"
      
VOLUME [ "/etc/stunnel" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD /usr/local/bin/healthcheck

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/stunnel.sh"]
