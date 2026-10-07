# Infra Honeypot

An automated infrastructure-as-code (IaC) deployment for a multi-tier, distributed honeypot and threat intelligence system. This project uses **Terraform** for cloud resource provisioning (Azure) and **Ansible** for configuration management.

## 🚀 Architecture Context

This repository is part of a larger Multi-ML Active Defense Architecture, which spans three core repositories:
- **[infra_honeypot](./)**: Infrastructure automation (this repo).
- **[sec_dash](../sec_dash)**: The central Security Operations Center (SOC) dashboard (React + Go).
- **[xpd-shield](../xpd-shield)**: An eBPF/XDP-based edge mitigation agent.

## ⚙️ What It Does

`infra_honeypot` sets up the following environments:
1. **Honeypot Nodes:** Provisions the target servers and installs Vector (log aggregation), Honeypots (e.g., Cowrie, Snare), and the **xpd-shield** agent for dropping malicious connections directly at the network interface.
2. **Monitoring Hub / Backend:** Provisions the central infrastructure including Redis (acting as the low-latency message broker for the ban feed) and the **sec_dash** services.

## 🛠️ Tech Stack
- **Terraform**: Declarative provisioning of Azure Compute, Network, and Security structures.
- **Ansible**: Post-provisioning configuration, role-based deployment of Vector, Redis, Honeypot daemons, and `xpd-shield`.

## 📂 Project Structure
- `terraform/`: Contains the Terraform modules (`main.tf`, `compute.tf`, `network.tf`, `security.tf`) to spin up Azure resources.
- `ansible/`: Contains Ansible playbooks (`site.yml`) and roles (`vector`, `honeypot`, `redis`, `xpd_shield`, `monitoring`, `snare`) to configure instances.

## 📖 Usage
1. Configure your Azure credentials for Terraform.
2. Navigate to `terraform/` and run `terraform init`, `terraform plan`, and `terraform apply`.
3. The Terraform output will generate an Ansible inventory.
4. Navigate to `ansible/` and run the playbook against the provisioned environment: `ansible-playbook -i inventory.yml site.yml`.

## 🤝 Open Source Learning
This project serves as a learning platform for building highly available, secure infrastructure, writing idempotent configuration code, and designing distributed machine-learning security systems.
