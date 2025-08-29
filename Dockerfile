FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copiar go.mod e go.sum
COPY go.mod go.sum ./
RUN go mod download

# Copiar código fonte
COPY . .

# Build da aplicação (estruturada)
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/server

# Stage final
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

# Copiar binário
COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
