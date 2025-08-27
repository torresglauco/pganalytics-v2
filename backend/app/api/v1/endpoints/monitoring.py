from fastapi import APIRouter
import random
from datetime import datetime, timedelta

api_router = APIRouter()

@api_router.get("/")
async def api_info():
    """API information endpoint"""
    return {
        "message": "pgAnalytics API v1",
        "version": "2.0.0",
        "docs": "/docs",
        "health": "/health",
        "endpoints": {
            "monitoring": "/api/v1/monitoring/stats",
            "databases": "/api/v1/monitoring/databases",
            "connections": "/api/v1/monitoring/connections",
            "queries": "/api/v1/monitoring/queries",
            "alerts": "/api/v1/alerts"
        }
    }

@api_router.get("/metrics")
async def get_metrics():
    """Prometheus metrics endpoint"""
    return {
        "metrics": {
            "api_version": "2.0.0",
            "status": "running",
            "timestamp": datetime.now().isoformat(),
            "uptime_seconds": random.randint(3600, 86400),
            "requests_total": random.randint(1000, 5000),
            "response_time_avg": round(random.uniform(50, 200), 2)
        }
    }

@api_router.get("/monitoring/stats")
async def get_monitoring_stats():
    """Get current PostgreSQL monitoring statistics"""
    return {
        "database": {
            "connections": random.randint(35, 65),
            "queries_per_second": random.randint(100, 200),
            "active_queries": random.randint(2, 12),
            "avg_query_time": round(random.uniform(25.0, 85.0), 1),
            "locks": random.randint(0, 5),
            "deadlocks": random.randint(0, 2)
        },
        "system": {
            "cpu_usage": round(random.uniform(20.0, 80.0), 1),
            "memory_usage": round(random.uniform(40.0, 85.0), 1),
            "disk_usage": round(random.uniform(60.0, 90.0), 1),
            "load_average": round(random.uniform(0.5, 3.0), 2)
        },
        "alerts": {
            "active": random.randint(0, 5),
            "warning": random.randint(0, 3),
            "critical": random.randint(0, 2)
        },
        "cache": {
            "hit_ratio": round(random.uniform(85.0, 98.0), 1),
            "size_mb": random.randint(512, 2048)
        },
        "timestamp": datetime.now().isoformat()
    }

@api_router.get("/monitoring/databases")
async def get_databases():
    """Get list of monitored databases"""
    databases = [
        {
            "name": "production_db",
            "size": f"{random.uniform(2.0, 5.0):.1f} GB",
            "connections": random.randint(40, 70),
            "status": "healthy",
            "last_backup": (datetime.now() - timedelta(hours=random.randint(1, 24))).isoformat(),
            "tables": random.randint(45, 120),
            "indexes": random.randint(80, 200)
        },
        {
            "name": "staging_db", 
            "size": f"{random.uniform(1.0, 2.5):.1f} GB",
            "connections": random.randint(10, 25),
            "status": "healthy",
            "last_backup": (datetime.now() - timedelta(hours=random.randint(1, 12))).isoformat(),
            "tables": random.randint(30, 80),
            "indexes": random.randint(50, 120)
        },
        {
            "name": "development_db", 
            "size": f"{random.uniform(0.5, 1.5):.1f} GB",
            "connections": random.randint(5, 15),
            "status": random.choice(["healthy", "warning"]),
            "last_backup": (datetime.now() - timedelta(hours=random.randint(6, 48))).isoformat(),
            "tables": random.randint(20, 60),
            "indexes": random.randint(30, 90)
        },
        {
            "name": "analytics_db", 
            "size": f"{random.uniform(3.0, 8.0):.1f} GB",
            "connections": random.randint(15, 35),
            "status": "healthy",
            "last_backup": (datetime.now() - timedelta(hours=random.randint(2, 18))).isoformat(),
            "tables": random.randint(60, 150),
            "indexes": random.randint(100, 250)
        }
    ]
    return {"databases": databases}

@api_router.get("/monitoring/queries")
async def get_slow_queries():
    """Get slow queries information"""
    queries = [
        {
            "id": 1,
            "query": "SELECT u.id, u.username, p.title FROM users u JOIN posts p ON u.id = p.user_id WHERE u.created_at > NOW() - INTERVAL '30 days'",
            "duration": f"{random.uniform(2.0, 8.0):.1f}s",
            "database": "production_db",
            "timestamp": (datetime.now() - timedelta(minutes=random.randint(1, 60))).isoformat(),
            "rows_examined": random.randint(10000, 100000),
            "rows_sent": random.randint(100, 5000)
        },
        {
            "id": 2,
            "query": "UPDATE inventory SET status = 'processed', updated_at = NOW() WHERE batch_id IN (SELECT id FROM batches WHERE created_at < NOW() - INTERVAL '1 hour')",
            "duration": f"{random.uniform(1.5, 5.0):.1f}s", 
            "database": "production_db",
            "timestamp": (datetime.now() - timedelta(minutes=random.randint(5, 120))).isoformat(),
            "rows_examined": random.randint(5000, 50000),
            "rows_sent": random.randint(500, 2000)
        },
        {
            "id": 3,
            "query": "SELECT COUNT(*) as total, DATE(created_at) as date FROM orders WHERE created_at >= '2024-01-01' GROUP BY DATE(created_at) ORDER BY date",
            "duration": f"{random.uniform(1.0, 3.5):.1f}s",
            "database": "analytics_db", 
            "timestamp": (datetime.now() - timedelta(minutes=random.randint(10, 180))).isoformat(),
            "rows_examined": random.randint(15000, 75000),
            "rows_sent": random.randint(50, 500)
        }
    ]
    return {"slow_queries": queries}

@api_router.get("/alerts")
async def get_alerts():
    """Get active and recent alerts"""
    alerts = [
        {
            "id": 1,
            "type": "warning",
            "severity": "medium",
            "message": f"High CPU usage detected ({random.randint(75, 85)}%)",
            "timestamp": (datetime.now() - timedelta(minutes=random.randint(10, 60))).isoformat(),
            "resolved": False,
            "database": "production_db",
            "category": "performance"
        },
        {
            "id": 2,
            "type": "critical",
            "severity": "high", 
            "message": f"Long running query detected (>{random.randint(10, 30)}s)",
            "timestamp": (datetime.now() - timedelta(minutes=random.randint(5, 45))).isoformat(),
            "resolved": False,
            "database": "production_db",
            "category": "query"
        },
        {
            "id": 3,
            "type": "info",
            "severity": "low",
            "message": "Database backup completed successfully",
            "timestamp": (datetime.now() - timedelta(hours=random.randint(1, 12))).isoformat(),
            "resolved": True,
            "database": "production_db",
            "category": "backup"
        },
        {
            "id": 4,
            "type": "warning",
            "severity": "medium",
            "message": f"Memory usage above threshold ({random.randint(80, 90)}%)",
            "timestamp": (datetime.now() - timedelta(minutes=random.randint(30, 120))).isoformat(),
            "resolved": random.choice([True, False]),
            "database": "analytics_db",
            "category": "resource"
        },
        {
            "id": 5,
            "type": "critical",
            "severity": "high",
            "message": "Connection limit approaching (90% of max)",
            "timestamp": (datetime.now() - timedelta(minutes=random.randint(15, 90))).isoformat(),
            "resolved": random.choice([True, False]),
            "database": "production_db",
            "category": "connection"
        }
    ]
    return {"alerts": alerts}

@api_router.get("/monitoring/connections")
async def get_connections():
    """Get database connection information"""
    total_connections = random.randint(45, 80)
    active_connections = random.randint(25, int(total_connections * 0.7))
    idle_connections = total_connections - active_connections
    
    return {
        "total_connections": total_connections,
        "max_connections": 100,
        "active_connections": active_connections,
        "idle_connections": idle_connections,
        "usage_percentage": round((total_connections / 100) * 100, 1),
        "connections_by_database": {
            "production_db": random.randint(20, 40),
            "staging_db": random.randint(8, 18),
            "development_db": random.randint(2, 10),
            "analytics_db": random.randint(10, 25)
        },
        "connections_by_state": {
            "active": active_connections,
            "idle": idle_connections,
            "idle_in_transaction": random.randint(0, 5),
            "waiting": random.randint(0, 3)
        },
        "avg_connection_duration": f"{random.randint(300, 1800)}s",
        "timestamp": datetime.now().isoformat()
    }
