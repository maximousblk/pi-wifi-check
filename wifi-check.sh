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
        echo $message >> $LOG_FILE
    fi
}

# Function to log Prometheus metrics, logs WiFi status and ESSID if enabled
prom_log() {
    local status=$1
    local wifi_essid=$(iwgetid -r)
    if [[ $ENABLE_PROMETHEUS_METRIC -eq 1 ]]; then
        echo "wifi_check_status $status" > $PROMETHEUS_METRIC_FILE
        echo "wifi_check_essid{name=\"$wifi_essid\"} $status" >> $PROMETHEUS_METRIC_FILE
    fi
}

# Function to check internet connectivity by pinging a reliable host
check_internet() {
    ping -c 2 $TEST_HOST > /dev/null
    return $?
}

# Function to wait until a service reaches a specific active state
wait_for_service() {
    local service=$1
    local state=$2

    while [[ $(systemctl is-active $service) != $state ]]; do
        sleep 1
    done
}

# Start the WiFi check
log 'Starting WiFi check...'

# Check the existence of the WiFi interface and manage connectivity
if [ -d "/sys/class/net/$WIFI_INTERFACE" ]; then
    # If internet access is not available, restart NetworkManager service
    if ! check_internet; then
        log "Status: No internet access on interface $WIFI_INTERFACE. Initiating NetworkManager.service restart..."
        log "Action: Restarting NetworkManager.service..."
        sudo systemctl restart NetworkManager.service
        wait_for_service NetworkManager active
    fi
    # Wait to allow the connection to establish
    sleep 5

    # Log final status of internet access and log Prometheus metrics
    if check_internet; then
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
