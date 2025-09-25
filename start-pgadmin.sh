#!/bin/bash

# pgAdmin Development Setup Script
# This script starts pgAdmin in development mode using Podman
# Port: 8091 (to avoid conflict with Spring Boot on 8080 and other services)
# Web Interface: http://localhost:8091
# Runs in background (detached) mode

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

CONTAINER_NAME="${PGADMIN_CONTAINER_NAME:-nexus-pgadmin-dev}"
PORT="${PGADMIN_PORT:-8091}"
IMAGE="dpage/pgadmin4:latest"
ADMIN_EMAIL="${PGADMIN_EMAIL:-admin@systech.com}"
ADMIN_PASSWORD="${PGADMIN_PASSWORD:-changeme}"

echo "🔍 Checking pgAdmin instance status..."

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
    echo "✅ pgAdmin is already running!"
    echo "🌐 Web Interface: http://localhost:${PORT}"
    echo "📧 Email: ${ADMIN_EMAIL}"
    echo "🔑 Password: ${ADMIN_PASSWORD}"
    echo ""
    echo "💡 Use './stop-pgadmin.sh' to stop the instance"
    echo "📊 Use './dev-status.sh' to check detailed status"
    exit 0
fi

# Check if container exists but is stopped
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "🗑️  Removing stopped pgAdmin container..."
    podman rm ${CONTAINER_NAME} >/dev/null 2>&1
fi

echo "🚀 Starting pgAdmin in development mode..."
echo "📍 Port: ${PORT}"
echo "🌐 Web Interface: http://localhost:${PORT}"
echo "📧 Email: ${ADMIN_EMAIL}"
echo "🔑 Password: ${ADMIN_PASSWORD}"
echo ""

# Start pgAdmin in detached mode
podman run -d \
  --name ${CONTAINER_NAME} \
  -e PGADMIN_DEFAULT_EMAIL=${ADMIN_EMAIL} \
  -e PGADMIN_DEFAULT_PASSWORD=${ADMIN_PASSWORD} \
  -p ${PORT}:80 \
  ${IMAGE}

if [ $? -eq 0 ]; then
    echo "✅ pgAdmin container started successfully!"
    echo ""
    echo "⏳ Waiting for pgAdmin to be ready..."

    # Wait for pgAdmin to be ready
    COUNTER=0
    MAX_ATTEMPTS=30

    while [ $COUNTER -lt $MAX_ATTEMPTS ]; do
        if curl -s http://localhost:${PORT}/misc/ping >/dev/null 2>&1; then
            echo "🎉 pgAdmin is ready!"
            echo ""
            echo "🌐 Web Interface Access:"
            echo "   URL: http://localhost:${PORT}"
            echo "   Email: ${ADMIN_EMAIL}"
            echo "   Password: ${ADMIN_PASSWORD}"
            echo ""
            echo "🗄️  PostgreSQL Connection Setup (if PostgreSQL is running):"
            echo "   1. Open http://localhost:${PORT} in your browser"
            echo "   2. Login with the credentials above"
            echo "   3. Right-click 'Servers' → Create → Server"
            echo "   4. General tab: Name = 'Nexus PostgreSQL'"
            echo "   5. Connection tab:"
            echo "      Host name/address: host.containers.internal"
            echo "      Port: 5432"
            echo "      Username: admin"
            echo "      Password: secret"
            echo "      Maintenance database: nexus_app_dev"
            echo ""
            echo "🛠️  Useful commands:"
            echo "   ./stop-pgadmin.sh          - Stop pgAdmin"
            echo "   ./start-postgres.sh        - Start PostgreSQL database"
            echo "   ./dev-status.sh       - Check status"
            echo "   podman logs ${CONTAINER_NAME}     - View logs"
            break
        fi

        echo -n "."
        sleep 2
        COUNTER=$((COUNTER + 1))
    done

    if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
        echo ""
        echo "⚠️  pgAdmin is starting but not yet ready. This may take a few more moments."
        echo "🔍 Check status with: podman logs ${CONTAINER_NAME}"
        echo "🧪 Test access with: curl http://localhost:${PORT}/misc/ping"
    fi

else
    echo "❌ Failed to start pgAdmin container!"
    echo "🔍 Check podman status and try again"
    exit 1
fi