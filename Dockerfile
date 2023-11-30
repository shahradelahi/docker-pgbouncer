FROM alpine:3.18
ARG VERSION=1.21.0

# Update and upgrade packages
RUN apk update && apk upgrade

# Install pgbouncer from source
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    libc-dev \
    libevent-dev \
    libtool \
    make \
    openssl-dev \
    pkgconf \
    readline-dev \
    tar \
    wget \
    zlib-dev \
    && apk add --no-cache \
    bash \
    libevent \
    # Install pgbouncer
    && wget -O - "https://pgbouncer.github.io/downloads/files/${VERSION}/pgbouncer-${VERSION}.tar.gz" | tar xz \
    && cd "pgbouncer-${VERSION}" \
    && ./configure --prefix=/usr --with-udns \
    && make \
    && make install \
    && cp pgbouncer /usr/bin \
    && mkdir -p /etc/pgbouncer /var/log/pgbouncer \
    && touch /etc/pgbouncer/userlist.txt \
    && cd .. \
    # Cleanup
    && rm -rf "pgbouncer-${VERSION}" \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

# Fix permissions
RUN addgroup -S pgbouncer \
    && adduser -S -G pgbouncer pgbouncer \
    && chown -R pgbouncer:pgbouncer /etc/pgbouncer /var/log/pgbouncer

# Add scripts to bin
COPY scripts/* /usr/local/bin/

# Setup entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Setup user
USER pgbouncer

EXPOSE 5432
CMD ["/usr/bin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]

# Build:
#   docker build -t litehex/pgbouncer:1.21.0 .
# Run:
#   docker run --rm -p 6432:5432 -e DB_URL="postgres://postgres:secure-password@localhost:5432/db" litehex/pgbouncer:1.21.0
#   docker run --rm -p 6432:5432 -v ./pgbouncer.ini:/etc/pgbouncer/pgbouncer.ini litehex/pgbouncer:1.21.0

# parse-conn postgres://postgres:secure-password@localhost:5432/db | xargs | IFS=' ' read -r DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD
# echo "${DB_HOST}"
# IFS=' ' read -ra parsed <<< "$(parse-conn postgres://postgres:secure-password@localhost:5432/db)"