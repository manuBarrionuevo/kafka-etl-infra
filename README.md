# kafka-etl-infra (Docker Compose)

Repositorio de **infraestructura base** para montar un **núcleo de event-streaming + observabilidad**, pensado como base de un circuito ETL/Integración:  
**Productores (APIs/PLC/Apps) → Kafka → Procesamiento (ksqlDB) / Consumo → Persistencia (DB) + Monitoreo/Alertas**.

Este repo NO es la aplicación final del cliente. Es el **core reutilizable** para que después se conecten:
- APIs (Python/Java/.NET) que publican eventos
- Procesos ETL (NiFi, consumers custom)
- Bases de datos (PostgreSQL / SQL Server / Oracle)
- Dashboards/alertas (Grafana)

---

## Qué incluye este repo (componentes)

### 1) Kafka (Apache Kafka, modo KRaft)
Es el **broker** de eventos (mensajería distribuida).  
Función:
- Recibe eventos (mensajes) desde productores.
- Los guarda en **topics**.
- Los distribuye a consumidores.
- Permite desacoplar sistemas (no se conectan directo entre sí, se conectan al broker).

Notas:
- Está configurado para **single-node** (PoC/lab/demo). Escalable a multi-broker más adelante.
- Expuesto por defecto en `localhost:9092` (configurable por `.env`).

### 2) ksqlDB
Motor de **procesamiento de streams** en tiempo real (SQL sobre Kafka).  
Función típica:
- Transformaciones, filtros, joins.
- Enriquecimiento de eventos.
- Generación de streams/tabla derivadas para consumo o persistencia.

Endpoint:
- UI/API en `http://localhost:8088`

### 3) Kafdrop (UI)
Interfaz web liviana para observar Kafka.  
Función:
- Ver topics, particiones, mensajes, consumidores.
- Útil para debug y validación rápida.

Endpoint:
- `http://localhost:9000`

### 4) Prometheus
Sistema de recolección de métricas.  
Función:
- Scrapea métricas de `kafka_exporter` y `cadvisor`.
- Sirve como base para gráficos/alertas en Grafana.

Endpoint:
- `http://localhost:9090`

### 5) Grafana
Paneles y alertas sobre métricas.  
Función:
- Dashboards (Kafka lag, throughput, CPU/RAM, etc).
- Alertas (ej: lag alto, broker caído, CPU alta).

Endpoint:
- `http://localhost:3000`

### 6) cAdvisor
Métricas de contenedores Docker.  
Función:
- CPU/RAM/FS/Network de cada container.
- Útil para dimensionamiento y troubleshooting.

Endpoint:
- `http://localhost:8080`

### 7) kafka_exporter
Exporter de métricas Kafka para Prometheus.  
Función:
- Expone métricas de brokers/topics/consumers/lag.
- Base para alertas (consumer lag, etc).

Endpoint:
- `http://localhost:9308/metrics`

---

## Para qué sirve (casos de uso)

- **Integración de sistemas**: APIs y servicios publican eventos a Kafka y otros sistemas los consumen sin acoplamiento.
- **ETL near-real-time**: transformar/enriquecer datos con ksqlDB o consumers, y luego persistir en DB.
- **Monitoreo/alertas**: visualizar estado del stack y disparar alertas por lag, caídas o saturación.
- **PoC/Demo**: montar un entorno reproducible para pruebas con clientes (fábrica/ERP/servicios públicos/etc).

---

## Requisitos

- Linux recomendado
- Docker
- Docker Compose v2 (plugin)
  - Verificar: `docker compose version`

---

## Configuración (.env)

Copiar el ejemplo:
```bash
cp .env.example .env

Variables principales:

KAFKA_HOST_PORT (por defecto 9092)

KAFKA_ADVERTISED_HOST (por defecto localhost)

Puertos de UI/monitoring: KAFDROP_PORT, KSQLDB_PORT, PROM_PORT, GRAFANA_PORT, etc.


Deploy (levantar todo)

Opción 1 (recomendada):

./scripts/deploy.sh

Opción 2 (directo):

docker compose up -d

Ver estado:

docker ps

Bajar todo:

docker compose down

Endpoints rápidos

Kafka: localhost:9092

ksqlDB: http://localhost:8088

Kafdrop: http://localhost:9000

Prometheus: http://localhost:9090

Grafana: http://localhost:3000

cAdvisor: http://localhost:8080

Kafka Exporter metrics: http://localhost:9308/metrics
