🚀 **Application Workload:** This platform is designed to host the [Musical Volunteer Flask Application](https://github.com/rjabeen04/musical-volunteer).

# FDIC-Style Azure DevSecOps Platform

## Project Goal
This repository represents an **FDIC-style Azure DevSecOps platform** designed using enterprise and regulated-environment best practices.

The goal is to demonstrate:
- Separation of application and infrastructure concerns
- Secure-by-default cloud architecture
- Governance, auditability, and DevSecOps workflows
- Infrastructure-as-Code using Terraform
- Kubernetes-based application delivery on Azure

This project is built as a **Proof of Concept (POC)** and resources can be safely created and destroyed.

---

## High-Level Architecture
The platform provisions and manages the following Azure components:

- **Azure Kubernetes Service (AKS)**
- **Azure Container Registry (ACR)**
- **Application Gateway with Web Application Firewall (WAF)**
- **Azure Key Vault** for secrets management
- **Log Analytics** for centralized logging and monitoring
- **GitHub Actions** for CI/CD and security automation

Application workloads are deployed to AKS using **Helm**, while infrastructure is provisioned using **Terraform**.

Detailed diagrams are maintained in `docs/diagrams/`.

---

## Pipeline Overview
This repository focuses on **platform and infrastructure pipelines**.

Planned pipeline stages include:
- Pull request validation with security scanning
- Terraform plan on pull requests
- Manual approval gates for protected environments
- Terraform apply for environment provisioning
- Helm-based application deployment
- Optional destroy workflows for POC teardown

Security gates (SAST, dependency scanning, IaC scanning) are enforced before changes reach protected branches.

---

## Phases / Roadmap
**Phase 0 – Repository Governance & Structure**
- Repository scaffolding, Documentation, and Security baselines (CodeQL, Dependabot).

**Phase 1 – Infrastructure Provisioning**
- AKS, networking, WAF, and supporting services.
- Terraform modules and environments.

**Phase 2 – Application Deployment**
- Helm charts for application workloads.
- Ingress and WAF integration.

**Phase 3 – Security & Observability**
- Infrastructure security scanning.
- Runtime monitoring and logging.

---

## How to Run (Placeholder)
Execution details will be added as Terraform modules and pipelines are implemented.

Typical usage includes:
- Terraform plan/apply via GitHub Actions.
- Helm deployments to AKS.
- Manual approvals for protected environments.

---

## 🔍 Post-Mortem: Handling Cloud "Eventual Consistency"
**Current Status:** Deployment pipeline intermittently encounters a `403 Forbidden` at the `azurerm_key_vault_key` stage.

### The Technical Challenge
In high-security environments, Azure Key Vault uses a firewall to restrict access. While Terraform successfully updates the firewall rules (Management Plane), the physical distribution of those rules across Azure's global infrastructure (Data Plane) experiences a "propagation lag." 

### Engineering Response
1. **Dynamic Whitelisting:** Implemented `data "http"` to fetch the GitHub Runner's IP dynamically.
2. **Synchronization Gates:** Introduced a `time_sleep` resource to create a 150-second buffer.
3. **Conclusion:** This error highlights the gap between "API Success" and "Resource Readiness." In a production enterprise setting, the next architectural step would be utilizing **Self-Hosted GitHub Runners** inside the VNet to bypass public internet propagation entirely.
