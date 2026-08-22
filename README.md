🚀 **Application Workload:** This platform is designed to host the [Musical Volunteer Flask Application](https://github.com/rjabeen04/musical-volunteer).

# FDIC-Style Azure DevSecOps Platform

## Project Goal

This repository demonstrates an **FDIC-style Azure DevSecOps platform** designed around enterprise and regulated-environment practices.

The goal is to demonstrate:

- Separation of application and infrastructure concerns
- Secure-by-default cloud architecture
- Governance and auditability
- Infrastructure as Code using Terraform
- Kubernetes-based application delivery on Azure
- Automated security validation
- Controlled infrastructure changes through CI/CD

This project is built as a **Proof of Concept (POC)** and resources can be safely created and destroyed.

---

## High-Level Architecture

The platform provisions and manages the following Azure components:

- **Azure Kubernetes Service (AKS)**
- **Azure Container Registry (ACR)**
- **Application Gateway with Web Application Firewall (WAF)**
- **Azure Key Vault** for secrets management
- **Customer-managed encryption**
- **Virtual Network and subnet segmentation**
- **Log Analytics** for centralized monitoring
- **Azure DevOps Pipelines** for CI/CD and security automation

Infrastructure is provisioned using **Terraform modules**, while application workloads are designed to run on **AKS**.

---

## Pipeline Overview

This repository uses **GitHub as the source repository** and **Azure DevOps as the CI/CD orchestration platform**.

Infrastructure changes follow a controlled Terraform workflow.

The Azure DevOps pipeline performs:

1. Terraform format validation
2. Terraform initialization
3. Terraform validation
4. Checkov infrastructure security scanning
5. Gitleaks secret scanning
6. Terraform plan
7. Terraform plan artifact publication
8. Terraform apply

The pipeline is designed to provide security and validation gates before infrastructure changes are applied.

---

## Deployment Model

```text
Developer
    |
    v
GitHub Repository
    |
    v
Azure DevOps Pipeline
    |
    +--> Terraform Format Check
    |
    +--> Terraform Init
    |
    +--> Terraform Validate
    |
    +--> Checkov IaC Security Scan
    |
    +--> Gitleaks Secret Scan
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
    +--> Virtual Network
    +--> ACR
    +--> Key Vault
    +--> AKS
    +--> Application Gateway / WAF
    +--> Log Analytics
