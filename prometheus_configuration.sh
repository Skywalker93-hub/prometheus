#! /bin/bash
# The script to install the Prometheus ARM64 or AMD64 version.
# It creates a systemd service for Prometheus to run on private IP.

set -e

echo "Starting setup the Prometheus. Please, waitting..."

# Check architecture and Install Prometheus

ARCH=$(uname -m)

if [[ "$ARCH" = "aarch64" || "$ARCH" = "arm64" ]]; then 
    wget -q https://github.com/prometheus/prometheus/releases/download/v3.8.1/prometheus-3.8.1.linux-arm64.tar.gz
    tar -xzf prometheus-3.8.1.linux-arm64.tar.gz >/dev/null 2>&1
elif [[ "$ARCH" = "x86_64" ]]; then
    wget -q https://github.com/prometheus/prometheus/releases/download/v3.8.1/prometheus-3.8.1.linux-amd64.tar.gz
    tar -xzf prometheus-3.8.1.linux-amd64.tar.gz >/dev/null 2>&1
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Move Prometheus files to /usr/local/bin/prometheus, set permissions, and create a systemd service for Prometheus.

if [[ "$ARCH" = "x86_64" ]]; then
  PROMETHEUS_DIR=prometheus-3.8.1.linux-amd64
else
  PROMETHEUS_DIR=prometheus-3.8.1.linux-arm64
fi

sudo mkdir -p /usr/local/bin/prometheus && sudo mv -f $PROMETHEUS_DIR /usr/local/bin/prometheus
sudo chmod 755 /usr/local/bin/prometheus

# Create Prometheus user if it doesn't exist

if ! id -u prometheus &>/dev/null; then
    sudo useradd -rs /bin/false prometheus
fi

# Set up directories for Prometheus

sudo mkdir -p /usr/local/bin/prometheus/$PROMETHEUS_DIR/data
sudo chown -R prometheus:prometheus /usr/local/bin/prometheus
sudo mkdir -p /etc/prometheus && sudo touch /etc/prometheus/prometheus.yml
sudo chown -R prometheus:prometheus /etc/prometheus

# Set up Prometheus configuration file

PORT_PROMETHEUS=9090

echo "Now choose the private IP addresses for Prometheus servers from the list below:"
ip addr show | awk '/inet / {print $2}' | cut -d/ -f1 | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)'

read -p "Paste IP address for Prometheus from the list above: " IP_ADDRESS_PROMETHEUS
echo "Prometheus IP: $IP_ADDRESS_PROMETHEUS" 

sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ["$IP_ADDRESS_PROMETHEUS:$PORT_PROMETHEUS"]

  - job_name: "node_exporter"
    static_configs:
      - targets:
EOF

read -p "Please, enter the IP adresses for all servers where Node Exporter is installed (separated by space): " IP_ADDRESS_NODE_EXPORTER
for IP in $IP_ADDRESS_NODE_EXPORTER; do
    echo "        - \"$IP:9100\"" | sudo tee -a /etc/prometheus/prometheus.yml > /dev/null
done

# Create systemd service for Prometheus

sudo touch /etc/systemd/system/prometheus.service
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=prometheus.service
After=network.target

[Service]
User=prometheus 
Group=prometheus 
ExecStart=/usr/local/bin/prometheus/$PROMETHEUS_DIR/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/usr/local/bin/prometheus/$PROMETHEUS_DIR/data --web.listen-address=$IP_ADDRESS_PROMETHEUS:9090
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Prometheus service
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl restart prometheus

sudo systemctl is-active --quiet prometheus
if [ $? -eq 0 ]; then
    echo "Prometheus service is running"
else
    echo "Prometheus service isn't running"
fi