#!/bin/bash

# PostgreSQL Stop Script
# This script stops and optionally removes the PostgreSQL development container

CONTAINER_NAME="nexus-postgres-dev"
PORT=5432
VOLUME_NAME="nexus-postgres-data"

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
    echo "🛑 Stopping PostgreSQL container..."

    podman stop ${CONTAINER_NAME}

    if [ $? -eq 0 ]; then
        echo "✅ PostgreSQL stopped successfully!"

        # Ask user if they want to remove the container
        echo ""
        read -p "🗑️  Do you want to remove the container? (y/N): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            podman rm ${CONTAINER_NAME}
            if [ $? -eq 0 ]; then
                echo "✅ Container removed successfully!"

                # Ask about volume removal
                echo ""
                echo "💾 Volume Management:"
                echo "⚠️  WARNING: The data volume '${VOLUME_NAME}' contains ALL your Nexus PostgreSQL databases:"
                echo "   📊 Databases: nexus_app_dev, and any other Nexus databases"
                echo "   👤 Credentials: admin/secret"
                echo "   🗄️  All tables, data, and configurations"
                echo ""
                echo "🚨 DANGER: Removing this volume will PERMANENTLY DELETE all data!"
                echo "💡 RECOMMENDED: Answer 'N' to keep your data safe"
                echo ""
                read -p "💾 Remove data volume '${VOLUME_NAME}'? (y/N): " -n 1 -r
                echo

                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    podman volume rm ${VOLUME_NAME}
                    if [ $? -eq 0 ]; then
                        echo "✅ Data volume removed successfully!"
                    else
                        echo "❌ Failed to remove data volume"
                    fi
                else
                    echo "💾 Data volume '${VOLUME_NAME}' preserved"
                    echo "💡 Your data will be available when you restart PostgreSQL"
                fi
            else
                echo "❌ Failed to remove container"
            fi
        else
            echo "📦 Container kept (stopped state)"
            echo "💡 Use './start-postgres.sh' to restart, or 'podman rm ${CONTAINER_NAME}' to remove manually"
        fi
    else
        echo "❌ Failed to stop PostgreSQL container"
        exit 1
    fi

elif podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "⏹️  PostgreSQL container exists but is already stopped"

    # Ask user if they want to remove the stopped container
    echo ""
    read -p "🗑️  Do you want to remove the stopped container? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman rm ${CONTAINER_NAME}
        if [ $? -eq 0 ]; then
            echo "✅ Stopped container removed successfully!"

            # Ask about volume removal
            echo ""
            read -p "💾 Do you want to remove the data volume '${VOLUME_NAME}' as well? (y/N): " -n 1 -r
            echo
            echo "⚠️  WARNING: This will delete ALL PostgreSQL data permanently!"

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                podman volume rm ${VOLUME_NAME}
                if [ $? -eq 0 ]; then
                    echo "✅ Data volume removed successfully!"
                else
                    echo "❌ Failed to remove data volume"
                fi
            else
                echo "💾 Data volume '${VOLUME_NAME}' preserved"
                echo "💡 Your data will be available when you restart PostgreSQL"
            fi
        else
            echo "❌ Failed to remove stopped container"
        fi
    else
        echo "📦 Stopped container kept"
        echo "💡 Use './start-postgres.sh' to restart, or 'podman rm ${CONTAINER_NAME}' to remove manually"
    fi

else
    echo "❌ PostgreSQL container '${CONTAINER_NAME}' not found"
    echo "💡 Nothing to stop. Use './start-postgres.sh' to start PostgreSQL"
fi

echo ""
echo "🛠️  Useful commands:"
echo "   ./start-postgres.sh    - Start PostgreSQL"
echo "   ./stop-pgadmin.sh      - Stop pgAdmin"
echo "   ./dev-status.sh   - Check status"
echo "   podman ps -a           - List all containers"
echo "   podman volume ls       - List all volumes"