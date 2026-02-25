#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f .env ]; then
  echo "[INFO] No existe .env, copiando desde .env.example"
  cp .env.example .env
fi

echo "[INFO] Verificando Docker..."
command -v docker >/dev/null 2>&1 || { echo "Docker no está instalado"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "Docker Compose v2 no disponible (docker compose)"; exit 1; }

# Cargar variables .env
set -a
# shellcheck disable=SC1091
source .env
set +a

NET_NAME="${DOCKER_NET_NAME:-etl-net}"

echo "[INFO] Creando red si no existe: ${NET_NAME}"
docker network inspect "${NET_NAME}" >/dev/null 2>&1 || docker network create "${NET_NAME}"

echo "[INFO] Levantando stack (core + etl + ui + monitoring)..."
# Profiles: core siempre (no es profile), y activamos los demás:
docker compose --profile etl --profile ui --profile monitoring up -d

echo "[INFO] Esperando servicios..."
# Kafka healthcheck ya está, esperamos que esté healthy
for i in {1..60}; do
  status="$(docker inspect -f '{{.State.Health.Status}}' "$(docker compose ps -q kafka)" 2>/dev/null || true)"
  if [ "$status" = "healthy" ]; then
    echo "[OK] Kafka healthy"
    break
  fi
  sleep 2
  if [ "$i" -eq 60 ]; then
    echo "[ERROR] Kafka no llegó a healthy. Logs:"
    docker compose logs --no-color --tail=200 kafka
    exit 1
  fi
done

# Chequeos HTTP básicos
curl -fsS "http://localhost:${PROM_PORT:-9090}/-/ready" >/dev/null && echo "[OK] Prometheus ready"
curl -fsS "http://localhost:${GRAFANA_PORT:-3000}/login" >/dev/null && echo "[OK] Grafana up"
curl -fsS "http://localhost:${KSQLDB_PORT:-8088}/info" >/dev/null && echo "[OK] ksqlDB up"
curl -fsS "http://localhost:${KAFDROP_PORT:-9000}" >/dev/null && echo "[OK] Kafdrop up"

echo
echo "[DONE] URLs:"
echo "  Kafka (host):        ${KAFKA_ADVERTISED_HOST:-localhost}:${KAFKA_HOST_PORT:-9092}"
echo "  Kafdrop:             http://localhost:${KAFDROP_PORT:-9000}"
echo "  ksqlDB:              http://localhost:${KSQLDB_PORT:-8088}"
echo "  Prometheus:          http://localhost:${PROM_PORT:-9090}"
echo "  Grafana:             http://localhost:${GRAFANA_PORT:-3000} (admin/admin al primer login)"
echo
echo "[TIP] Ver estado: ./scripts/status.sh"
