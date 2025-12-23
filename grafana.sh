
#!/bin/bash
# Grafana installation script for Debian-based systems

# Update package list and install Grafana

sudo apt-get install -y apt-transport-https wget
sudo mkdir -p /etc/apt/keyrings/
sudo wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana 

# Add public IP address and port to the configuration file

PORT_GRAFANA=3000
PORT_PROMETHEUS=9090

echo "Now choose the IP addresses for Grafana and Prometheus servers from the list below:"
ip addr show | awk '/inet / {print $2}' | cut -d/ -f1 | grep -vE '^127\.|^172\.17\.'

read -p "Paste IP address for Grafana from the list above: " IP_ADDRESS_GRAFANA
echo "Grafana IP: $IP_ADDRESS_GRAFANA" 

read -p "Paste IP address for Prometheus from the list above: " IP_ADDRESS_PROMETHEUS
echo "Prometheus IP: $IP_ADDRESS_PROMETHEUS"

sudo sed -Ei "s|;http_addr =.*|http_addr = $IP_ADDRESS_GRAFANA|" /etc/grafana/grafana.ini
sudo sed -E "s|;http_port =.*|http_port = $PORT_GRAFANA|" /etc/grafana/grafana.ini

# Config Data Sources for Grafana in the /etc/grafana/provisioning/datasources/prometheus.yaml, which Grafana uses to connect to data sources

sudo touch /etc/grafana/provisioning/datasources/prometheus.yaml 
sudo tee /etc/grafana/provisioning/datasources/prometheus.yaml > /dev/null <<EOL
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://$IP_ADDRESS_PROMETHEUS:$PORT_PROMETHEUS
    isDefault: true
EOL

# Enable and start Grafana service

sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Verify Grafana service status

STATUS=$(sudo systemctl is-active grafana-server)

echo $STATUS
if [[ "$STATUS" = "active" ]]; then
    echo "Grafana installation succeeded"
    exit 0
else
    echo "Grafana installation failed" 
    exit 1
fi
