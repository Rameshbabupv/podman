#!/bin/bash

# Development Environment Management Script
# Manages the complete container ecosystem: PostgreSQL, pgAdmin, Keycloak, etc.

echo "🚀 Development Environment Manager"
echo "================================="
echo ""

# Show current container status
show_environment_overview() {
    echo "🐳 Current Container Status:"
    echo "---------------------------"

    ALL_CONTAINERS=$(podman ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -v "NAMES")

    if [ -n "$ALL_CONTAINERS" ]; then
        echo "$ALL_CONTAINERS" | while IFS=$'\t' read -r name image status ports; do
            # Determine container type and status
            if [[ $status == *"Up"* ]]; then
                STATUS_ICON="✅"
            else
                STATUS_ICON="⏹️ "
            fi

            # Categorize and display containers
            if [[ $name == *"postgres"* ]] || [[ $name == *"db"* ]]; then
                echo "   ${STATUS_ICON} 🗄️  $name (Database)"
            elif [[ $name == *"pgadmin"* ]] || [[ $name == *"admin"* ]]; then
                echo "   ${STATUS_ICON} 🔧 $name (Admin Tool)"
            elif [[ $name == *"keycloak"* ]]; then
                echo "   ${STATUS_ICON} 🔐 $name (Auth Server)"
            elif [[ $name == *"redis"* ]]; then
                echo "   ${STATUS_ICON} 📦 $name (Cache)"
            else
                echo "   ${STATUS_ICON} 📦 $name (Service)"
            fi

            if [ -n "$ports" ] && [[ $status == *"Up"* ]]; then
                echo "      📍 $ports"
            fi
        done

        # Summary
        RUNNING_COUNT=$(echo "$ALL_CONTAINERS" | grep -c "Up")
        TOTAL_COUNT=$(echo "$ALL_CONTAINERS" | wc -l)
        echo ""
        echo "📊 Summary: $RUNNING_COUNT/$TOTAL_COUNT containers running"

    else
        echo "❌ No containers found"
    fi
    echo ""
}

# Container management functions
start_postgres() {
    echo "🗄️  Starting PostgreSQL..."
    ./start-postgres.sh
}

start_pgadmin() {
    echo "🔧 Starting pgAdmin..."
    ./start-pgadmin.sh
}

stop_postgres() {
    echo "🛑 Stopping PostgreSQL..."
    ./stop-postgres.sh
}

stop_pgadmin() {
    echo "🛑 Stopping pgAdmin..."
    ./stop-pgadmin.sh
}

stop_all_dev_containers() {
    echo "🛑 Stopping all development containers..."

    RUNNING_CONTAINERS=$(podman ps --format "{{.Names}}")

    if [ -n "$RUNNING_CONTAINERS" ]; then
        echo "$RUNNING_CONTAINERS" | while read container; do
            echo "   Stopping $container..."
            podman stop "$container"
        done
        echo "✅ All containers stopped"
    else
        echo "❌ No running containers to stop"
    fi
    echo ""
}

cleanup_stopped_containers() {
    echo "🗑️  Cleaning up stopped containers..."

    STOPPED_CONTAINERS=$(podman ps -a --filter "status=exited" --format "{{.Names}}")

    if [ -n "$STOPPED_CONTAINERS" ]; then
        echo "$STOPPED_CONTAINERS" | while read container; do
            echo "   Removing $container..."
            podman rm "$container"
        done
        echo "✅ Stopped containers removed"
    else
        echo "❌ No stopped containers to clean up"
    fi
    echo ""
}

# Main menu
show_environment_overview

echo "🛠️  Development Environment Actions:"
echo "-----------------------------------"
echo ""
echo "📍 Start Services:"
echo "1) 🔐 Start Keycloak (port 8090)"
echo "2) 🗄️  Start PostgreSQL (port 5432)"
echo "3) 🔧 Start pgAdmin (port 8091)"
echo ""
echo "📍 Stop Services:"
echo "4) 🛑 Stop Keycloak"
echo "5) 🛑 Stop PostgreSQL"
echo "6) 🛑 Stop pgAdmin"
echo "7) 🛑 Stop ALL containers"
echo ""
echo "📍 Management:"
echo "8) 📊 Full environment status"
echo "9) 🗑️  Clean up stopped containers"
echo "10) 🌐 Show port usage"
echo "11) 📋 Show container logs menu"
echo "12) 🚪 Exit"
echo ""

read -p "Choose an action (1-12): " choice

case $choice in
    1)
        echo "🔐 Starting Keycloak..."
        ./start-keycloak.sh
        ;;
    2)
        start_postgres
        ;;
    3)
        start_pgadmin
        ;;
    4)
        echo "🛑 Stopping Keycloak..."
        ./stop-keycloak.sh
        ;;
    5)
        stop_postgres
        ;;
    6)
        stop_pgadmin
        ;;
    7)
        read -p "⚠️  Stop ALL containers? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            stop_all_dev_containers
        else
            echo "❌ Operation cancelled"
        fi
        ;;
    8)
        ./dev-status.sh
        ;;
    9)
        read -p "🗑️  Remove all stopped containers? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup_stopped_containers
        else
            echo "❌ Operation cancelled"
        fi
        ;;
    10)
        echo "🌐 Port Usage Overview:"
        echo "----------------------"
        podman ps --format "table {{.Names}}\t{{.Ports}}" | grep -v "NAMES"
        echo ""
        echo "📍 Development Ports:"
        echo "   5432  - PostgreSQL Database"
        echo "   8090  - Keycloak Auth Server"
        echo "   8091  - pgAdmin Web Interface"
        echo "   8080  - Spring Boot Backend"
        echo "   3000  - React Frontend"
        echo "   3001  - React Frontend (alternate)"
        echo ""
        netstat -tulpn | grep LISTEN | grep -E ":(5432|8080|8090|8091|3000|3001)" | while read line; do
            port=$(echo $line | awk '{print $4}' | cut -d':' -f2)
            echo "📍 Port $port: $line"
        done
        ;;
    11)
        echo "📋 Container Logs Menu:"
        echo "----------------------"
        podman ps --format "{{.Names}}" | nl -w2 -s') '
        echo ""
        read -p "Enter container number to view logs: " log_choice
        container_name=$(podman ps --format "{{.Names}}" | sed -n "${log_choice}p")
        if [ -n "$container_name" ]; then
            echo "📋 Showing logs for $container_name (press Ctrl+C to exit):"
            podman logs -f "$container_name"
        else
            echo "❌ Invalid selection"
        fi
        ;;
    12)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        ;;
esac

echo ""
echo "🔄 Environment management complete!"
echo "💡 Run './dev-env.sh' again to manage your containers"