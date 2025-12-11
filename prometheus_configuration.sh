#! /bin/bash
# The script to install the Prometheus (ARM64)

set -e

echo "Starting setup the Prometheus. Please, waitting..."

# Download and install Prometheus
wget -q https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-arm64.tar.gz
tar -xzf prometheus-3.5.0.linux-arm64.tar.gz >/dev/null 2>&1

sudo mkdir -p /usr/local/bin/prometheus && sudo mv -f prometheus-3.5.0.linux-arm64 /usr/local/bin/prometheus
sudo chmod 755 /usr/local/bin/prometheus

# Create Prometheus user if it doesn't exist
if ! id -u prometheus &>/dev/null; then
    sudo useradd -rs /bin/false prometheus
fi

# Set up directories for Prometheus
sudo mkdir -p /usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/data
sudo chown -R prometheus:prometheus /usr/local/bin/prometheus
sudo mkdir -p /etc/prometheus && sudo touch /etc/prometheus/prometheus.yml
sudo chown -R prometheus:prometheus /etc/prometheus

# Create systemd service for Prometheus
sudo touch /etc/systemd/system/prometheus.service
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=prometheus.service
After=network.target

[Service]
User=prometheus 
Group=prometheus 
ExecStart=/usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/data
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Set up Prometheus configuration file
IP_ADDRESS=$(ip a | grep "192.*.*.*" | awk '{print $2}' | cut -d/ -f1)
PORT_PROMETHEUS=9090

read -p "Enter the IP adress for Node Exporter to scrape metrics: " $IP_ADDRESS_NODE_EXPORTER

sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ["$IP_ADDRESS:$PORT_PROMETHEUS"]

  - job_name: "node_exporter"
    static_configs:
      - targets: ["$IP_ADDRESS_NODE_EXPORTER:9100"]
EOF

# Start and enable Prometheus service
sudo systemctl daemon-reload
sudo systemctl restart prometheus
sudo systemctl status prometheus

systemctl is-active --quiet prometheus
if [ $? -eq 0 ]; then
    echo "Prometheus service is running"
else
    echo "Prometheus service isn't running"
fi