#!/bin/bash

# Read configurations from environment variables, default to 0 if not set
ENABLE_LOG_FILE=${ENABLE_LOG_FILE:-0}
ENABLE_PROMETHEUS_METRIC=${ENABLE_PROMETHEUS_METRIC:-0}

# Define variables
LOG_FILE="/var/log/wifi-check.log"
PROMETHEUS_METRIC_FILE="/var/lib/node_exporter/wifi_check.prom" # Ensure Node Exporter is set up to use this directory
WIFI_INTERFACE="wlan0"
TEST_HOST="google.com" # Google's main site, used for testing the internet connectivity

# Define a function for logging
log() {
    local timestamp=$(date -Is)
    local message="$timestamp $1"
    echo $message
    if [[ $ENABLE_LOG_FILE -eq 1 ]]; then
        echo $message >> $LOG_FILE
    fi
}

# Define a function for checking internet connectivity
check_internet() {
    ping -c 2 $TEST_HOST > /dev/null
    return $?
}

# Define a function for waiting for a service to reach a specific state
wait_for_service() {
    local service=$1
    local state=$2

    while [[ $(systemctl is-active $service) != $state ]]; do
        sleep 1
    done
}

# Start the script
log 'WiFi check started'

# Check if the WiFi interface exists
if [ -d "/sys/class/net/$WIFI_INTERFACE" ]; then
    # Check if we have internet access
    if ! check_internet; then
        log "No internet access on $WIFI_INTERFACE, trying to reconnect"
        # Take the WiFi interface down
        sudo systemctl stop NetworkManager.service
        wait_for_service NetworkManager inactive
        # Bring the WiFi interface back up
        sudo systemctl start NetworkManager.service
        wait_for_service NetworkManager active
    fi
    # Give it some time to establish connection
    sleep 5

    # Log the final status and update Prometheus metric
    if check_internet; then
        log "Internet access available on $WIFI_INTERFACE"
        if [[ $ENABLE_PROMETHEUS_METRIC -eq 1 ]]; then
            echo "wifi_check_status 1" > $PROMETHEUS_METRIC_FILE
        fi
    else
        log "Still no internet access on $WIFI_INTERFACE after attempt to reconnect"
        if [[ $ENABLE_PROMETHEUS_METRIC -eq 1 ]]; then
            echo "wifi_check_status 0" > $PROMETHEUS_METRIC_FILE
        fi
    fi
else
    log "WiFi interface $WIFI_INTERFACE not found"
    if [[ $ENABLE_PROMETHEUS_METRIC -eq 1 ]]; then
        echo "wifi_check_status 0" > $PROMETHEUS_METRIC_FILE
    fi
fi

# Finish the script
log 'WiFi check finished'
