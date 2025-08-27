from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
import os

from app.core.config import settings
from app.api.v1.api import api_router

# Create FastAPI app
app = FastAPI(
    title="pgAnalytics API",
    description="Modern PostgreSQL monitoring API",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/", response_class=HTMLResponse)
async def root():
    """Root endpoint with API information"""
    return '''
    <!DOCTYPE html>
    <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>pgAnalytics API</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .container {
                    background: white;
                    padding: 3rem;
                    border-radius: 20px;
                    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                    max-width: 600px;
                    width: 90%;
                    text-align: center;
                }
                h1 {
                    color: #333;
                    margin-bottom: 1rem;
                    font-size: 2.5rem;
                }
                .subtitle {
                    color: #666;
                    margin-bottom: 2rem;
                    font-size: 1.1rem;
                }
                .links {
                    display: grid;
                    gap: 1rem;
                    margin-top: 2rem;
                }
                .link {
                    display: flex;
                    align-items: center;
                    padding: 1rem 1.5rem;
                    background: #f8f9fa;
                    text-decoration: none;
                    color: #333;
                    border-radius: 12px;
                    transition: all 0.3s ease;
                    border: 2px solid transparent;
                }
                .link:hover {
                    background: #e9ecef;
                    border-color: #667eea;
                    transform: translateY(-2px);
                }
                .icon {
                    font-size: 1.5rem;
                    margin-right: 1rem;
                }
                .version {
                    margin-top: 2rem;
                    color: #999;
                    font-size: 0.9rem;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🐘 pgAnalytics API</h1>
                <p class="subtitle">Modern PostgreSQL monitoring solution</p>
                
                <div class="links">
                    <a href="/docs" class="link">
                        <span class="icon">📖</span>
                        <div>
                            <strong>API Documentation</strong><br>
                            <small>Interactive Swagger UI</small>
                        </div>
                    </a>
                    <a href="/redoc" class="link">
                        <span class="icon">📋</span>
                        <div>
                            <strong>ReDoc Documentation</strong><br>
                            <small>Alternative API docs</small>
                        </div>
                    </a>
                    <a href="/health" class="link">
                        <span class="icon">❤️</span>
                        <div>
                            <strong>Health Check</strong><br>
                            <small>Service status</small>
                        </div>
                    </a>
                    <a href="/api/v1/monitoring/stats" class="link">
                        <span class="icon">📊</span>
                        <div>
                            <strong>Live Metrics</strong><br>
                            <small>Real-time monitoring data</small>
                        </div>
                    </a>
                </div>
                
                <div class="version">
                    Version 2.0.0 • Environment: ''' + settings.ENVIRONMENT + '''
                </div>
            </div>
        </body>
    </html>
    '''

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "pgAnalytics API",
        "version": "2.0.0",
        "environment": settings.ENVIRONMENT,
        "debug": settings.DEBUG
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True if settings.ENVIRONMENT == "development" else False
    )
