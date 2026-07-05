# syntax=docker/dockerfile:1

FROM alpine:edge

RUN <<EOF
  set -eu

  apk update
  apk upgrade
  apk --no-cache add \
    tini \
    bash \
    openssl \
    stunnel

  # Remove default stunnel config
  rm -rf /etc/stunnel/stunnel.conf

  rm -rf /tmp/* /var/cache/apk/*
EOF

COPY --chmod=755 entrypoint.sh /usr/bin/entrypoint.sh

RUN ln -sf /dev/stdout /var/log/stunnel.log

ENV LISTEN_PORT="853"
ENV CONNECT_PORT="53"
ENV CONNECT_HOST="1.1.1.1"

VOLUME [ "/etc/stunnel" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD /usr/local/bin/healthcheck

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/entrypoint.sh"]
