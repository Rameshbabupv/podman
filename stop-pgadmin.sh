#!/bin/bash

# pgAdmin Stop Script
# This script stops and optionally removes the pgAdmin development container

CONTAINER_NAME="nexus-pgadmin-dev"
PORT=8091

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
    echo "🛑 Stopping pgAdmin container..."

    podman stop ${CONTAINER_NAME}

    if [ $? -eq 0 ]; then
        echo "✅ pgAdmin stopped successfully!"

        # Ask user if they want to remove the container
        echo ""
        read -p "🗑️  Do you want to remove the container? (y/N): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            podman rm ${CONTAINER_NAME}
            if [ $? -eq 0 ]; then
                echo "✅ Container removed successfully!"
                echo "💡 pgAdmin configuration and server connections will be reset on next start"
            else
                echo "❌ Failed to remove container"
            fi
        else
            echo "📦 Container kept (stopped state)"
            echo "💡 Use './start-pgadmin.sh' to restart, or 'podman rm ${CONTAINER_NAME}' to remove manually"
            echo "💾 pgAdmin configuration and server connections are preserved"
        fi
    else
        echo "❌ Failed to stop pgAdmin container"
        exit 1
    fi

elif podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "⏹️  pgAdmin container exists but is already stopped"

    # Ask user if they want to remove the stopped container
    echo ""
    read -p "🗑️  Do you want to remove the stopped container? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman rm ${CONTAINER_NAME}
        if [ $? -eq 0 ]; then
            echo "✅ Stopped container removed successfully!"
            echo "💡 pgAdmin configuration and server connections will be reset on next start"
        else
            echo "❌ Failed to remove stopped container"
        fi
    else
        echo "📦 Stopped container kept"
        echo "💡 Use './start-pgadmin.sh' to restart, or 'podman rm ${CONTAINER_NAME}' to remove manually"
        echo "💾 pgAdmin configuration and server connections are preserved"
    fi

else
    echo "❌ pgAdmin container '${CONTAINER_NAME}' not found"
    echo "💡 Nothing to stop. Use './start-pgadmin.sh' to start pgAdmin"
fi

echo ""
echo "🛠️  Useful commands:"
echo "   ./start-pgadmin.sh     - Start pgAdmin"
echo "   ./stop-postgres.sh     - Stop PostgreSQL"
echo "   ./dev-status.sh   - Check status"
echo "   podman ps -a           - List all containers"