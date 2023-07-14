#!/bin/bash

# Determine the directory the script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to that directory, pull the latest code from the repository, then return to the original directory
cd $DIR
git pull
cd -

# Prompt for user preferences
read -p "Do you want to enable logging? [y/n] " enable_logging
read -p "Do you want to enable Prometheus integration? [y/n] " enable_prometheus

# Convert the user's responses to 0 or 1
enable_logging=$([[ "$enable_logging" == "y" ]] && echo 1 || echo 0)
enable_prometheus=$([[ "$enable_prometheus" == "y" ]] && echo 1 || echo 0)

# Create a systemd drop-in directory for the service unit
mkdir -p /etc/systemd/system/wifi-check.service.d

# Create a new drop-in file with the user's preferences
cat > /etc/systemd/system/wifi-check.service.d/override.conf <<EOF
[Service]
Environment="ENABLE_LOG_FILE=$enable_logging" "ENABLE_PROMETHEUS_METRIC=$enable_prometheus"
EOF

# Copy the script, service, and timer files to the appropriate directories
cp $DIR/wifi-check.sh /usr/local/bin/
cp $DIR/wifi-check.service /etc/systemd/system/
cp $DIR/wifi-check.timer /etc/systemd/system/

# If logging is enabled, setup log rotation
if [[ "$enable_logging" == "1" ]]; then
  cp $DIR/wifi-check.logrotate /etc/logrotate.d/wifi-check
fi

# If Prometheus integration is enabled, setup the node_exporter directory
if [[ "$enable_prometheus" == "1" ]]; then
  sudo mkdir -p /var/lib/node_exporter/
fi

# Reload the systemd daemon and enable the timer
systemctl daemon-reload
systemctl enable --now wifi-check.timer
