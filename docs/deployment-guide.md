

# FDIC-Style Azure DevSecOps Deployment Guide

## 1. Purpose

This guide documents the deployment process for the FDIC-style Azure DevSecOps platform.

Infrastructure is provisioned using Terraform and deployed through Azure DevOps CI/CD using Microsoft Entra ID Workload Identity Federation.

The deployment process is designed to provide:

- Infrastructure as Code
- Automated validation
- Infrastructure security scanning
- Secret scanning
- Terraform plan review
- Controlled Terraform apply
- Repeatable Azure deployments

---

## 2. Deployment Architecture

```text
Developer
    │
    ▼
GitHub Repository
    │
    ▼
Feature Branch / Pull Request
    │
    ▼
Azure DevOps
    │
    ├── Checkout
    │
    ├── Install Terraform
    │
    ├── Terraform Init
    │
    ├── Terraform Validate
    │
    ├── Checkov
    │
    ├── Gitleaks
    │
    ├── Terraform Plan
    │
    └── Terraform Apply
    │
    ▼
Azure Subscription
    │
    └── fdic-dev-rg
3. Prerequisites
Before running the deployment, verify that the following are available:
Source Control
GitHub repository
Appropriate branch
Access to the repository
Azure
Azure subscription
Target Azure region
Required resource permissions
Microsoft Entra ID
Azure DevOps service connection using Workload Identity Federation
Development Environment
Recommended tools:
Git
Terraform
Azure CLI
Azure DevOps access

4. Repository Structure
The infrastructure is organized as reusable Terraform modules and environment-specific configurations.
fdic-style-azure-devsecops/
│
├── azure-pipelines.yml
│
├── docs/
│   ├── architecture.md
│   ├── deployment-guide.md
│   ├── infrastructure.md
│   ├── security.md
│   ├── troubleshooting.md
│   ├── disaster-recovery.md
│   └── runbooks/
│
├── infra/
│   └── terraform/
│       ├── environments/
│       │   ├── dev/
│       │   ├── stage/
│       │   └── prod/
│       │
│       └── modules/
│           ├── acr/
│           ├── aks/
│           ├── appgw_waf/
│           ├── des/
│           ├── key_vault/
│           ├── log_analytics/
│           ├── network/
│           └── rg/
│
├── scripts/
│
├── .checkov.yml
│
└── README.md
5. Azure DevOps Authentication
The Azure DevOps pipeline authenticates to Azure using Microsoft Entra ID Workload Identity Federation.
The pipeline does not rely on a long-lived Azure client secret.
The authentication flow is:
Azure DevOps
      │
      ▼
Federated Identity
      │
      ▼
Microsoft Entra ID
      │
      ▼
Azure Access Token
      │
      ▼
Terraform
      │
      ▼
Azure Resource Manager


The pipeline exports the required Azure/Terraform authentication variables during the Azure CLI deployment task.

6. Pipeline Stages
The Azure DevOps pipeline performs the following major operations.
Stage 1 — Checkout
The pipeline retrieves the selected GitHub branch.
Example:
feature/azure-devops-pipeline
The repository is checked out onto the Azure DevOps build agent.

Stage 2 — Terraform Installation
The pipeline installs the configured Terraform version on the build agent.
Terraform version is controlled by the pipeline configuration.

Stage 3 — Terraform Initialization
Terraform initializes the working directory and downloads the required providers and modules.
Example:
terraform init -reconfigure
The -reconfigure option ensures that Terraform initializes using the configured backend and provider configuration.

Stage 4 — Terraform Validation
The pipeline validates the Terraform configuration.
terraform validate
The validation step checks whether the Terraform configuration is syntactically valid and internally consistent.
A successful validation should report:
Success! The configuration is valid
.checkov.yml
to define Checkov configuration and project-specific controls.
Gitleaks
Gitleaks scans the repository for accidentally committed secrets and credentials.
The goal is to prevent credentials, tokens, and other sensitive material from reaching the deployment process.
## 7. Infrastructure Security Scanning

The pipeline performs infrastructure security scanning before deployment.

### Checkov

Checkov analyzes Terraform configuration for security and compliance issues.

The project uses:

```text
.checkov.yml


8. Terraform Plan
After validation and security scanning, Terraform generates an execution plan.


terraform plan -out=tfplan
The plan identifies:
Resources to create
Resources to update
Resources to destroy
Configuration differences
Dependency changes
The plan is stored as an artifact by Azure DevOps.
9. Plan and Apply Separation
The pipeline separates the Terraform planning and deployment operations.
Terraform Plan
      │
      ▼
tfplan
      │
      ▼
Azure DevOps Artifact
      │
      ▼
Terraform Apply
The Apply stage uses the generated Terraform plan artifact rather than generating a completely new plan.
This provides greater control over what is deployed.

10. Terraform Apply
The deployment stage downloads the Terraform plan artifact and applies the approved plan.
Conceptually:
terraform apply tfplan
Terraform then provisions or updates the Azure infrastructure.
The deployment includes the resources defined by the development environment configuration.

11. Development Environment
The current development environment is:
Environment: dev
Resource Group: fdic-dev-rg
Region: East US
The environment contains the platform infrastructure required for the FDIC-style Azure DevSecOps architecture.

12. Infrastructure Deployment Components
The deployment provisions or manages the following major components:
Resource Group
Fdic-dev-rg
Networking
Virtual Network
AKS subnet
Management subnet
Private endpoint subnet
Network Security Groups
Azure Container Registry


Fdicdevacr
The registry is integrated with AKS for container image retrieval.
The registry also uses geo-replication.
Current replicas include:
East US
West US 2
Key Vault
Fdic-dev-kv
Key Vault stores the customer-managed encryption key used by the Disk Encryption Set.
Disk Encryption Set
Fdic-dev-des
The Disk Encryption Set uses a managed identity to access the customer-managed key.
AKS
Fdic-dev-aks
The AKS cluster is configured as a private cluster and integrates with Microsoft Entra ID.
Log Analytics
Fdic-dev-law
Log Analytics provides centralized monitoring for the platform.

13. Post-Deployment Verification
After the pipeline completes successfully, verify the deployment in Azure.
Resource Group
Navigate to:
Azure Portal
→ Resource Groups
→ fdic-dev-rg
Confirm that the expected resources exist.

AKS
Navigate to:
Azure Portal
→ Kubernetes services
→ fdic-dev-aks
Verify:
Provisioning state: Succeeded
Power state: Running
Kubernetes version
Node pools
Private cluster configuration
Entra ID integration
OIDC issuer
Container Insights

Azure Container Registry
Navigate to:
Azure Portal
→ Container registries
→ fdicdevacr
Verify:
Registry availability
SKU
Replication
Network configuration
AKS integration

Key Vault
Navigate to:
Azure Portal
→ Key vaults
→ fdic-dev-kv
Verify:
Key Vault availability
Private endpoint
Customer-managed key
Access configuration

Disk Encryption Set
Navigate to:
Azure Portal
→ Disk Encryption Sets
→ fdic-dev-des
Verify:
Provisioning state
Managed identity
Key Vault key reference

Log Analytics
Navigate to:
Azure Portal
→ Log Analytics workspaces
→ fdic-dev-law
Verify that the workspace is available and connected to the AKS monitoring configuration.

14. CLI Verification
Azure CLI can also be used for post-deployment verification.
Verify subscription
az account show
Verify resource group
az group show \
  --name fdic-dev-rg \
  --output table
List resources
az resource list \
  --resource-group fdic-dev-rg \
  --output table
Verify AKS
az aks show \
  --resource-group fdic-dev-rg \
  --name fdic-dev-aks \
  --output table

az aks nodepool list \
  --resource-group fdic-dev-rg \
  --cluster-name fdic-dev-aks \
  --output table
Verify ACR
az acr show \
  --resource-group fdic-dev-rg \
  --name fdicdevacr \
  --output table
15. Deployment Failure Procedure
If the pipeline fails:
Identify the first actual error.
Determine whether the failure is:
Authentication
Authorization
Terraform configuration
Azure resource configuration
SKU or quota
Resource dependency
Azure policy
Review Terraform output.
Check the affected Azure resource.
Review Terraform state.
Correct the root cause.
Run Terraform validation.
Commit the change.
Push the change.
Allow Azure DevOps to generate a new plan.
Review the new plan.
Apply the corrected plan
Do not make unrelated infrastructure changes while troubleshooting a specific failure.

16. Terraform State Considerations
Terraform state is the source of truth used by Terraform to track managed infrastructure.
Before making manual changes to Azure resources, determine whether the resource is managed by Terraform.
Useful commands include:
terraform state list
And:
terraform state show <resource>
Avoid manually deleting Terraform-managed resources from the Azure Portal unless there is a documented recovery procedure.
Unexpected manual changes can create Terraform drift.

17. Safe Change Workflow
Infrastructure changes should follow:
Create change
     │
     ▼
Git branch
     │
     ▼
Pull Request
     │
     ▼
CI validation
     │
     ▼
Security scans
     │
     ▼
Terraform plan
     │
     ▼
Review
     │
     ▼
Merge / deployment
     │
     ▼
Terraform apply
     │
     ▼
Azure verification
18. Rollback and Recovery
Terraform does not provide a traditional application-style rollback command.
If a deployment produces an unwanted infrastructure change:
Identify the configuration change.
Revert the Terraform configuration through Git.
Generate a new Terraform plan.
Review the proposed changes.
Apply the corrected plan.
Verify the Azure resources.
For destructive or high-impact changes, obtain the required approval before applying.

19. Production Deployment Considerations
The dev environment is used for development and validation.
Before deploying equivalent infrastructure to production:
Review Terraform plan
Verify approved VM SKUs
Verify Azure subscription capabilities
Verify RBAC assignments
Verify networking requirements
Verify Key Vault permissions
Verify encryption configuration
Verify monitoring
Review security scan results
Obtain required approvals
Validate disaster recovery requirements
Production changes should not be copied blindly from development without reviewing environment-specific requirements.

20. Post-Deployment Checklist
Use this checklist after a successful deployment.
Azure DevOps
Pipeline completed successfully
Terraform validation passed
Checkov passed
Gitleaks passed
Terraform plan completed
Terraform apply completed
Azure
Resource group exists
VNet exists
Required subnets exist
NSGs exist
ACR exists
ACR replication verified
Key Vault exists
Key Vault private endpoint exists
Customer-managed key exists
Disk Encryption Set exists
AKS exists
AKS provisioning state is Succeeded
AKS power state is Running
Node pools are healthy
Entra ID integration is configured
OIDC issuer is enabled
Log Analytics exists
Container Insights is available

21. Deployment Completion Criteria
A deployment is considered successful when:
Azure DevOps pipeline completes successfully.
Terraform validation and security scans pass.
Terraform plan is successfully generated.
Terraform apply completes successfully.
Azure resources report successful provisioning.
AKS reports Succeeded and Running.
Required security and networking controls are present.
Monitoring is available.
Post-deployment verification is complete.

22. Operational Ownership
The platform engineering / DevOps team is responsible for:
Maintaining Terraform modules
Maintaining Azure DevOps pipelines
Managing infrastructure changes
Monitoring deployment failures
Reviewing security scan findings
Maintaining RBAC configuration
Supporting AKS infrastructure
Maintaining monitoring and observability
Maintaining operational runbooks
Application teams are responsible for application-level configuration and workloads deployed onto the platform.


