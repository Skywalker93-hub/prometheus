#! /bin/bash
# The script to install the Prometheus (ARM64)

set -e

echo "Starting setup the Prometheus. Please, waitting..."

wget -q https://github.com/prometheus/prometheus/releases/download/v3.5.0/prometheus-3.5.0.linux-arm64.tar.gz
tar -xzf prometheus-3.5.0.linux-arm64.tar.gz >/dev/null 2>&1

sudo mkdir -p /usr/local/bin/prometheus && sudo mv -f prometheus-3.5.0.linux-arm64 /usr/local/bin/prometheus
sudo chmod 755 /usr/local/bin/prometheus

if ! id -u prometheus &>/dev/null; then
    sudo useradd -rs /bin/false prometheus
fi

sudo mkdir -p /usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/data
sudo chown -R prometheus:prometheus /usr/local/bin/prometheus

sudo touch /etc/systemd/system/prometheus.service
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=prometheus.service
After=network.target

[Service]
User=prometheus 
Group=prometheus 
ExecStart=/usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/prometheus \ 
--config.file=/usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/prometheus.yml \
--storage.tsdb.path=/usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/data
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

systemctl is-active --quiet prometheus
if [ $? -eq 0 ]; then
    echo "Prometheus service is running"
else
    echo "Prometheus service isn't running"
fi

sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=prometheus.service
After=network.target

[Service]
User=prometheus 
Group=prometheus 
ExecStart=/usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/prometheus \ 
--config.file=/usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/prometheus.yml \
--storage.tsdb.path=/usr/local/bin/prometheus/prometheus-3.5.0.linux-arm64/data
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF