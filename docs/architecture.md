# Architecture

## Network Topology

```
┌─────────────────────────────────────────────────────────────────────┐
│  AWS Account: <AWS_ACCOUNT_ID>  |  Region: ap-south-2 (Hyderabad)  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  VPC: aditya-vpc (10.20.0.0/16)                             │    │
│  │                                                              │    │
│  │  ┌──────────────────────────┐  ┌──────────────────────────┐ │    │
│  │  │ Public Subnet 1          │  │ Public Subnet 2          │ │    │
│  │  │ 10.20.1.0/24 (2a)       │  │ 10.20.3.0/24 (2b)       │ │    │
│  │  │                          │                               │    │
│  │  │  ┌─────┐  ┌──────────┐  │                               │    │
│  │  │  │ IGW │  │ NAT GW   │  │                               │    │
│  │  │  └──┬──┘  └────┬─────┘  │                               │    │
│  │  └─────┼──────────┼────────┘                               │    │
│  │        │          │                                         │    │
│  │  ┌─────┼──────────┼────────┐  ┌──────────────────────────┐ │    │
│  │  │ Private Subnet 1        │  │ Private Subnet 2          │ │    │
│  │  │ 10.20.0.0/24 (2a)      │  │ 10.20.2.0/24 (2b)        │ │    │
│  │  │                         │  │                            │ │    │
│  │  │  ┌───────────────────┐  │  │  ┌───────────────────┐    │ │    │
│  │  │  │ EKS Worker Node 1 │  │  │  │ EKS Worker Node 2 │    │ │    │
│  │  │  │                   │  │  │  │                    │    │ │    │
│  │  │  │ ┌──────────────┐  │  │  │  │ ┌──────────────┐   │    │ │    │
│  │  │  │ │Hello World   │  │  │  │  │ │Hello World   │   │    │ │    │
│  │  │  │ │Pod (replica) │  │  │  │  │ │Pod (replica) │   │    │ │    │
│  │  │  │ └──────────────┘  │  │  │  │ └──────────────┘   │    │ │    │
│  │  │  │ ┌──────────────┐  │  │  │  │ ┌──────────────┐   │    │ │    │
│  │  │  │ │Prometheus    │  │  │  │  │ │Grafana       │   │    │ │    │
│  │  │  │ └──────────────┘  │  │  │  │ └──────────────┘   │    │ │    │
│  │  │  └───────────────────┘  │  │  └───────────────────┘    │ │    │
│  │  └─────────────────────────┘  └──────────────────────────┘ │    │
│  │                                                              │    │
│  │  ┌──────────────────────────────────────────────────────┐   │    │
│  │  │ EKS Control Plane (AWS Managed)                       │   │    │
│  │  │ - API Server (private + public restricted endpoint)   │   │    │
│  │  │ - etcd (encrypted with KMS)                           │   │    │
│  │  │ - Controller Manager, Scheduler                       │   │    │
│  │  └──────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

## Security Model

### Infrastructure Layer
- **VPC**: Entire network created from scratch via Terraform — VPC, IGW, 2 public + 2 private subnets, route tables
- **Private subnets**: EKS worker nodes placed exclusively in private subnets with no public IPs
- **NAT Gateway**: Single NAT GW in first public subnet provides outbound internet access for nodes
- **Security Groups**: Least-privilege rules — cluster ↔ node communication only on required ports
- **KMS Encryption**: Kubernetes secrets encrypted at rest using customer-managed KMS key with automatic rotation
- **Cluster endpoint**: Private access enabled; **public access currently open (0.0.0.0/0) for GitHub Actions CI/CD compatibility** - production deployments should restrict to specific IP ranges or use VPC endpoints
- **aws-auth ConfigMap**: GitHub Actions IAM role mapped with system:masters permissions for kubectl access from CI/CD
- **IAM Roles**: Separate roles for cluster and nodes with minimum required AWS managed policies
- **IRSA**: Pod-level IAM via OIDC — no static credentials mounted in pods

### Application Layer
- **Minimal image**: Multi-stage build with alpine:3.20 — small attack surface
- **Non-root execution**: Container runs as UID 65534 (nobody) via Dockerfile USER directive and podSecurityContext
- **Read-only root filesystem**: Enforced via `readOnlyRootFilesystem: true` in container securityContext
- **Capabilities dropped**: All Linux capabilities dropped via `capabilities.drop: [ALL]`
- **Seccomp**: RuntimeDefault seccomp profile applied via podSecurityContext
- **NetworkPolicy**: Ingress restricted to port 8080 only; egress limited to DNS (53) and HTTPS (443)
- **Resource limits**: CPU and memory limits prevent resource exhaustion

### CI/CD Security
- **OIDC authentication**: GitHub Actions uses OIDC federation via `aws_iam_openid_connect_provider` — no long-lived AWS credentials stored
- **OIDC trust policy**: Uses `StringLike` with wildcards to match GitHub's token format: `repo:AdityaNutulapati*/devops-lcdt*:ref:refs/heads/main`
- **IAM role mapping**: GitHub Actions role added to EKS `aws-auth` ConfigMap for kubectl authentication
- **Trivy scanning**: Container images scanned for CRITICAL and HIGH vulnerabilities; build fails on findings (`exit-code: 1`)
- **Go 1.26**: Latest Go version with all security patches, no known vulnerabilities
- **Scoped permissions**: CI/CD role has minimal permissions (ECR push, EKS describe)

## Monitoring Stack

```
┌──────────────────────────────────────────────────┐
│                Monitoring Namespace               │
│                                                   │
│  ┌─────────────┐   scrape    ┌───────────────┐   │
│  │ Prometheus  │◄────────────│ ServiceMonitor │   │
│  │             │             │ (hello-world)  │   │
│  │             │◄────────────│ PrometheusRule │   │
│  │             │             │ (custom-alerts)│   │
│  └──────┬──────┘             └───────────────┘   │
│         │                                         │
│         │ datasource                              │
│         ▼                                         │
│  ┌─────────────┐                                  │
│  │  Grafana    │  ◄── Dashboard: Hello World App  │
│  │             │  ◄── Dashboard: Cluster Overview  │
│  └─────────────┘                                  │
│                                                   │
│  ┌──────────────────┐  ┌──────────────┐           │
│  │ kube-state-metrics│  │ node-exporter│           │
│  └──────────────────┘  └──────────────┘           │
│                                                   │
│  Note: Alertmanager disabled for cost optimization│
│        Alerts visible in Prometheus UI only       │
└──────────────────────────────────────────────────┘
```

### Application Metrics (RED Method)
- **Rate**: `http_requests_total` — request count by method, path, status
- **Errors**: `http_requests_total{status=~"5.."}` — 5xx error count
- **Duration**: `http_request_duration_seconds` — histogram with default buckets

### Alert Categories
| Category | Alerts |
|----------|--------|
| Application | HighErrorRate (>1%), HighLatencyP99 (>500ms, >1s), NoTraffic |
| Pod/Deployment | PodCrashLooping, PodNotReady, ReplicasMismatch, HPAMaxedOut |
| Node | NodeNotReady, NodeHighCPU (>85%), NodeHighMemory (>85%), DiskAlmostFull (>85%) |

## High Availability Design

- **Multi-AZ**: Pods spread across 2 AZs via `topologySpreadConstraints` (maxSkew: 1, ScheduleAnyway)
- **Multiple replicas**: Minimum 2 replicas with HPA scaling to 6
- **PodDisruptionBudget**: `minAvailable: 1` ensures at least 1 pod during voluntary disruptions (node drain, upgrades)
- **HPA**: Auto-scales from 2 to 6 replicas based on 70% CPU utilization target
- **Managed node group**: AWS handles node health checks and replacement (update_config.max_unavailable: 1)
- **EKS managed add-ons**: CoreDNS, kube-proxy, vpc-cni managed by AWS
- **Single NAT Gateway**: Cost optimization — production would use NAT per AZ for full HA

---

## Acknowledged Limitations

This is a demo/learning environment with intentional cost optimizations and simplifications:

### 1. **EKS API Endpoint Access (0.0.0.0/0)**
- **Current State**: Public endpoint open to all IPs
- **Reason**: GitHub Actions runners use dynamic IPs from multiple ranges globally
- **Production Recommendation**: Use AWS PrivateLink VPC endpoints for private-only access, or deploy GitHub self-hosted runners within your VPC

### 2. **Single NAT Gateway**
- **Current State**: One NAT Gateway in ap-south-2a only
- **Reason**: Cost optimization (~$32/month per NAT Gateway × 2 AZs = $64/month saved)
- **Production Recommendation**: Deploy one NAT Gateway per AZ for true high availability

### 3. **Security Group Egress (0.0.0.0/0)**
- **Current State**: Both cluster and node security groups allow unrestricted egress
- **Reason**: Simplifies connectivity for demo purposes; avoids debugging egress-related issues
- **Production Recommendation**: Restrict egress to specific ports (443 for HTTPS, 53 for DNS) and known CIDR ranges
