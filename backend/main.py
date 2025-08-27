from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import asyncio
import uvicorn
import psutil
import time
from datetime import datetime
from typing import Dict, Any

# Criar app FastAPI
app = FastAPI(
    title="pgAnalytics API",
    description="PostgreSQL Monitoring and Analytics API",
    version="1.0.0"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mock data para demonstração
def get_mock_metrics():
    """Gerar métricas mockadas para demonstração"""
    return {
        "timestamp": datetime.now().isoformat(),
        "connections": {
            "active": 45,
            "max": 100,
            "idle": 15,
            "waiting": 2,
            "trend": "stable",
            "status": "healthy"
        },
        "database": {
            "size": 2147483648,  # 2GB in bytes
            "tables": 25,
            "indexes": 48,
            "growth_trend": "up"
        },
        "performance": {
            "queries_per_second": 150,
            "avg_query_time": 0.05,
            "slow_queries": 2,
            "trend": "up",
            "status": "healthy"
        },
        "system": {
            "cpu_percent": psutil.cpu_percent(),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_usage_percent": psutil.disk_usage('/').percent,
            "cpu_trend": "stable",
            "cpu_status": "healthy"
        },
        "locks": {
            "waiting": 0,
            "granted": 45,
            "deadlocks": 0
        },
        "replication": {
            "lag_seconds": 0.1,
            "status": "healthy"
        }
    }

def get_mock_databases():
    """Gerar lista de databases mockada"""
    return [
        {
            "name": "postgres",
            "size": 1073741824,  # 1GB
            "tables": 15,
            "connections": 25,
            "status": "active"
        },
        {
            "name": "analytics",
            "size": 536870912,  # 512MB
            "tables": 8,
            "connections": 12,
            "status": "active"
        },
        {
            "name": "logs",
            "size": 2147483648,  # 2GB
            "tables": 3,
            "connections": 5,
            "status": "idle"
        }
    ]

def get_mock_historical_data():
    """Gerar dados históricos mockados"""
    data = []
    for i in range(20):
        data.append({
            "timestamp": f"10:{i:02d}",
            "connections": 40 + (i % 10),
            "queries_per_second": 120 + (i * 2),
            "cpu_percent": 20 + (i % 15),
            "memory_percent": 45 + (i % 20)
        })
    return data

@app.get("/")
async def root():
    """Endpoint raiz"""
    return {
        "message": "pgAnalytics API is running",
        "version": "1.0.0",
        "status": "healthy"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "pganalytics-backend",
        "timestamp": datetime.now().isoformat(),
        "uptime": "running"
    }

@app.get("/api/v1/monitoring/current")
async def get_current_metrics():
    """Obter métricas atuais"""
    try:
        metrics = get_mock_metrics()
        return metrics
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/monitoring/historical")
async def get_historical_metrics(timeframe: str = "1h"):
    """Obter métricas históricas"""
    try:
        data = get_mock_historical_data()
        return {
            "timeframe": timeframe,
            "data": data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/databases")
async def get_databases():
    """Listar databases"""
    try:
        databases = get_mock_databases()
        return databases
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/databases/{db_name}/metrics")
async def get_database_metrics(db_name: str):
    """Obter métricas de uma database específica"""
    try:
        # Simular métricas específicas de database
        metrics = get_mock_metrics()
        metrics["database"]["name"] = db_name
        return metrics
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/settings")
async def get_settings():
    """Obter configurações"""
    return {
        "database": {
            "host": "postgres_app",
            "port": 5432,
            "database": "postgres",
            "username": "postgres"
        },
        "monitoring": {
            "interval": 30,
            "retention_days": 30,
            "enable_alerts": True
        },
        "slack": {
            "webhook_url": "",
            "channel": "#monitoring",
            "enabled": False
        }
    }

@app.put("/api/v1/settings")
async def update_settings(settings: Dict[str, Any]):
    """Atualizar configurações"""
    return {
        "message": "Settings updated successfully",
        "settings": settings
    }

@app.get("/api/v1/alerts")
async def get_alerts():
    """Obter alertas"""
    return [
        {
            "id": "1",
            "type": "warning",
            "message": "High CPU usage detected",
            "timestamp": datetime.now().isoformat(),
            "acknowledged": False,
            "source": "system_monitor"
        }
    ]

@app.post("/api/v1/alerts/{alert_id}/acknowledge")
async def acknowledge_alert(alert_id: str):
    """Reconhecer alerta"""
    return {
        "message": f"Alert {alert_id} acknowledged",
        "alert_id": alert_id,
        "acknowledged": True
    }

@app.get("/metrics")
async def prometheus_metrics():
    """Endpoint para Prometheus"""
    return "# pgAnalytics metrics\npganalytics_status 1\n"

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
