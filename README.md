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

- Azure Kubernetes Service (AKS)
- Azure Container Registry (ACR)
- Application Gateway with Web Application Firewall (WAF)
- Azure Key Vault for secrets management
- Log Analytics for centralized logging and monitoring
- GitHub Actions for CI/CD and security automation

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
- Repository scaffolding
- Documentation
- Security baselines (CodeQL, Dependabot)

**Phase 1 – Infrastructure Provisioning**
- AKS, networking, WAF, and supporting services
- Terraform modules and environments

**Phase 2 – Application Deployment**
- Helm charts for application workloads
- Ingress and WAF integration

**Phase 3 – Security & Observability**
- Infrastructure security scanning
- Runtime monitoring and logging
- Optional DAST and policy enforcement

---

## How to Run (Placeholder)
Execution details will be added as Terraform modules and pipelines are implemented.

Typical usage will include:
- Terraform plan/apply via GitHub Actions
- Helm deployments to AKS
- Manual approvals for protected environments

### CI/CD Security
- GitHub Actions uses Azure OIDC authentication (no client secrets)
- Terraform CI runs on pull requests with RBAC-based access
- Checkov enforces IaC security controls

