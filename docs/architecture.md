# FDIC-Style Azure DevSecOps Platform Architecture

## 1. Overview

This repository implements an enterprise-style Azure platform using Infrastructure as Code, Azure DevOps CI/CD, Microsoft Entra ID workload identity federation, security controls, private networking, centralized monitoring, and customer-managed encryption.

The platform is provisioned and managed through Terraform and deployed through an Azure DevOps pipeline.

The primary development environment is:

- Environment: `dev`
- Resource Group: `fdic-dev-rg`
- Region: East US
- Infrastructure Management: Terraform
- CI/CD: Azure DevOps
- Authentication: Microsoft Entra ID Workload Identity Federation
- Container Platform: Azure Kubernetes Service (AKS)
- Container Registry: Azure Container Registry (ACR)
- Secrets Management: Azure Key Vault
- Encryption: Customer-managed key + Disk Encryption Set
- Monitoring: Azure Log Analytics / Container Insights

---

## 2. High-Level Architecture

```text
                         ┌──────────────────────┐
                         │      Developer       │
                         │                      │
                         │ Git / Pull Request   │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │       GitHub         │
                         │                      │
                         │ Source Repository    │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │    Azure DevOps      │
                         │                      │
                         │ CI/CD Pipeline       │
                         └──────────┬───────────┘
                                    │
                                    ▼
                     ┌──────────────────────────────┐
                     │ Microsoft Entra ID / WIF     │
                     │                              │
                     │ Federated authentication     │
                     │ without client secrets       │
                     └──────────────┬───────────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │      Terraform       │
                         │                      │
                         │ Init / Validate      │
                         │ Security Scans       │
                         │ Plan / Apply         │
                         └──────────┬───────────┘
                                    │
                                    ▼
                    ┌────────────────────────────────┐
                    │        fdic-dev-rg              │
                    │                                │
                    │  ┌──────────────────────────┐  │
                    │  │ VNet / Subnets / NSGs     │  │
                    │  └────────────┬─────────────┘  │
                    │               │                │
                    │       ┌───────▼────────┐       │
                    │       │      AKS        │       │
                    │       │                 │       │
                    │       │ Private Cluster │       │
                    │       │ Entra ID        │       │
                    │       │ OIDC            │       │
                    │       │ 2 Node Pools    │       │
                    │       └───────┬─────────┘       │
                    │               │                 │
                    │               ▼                 │
                    │       ┌────────────────┐        │
                    │       │      ACR        │        │
                    │       │                 │        │
                    │       │ Private access  │        │
                    │       │ Geo-replication │        │
                    │       └────────────────┘        │
                    │                                │
                    │  ┌──────────────────────────┐  │
                    │  │       Key Vault          │  │
                    │  │                          │  │
                    │  │       des-key            │  │
                    │  │          │               │  │
                    │  └──────────┼───────────────┘  │
                    │             │                  │
                    │             ▼                  │
                    │  ┌──────────────────────────┐  │
                    │  │ Disk Encryption Set      │  │
                    │  │                          │  │
                    │  │ Managed Identity         │  │
                    │  └──────────────────────────┘  │
                    │                                │
                    │  ┌──────────────────────────┐  │
                    │  │ Log Analytics             │  │
                    │  │ Container Insights        │  │
                    │  └──────────────────────────┘  │
                    │                                │
                    └────────────────────────────────┘

3. CI/CD and Infrastructure Provisioning Flow
The infrastructure deployment follows this workflow:
Developer
   │
   ▼
GitHub feature branch
   │
   ▼
Azure DevOps Pipeline
   │
   ├── Checkout
   ├── Terraform installation
   ├── Terraform initialization
   ├── Terraform validation
   ├── Checkov security scanning
   ├── Gitleaks scanning
   ├── Terraform plan
   └── Terraform apply
            │
            ▼
        Azure
The pipeline uses Microsoft Entra ID Workload Identity Federation rather than storing a long-lived Azure client secret in the pipeline.

4. Authentication Architecture
Azure DevOps authenticates to Azure using Workload Identity Federation.
Azure DevOps Pipeline
        │
        │ Federated identity
        ▼
Microsoft Entra ID
        │
        │ Token
        ▼
Azure Resource Manager
        │
        ▼
Terraform

5. Network Architecture
The platform uses an Azure Virtual Network with dedicated subnets and network security groups.
The AKS cluster is configured as a private cluster.
VNet
│
├── AKS subnet
│
├── Management subnet
│
└── Private Endpoint subnet
        │
        └── Key Vault Private Endpoint

Network security groups are used to control traffic associated with the platform subnets.
The AKS API server is accessed through a private endpoint rather than exposing a public Kubernetes API endpoint.
6. Azure Kubernetes Service
The AKS cluster is:
Private
Standard tier
Entra ID integrated
Local Kubernetes accounts disabled
OIDC issuer enabled
Azure CNI based
Configured with two node pools
Integrated with Azure Container Registry
Integrated with Log Analytics / Container Insights
Node pools
The cluster contains:
System node pool
User/application node pool
The system node pool is configured for critical cluster components, while the user node pool is intended for application workloads.
Managed OS disks are used for the node pools.

7. Microsoft Entra ID Integration
AKS authentication uses Microsoft Entra ID.
An Entra security group is used for AKS administrator access:

Fdic-aks-admins
The group is configured as the AKS administrator group.
The AKS local account is disabled so that access is managed through Entra ID instead of the built-in Kubernetes administrator credentials.

8. OpenID Connect (OIDC)
The AKS OIDC issuer is enabled:

oidc_issuer_enabled = true
OIDC provides the foundation for Kubernetes workload identity scenarios and avoids relying on long-lived credentials for workloads that need access to Azure resources.

9. Azure Container Registry
Azure Container Registry provides the container image registry for the AKS platform.
The registry:
Uses Premium SKU
Has administrator access disabled
Uses private network access configuration
Uses zone redundancy
Uses geo-replication
Is integrated with AKS through Azure RBAC
The AKS cluster is granted the AcrPull permission required to retrieve container images.
The registry currently has replicas in:
East US
West US 2

10. Azure Key Vault
Azure Key Vault is used for cryptographic key management.
The environment contains:

Fdic-dev-kv
The Key Vault is protected using private networking through a private endpoint.

11. Disk Encryption Set
The platform uses an Azure Disk Encryption Set:
Fdic-dev-des
The Disk Encryption Set uses a user-assigned managed identity to access the customer-managed key stored in Azure Key Vault.
The relationship is:
Key Vault
    │
    │ Customer-managed key
    ▼
Disk Encryption Set
    │
    │ Encryption configuration
    ▼
Azure managed disks / AKS infrastructure
This provides customer-managed encryption at rest for the AKS platform.

12. Monitoring and Observability
Azure Log Analytics provides centralized monitoring.
The environment contains:
Fdic-dev-law
Container Insights is enabled for AKS monitoring.
The monitoring architecture is:
AKS
 │
 ▼
Container Insights
 │
 ▼
Log Analytics
 │
 ▼
Centralized logs / metrics / diagnostics

13. Infrastructure as Code
All primary infrastructure resources are managed through Terraform.
The Terraform configuration is organized into reusable modules.
infra/
└── terraform/
    ├── environments/
    │   ├── dev/
    │   ├── stage/
    │   └── prod/
    │
    └── modules/
        ├── acr/
        ├── aks/
        ├── appgw_waf/
        ├── des/
        ├── key_vault/
        ├── log_analytics/
        ├── network/
        └── rg/
This structure separates environment-specific configuration from reusable infrastructure modules.

14. Security Architecture
Security controls implemented in the platform include:
Microsoft Entra ID authentication
Azure DevOps Workload Identity Federation
Disabled AKS local accounts
Private AKS cluster
Private Key Vault endpoint
Azure RBAC
Customer-managed encryption key
Disk Encryption Set
Network Security Groups
ACR administrator access disabled
Checkov infrastructure security scanning
Gitleaks secret scanning
Centralized monitoring through Log Analytics

15. Resource Inventory
Resource Group
Fdic-dev-rg
fdic-dev-vnet
fdicdevacr
fdic-dev-kv
fdic-dev-kv-pe
fdic-dev-des
fdic-dev-des-uai
fdic-dev-aks
fdic-dev-law

Network security groups
fdic-dev-vnet-aks-nsg
fdic-dev-vnet-management-nsg
fdic-dev-vnet-private_endpoints-nsg
ACR replication
East US
West US 2
16. Deployment State
The development environment has been successfully provisioned through the Azure DevOps Terraform pipeline.
AKS verification:
Cluster operation status: Succeeded
Power state: Running
Kubernetes version: 1.35.7
Pricing tier: Standard
Node pools: 2
Network configuration: Azure CNI
Private API server endpoint: Enabled
Encryption at rest with customer-managed key: Enabled

17. Design Principles
The platform follows these design principles:
Security by default
Infrastructure is provisioned with private networking, RBAC, Entra ID authentication, encryption, and secret-management controls.
Infrastructure as Code
Infrastructure changes are managed through Terraform rather than manual portal configuration wherever practical.
Federated authentication
Azure DevOps uses Workload Identity Federation to authenticate to Azure without relying on long-lived client secrets.
Least privilege
Azure RBAC is used to provide identities with the permissions required to perform their intended operations.
Reusable modules
Terraform modules separate reusable infrastructure components from environment-specific configuration.
Observable infrastructure
AKS and container workloads are integrated with Azure monitoring through Log Analytics and Container Insights.
Controlled deployment
Terraform plan artifacts are generated during the CI/CD process and the deployment stage applies the generated plan.
