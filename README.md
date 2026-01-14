# **Scripts for Installing and Configuring Prometheus, Node Exporter and Grafana**

## **Description**
Scripts for installing and configuring Prometheus, Node Exporter and Grafana in a private network (VPC). The setup focuses on secure metrics collection using private IPs only and exposing Grafana securely via a reverse proxy.

## **What the scripts do (summary):**
1) [prometheus_configuration.sh](https://github.com/Skywalker93-hub/prometheus/blob/master/prometheus_configuration.sh)

- Automatically detects system architecture (AMD64 / ARM64) and downloads the appropriate Prometheus binary.
- Extracts the package into `/usr/local/bin/prometheus`.
- Creates a dedicated `prometheus` system user without a login shell.
- Creates a `data` directory and assigns correct permissions (`prometheus:prometheus`).
- Automatically detects the host machine’s private IP address.
- Creates and installs a systemd service at `/etc/systemd/system/prometheus.service`.
- Generates a Prometheus configuration file dynamically with scrape targets for:
  - the Prometheus server itself,
  - a remote Node Exporter endpoint.


2) [exporter_configuration.sh](https://github.com/Skywalker93-hub/prometheus/blob/master/exporter_configuration.sh)  

- Downloads and installs Node Exporter.
- Creates a `node_exporter` system user.
- Configures and installs a Node Exporter systemd service.
- Starts the service after installation.
- Automatically detects the node’s private IP address and binds Node Exporter to it (port 9100).
- Firewall rules must allow access to port 9100 only from the Prometheus server (private network).

3) [grafana.sh](https://github.com/Skywalker93-hub/prometheus/blob/master/grafana.sh)

- Installs Grafana and configures it to listen only on localhost (127.0.0.1:3000).
- Provisions Prometheus as a Grafana data source via `/etc/grafana/provisioning/datasources/prometheus.yaml`.
- Installs Nginx and configures it as a reverse proxy for Grafana.
- Generates a self-signed TLS certificate (365 days) and enables HTTPS on port 443.
- Redirects HTTP (port 80) to HTTPS (301).
- Configures UFW to allow 22/80/443 and deny direct access to 3000.


## **Requirements**
- Supported architectures: AMD64 and ARM64.
- Linux with systemd  
- sudo or root permissions

## **Security notes** 
Node Exporter is not publicly exposed. Port 9100 should be accessible only from the Prometheus server over the private network. Prometheus Web UI (9090) should not be exposed via public IP. Grafana should not be exposed directly on port 3000; access should go through Nginx (80/443).

## **How to Run**
Make scripts executable:
> chmod +x prometheus_configuration.sh exporter_configuration.sh grafana.sh

Run Prometheus setup:
> sudo ./prometheus_configuration.sh

Run Node Exporter setup:
> sudo ./exporter_configuration.sh

Run Node Grafana setup:
> sudo ./grafana.sh

## **Recommendations** 
- Create a snapshot or backup before running the scripts.
- Test everything on a separate virtual machine first.

## **License**
Created: 2025

License: GPL-3.0  