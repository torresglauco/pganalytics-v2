# Multi-stage build para Go backend otimizado
FROM golang:1.21-alpine AS builder

# Instalar dependências de build
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Copiar arquivos de dependências
COPY go.mod go.sum ./
RUN go mod download

# Copiar código fonte
COPY . .

# Build da aplicação
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Estágio de produção
FROM alpine:latest

# Instalar dependências runtime
RUN apk --no-cache add ca-certificates curl

WORKDIR /root/

# Copiar binário
COPY --from=builder /app/main .

# Expor porta
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8081/health || exit 1

# Comando padrão
CMD ["./main"]
