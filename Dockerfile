FROM --platform=${TARGETPLATFORM} alpine:latest
LABEL maintainer="V2Fly Community <dev@v2fly.org>"

WORKDIR /tmp
ARG WORKDIR=/tmp
ARG TARGETPLATFORM
ARG TAG
COPY config.json "${WORKDIR}"/config.json 
COPY v2ray.sh "${WORKDIR}"/v2ray.sh

RUN set -ex \
    && apk add --no-cache ca-certificates \
    && mkdir -p /etc/v2ray /usr/local/share/v2ray /var/log/v2ray \
    && ln -sf /dev/stdout /var/log/v2ray/access.log \
    && ln -sf /dev/stderr /var/log/v2ray/error.log \
    && chmod +x "${WORKDIR}"/v2ray.sh \
    && "${WORKDIR}"/v2ray.sh "${TARGETPLATFORM}" "${TAG}"

USER v2rayuser

ENTRYPOINT ["/usr/bin/v2ray"]
