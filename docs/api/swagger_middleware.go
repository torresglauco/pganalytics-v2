// Middleware universal para Swagger - pode ser usado em qualquer projeto Go
package main

import (
    "encoding/json"
    "net/http"
    "strings"
)

// Universal Swagger middleware
func SwaggerMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Handle Swagger routes
        if strings.HasPrefix(r.URL.Path, "/swagger") || 
           strings.HasPrefix(r.URL.Path, "/docs") ||
           strings.HasPrefix(r.URL.Path, "/openapi.json") {
            
            switch r.URL.Path {
            case "/swagger", "/docs":
                w.Header().Set("Content-Type", "text/html; charset=utf-8")
                w.Write([]byte(getSwaggerHTML()))
                return
            case "/openapi.json":
                w.Header().Set("Content-Type", "application/json")
                json.NewEncoder(w).Encode(getOpenAPISpec())
                return
            }
        }
        
        // Continue to next handler
        next.ServeHTTP(w, r)
    })
}

func getSwaggerHTML() string {
    return `<!DOCTYPE html>
<html><head><title>API Documentation</title>
<link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@3.52.5/swagger-ui.css"/>
</head><body><div id="swagger-ui"></div>
<script src="https://unpkg.com/swagger-ui-dist@3.52.5/swagger-ui-bundle.js"></script>
<script>SwaggerUIBundle({url: '/openapi.json', dom_id: '#swagger-ui', presets: [SwaggerUIBundle.presets.apis]});</script>
</body></html>`
}

func getOpenAPISpec() interface{} {
    return map[string]interface{}{
        "openapi": "3.0.3",
        "info": map[string]interface{}{
            "title": "PG Analytics API",
            "version": "1.0.0",
        },
        "paths": map[string]interface{}{
            "/": map[string]interface{}{
                "get": map[string]interface{}{
                    "summary": "Root endpoint",
                    "responses": map[string]interface{}{
                        "200": map[string]interface{}{"description": "OK"},
                    },
                },
            },
        },
    }
}
