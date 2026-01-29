## Security Controls

The platform follows a layered DevSecOps security approach.

- **SAST**: GitHub CodeQL is enforced on all pull requests to detect common vulnerabilities and insecure coding patterns.
- **Dependency Scanning (SCA)**: Dependabot monitors application and pipeline dependencies and opens automated pull requests for known vulnerabilities.
- **Infrastructure Security (Planned)**: Terraform and Helm configurations will be scanned using infrastructure-as-code security tools prior to deployment.
- **Runtime & DAST (Planned)**: Dynamic security testing and runtime protections will be introduced once the platform is deployed and externally reachable.
> Note: This document will evolve as the platform moves from POC to production.
