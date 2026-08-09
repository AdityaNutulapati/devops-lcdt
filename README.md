# DevOps Assignment - E2E Microservice Deployment

Production-ready Kubernetes deployment on AWS EKS with complete Infrastructure as Code, GitOps, and observability.

##  Architecture

**Cloud**: AWS (ap-south-2 - Hyderabad)  
**Cluster**: EKS 1.36 with 4 nodes across 2 Availability Zones  
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
- **Node Groups**: 4 t3.micro instances
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

### Port Forward All Services

```bash
./scripts/port-forward-all.sh
```

### Individual Services

| Service | Command | URL |
|---------|---------|-----|
| **Grafana** | `kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80` | http://localhost:3000 |
| **Prometheus** | `kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090` | http://localhost:9090 |
| **ArgoCD** | `kubectl port-forward -n argocd svc/argocd-server 8080:443` | http://localhost:8080 |
| **Hello-World** | `kubectl port-forward -n default svc/hello-world 8081:80` | http://localhost:8081 |
| **Loki** | `kubectl port-forward -n monitoring svc/loki 3100:3100` | http://localhost:3100 |

### Credentials

**Grafana**: admin / changeme-use-secret-in-production  
**ArgoCD**: admin / `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

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

### Alerts

- Custom alert rules in `monitoring/alerts/custom-alerts.yaml`
- 12 alert rules covering application, deployment, and node health
- Visible in Prometheus UI

---

##  CI/CD Pipeline

### CI Workflow (`.github/workflows/ci.yaml`)

Triggers on: Push to main, PRs

**Steps:**
1. Lint Go code
2. Run tests
3. Build Docker image
4. Scan image with Trivy
5. Push to ECR
6. Lint Helm charts
7. Validate Terraform

### CD Workflow (`.github/workflows/cd.yaml`)

Triggers on: Push to main (after CI)

**Steps:**
1. Deploy infrastructure (Terraform)
2. Configure kubectl
3. Install ArgoCD
4. Bootstrap monitoring stack
5. Deploy applications
6. Apply custom alerts
7. Verify deployments

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
├── scripts/                # Helper scripts
│   ├── port-forward-all.sh
│   └── PORT-FORWARD-GUIDE.md
└── docs/                   # Documentation
    ├── architecture.md
    └── runbook.md
```

---

##  Key Features

### High Availability

-  Multi-AZ deployment (2 availability zones)
-  Multi-replica application (2-6 replicas with HPA)
-  Load balancing across pods
-  Health checks (liveness + readiness probes)

### Security

-  Private subnets for worker nodes
-  NAT Gateway for outbound-only internet
-  IAM roles with least privilege
-  IRSA (IAM Roles for Service Accounts)
-  Security groups for network isolation
-  Container image scanning (Trivy)
-  Non-root containers

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
| 4× t3.micro nodes | ~$12/month |
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
- **Port Forwarding**: See `scripts/PORT-FORWARD-GUIDE.md` for access guide

---

##  Design Decisions

### Why t3.micro?

- Free tier eligible
- Sufficient for demo/learning
- Production would use t3.medium or larger

### Why EmptyDir instead of EBS?

- No persistent storage costs
- Simpler setup
- Acceptable for demo (data loss on pod restart)
- Production would use EBS with backups

### Why Alertmanager Disabled?

- Saves resources (~50-100 MB)
- Alerts still evaluated by Prometheus
- Can be enabled when needed
- Production would enable with notifications

### Why Single NAT Gateway?

- Cost optimization (~$32/month vs $64)
- Single point of failure acceptable for demo
- Production would use NAT per AZ

---

##  Troubleshooting

### Pods Not Starting

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### Port Forward Fails

```bash
# Kill existing port forwards
pkill -f "kubectl port-forward"

# Restart
./scripts/port-forward-all.sh
```

### ArgoCD Not Syncing

```bash
kubectl get application -n argocd
kubectl describe application <app-name> -n argocd
```

### Terraform State Locked

```bash
# Check DynamoDB for lock
aws dynamodb scan --table-name lcdt-terraform-lock --profile lcdt

# Force unlock (use carefully)
terraform force-unlock <lock-id>
```

---

##  Assignment Requirements Met

 **Reusable Infrastructure**: Terraform modules  
 **High Availability**: Multi-AZ, multi-replica, HPA  
 **Security**: Private subnets, IAM, IRSA, scanning  
 **Observability**: Prometheus, Grafana, Loki, alerts  
 **Documentation**: Architecture, runbook, README  
 **CI/CD**: GitHub Actions for automated deployment  
 **GitOps**: ArgoCD for continuous deployment  

---

##  Contributing

This is an assignment project. For questions or improvements, please reach out.

---

##  License

This project is for educational purposes.
