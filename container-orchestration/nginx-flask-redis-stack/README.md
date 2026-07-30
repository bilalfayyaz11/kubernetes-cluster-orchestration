# Nginx, Flask, and Redis Container Stack

## What This Does

This implementation provides a complete three-tier containerized application using Nginx, Flask, Gunicorn, Redis, and Docker Compose.

The frontend is served by Nginx and communicates with the backend through a reverse proxy. The backend exposes REST API endpoints for incrementing a visit counter and storing or retrieving messages. Redis provides persistent application state across container restarts.

The stack includes container health checks, service dependency management, isolated networking, persistent storage, non-root backend execution, and end-to-end verification.

## Architecture

    User or API Client
            |
            | HTTP :8080
            v
       Nginx Frontend
            |
            | Reverse proxy /api/
            v
    Flask and Gunicorn Backend
            |
            | Redis protocol :6379
            v
          Redis
            |
            v
     Persistent Docker Volume

## Components

### Nginx Frontend

Nginx serves the browser interface and forwards all `/api/` requests to the backend service using Docker Compose service discovery.

### Flask Backend

The backend provides the following endpoints:

    GET  /api/health
    GET  /api/visits
    POST /api/message
    GET  /api/message

Gunicorn runs the Flask application with multiple worker processes.

### Redis

Redis stores:

    visits
    message

Append-only persistence is enabled, and Redis data is stored in a named Docker volume.

## Repository Structure

    nginx-flask-redis-stack/
    ├── backend/
    │   ├── app.py
    │   ├── Dockerfile
    │   └── requirements.txt
    ├── frontend/
    │   ├── Dockerfile
    │   ├── index.html
    │   └── nginx.conf
    ├── compose.yaml
    └── README.md

## Prerequisites

The following tools are required:

    Docker Engine
    Docker Compose plugin
    curl
    Git

Verify Docker and Compose:

    docker --version
    docker compose version
    docker info

## Build the Stack

Move into the implementation directory:

    cd container-orchestration/nginx-flask-redis-stack

Validate the Compose configuration:

    docker compose config

Build the application images:

    docker compose build

## Start the Services

Start the complete stack:

    docker compose up -d

Wait for the health checks, then inspect the services:

    docker compose ps

Expected services:

    redis      running and healthy
    backend    running and healthy
    frontend   running on port 8080

## Test the Frontend

Verify that Nginx serves the interface:

    curl -fsS http://127.0.0.1:8080/

The application is available at:

    http://localhost:8080

## Test Backend Health Through Nginx

    curl -fsS http://127.0.0.1:8080/api/health

Expected response:

    {
      "redis": "connected",
      "status": "healthy"
    }

## Test the Visit Counter

Run the request twice:

    curl -fsS http://127.0.0.1:8080/api/visits
    curl -fsS http://127.0.0.1:8080/api/visits

Expected progression:

    {"visits":1}
    {"visits":2}

## Store a Message

    curl -fsS -X POST http://127.0.0.1:8080/api/message \
      -H "Content-Type: application/json" \
      -d '{"message":"Hello from the container stack"}'

Expected response:

    {
      "message": "Hello from the container stack",
      "status": "saved"
    }

## Retrieve the Message

    curl -fsS http://127.0.0.1:8080/api/message

Expected response:

    {
      "message": "Hello from the container stack"
    }

## Verify Redis Data

Inspect the stored values directly:

    docker compose exec -T redis redis-cli GET visits
    docker compose exec -T redis redis-cli GET message

Expected output:

    2
    Hello from the container stack

## Verify Service Discovery

Resolve service names from the backend container:

    docker compose exec -T backend python -c \
    'import socket; print("redis:", socket.gethostbyname("redis")); print("backend:", socket.gethostbyname("backend"))'

This confirms that Docker Compose DNS allows services to communicate by service name instead of fixed IP addresses.

## Health Checks

Redis is checked with:

    redis-cli ping

The backend is checked through:

    http://127.0.0.1:5000/api/health

The backend does not start until Redis reports healthy, and the frontend does not start until the backend reports healthy.

## Persistent Storage

Redis uses the named volume:

    redis-data

Inspect the volume:

    docker volume ls
    docker volume inspect nginx-flask-redis-stack_redis-data

Data remains available when containers are recreated unless the volume is explicitly removed.

## View Runtime Logs

View all service logs:

    docker compose logs

Follow logs continuously:

    docker compose logs -f

View one service:

    docker compose logs backend
    docker compose logs frontend
    docker compose logs redis

## Restart the Stack

    docker compose restart

Verify service health:

    docker compose ps

## Stop the Stack

Stop and remove the containers and network:

    docker compose down

Stop the stack and remove persistent data:

    docker compose down -v

## Troubleshooting

### Docker Socket Permission Denied

Add the current user to the Docker group:

    sudo usermod -aG docker "$USER"

Start a shell with Docker group access:

    newgrp docker

Verify access:

    docker info

### Port 8080 Is Already in Use

Identify the process using the port:

    sudo ss -lntp | grep ':8080'

Stop the conflicting process or change the frontend port mapping in `compose.yaml`.

### Backend Is Unhealthy

Inspect backend logs:

    docker compose logs backend

Check Redis status:

    docker compose ps redis

Verify the Redis hostname:

    docker compose exec -T backend env | grep REDIS_HOST

### Frontend Cannot Reach the Backend

Validate the Nginx configuration:

    docker compose exec -T frontend nginx -t

Resolve the backend service name:

    docker compose exec -T frontend getent hosts backend

Inspect frontend logs:

    docker compose logs frontend

### Redis Data Is Missing

Check the active volumes:

    docker volume ls

Inspect the Redis volume:

    docker volume inspect nginx-flask-redis-stack_redis-data

Ensure the stack was not removed with:

    docker compose down -v

## Security and Reliability Improvements

This implementation includes:

- A non-root backend user
- Production Gunicorn execution
- No direct host exposure for Redis
- No direct host exposure for the backend
- Nginx reverse proxying
- Health-aware startup dependencies
- Persistent Redis storage
- Isolated bridge networking
- Automatic container restart policies

## Skills Demonstrated

- Multi-container application architecture
- Dockerfile creation
- Docker Compose orchestration
- Container networking and DNS
- Nginx reverse proxy configuration
- Flask REST API development
- Gunicorn application serving
- Redis integration
- Persistent Docker volumes
- Health checks
- Startup dependency management
- Linux permission troubleshooting
- End-to-end service verification

## Real-World Use Case

This architecture reflects the foundation of many internal platforms, web services, microservice systems, AI inference APIs, MLOps control planes, and cloud-native applications.

Separating the frontend, backend, and state layer allows each component to be independently built, deployed, monitored, scaled, and replaced.

## Lessons Learned

- Containers communicate reliably through service names on shared networks.
- Health checks provide stronger dependency control than simple startup ordering.
- Nginx can expose one public entry point while keeping internal services private.
- Persistent volumes separate application data from container lifecycles.
- Production application servers such as Gunicorn should replace Flask's development server.
- Fixed container names should be avoided because they restrict horizontal scaling.
- Application configuration should be supplied through environment variables.
- End-to-end verification must test both API behavior and underlying stored data.
