module pganalytics-otel-collector

go 1.21

require (
    github.com/lib/pq v1.10.9
    go.opentelemetry.io/otel v1.21.0
    go.opentelemetry.io/otel/exporters/prometheus v0.44.0
    go.opentelemetry.io/otel/metric v1.21.0
    go.opentelemetry.io/otel/sdk/metric v1.21.0
    github.com/prometheus/client_golang v1.17.0
)
