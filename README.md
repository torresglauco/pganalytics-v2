# pgAnalytics - Modern PostgreSQL Monitoring

🐘 A modern, real-time PostgreSQL monitoring solution built with FastAPI, React, and Docker.

## ✨ Features

- 🔍 **Real-time PostgreSQL monitoring** - Live database metrics and performance tracking
- 📊 **Interactive dashboards** - Beautiful, responsive Material-UI interface
- 🚨 **Smart alerting system** - Configurable thresholds with Slack integration
- 🐳 **Full Docker containerization** - One-command deployment
- 📱 **Mobile-responsive UI** - Monitor from anywhere
- 📈 **Historical data analysis** - Prometheus + Grafana integration
- 🛠️ **Easy configuration** - Environment-based setup

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- PostgreSQL database to monitor

### Installation (60 seconds)

1. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your PostgreSQL connection details
   ```

2. **Start everything:**
   ```bash
   make start
   # or: docker-compose up -d
   ```

3. **Access your monitoring:**
   - 🌐 **Dashboard:** http://localhost:3000
   - 🔧 **API:** http://localhost:8000  
   - 📖 **API Docs:** http://localhost:8000/docs
   - 📊 **Grafana:** http://localhost:3001 (admin/admin)
   - 📈 **Prometheus:** http://localhost:9090

## 📋 What You'll Monitor

### 📊 Database Metrics
- Active connections and limits
- Query performance and slow queries  
- Database sizes and growth
- Table and index statistics

### 💻 System Metrics
- CPU usage and load
- Memory consumption
- Disk usage and I/O

### 🚨 Smart Alerts
- Configurable thresholds
- Slack notifications
- Alert history and trends

## ⚙️ Configuration

Edit `.env` file:
```env
# Required: Your PostgreSQL database to monitor
DB_HOST=your-postgres-host
DB_PORT=5432
DB_NAME=your-database
DB_USER=your-user
DB_PASSWORD=your-password

# Optional: Slack integration
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_CHANNEL=#monitoring-alerts
```

## 🛠️ Available Commands

```bash
make start      # Start all services
make stop       # Stop all services  
make logs       # View logs
make health     # Check service health
make clean      # Clean up containers
make build      # Build images
```

## 🏗️ Architecture

- **Backend:** FastAPI (Python 3.11+) with async PostgreSQL monitoring
- **Frontend:** React 18 + TypeScript + Material-UI
- **Monitoring:** Prometheus + Grafana stack
- **Caching:** Redis for real-time features
- **Deployment:** Docker Compose orchestration

## 📝 License

MIT License - Feel free to modify and use for your projects!

---

**Happy monitoring!** 🐘📊✨

# Atualização necessária para o README.md

## Adicionar seção de Pré-requisitos:

### Pré-requisitos

- **Docker & Docker Compose** (recomendado)
- **Python 3.11+** (para desenvolvimento local)
- **Node.js 18+** (para desenvolvimento local do frontend)
- **npm** (vem com Node.js)
- **PostgreSQL 12+** (se não usar Docker)

### Instalação Local (sem Docker)

1. **Backend:**
```bash
cd backend
pip install -r requirements.txt
```

2. **Frontend:**
```bash
cd frontend
npm install
```

3. **Executar em desenvolvimento:**
```bash
# Terminal 1 - Backend
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Terminal 2 - Frontend
cd frontend
npm run dev
```

### Instalação com Docker (Recomendado)

```bash
docker-compose up --build
```

### URLs de Acesso

- **Frontend:** http://localhost:3000 (dev) ou http://localhost (docker)
- **Backend API:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs

