# DevOps Assignment - E2E Microservice Deployment

Production-ready Kubernetes deployment on AWS EKS with complete Infrastructure as Code, GitOps, and observability.

##  Architecture

**Cloud**: AWS (ap-south-2 - Hyderabad)  
**Cluster**: EKS 1.36 with 3 nodes across 2 Availability Zones  
**Network**: Custom VPC (10.20.0.0/16) with public/private subnets  
**Deployment**: GitOps using ArgoCD  
**Monitoring**: Prometheus + Grafana + Loki

### Components

- **Application**: Go microservice with Prometheus metrics
- **Infrastructure**: Terraform modules (VPC, IAM, EKS)
- **Packaging**: Helm charts
- **GitOps**: ArgoCD for continuous deployment
- **Monitoring**: Prometheus, Grafana, Loki, Promtail
- **CI/CD**: GitHub Actions

---

##  Quick Start

### Prerequisites

- AWS CLI configured with profile `lcdt`
- kubectl installed
- Terraform >= 1.0
- Helm >= 3.0

### 1. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region ap-south-2 --name aditya-eks-cluster --profile lcdt
```

### 3. Verify Cluster

```bash
kubectl get nodes
kubectl get pods -A
```

---

##  What Gets Deployed

### Infrastructure (Terraform)

- **VPC**: 10.20.0.0/16 with 2 AZs
- **Subnets**: 2 public + 2 private
- **NAT Gateway**: For private subnet internet access
- **EKS Cluster**: Kubernetes 1.36
- **Node Groups**: 3 t3.micro instances (autoscaling 3-5)
- **IAM Roles**: Cluster role, node role, IRSA for apps
- **Security Groups**: Cluster and node security

### Applications (Helm + ArgoCD)

- **hello-world**: Go microservice (2 replicas)
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Loki**: Log aggregation
- **Promtail**: Log collection
- **ArgoCD**: GitOps controller

---

##  Access Services

### Port Forward Services

| Service | Command | URL |
|---------|---------|-----|
| **ArgoCD** | `kubectl port-forward -n argocd svc/argocd-server 8081:80` | http://localhost:8081 |
| **Hello-World** | `kubectl port-forward -n default svc/hello-world 8080:80` | http://localhost:8080 |
| **Grafana** | `kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80` | http://localhost:3000 |
| **Prometheus** | `kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090` | http://localhost:9090 |
| **Loki** | `kubectl port-forward -n monitoring svc/loki 3100:3100` | http://localhost:3100 |

### Credentials

**Grafana**:
```bash
kubectl get secret grafana-admin-credentials -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
# Default: admin / admin
```

**ArgoCD**:
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d
```

---

##  Monitoring

### Metrics (Prometheus)

- Application metrics: `http_requests_total`, `http_request_duration_seconds`
- Kubernetes metrics: Pod, node, deployment status
- Retention: 7 days

### Logs (Loki)

- Centralized log aggregation from all pods
- Query via Grafana Explore
- Volume API enabled for log queries

### Dashboards (Grafana)

- Pre-configured Kubernetes dashboards
- Custom application metrics dashboard
- Log exploration via Loki datasource

---

##  CI/CD Pipeline

### CI Workflow (`.github/workflows/ci.yaml`)

Triggers on: Push to main, PRs

**Steps:**
1. Lint Go code and run tests with race detector
2. **Authenticate with AWS using OIDC** (no static credentials)
3. Build Docker image with Go 1.26
4. Scan image with Trivy (fail on CRITICAL/HIGH vulnerabilities)
5. Push to ECR (commit SHA + latest tags)
6. Lint Helm charts and validate templates
7. Validate Terraform and check formatting

### CD Workflow (`.github/workflows/cd.yaml`)

Triggers on: Push to main (after CI)

**Steps:**
1. **Assume AWS IAM role via OIDC** (GitHub Actions federation)
2. Configure kubectl for EKS cluster access
3. Trigger ArgoCD hard refresh for all applications
4. Restart hello-world deployment to pull latest image
5. Wait for rollout completion (180s timeout)
6. Verify monitoring stack health

---

##  Project Structure

```
devops-lcdt/
├── app/                    # Go microservice source
│   ├── main.go
│   ├── Dockerfile
│   └── go.mod
├── terraform/              # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf         # S3 remote state
│   └── modules/
│       ├── networking/    # VPC, subnets, NAT
│       ├── iam/          # Roles and policies
│       └── eks/          # EKS cluster and nodes
├── helm/                   # Helm charts
│   └── hello-world/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-prod.yaml
│       └── templates/
├── argocd/                 # GitOps configuration
│   ├── install-values.yaml
│   ├── project.yaml
│   └── apps/
│       ├── hello-world.yaml
│       └── monitoring.yaml
├── monitoring/             # Monitoring configs
│   ├── kube-prometheus-stack-values.yaml
│   ├── loki-simple-values.yaml
│   ├── promtail-values.yaml
│   └── alerts/
│       └── custom-alerts.yaml
├── .github/workflows/      # CI/CD pipelines
│   ├── ci.yaml
│   └── cd.yaml
└── docs/                   # Documentation
    ├── architecture.md
    ├── runbook.md
    └── TROUBLESHOOTING.md
```

---

##  Acknowledged Limitations

This is a demo/learning environment with cost optimizations. Production deployments should address:

### 1. **EKS API Endpoint Access**
- **Current**: Open to all IPs (`0.0.0.0/0`)
- **Why**: GitHub Actions runners use dynamic IPs from various ranges
- **Production Fix**: Use AWS VPC endpoints for private-only access, or GitHub self-hosted runners in your VPC

### 2. **Single NAT Gateway**
- **Current**: One NAT Gateway in a single AZ
- **Why**: Cost optimization (~$32/month per NAT Gateway)
- **Production Fix**: Deploy NAT Gateway per AZ for high availability

### 3. **Security Group Egress**
- **Current**: Unrestricted egress (`0.0.0.0/0` on all protocols)
- **Why**: Simplifies connectivity for demo purposes
- **Production Fix**: Restrict egress to specific ports (443 for HTTPS, 53 for DNS) and destinations

### 4. **Alerting**
- **Current**: Alertmanager disabled, no alert notifications
- **Why**: Cost optimization and demo simplicity
- **Production Fix**: Enable Alertmanager with receivers (Slack, PagerDuty, email)

---

##  Key Features

### High Availability

-  Multi-AZ deployment (2 AZs with topologySpreadConstraints)
-  Multi-replica application (2-6 replicas with HPA)
-  PodDisruptionBudget (minAvailable: 1)
-  Load balancing across pods
-  Health checks (liveness + readiness probes)

### Security

-  Private subnets for worker nodes
-  NAT Gateway for outbound-only internet
-  IAM roles with least privilege
-  IRSA (IAM Roles for Service Accounts)
-  Security groups for network isolation
-  Container image scanning (Trivy in CI pipeline)
-  Non-root containers (UID 65534, readOnlyRootFilesystem, drop ALL capabilities)
-  NetworkPolicy restricting ingress/egress
-  PodDisruptionBudget for voluntary disruption safety
-  **OIDC authentication** for CI/CD (GitHub Actions federation, no static AWS credentials)
-  **aws-auth ConfigMap** properly configured for IAM role-based kubectl access
-  **EKS API endpoint**: Currently open (0.0.0.0/0) for GitHub Actions CI/CD - production should use IP restrictions or VPC endpoints

### Observability

-  Prometheus metrics collection
-  Grafana dashboards
-  Loki log aggregation
-  Custom alert rules
-  ServiceMonitor for auto-discovery

### Infrastructure as Code

-  Terraform modules (reusable)
-  S3 remote state with DynamoDB locking
-  Parameterized configurations
-  No hardcoded values

---

##  Cost Optimization

**Current monthly cost**: ~$50-60

| Resource | Cost |
|----------|------|
| EKS Cluster | $72/month |
| 3× t3.micro nodes | ~$9/month |
| NAT Gateway | ~$32/month |
| EBS Volumes (120 GB) | ~$10/month |
| S3 + DynamoDB | ~$0 (free tier) |

**Free tier eligible**: S3, DynamoDB, partial EC2

---

##  Cleanup

### Destroy Everything

```bash
# Delete Kubernetes resources
kubectl delete -f argocd/apps/
kubectl delete namespace argocd monitoring

# Destroy infrastructure
cd terraform
terraform destroy
```

### Delete S3 Backend (Optional)

```bash
aws s3 rb s3://lcdt-terraform-state-515230700333 --force --profile lcdt
aws dynamodb delete-table --table-name lcdt-terraform-lock --region ap-south-2 --profile lcdt
```

---

##  Documentation

- **Architecture**: See `docs/architecture.md` for detailed system design
- **Runbook**: See `docs/runbook.md` for operational procedures
- **Troubleshooting**: See `docs/TROUBLESHOOTING.md` for common issues and solutions
---

##  Assignment Requirements

 **Reusable Infrastructure**: Terraform modules  
 **High Availability**: Multi-AZ, multi-replica, HPA  
 **Security**: Private subnets, IAM, IRSA, scanning  
 **Observability**: Prometheus, Grafana, Loki, alerts  
 **Documentation**: Architecture, runbook, README  
 **CI/CD**: GitHub Actions for automated deployment  
 **GitOps**: ArgoCD for continuous deployment  

---

## Working screenshots
AWS Infra:
<img width="2555" height="1395" alt="image" src="https://github.com/user-attachments/assets/116b1262-76d2-42f5-b400-b1199fd49af2" />
<img width="2566" height="1220" alt="image" src="https://github.com/user-attachments/assets/a097a883-e672-411d-86b8-41e94747ced2" />
<img width="2558" height="624" alt="image" src="https://github.com/user-attachments/assets/2d8775b0-2d20-4ccb-a7ae-53e47b5ae1a5" />

GitHub Actions CI/CD:
<img width="2556" height="813" alt="image" src="https://github.com/user-attachments/assets/48621678-124b-4084-a711-b9921a1b67a4" />


ArgoCD:
<img width="2570" height="1388" alt="image" src="https://github.com/user-attachments/assets/c43bb14f-5229-4d6b-be3d-e24100f5f2b4" />

Grafana:
<img width="2559" height="1309" alt="image" src="https://github.com/user-attachments/assets/2df2cb80-1b51-47b4-bb44-8dc28b44bcf5" />
<img width="1806" height="1237" alt="image" src="https://github.com/user-attachments/assets/86c72788-c051-4be4-a13f-3ca2619df808" />


Prometheus:
<img width="2547" height="820" alt="image" src="https://github.com/user-attachments/assets/9d77f087-a3d6-4255-9c28-f366c6495527" />

Loki:
<img width="2558" height="1283" alt="image" src="https://github.com/user-attachments/assets/4a368ce6-6aad-49e7-9ea3-58ce183442be" />
<img width="2562" height="1398" alt="image" src="https://github.com/user-attachments/assets/56f4b72c-d8c6-4596-bdca-a953c4e16c33" />

---

##  Contributing

This is an assignment project. For questions or improvements, please reach out.

---

##  License

This project is for educational purposes.
