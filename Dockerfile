FROM alpine:3.18

ENV PERCONA_TOOLKIT_VERSION 3.3.1

# hadolint ignore=DL3003
RUN apk add --no-cache perl perl-dbi perl-dbd-mysql perl-io-socket-ssl perl-term-readkey make ca-certificates wget \
    && update-ca-certificates \
    && wget -q -O /tmp/percona-toolkit.tar.gz https://www.percona.com/downloads/percona-toolkit/${PERCONA_TOOLKIT_VERSION}/source/tarball/percona-toolkit-${PERCONA_TOOLKIT_VERSION}.tar.gz \
    && tar -xzvf /tmp/percona-toolkit.tar.gz -C /tmp \
    && cd /tmp/percona-toolkit-${PERCONA_TOOLKIT_VERSION} \
    && perl Makefile.PL \
    && make \
    && make test \
    && make install \
    && apk del make ca-certificates wget \
    && rm -rf /var/cache/apk/* /tmp/percona-toolkit*
