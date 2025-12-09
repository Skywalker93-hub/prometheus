#! /bin/bash
# This script sets up environment variables for Prometheus exporters.
# This script fits for ARM64 architecture system because it downloads the ARM64 version of node_exporter.

echo "Starting setup of Prometheus Node Exporter. Please, wait"
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-arm64.tar.gz
tar -xzf node_exporter-1.10.2.linux-arm64.tar.gz >/dev/null 2>&1
sudo mkdir -p /usr/local/bin/node_exporter/ && sudo mv -f node_exporter-1.10.2.linux-arm64 /usr/local/bin/node_exporter 
sudo chmod 0755 /usr/local/bin/node_exporter/node_exporter-1.10.2.linux-arm64 

sudo useradd -rs /bin/false node_exporter
sudo touch /etc/systemd/system/node_exporter.service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=node.exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter/node_exporter-1.10.2.linux-arm64/node_exporter 
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter 
sudo systemctl start node_exporter

systemctl is-active --quiet node_exporter
if [ $? -eq 0 ]; then
    echo "node_exporter service is running"
else
    echo "node_exporter service isn't running"
fi
