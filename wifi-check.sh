#!/bin/bash

# Read configurations from environment variables or default to 0 if not set
ENABLE_LOG_FILE=${ENABLE_LOG_FILE:-0}
ENABLE_PROMETHEUS_METRIC=${ENABLE_PROMETHEUS_METRIC:-0}

# Define log and Prometheus metric file paths
LOG_FILE="/var/log/wifi-check.log"
PROMETHEUS_METRIC_FILE="/var/lib/node_exporter/wifi_check.prom"

# Define WiFi interface and host for internet connectivity check
WIFI_INTERFACE="wlan0"
TEST_HOST="google.com"

# Function to log messages with timestamp, writes to log file if enabled
log() {
    local timestamp=$(date -Is)
    local message="[$timestamp] $1"
    echo $message
    if [[ $ENABLE_LOG_FILE -eq 1 ]]; then
        echo $message >>$LOG_FILE
    fi
}

# Function to log Prometheus metrics, logs WiFi status and ESSID if enabled
prom_log() {
    local status=$1
    local wifi_essid=$(iwgetid -r)
    if [[ $ENABLE_PROMETHEUS_METRIC -eq 1 ]]; then
        echo "wifi_check_status $status" >$PROMETHEUS_METRIC_FILE
        echo "wifi_check_essid{name=\"$wifi_essid\"} $status" >>$PROMETHEUS_METRIC_FILE
    fi
}

# Function to check internet connectivity by pinging a reliable host with retry
check_internet_retry() {
    local retries=5
    for i in $(seq 1 $retries); do
        if ping -c 2 $TEST_HOST >/dev/null; then
            return 0
        fi
        log "Internet check failed. Retry $i of $retries..."
        sleep 5
    done
    return 1
}

# Function to wait until a service reaches a specific active state
wait_for_service() {
    local service=$1
    local state=$2

    while [[ $(systemctl is-active $service) != $state ]]; do
        sleep 1
    done
}

# Function to check if the WiFi interface is up
is_wifi_interface_up() {
    ip link show $WIFI_INTERFACE | grep -q 'state UP'
    return $?
}

# Start the WiFi check
log 'Starting WiFi check...'

# Check the existence of the WiFi interface and manage connectivity
if is_wifi_interface_up; then
    # If internet access is not available, restart NetworkManager service
    if !check_internet_retry; then
        log "Status: No internet access on interface $WIFI_INTERFACE. Initiating NetworkManager.service restart..."
        # Turn WiFi interface off
        log "Action: Turning $WIFI_INTERFACE off..."
        sudo ip link set $WIFI_INTERFACE down

        # Restart NetworkManager service
        log "Action: Restarting NetworkManager.service..."
        sudo systemctl restart NetworkManager.service
        wait_for_service NetworkManager active

        # Turn WiFi interface on
        sudo ip link set $WIFI_INTERFACE up
    fi
    # Wait to allow the connection to establish
    sleep 5

    # Log final status of internet access and log Prometheus metrics
    if check_internet_retry; then
        log "Status: Internet access is now available on interface $WIFI_INTERFACE."
        prom_log 1
    else
        log "Status: Unable to establish internet access on interface $WIFI_INTERFACE despite NetworkManager.service restart."
        prom_log 0
    fi
else
    # If WiFi interface is not found, log the status and update Prometheus metrics
    log "Status: WiFi interface $WIFI_INTERFACE was not found."
    prom_log 0
fi

# Finish the WiFi check
log 'WiFi check completed.'
