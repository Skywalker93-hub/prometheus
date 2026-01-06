
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
IP_ADDRESS_GRAFANA="127.0.0.1"

ip addr show | awk '/inet / {print $2}' | cut -d/ -f1 | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)'
read -p "Paste IP address for Prometheus from the list above: " IP_ADDRESS_PROMETHEUS
echo "Prometheus IP: $IP_ADDRESS_PROMETHEUS"

sudo sed -Ei "s|;http_addr =.*|http_addr = $IP_ADDRESS_GRAFANA|" /etc/grafana/grafana.ini
sudo sed -Ei "s|;http_port =.*|http_port = $PORT_GRAFANA|" /etc/grafana/grafana.ini

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

echo "$STATUS"
if [[ "$STATUS" = "active" ]]; then
    echo "Grafana installation succeeded"
else
    echo "Grafana installation failed" 
fi

# Setup Nginx as a reverse proxy for Grafana 

if ! command -v nginx &> /dev/null
then
    echo "Nginx could not be found, installing Nginx..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y nginx 
else
    echo "Nginx is already installed"
fi

sudo touch /etc/nginx/sites-available/grafana && sudo tee /etc/nginx/sites-available/grafana > /dev/null <<EOL
server {
    listen 80;

    server_name grafana;   

    location / {
        proxy_pass http://$IP_ADDRESS_GRAFANA:$PORT_GRAFANA;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/grafana
sudo nginx -t
sudo systemctl reload nginx

# Setup Firewall if it is installed and Configure it to allow HTTP traffic

if ! dpkg -l | grep -q "ufw"; then
    sudo apt-get update && sudo apt-get install -y ufw
fi

sudo ufw deny 3000/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp