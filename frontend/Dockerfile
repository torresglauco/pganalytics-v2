# Use uma versão específica do Node.js
FROM node:18-alpine AS builder

# Instalar dependências necessárias para esbuild
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copiar arquivos de dependências primeiro (para cache do Docker)
COPY package.json package-lock.json* ./

# Limpar cache do npm e instalar dependências
RUN npm ci --prefer-offline --no-audit

# Copiar código fonte
COPY . .

# Build da aplicação
RUN npm run build

# Estágio de produção com nginx
FROM nginx:alpine

# Copiar arquivos buildados
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuração do nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Expor porta
EXPOSE 80

# Comando para iniciar nginx
CMD ["nginx", "-g", "daemon off;"]

