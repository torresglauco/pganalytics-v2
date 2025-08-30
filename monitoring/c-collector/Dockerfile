FROM alpine:3.18

RUN apk add --no-cache \
    gcc \
    musl-dev \
    postgresql-dev \
    libmicrohttpd-dev \
    make \
    pkgconfig

WORKDIR /app
COPY . .
RUN make clean && make

EXPOSE 9188
CMD ["./pg_metrics_collector"]
