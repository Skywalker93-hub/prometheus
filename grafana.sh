
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

IP_PUB_ADDRESS=$(hostname -I | grep -oE "151\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
PORT_GRAFANA=3000
IP_PRIVATE_ADDRESS=$(hostname -I | grep -oE "192\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
PORT_PROMETHEUS=9090

sudo sed -Ei "s|;http_addr =.*|http_addr = $IP_PUB_ADDRESS|" /etc/grafana/grafana.ini
sudo sed -E "s|;http_port =.*|http_port = $PORT_GRAFANA" /etc/grafana/grafana.ini

# Config Data Sources for Grafana in the /etc/grafana/provisioning/datasources/prometheus.yaml, which Grafana uses to connect to data sources

sudo touch /etc/grafana/provisioning/datasources/prometheus.yaml 
sudo tee /etc/grafana/provisioning/datasources/prometheus.yaml > /dev/null <<EOL
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://$IP_PRIVATE_ADDRESS:$PORT_PROMETHEUS
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
