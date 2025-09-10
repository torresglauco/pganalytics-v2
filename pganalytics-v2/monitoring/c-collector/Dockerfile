FROM alpine:3.18
RUN apk add --no-cache gcc musl-dev postgresql-dev curl
WORKDIR /app
COPY . .
RUN gcc -Wall -std=c99 -O2 -I/usr/include/postgresql -o collector main.c -lpq -lpthread
RUN adduser -D collector && chown collector:collector /app/collector
USER collector
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8080/health || exit 1
CMD ["./collector"]