package docs

import "github.com/swaggo/swag"

const docTemplate = `{
    "swagger": "2.0",
    "info": {
        "description": "PostgreSQL Analytics API",
        "title": "PG Analytics API",
        "contact": {},
        "version": "1.0"
    },
    "host": "localhost:8080",
    "basePath": "/api/v1",
    "paths": {
        "/health": {
            "get": {
                "description": "Health check endpoint",
                "produces": ["application/json"],
                "tags": ["health"],
                "summary": "Health check",
                "responses": {
                    "200": {
                        "description": "OK",
                        "schema": {
                            "type": "object",
                            "properties": {
                                "status": {
                                    "type": "string"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}`

var SwaggerInfo = &swag.Spec{
    Version:          "1.0",
    Host:             "localhost:8080",
    BasePath:         "/api/v1",
    Schemes:          []string{},
    Title:            "PG Analytics API",
    Description:      "PostgreSQL Analytics API",
    InfoInstanceName: "swagger",
    SwaggerTemplate:  docTemplate,
}

func init() {
    swag.Register(SwaggerInfo.InstanceName(), SwaggerInfo)
}
