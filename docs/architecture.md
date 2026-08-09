# Architecture

## Network Topology

```
┌─────────────────────────────────────────────────────────────────────┐
│  AWS Account: 515230700333  |  Region: ap-south-2 (Hyderabad)      │
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
- **Cluster endpoint**: Private access enabled; public access restricted by CIDR allowlist
- **IAM Roles**: Separate roles for cluster and nodes with minimum required AWS managed policies
- **IRSA**: Pod-level IAM via OIDC — no static credentials mounted in pods

### Application Layer
- **Distroless image**: No shell, no package manager, no OS utilities — minimal attack surface
- **Non-root execution**: Container runs as UID 65534 (nobody)
- **Read-only root filesystem**: No writes allowed to container filesystem
- **Capabilities dropped**: All Linux capabilities dropped via securityContext
- **Seccomp**: RuntimeDefault seccomp profile applied
- **NetworkPolicy**: Ingress restricted to port 8080 only; egress unrestricted (for metrics, DNS)
- **Resource limits**: CPU and memory limits prevent resource exhaustion

### CI/CD Security
- **OIDC authentication**: GitHub Actions uses OIDC federation — no long-lived AWS credentials stored as secrets
- **Trivy scanning**: Container images scanned for CRITICAL and HIGH vulnerabilities; build fails on findings
- **Lint**: golangci-lint static analysis catches bugs and security issues

## Monitoring Stack

```
┌──────────────────────────────────────────────────┐
│                Monitoring Namespace               │
│                                                   │
│  ┌─────────────┐   scrape    ┌───────────────┐   │
│  │ Prometheus  │◄────────────│ ServiceMonitor │   │
│  │             │             │ (hello-world)  │   │
│  └──────┬──────┘             └───────────────┘   │
│         │                                         │
│         │ datasource                              │
│         ▼                                         │
│  ┌─────────────┐                                  │
│  │  Grafana    │  ◄── Dashboard: Hello World App  │
│  │             │  ◄── Dashboard: Cluster Overview  │
│  └─────────────┘                                  │
│                                                   │
│  ┌──────────────┐                                 │
│  │ Alertmanager │  ◄── PrometheusRule             │
│  │              │      (custom-alerts.yaml)       │
│  └──────────────┘                                 │
│                                                   │
│  ┌──────────────────┐  ┌──────────────┐           │
│  │ kube-state-metrics│  │ node-exporter│           │
│  └──────────────────┘  └──────────────┘           │
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

- **Multi-AZ**: Pods spread across 2 AZs via `topologySpreadConstraints`
- **Multiple replicas**: Minimum 2 replicas (1 per AZ)
- **PodDisruptionBudget**: At least 1 pod always available during voluntary disruptions
- **HPA**: Auto-scales from 2 to 6 replicas based on CPU utilization
- **Rolling updates**: Zero-downtime deployments (maxUnavailable: 0, maxSurge: 1)
- **Managed node group**: AWS handles node health checks and replacement
- **EKS managed add-ons**: CoreDNS, kube-proxy, vpc-cni managed by AWS
