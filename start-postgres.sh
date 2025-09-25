#!/bin/bash

# PostgreSQL Development Setup Script
# This script starts PostgreSQL in development mode using Podman
# Port: 5432 (standard PostgreSQL port)
# Database: nexus_app_dev with admin user
# Runs in background (detached) mode

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:-nexus-postgres-dev}"
PORT="${DB_PORT:-5432}"
IMAGE="postgres:16"
DB_USER="${DB_USER:-admin}"
DB_PASSWORD="${DB_PASSWORD:-changeme}"
DB_NAME="${DB_NAME:-nexus_app_dev}"
VOLUME_NAME="${POSTGRES_VOLUME_NAME:-nexus-postgres-data}"

echo "🔍 Checking PostgreSQL instance status..."

# Show current container ecosystem
show_container_overview() {
    echo ""
    echo "🐳 Current Development Environment:"
    echo "=================================="

    RUNNING_CONTAINERS=$(podman ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -v "NAMES")

    if [ -n "$RUNNING_CONTAINERS" ]; then
        echo "✅ Running Containers:"
        echo "$RUNNING_CONTAINERS" | while IFS=$'\t' read -r name image status ports; do
            if [[ $name == *"postgres"* ]] || [[ $name == *"db"* ]]; then
                echo "   🗄️  $name ($image) - $status"
            elif [[ $name == *"pgadmin"* ]] || [[ $name == *"admin"* ]]; then
                echo "   🔧 $name ($image) - $status"
            elif [[ $name == *"keycloak"* ]]; then
                echo "   🔐 $name ($image) - $status"
            else
                echo "   📦 $name ($image) - $status"
            fi
            if [ -n "$ports" ]; then
                echo "      📍 Ports: $ports"
            fi
        done
    else
        echo "❌ No containers currently running"
    fi

    echo ""
}

show_container_overview

# Check if container exists and is running
if podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ PostgreSQL is already running!"
    echo "📍 Database Server: localhost:${PORT}"
    echo "👤 Database User: ${DB_USER}"
    echo "🔑 Database Password: ${DB_PASSWORD}"
    echo "🗄️  Database Name: ${DB_NAME}"
    echo ""
    echo "💡 Use './stop-postgres.sh' to stop the instance"
    echo "📊 Use './dev-status.sh' to check detailed status"
    exit 0
fi

# Check if container exists but is stopped
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "🗑️  Removing stopped PostgreSQL container..."
    podman rm ${CONTAINER_NAME} >/dev/null 2>&1
fi

echo "🚀 Starting PostgreSQL in development mode..."
echo "📍 Port: ${PORT}"
echo "🗄️  Database: ${DB_NAME}"
echo "👤 User: ${DB_USER}"
echo "🔑 Password: ${DB_PASSWORD}"
echo "💾 Volume: ${VOLUME_NAME}"
echo ""

# Create volume if it doesn't exist
if ! podman volume exists ${VOLUME_NAME} 2>/dev/null; then
    echo "📦 Creating PostgreSQL data volume..."
    podman volume create ${VOLUME_NAME}
fi

# Start PostgreSQL in detached mode
podman run -d \
  --name ${CONTAINER_NAME} \
  -e POSTGRES_USER=${DB_USER} \
  -e POSTGRES_PASSWORD=${DB_PASSWORD} \
  -e POSTGRES_DB=${DB_NAME} \
  -v ${VOLUME_NAME}:/var/lib/postgresql/data \
  -p ${PORT}:5432 \
  ${IMAGE}

if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL container started successfully!"
    echo ""
    echo "⏳ Waiting for PostgreSQL to be ready..."

    # Wait for PostgreSQL to be ready
    COUNTER=0
    MAX_ATTEMPTS=30

    while [ $COUNTER -lt $MAX_ATTEMPTS ]; do
        if podman exec ${CONTAINER_NAME} pg_isready -U ${DB_USER} -d ${DB_NAME} >/dev/null 2>&1; then
            echo "🎉 PostgreSQL is ready!"
            echo ""
            echo "🗄️  Database Connection Details:"
            echo "   Host: localhost"
            echo "   Port: ${PORT}"
            echo "   Database: ${DB_NAME}"
            echo "   Username: ${DB_USER}"
            echo "   Password: ${DB_PASSWORD}"
            echo ""
            echo "📋 Connection Examples:"
            echo "   psql: psql -h localhost -p ${PORT} -U ${DB_USER} -d ${DB_NAME}"
            echo "   URL:  postgresql://${DB_USER}:${DB_PASSWORD}@localhost:${PORT}/${DB_NAME}"
            echo ""
            echo "🛠️  Useful commands:"
            echo "   ./stop-postgres.sh         - Stop PostgreSQL"
            echo "   ./start-pgadmin.sh         - Start pgAdmin web interface"
            echo "   ./dev-status.sh       - Check status"
            echo "   podman logs ${CONTAINER_NAME}    - View logs"
            break
        fi

        echo -n "."
        sleep 2
        COUNTER=$((COUNTER + 1))
    done

    if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
        echo ""
        echo "⚠️  PostgreSQL is starting but not yet ready. This may take a few more moments."
        echo "🔍 Check status with: podman logs ${CONTAINER_NAME}"
        echo "🧪 Test connection with: podman exec ${CONTAINER_NAME} pg_isready -U ${DB_USER}"
    fi

else
    echo "❌ Failed to start PostgreSQL container!"
    echo "🔍 Check podman status and try again"
    exit 1
fi