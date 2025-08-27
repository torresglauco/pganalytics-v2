#!/bin/bash
# force_swagger.sh - Força Swagger a funcionar

echo "💪 FORÇANDO SWAGGER A FUNCIONAR"
echo "==============================="

# Criar estrutura docs completa
mkdir -p docs

# docs.go com implementação manual
cat > docs/docs.go << 'EOF'
package docs

import (
	"bytes"
	"encoding/json"
	"strings"
	"text/template"

	"github.com/swaggo/swag"
)

var doc = `{"swagger":"2.0","info":{"description":"Modern PostgreSQL analytics backend","title":"PGAnalytics API","version":"1.0"},"host":"localhost:8080","basePath":"/","paths":{"/health":{"get":{"description":"Get health status","tags":["Health"],"summary":"Check API health","responses":{"200":{"description":"OK"}}}},"/auth/login":{"post":{"description":"Authenticate and get JWT token","consumes":["application/json"],"produces":["application/json"],"tags":["Authentication"],"summary":"User login","responses":{"200":{"description":"OK"},"401":{"description":"Unauthorized"}}}},"/api/metrics":{"post":{"security":[{"BearerAuth":[]}],"description":"Submit performance metrics","consumes":["application/json"],"produces":["application/json"],"tags":["Metrics"],"summary":"Submit metrics","responses":{"200":{"description":"OK"},"401":{"description":"Unauthorized"}}}},"/api/data":{"get":{"security":[{"BearerAuth":[]}],"description":"Get performance analytics","produces":["application/json"],"tags":["Analytics"],"summary":"Get analytics data","responses":{"200":{"description":"OK"},"401":{"description":"Unauthorized"}}}}},"securityDefinitions":{"BearerAuth":{"type":"apiKey","name":"Authorization","in":"header"}}}`

type swaggerInfo struct {
	Version     string
	Host        string
	BasePath    string
	Schemes     []string
	Title       string
	Description string
}

var SwaggerInfo = swaggerInfo{
	Version:     "1.0",
	Host:        "localhost:8080", 
	BasePath:    "/",
	Schemes:     []string{},
	Title:       "PGAnalytics API",
	Description: "Modern PostgreSQL analytics backend",
}

func init() {
	swag.Register("swagger", &s{})
}

type s struct{}

func (s *s) ReadDoc() string {
	sInfo := SwaggerInfo
	sInfo.Description = strings.Replace(sInfo.Description, "
", "\n", -1)

	t, err := template.New("swagger_info").Funcs(template.FuncMap{
		"marshal": func(v interface{}) string {
			a, _ := json.Marshal(v)
			return string(a)
		},
		"escape": func(v interface{}) string {
			return template.HTMLEscapeString(v.(string))
		},
	}).Parse(doc)
	if err != nil {
		return doc
	}

	var tpl bytes.Buffer
	if err := t.Execute(&tpl, sInfo); err != nil {
		return doc
	}

	return tpl.String()
}
EOF

# swagger.json de backup
cat > docs/swagger.json << 'EOF'
{
    "swagger": "2.0",
    "info": {
        "description": "Modern PostgreSQL analytics backend",
        "title": "PGAnalytics API", 
        "version": "1.0"
    },
    "host": "localhost:8080",
    "basePath": "/",
    "schemes": ["http"],
    "securityDefinitions": {
        "BearerAuth": {
            "type": "apiKey",
            "name": "Authorization",
            "in": "header"
        }
    },
    "paths": {
        "/health": {
            "get": {
                "tags": ["Health"],
                "summary": "Check API health",
                "description": "Get health status",
                "responses": {
                    "200": {"description": "OK"}
                }
            }
        },
        "/auth/login": {
            "post": {
                "tags": ["Authentication"],
                "summary": "User login", 
                "description": "Authenticate and get JWT token",
                "consumes": ["application/json"],
                "produces": ["application/json"],
                "responses": {
                    "200": {"description": "OK"},
                    "401": {"description": "Unauthorized"}
                }
            }
        },
        "/api/metrics": {
            "post": {
                "tags": ["Metrics"],
                "summary": "Submit metrics",
                "description": "Submit performance metrics",
                "consumes": ["application/json"],
                "produces": ["application/json"],
                "security": [{"BearerAuth": []}],
                "responses": {
                    "200": {"description": "OK"},
                    "401": {"description": "Unauthorized"}
                }
            }
        },
        "/api/data": {
            "get": {
                "tags": ["Analytics"],
                "summary": "Get analytics data",
                "description": "Get performance analytics",
                "produces": ["application/json"],
                "security": [{"BearerAuth": []}],
                "responses": {
                    "200": {"description": "OK"},
                    "401": {"description": "Unauthorized"}
                }
            }
        }
    }
}
EOF

# Atualizar main.go com import forçado
if ! grep -q "_ "pganalytics-backend/docs"" cmd/server/main.go; then
    cp cmd/server/main.go cmd/server/main.go.bak
    sed '/ginSwagger.*gin-swagger/a\
	_ "pganalytics-backend/docs"' cmd/server/main.go > /tmp/main.go
    mv /tmp/main.go cmd/server/main.go
fi

# Build e restart
go mod tidy
go build -o /tmp/test ./cmd/server && rm /tmp/test
docker-compose restart api

echo "✅ Swagger forçado! Aguarde 10 segundos e teste:"
echo "  http://localhost:8080/swagger/index.html"
