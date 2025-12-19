#! /bin/bash
# This script sets up environment variables for Prometheus exporters.
# It fits for AMD64 and ARM64 architecture systems because it downloads the ARM64 or AMD64 versions of node_exporter.
# It creates a systemd service for node_exporter to run on private IP


set -e

# Check architecture and Install Prometheus Node Exporter

echo "Starting setup of Prometheus Node Exporter. Please, waiting..."

ARCH=$(uname -m)

if [[ "$ARCH" = "x86_64" ]]; then
    wget -q https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
    tar -xzf node_exporter-1.10.2.linux-amd64.tar.gz >/dev/null 2>&1
elif [[ "$ARCH" = "aarch64" || "$ARCH" = "arm64" ]]; then
    wget -q https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-arm64.tar.gz
    tar -xzf node_exporter-1.10.2.linux-arm64.tar.gz >/dev/null 2>&1
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Create directory and move node_exporter files to it, set permissions, and create a systemd service for node_exporter.

if [[ "$ARCH" = "x86_64" ]]; then
    NODE_EXPORTER_DIR=node_exporter-1.10.2.linux-amd64
else
    NODE_EXPORTER_DIR=node_exporter-1.10.2.linux-arm64
fi

sudo mkdir -p /usr/local/bin/node_exporter/ && sudo mv -f $NODE_EXPORTER_DIR /usr/local/bin/node_exporter 
sudo chmod 0755 /usr/local/bin/node_exporter/$NODE_EXPORTER_DIR
NODE_EXPORTER_PATH=/usr/local/bin/node_exporter/$NODE_EXPORTER_DIR/node_exporter

# Create node_exporter user if it doesn't exist
if ! id -u node_exporter &>/dev/null; then
    sudo useradd -rs /bin/false node_exporter
fi

# Create systemd service file for node_exporter and bind it to private IP

PRIVATE_IP=$(hostname -I | grep -oE '192\.168\.30\.[0-9]+')

if [[ -z "$PRIVATE_IP" ]]; then
    echo "ERROR: Could not detect private IP"
    exit 1
fi

sudo touch /etc/systemd/system/node_exporter.service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=node.exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter/$NODE_EXPORTER_DIR/node_exporter --web.listen-address=$PRIVATE_IP:9100
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start node_exporter service, and check its status.

sudo systemctl daemon-reload
sudo systemctl enable node_exporter 
sudo systemctl start node_exporter

systemctl is-active --quiet node_exporter
if [ $? -eq 0 ]; then
    echo "node_exporter service is running"
else
    echo "node_exporter service isn't running"
fi
