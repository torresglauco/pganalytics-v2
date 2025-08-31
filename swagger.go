package main

import (
    "encoding/json"
    "net/http"
)

// OpenAPI specification
var openAPISpec = map[string]interface{}{
    "openapi": "3.0.3",
    "info": map[string]interface{}{
        "title":       "PG Analytics Backend API",
        "description": "API completa para analytics PostgreSQL",
        "version":     "1.0.0",
        "contact": map[string]interface{}{
            "name":  "PG Analytics Team",
            "email": "admin@pganalytics.com",
        },
    },
    "servers": []map[string]interface{}{
        {
            "url":         "http://localhost:8000",
            "description": "Servidor local de desenvolvimento",
        },
    },
    "paths": map[string]interface{}{
        "/": map[string]interface{}{
            "get": map[string]interface{}{
                "summary":     "Root endpoint",
                "description": "Retorna informações básicas da API",
                "responses": map[string]interface{}{
                    "200": map[string]interface{}{
                        "description": "Informações da API",
                        "content": map[string]interface{}{
                            "application/json": map[string]interface{}{
                                "schema": map[string]interface{}{
                                    "type": "object",
                                    "properties": map[string]interface{}{
                                        "service": map[string]interface{}{"type": "string"},
                                        "version": map[string]interface{}{"type": "string"},
                                        "status":  map[string]interface{}{"type": "string"},
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
        "/api/health": map[string]interface{}{
            "get": map[string]interface{}{
                "summary":     "Health check",
                "description": "Verificação de saúde do backend",
                "responses": map[string]interface{}{
                    "200": map[string]interface{}{
                        "description": "Status de saúde",
                    },
                },
            },
        },
        "/api/metrics": map[string]interface{}{
            "get": map[string]interface{}{
                "summary":     "Sistema metrics",
                "description": "Métricas do sistema backend",
                "responses": map[string]interface{}{
                    "200": map[string]interface{}{
                        "description": "Métricas do sistema",
                    },
                },
            },
        },
        "/api/auth/login": map[string]interface{}{
            "post": map[string]interface{}{
                "summary":     "User login",
                "description": "Autenticação de usuário",
                "requestBody": map[string]interface{}{
                    "required": true,
                    "content": map[string]interface{}{
                        "application/json": map[string]interface{}{
                            "schema": map[string]interface{}{
                                "type": "object",
                                "properties": map[string]interface{}{
                                    "username": map[string]interface{}{"type": "string"},
                                    "password": map[string]interface{}{"type": "string"},
                                },
                                "required": []string{"username", "password"},
                            },
                        },
                    },
                },
                "responses": map[string]interface{}{
                    "200": map[string]interface{}{
                        "description": "Login bem-sucedido",
                    },
                    "401": map[string]interface{}{
                        "description": "Credenciais inválidas",
                    },
                },
            },
        },
    },
}

// Swagger UI HTML
var swaggerUIHTML = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PG Analytics Backend API</title>
    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@3.52.5/swagger-ui.css" />
    <style>
        html { box-sizing: border-box; overflow: -moz-scrollbars-vertical; overflow-y: scroll; }
        *, *:before, *:after { box-sizing: inherit; }
        body { margin:0; background: #fafafa; }
    </style>
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@3.52.5/swagger-ui-bundle.js"></script>
    <script src="https://unpkg.com/swagger-ui-dist@3.52.5/swagger-ui-standalone-preset.js"></script>
    <script>
        window.onload = function() {
            const ui = SwaggerUIBundle({
                url: '/openapi.json',
                dom_id: '#swagger-ui',
                deepLinking: true,
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIStandalonePreset
                ],
                plugins: [
                    SwaggerUIBundle.plugins.DownloadUrl
                ],
                layout: "StandaloneLayout"
            });
        };
    </script>
</body>
</html>
`

// Handler para /swagger
func swaggerHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "text/html; charset=utf-8")
    w.WriteHeader(http.StatusOK)
    w.Write([]byte(swaggerUIHTML))
}

// Handler para /docs (alias)
func docsHandler(w http.ResponseWriter, r *http.Request) {
    swaggerHandler(w, r)
}

// Handler para /openapi.json
func openAPIHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(openAPISpec)
}

// Registrar handlers Swagger
func setupSwaggerRoutes(mux *http.ServeMux) {
    mux.HandleFunc("/swagger", swaggerHandler)
    mux.HandleFunc("/docs", docsHandler)
    mux.HandleFunc("/openapi.json", openAPIHandler)
}
