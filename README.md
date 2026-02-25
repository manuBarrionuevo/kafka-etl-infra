# kafka-etl-infra (Docker Compose)

Infraestructura base para ETL/event-streaming:
- Kafka
- ksqlDB
- Kafdrop (UI)
- Prometheus + Grafana + cAdvisor + kafka_exporter

## Requisitos
- Docker + Docker Compose v2 (`docker compose version`)

## Deploy
```bash
cp .env.example .env
./scripts/deploy.sh
