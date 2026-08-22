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
- **Azure DevOps Pipelines** for CI/CD and security automation

Application workloads are deployed to AKS using **Helm**, while infrastructure is provisioned using **Terraform**.

Detailed diagrams are maintained in `docs/diagrams/`.

---
## Pipeline Overview

This repository uses **Azure DevOps** as the CI/CD orchestration layer with GitHub as the source repository.

The infrastructure pipeline performs:

1. Terraform format validation
2. Terraform initialization
3. Terraform validation
4. Checkov infrastructure security scanning
5. Gitleaks secret scanning
6. Terraform plan
7. Terraform plan artifact publication
8. Terraform apply

Azure authentication uses **Microsoft Entra ID Workload Identity Federation**, avoiding long-lived Azure service principal credentials in the pipeline.

---

## Security & Platform Engineering

The platform incorporates enterprise-oriented security controls including:

- Private Azure Kubernetes Service (AKS)
- Microsoft Entra ID integration
- AKS OIDC issuer
- Azure Container Registry (ACR)
- Azure Key Vault
- Customer-managed encryption
- Network segmentation
- Application Gateway with Web Application Firewall (WAF)
- Centralized Log Analytics monitoring
- Checkov IaC security scanning
- Gitleaks secret detection
- Workload Identity Federation for Azure DevOps

The infrastructure is implemented using reusable Terraform modules and environment-specific configurations.

---

## Deployment Model

Infrastructure changes are delivered through Azure DevOps using a controlled Terraform workflow:

```text
GitHub
   |
   v
Azure DevOps Pipeline
   |
   +--> Terraform Format
   |
   +--> Terraform Init
   |
   +--> Terraform Validate
   |
   +--> Checkov
   |
   +--> Gitleaks
   |
   +--> Terraform Plan
   |
   +--> Plan Artifact
   |
   +--> Terraform Apply
   |
   v
Azure Platform
   |
   +--> VNet / Networking
   +--> ACR
   +--> Key Vault
   +--> AKS
   +--> Application Gateway / WAF
   +--> Log Analytics

