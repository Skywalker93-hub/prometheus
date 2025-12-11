# **Scripts for Installing and Configuring Prometheus and Node Exporter**

## **Description**
Scripts for installing Prometheus and Node Exporter, creating service users, and configuring systemd services.

## **What the scripts do (summary):**
1) [prometheus_configuration.sh](https://github.com/Skywalker93-hub/prometheus/blob/master/prometheus_configuration.sh)

- Downloads the Prometheus tarball (ARM64 build in the current version).
- Extracts the package into `/usr/local/bin/prometheus`.
- Creates a dedicated `prometheus` system user without a login shell.
- Creates a `data` directory and assigns correct permissions (`prometheus:prometheus`).
- Automatically detects the host machine’s IP address.
- Creates and installs a systemd service at `/etc/systemd/system/prometheus.service`.
- Generates a Prometheus configuration file with scrape targets for:
  - the Prometheus server itself,
  - a remote Node Exporter endpoint.


2) [exporter_configuration.sh](https://github.com/Skywalker93-hub/prometheus/blob/master/exporter_configuration.sh)  

- Downloads and installs Node Exporter.
- Creates a `node_exporter` system user.
- Configures and installs a Node Exporter systemd service.
- Starts the service after installation.
- **Interactive:** prompts the user for the IP address of the machine where Node Exporter is running, so Prometheus can scrape it.


## **Requirements**
- Scripts currently installs the ARM64 build (architecture must match the system)
- Linux with systemd  
- sudo or root permissions

## **Security notes** 
Configure the firewall/ACL if you need to restrict access to port 9090.

## **How to Run**
Make scripts executable:
> chmod +x prometheus_configuration.sh 

> exporter_configuration.sh

Run Prometheus setup:
> sudo ./prometheus_configuration.sh

Run Node Exporter setup:
> sudo ./exporter_configuration.sh

## **RecommendationsSecurity notes** 
- Create a snapshot or backup before running the scripts.
- Test everything on a separate virtual machine first.

## **License**
Created: 2025

License: GPL-3.0  