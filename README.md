


# KijaniKiosk Production Foundation

## Infrastructure-First DevOps Capstone

KijaniKiosk Production Foundation demonstrates an end-to-end production delivery platform for the KijaniKiosk payments service.

The project follows **Track A - Infrastructure-First** and combines Infrastructure as Code, configuration management, containerization, Kubernetes, CI/CD, security validation, monitoring, immutable releases, environment promotion, and operational evidence.

## Project Goals

The platform demonstrates:

- Terraform infrastructure provisioning
- Ansible environment configuration
- Docker application packaging
- Kubernetes orchestration
- Separate staging and production environments
- Jenkins CI/CD automation
- Automated linting and testing
- Dependency vulnerability auditing
- Nexus artifact publication
- Git-derived immutable container images
- Staging smoke testing
- Manual production approval
- Same-image promotion from staging to production
- Prometheus monitoring and alerting
- S3-compatible receipt processing with MinIO
- Operational evidence stored with the repository
## Architecture

The platform follows a layered production delivery architecture:

Developer / GitHub
        |
        v
     Jenkins
        |
        +--> Lint
        +--> Build
        +--> Automated Tests
        +--> Security Audit
        +--> Package Artifact
        +--> Publish to Nexus
        +--> Build Container Image
        |
        v
Kubernetes Staging
(kijani-staging)
        |
        +--> Deployment
        +--> Service
        +--> 3 Application Replicas
        +--> Smoke Test
        |
        v
Manual Production Approval
        |
        v
Kubernetes Production
(kijani-production)
        |
        +--> Deployment
        +--> Service
        +--> 3 Application Replicas
        +--> Production Verification

Supporting infrastructure includes:

- Terraform for infrastructure provisioning
- Ansible for configuration management
- Docker for application packaging
- Minikube for the Kubernetes environment
- Nexus Repository for versioned artifacts
- Prometheus for metrics and alerting
- MinIO for S3-compatible object storage
- GitHub for source control

## Technology Stack

| Area | Technology |
|---|---|
| Source Control | Git and GitHub |
| CI/CD | Jenkins |
| Infrastructure as Code | Terraform |
| Configuration Management | Ansible |
| Containers | Docker |
| Orchestration | Kubernetes / Minikube |
| Application Runtime | Node.js |
| Package Management | npm |
| Artifact Repository | Nexus Repository |
| Monitoring | Prometheus |
| Object Storage | MinIO |
| Testing | Jest |
| Security | npm audit |



## CI/CD Pipeline

The Jenkins pipeline implements a controlled delivery process from source code validation through production deployment.

### Pipeline Stages

1. **Lint**
   - Installs dependencies using `npm ci`.
   - Runs application linting.
   - Determines the current Git commit SHA.
   - Generates a version associated with the source revision.

2. **Build**
   - Builds the Node.js payments application.
   - Verifies that the expected distribution files were generated.

3. **Verify**
   - Executes automated tests.
   - Performs dependency security auditing.
   - Test and security checks are executed as verification stages before release packaging.

4. **Archive**
   - Creates a versioned npm package.
   - Archives the generated artifact in Jenkins.
   - Enables artifact fingerprinting for traceability.

5. **Publish**
   - Authenticates to Nexus using Jenkins-managed credentials.
   - Publishes the versioned npm package to the Nexus hosted repository.

6. **Build Container Image**
   - Builds the production Docker image.
   - Tags the image using the Git commit identifier.
   - Loads the image into the Minikube environment used by Kubernetes.

7. **Deploy Staging**
   - Applies the staging Kubernetes overlay.
   - Updates the `kk-payments` deployment to the newly built immutable image.
   - Waits for the Kubernetes rollout to complete.

8. **Staging Smoke Test**
   - Executes a health check against the staging service.
   - Production promotion cannot continue unless staging verification succeeds.

9. **Production Approval**
   - Jenkins pauses the pipeline.
   - A human must explicitly approve the production deployment.

10. **Deploy Production**
    - Applies the production Kubernetes overlay.
    - Promotes the exact container image tested in staging.
    - Waits for the production rollout to complete.

11. **Production Verification**
    - Executes a health check against the production service.
    - Confirms the promoted application is operational.

## Immutable Release Promotion

Container images are associated with the Git revision that produced them.

A successfully verified release used:

`kijanikiosk-payments:ecc72824`

The same image was promoted through both environments:

| Environment | Namespace | Image | Replicas |
|---|---|---|---|
| Staging | `kijani-staging` | `kijanikiosk-payments:ecc72824` | 3 |
| Production | `kijani-production` | `kijanikiosk-payments:ecc72824` | 3 |

This promotion model avoids rebuilding the application between staging and production. The artifact tested in staging is the artifact deployed to production.

## Quality and Security Gates

A release must pass multiple controls before production deployment:

- Source linting
- Application build validation
- Automated Jest tests
- Production dependency security audit
- Artifact packaging
- Nexus publication
- Container image build
- Kubernetes staging rollout
- Staging health check
- Manual production approval
- Kubernetes production rollout
- Production health verification

The dependency audit was validated with:

`npm audit --omit=dev --audit-level=high`

At the time of final validation, the production dependency audit reported:

`found 0 vulnerabilities`

The automated Jest test suite also completed successfully.
