
#!/bin/bash
# Grafana installation script for Debian-based systems

# Update package list and install Grafana

echo "Grafana installation is starting..."

sudo apt-get install -y apt-transport-https wget
sudo mkdir -p /etc/apt/keyrings/
sudo wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana 

# Add public IP address and port to the configuration file

PORT_GRAFANA=3000
PORT_PROMETHEUS=9090
IP_ADDRESS_GRAFANA="127.0.0.1"

ip addr show | awk '/inet / {print $2}' | cut -d/ -f1 | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)'
read -p "Paste IP address for Prometheus from the list above: " IP_ADDRESS_PROMETHEUS
echo "Prometheus IP: ${IP_ADDRESS_PROMETHEUS}"

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
    exit 1
fi

# Setup Nginx as a reverse proxy for Grafana 

echo "Nginx installation is starting..."

if ! command -v nginx &> /dev/null
then
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y nginx 
else
    echo "Nginx is already installed"
fi

# Configure TLS/SSL for Nginx using OpenSSL 

if ! command -v openssl &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y openssl
fi

if [[ ! -d /etc/nginx/ssl ]]; then
    sudo mkdir -p /etc/nginx/ssl
fi

read -p "Enter domain name for Grafana: " DOMAIN_NAME
echo "Domain name for Grafana: ${DOMAIN_NAME}"

if [[ ! -s /etc/nginx/ssl/grafana.key || ! -s /etc/nginx/ssl/grafana.crt ]]; then
    sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/nginx/ssl/grafana.key -out /etc/nginx/ssl/grafana.crt -sha256 -days 365 -subj "/C=XX/L=XX/O=Monitoring/CN=${DOMAIN_NAME}"
fi

# Configure Nginx to proxy requests to Grafana 

sudo touch /etc/nginx/sites-available/grafana && sudo tee /etc/nginx/sites-available/grafana > /dev/null <<EOL
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN_NAME};

    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ${DOMAIN_NAME};

    ssl_certificate     /etc/nginx/ssl/grafana.crt;
    ssl_certificate_key /etc/nginx/ssl/grafana.key;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/grafana

# Test Nginx configuration and reload Nginx

sudo nginx -t
sudo systemctl reload nginx

# Setup Firewall if it is installed and Configure it to allow HTTP, HTTPS and SSH traffic requiers

if ! command -v ufw &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y ufw
fi

sudo ufw deny 3000/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp 
sudo ufw --force enable 
