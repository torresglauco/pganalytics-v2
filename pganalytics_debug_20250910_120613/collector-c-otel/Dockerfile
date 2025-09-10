FROM alpine:3.18

# Instalar dependências incluindo cURL para OTLP
RUN apk add --no-cache \
    gcc \
    musl-dev \
    postgresql-dev \
    postgresql-client \
    libpq \
    curl-dev \
    json-c-dev \
    make \
    pkgconfig \
    linux-headers

WORKDIR /app
COPY . .

# Compilar com todas as dependências
RUN gcc -Wall -Wextra -std=c99 -O2 \
    -I/usr/include/postgresql \
    -I/usr/include/json-c \
    -I/usr/include/curl \
    -o pg_c_otel_collector \
    main.c \
    -lpq -ljson-c -lcurl

EXPOSE 8080

# Health check básico
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD pgrep pg_c_otel_collector || exit 1

CMD ["./pg_c_otel_collector"]
