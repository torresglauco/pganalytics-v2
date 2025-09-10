FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Copiar apenas go.mod primeiro
COPY go.mod ./

# Fazer download das dependências (isso criará go.sum)
RUN go mod download

# Copiar resto do código
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o otel-collector .

# Stage final
FROM alpine:3.18
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/otel-collector .

EXPOSE 9188
CMD ["./otel-collector"]
