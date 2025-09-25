#!/bin/bash

# Keycloak Development Setup Script
# This script starts Keycloak in development mode using Podman
# Port: 8090 (to avoid conflict with Spring Boot on 8080)
# Database: Internal H2 (development mode)
# Runs in background (detached) mode

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

CONTAINER_NAME="${KEYCLOAK_CONTAINER_NAME:-nexus-keycloak-dev}"
PORT="${KEYCLOAK_PORT:-8090}"
IMAGE="quay.io/keycloak/keycloak:latest"
ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-changeme}"

echo "🔍 Checking Keycloak instance status..."

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
                echo "   🗄️  $name (Database) - $status"
            elif [[ $name == *"pgadmin"* ]] || [[ $name == *"admin"* ]]; then
                echo "   🔧 $name (Admin Tool) - $status"
            elif [[ $name == *"keycloak"* ]]; then
                echo "   🔐 $name (Auth Server) - $status"
            else
                echo "   📦 $name (Service) - $status"
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
    echo "✅ Keycloak is already running!"
    echo "📍 Admin Console: http://localhost:${PORT}"
    echo "👤 Admin User: admin"
    echo "🔑 Admin Password: ${ADMIN_PASSWORD}"
    echo ""
    echo "💡 Use './stop-keycloak.sh' to stop the instance"
    echo "📊 Use './dev-status.sh' to check detailed status"
    exit 0
fi

# Check if container exists but is stopped
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "🗑️  Removing stopped Keycloak container..."
    podman rm ${CONTAINER_NAME} >/dev/null 2>&1
fi

echo "🚀 Starting Keycloak in development mode..."
echo "📍 Port: ${PORT}"
echo "🌐 Admin Console: http://localhost:${PORT}"
echo "👤 Admin User: admin"
echo "🔑 Admin Password: ${ADMIN_PASSWORD}"
echo ""

# Start Keycloak in detached mode
podman run -d \
  --name ${CONTAINER_NAME} \
  -p ${PORT}:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=${ADMIN_PASSWORD} \
  ${IMAGE} \
  start-dev

if [ $? -eq 0 ]; then
    echo "✅ Keycloak container started successfully!"
    echo ""
    echo "⏳ Waiting for Keycloak to be ready..."

    # Wait for Keycloak to be ready (check health endpoint)
    COUNTER=0
    MAX_ATTEMPTS=30

    while [ $COUNTER -lt $MAX_ATTEMPTS ]; do
        if curl -s http://localhost:${PORT}/health/ready >/dev/null 2>&1; then
            echo "🎉 Keycloak is ready!"
            echo ""
            echo "🌐 Admin Console: http://localhost:${PORT}"
            echo "👤 Admin User: admin"
            echo "🔑 Admin Password: ${ADMIN_PASSWORD}"
            echo ""
            echo "📋 Next steps:"
            echo "   1. Open http://localhost:${PORT} in your browser"
            echo "   2. Click 'Administration Console'"
            echo "   3. Login with admin/${ADMIN_PASSWORD}"
            echo "   4. Follow realm-configuration.md to set up your application"
            echo ""
            echo "🛠️  Useful commands:"
            echo "   ./stop-keycloak.sh   - Stop Keycloak"
            echo "   ./dev-status.sh - Check status"
            echo "   podman logs ${CONTAINER_NAME} - View logs"
            break
        fi

        echo -n "."
        sleep 2
        COUNTER=$((COUNTER + 1))
    done

    if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
        echo ""
        echo "⚠️  Keycloak is starting but not yet ready. This may take a few more moments."
        echo "🔍 Check status with: ./dev-status.sh"
        echo "📋 View logs with: podman logs ${CONTAINER_NAME}"
    fi

else
    echo "❌ Failed to start Keycloak container!"
    echo "🔍 Check podman status and try again"
    exit 1
fi