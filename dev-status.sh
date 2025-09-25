#!/bin/bash

# Development Environment Status Script
# This script provides comprehensive status information about all containers and images

echo "📊 Complete Development Environment Status"
echo "========================================="
echo ""

# Show complete container ecosystem
show_development_environment() {
    echo "🐳 Container Ecosystem Overview:"
    echo "-------------------------------"

    ALL_CONTAINERS=$(podman ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -v "NAMES")

    if [ -n "$ALL_CONTAINERS" ]; then
        echo ""
        echo "📦 All Containers (Running + Stopped):"

        echo "$ALL_CONTAINERS" | while IFS=$'\t' read -r name image status ports; do
            # Determine container type and status
            if [[ $status == *"Up"* ]]; then
                STATUS_ICON="✅"
            else
                STATUS_ICON="⏹️ "
            fi

            # Categorize containers
            if [[ $name == *"postgres"* ]] || [[ $name == *"db"* ]]; then
                echo "   ${STATUS_ICON} 🗄️  $name"
                echo "      📋 Database: $(echo $image | cut -d':' -f1)"
                echo "      🔄 Status: $status"
                if [ -n "$ports" ] && [[ $status == *"Up"* ]]; then
                    echo "      📍 Ports: $ports"
                fi
            elif [[ $name == *"pgadmin"* ]] || [[ $name == *"admin"* ]]; then
                echo "   ${STATUS_ICON} 🔧 $name"
                echo "      📋 Admin Tool: $(echo $image | cut -d':' -f1)"
                echo "      🔄 Status: $status"
                if [ -n "$ports" ] && [[ $status == *"Up"* ]]; then
                    echo "      📍 Ports: $ports"
                fi
            elif [[ $name == *"keycloak"* ]]; then
                echo "   ${STATUS_ICON} 🔐 $name"
                echo "      📋 Auth Server: $(echo $image | cut -d':' -f1)"
                echo "      🔄 Status: $status"
                if [ -n "$ports" ] && [[ $status == *"Up"* ]]; then
                    echo "      📍 Ports: $ports"
                fi
            elif [[ $name == *"redis"* ]]; then
                echo "   ${STATUS_ICON} 📦 $name"
                echo "      📋 Cache: $(echo $image | cut -d':' -f1)"
                echo "      🔄 Status: $status"
                if [ -n "$ports" ] && [[ $status == *"Up"* ]]; then
                    echo "      📍 Ports: $ports"
                fi
            else
                echo "   ${STATUS_ICON} 📦 $name"
                echo "      📋 Service: $(echo $image | cut -d':' -f1)"
                echo "      🔄 Status: $status"
                if [ -n "$ports" ] && [[ $status == *"Up"* ]]; then
                    echo "      📍 Ports: $ports"
                fi
            fi
            echo ""
        done

        # Show resource usage summary
        RUNNING_COUNT=$(echo "$ALL_CONTAINERS" | grep -c "Up")
        STOPPED_COUNT=$(echo "$ALL_CONTAINERS" | grep -c -v "Up")

        echo "📊 Summary:"
        echo "   ✅ Running: $RUNNING_COUNT containers"
        echo "   ⏹️  Stopped: $STOPPED_COUNT containers"

        # Show port usage overview
        echo ""
        echo "🌐 Port Usage Summary:"
        echo "$ALL_CONTAINERS" | grep "Up" | grep -o '0.0.0.0:[0-9]*' | sort -u | while read port_mapping; do
            port=$(echo $port_mapping | cut -d':' -f2)
            echo "   📍 Port $port: In use"
        done

    else
        echo "❌ No containers found"
    fi

    echo ""
    echo "🔍 Keycloak Specific Status:"
    echo "----------------------------"
}

# Show all Podman images
show_podman_images() {
    echo "🖼️  Podman Images Overview:"
    echo "----------------------------"

    IMAGES=$(podman images --format "{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Created}}\t{{.Size}}")

    if [ -n "$IMAGES" ]; then
        echo "$IMAGES" | while IFS=$'\t' read -r repository id created size; do
            # Categorize images
            if [[ $repository == *"postgres"* ]]; then
                echo "   🗄️  $repository"
                echo "      📋 ID: $id"
                echo "      📅 Created: $created"
                echo "      📦 Size: $size"
            elif [[ $repository == *"pgadmin"* ]]; then
                echo "   🔧 $repository"
                echo "      📋 ID: $id"
                echo "      📅 Created: $created"
                echo "      📦 Size: $size"
            elif [[ $repository == *"keycloak"* ]]; then
                echo "   🔐 $repository"
                echo "      📋 ID: $id"
                echo "      📅 Created: $created"
                echo "      📦 Size: $size"
            elif [[ $repository == *"redis"* ]]; then
                echo "   📦 $repository"
                echo "      📋 ID: $id"
                echo "      📅 Created: $created"
                echo "      📦 Size: $size"
            else
                echo "   📦 $repository"
                echo "      📋 ID: $id"
                echo "      📅 Created: $created"
                echo "      📦 Size: $size"
            fi
            echo ""
        done

        # Image statistics
        IMAGE_COUNT=$(echo "$IMAGES" | wc -l | tr -d ' ')
        TOTAL_SIZE=$(podman images --format "{{.Size}}" | grep -E '[0-9]+' | sed 's/[A-Za-z]*//g' | awk '{sum += $1} END {print sum}')

        echo "📊 Image Summary:"
        echo "   📦 Total Images: $IMAGE_COUNT"
        if [ -n "$TOTAL_SIZE" ]; then
            echo "   💾 Estimated Total Size: ~${TOTAL_SIZE}MB"
        fi
    else
        echo "❌ No Podman images found"
    fi
    echo ""
}

# Show volumes
show_volumes() {
    echo "💾 Podman Volumes:"
    echo "------------------"

    VOLUMES=$(podman volume ls --format "{{.Name}}\t{{.Driver}}")

    if [ -n "$VOLUMES" ]; then
        echo "$VOLUMES" | while IFS=$'\t' read -r name driver; do
            if [[ $name == *"postgres"* ]] || [[ $name == *"db"* ]]; then
                echo "   🗄️  $name"
                echo "      📋 Driver: $driver"
            else
                echo "   💾 $name"
                echo "      📋 Driver: $driver"
            fi
        done
        echo ""

        VOLUME_COUNT=$(echo "$VOLUMES" | wc -l | tr -d ' ')
        echo "📊 Volume Summary:"
        echo "   💾 Total Volumes: $VOLUME_COUNT"
    else
        echo "❌ No Podman volumes found"
    fi
    echo ""
}

# Show networks
show_networks() {
    echo "🌐 Podman Networks:"
    echo "-------------------"

    NETWORKS=$(podman network ls --format "{{.Name}}\t{{.Driver}}\t{{.ID}}")

    if [ -n "$NETWORKS" ]; then
        echo "$NETWORKS" | while IFS=$'\t' read -r name driver id; do
            echo "   🌐 $name"
            echo "      📋 Driver: $driver"
            echo "      🆔 ID: $(echo $id | cut -c1-12)"
        done
        echo ""

        NETWORK_COUNT=$(echo "$NETWORKS" | wc -l | tr -d ' ')
        echo "📊 Network Summary:"
        echo "   🌐 Total Networks: $NETWORK_COUNT"
    else
        echo "❌ No custom Podman networks found"
    fi
    echo ""
}

# Enhanced port checking
show_port_usage() {
    echo "🌐 Port Usage Analysis:"
    echo "-----------------------"

    NEXUS_PORTS="5432 8090 8091"
    for port in $NEXUS_PORTS; do
        if lsof -i :${port} >/dev/null 2>&1; then
            PROCESS=$(lsof -i :${port} | tail -n 1 | awk '{print $1, $2}')
            case $port in
                5432) echo "   🗄️  Port $port (PostgreSQL): ✅ In use by $PROCESS" ;;
                8090) echo "   🔐 Port $port (Keycloak): ✅ In use by $PROCESS" ;;
                8091) echo "   🔧 Port $port (pgAdmin): ✅ In use by $PROCESS" ;;
                *) echo "   📍 Port $port: ✅ In use by $PROCESS" ;;
            esac
        else
            case $port in
                5432) echo "   🗄️  Port $port (PostgreSQL): ❌ Available" ;;
                8090) echo "   🔐 Port $port (Keycloak): ❌ Available" ;;
                8091) echo "   🔧 Port $port (pgAdmin): ❌ Available" ;;
                *) echo "   📍 Port $port: ❌ Available" ;;
            esac
        fi
    done
    echo ""
}

# Show system resource usage
show_system_resources() {
    echo "💻 System Resources:"
    echo "--------------------"

    # Show podman system info
    PODMAN_INFO=$(podman system info --format json 2>/dev/null)
    if [ $? -eq 0 ]; then
        RUNNING_CONTAINERS=$(podman ps -q | wc -l | tr -d ' ')
        TOTAL_CONTAINERS=$(podman ps -aq | wc -l | tr -d ' ')

        echo "   🐳 Containers: $RUNNING_CONTAINERS running / $TOTAL_CONTAINERS total"

        # Show disk usage if available
        if command -v podman >/dev/null 2>&1; then
            DISK_USAGE=$(podman system df 2>/dev/null | tail -n +2)
            if [ -n "$DISK_USAGE" ]; then
                echo "   💾 Disk Usage:"
                echo "$DISK_USAGE" | while read line; do
                    echo "      $line"
                done
            fi
        fi
    else
        echo "   ⚠️  Unable to retrieve system information"
    fi
    echo ""
}

# Main execution
show_podman_images
show_development_environment
show_volumes
show_networks
show_port_usage
show_system_resources

echo "🛠️  Available Commands:"
echo "   ./start-keycloak.sh     - Start Keycloak"
echo "   ./stop-keycloak.sh      - Stop Keycloak"
echo "   ./start-postgres.sh     - Start PostgreSQL"
echo "   ./stop-postgres.sh      - Stop PostgreSQL"
echo "   ./start-pgadmin.sh      - Start pgAdmin"
echo "   ./stop-pgadmin.sh       - Stop pgAdmin"
echo "   ./dev-env.sh            - Interactive environment manager"
echo ""

echo "🔧 Quick Diagnostic Commands:"
echo "   podman ps -a            - List all containers"
echo "   podman images           - List all images"
echo "   podman volume ls        - List all volumes"
echo "   podman system df        - Show disk usage"
echo "   podman system prune     - Clean unused resources"