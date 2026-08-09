# Port Forward Quick Reference

## All Services at Once

```bash
./scripts/port-forward-all.sh
```

This will start all port forwards in the background. Press `Ctrl+C` to stop all.

---

## Individual Service Commands

### Monitoring Stack

#### Grafana (Dashboards & Visualization)
```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```
- **URL**: http://localhost:3000
- **Credentials**: admin / changeme-use-secret-in-production

#### Prometheus (Metrics & Alerts)
```bash
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```
- **URL**: http://localhost:9090
- **Features**: Metrics, Alert Rules, Targets

#### Alertmanager (Alert Management)
```bash
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093
```
- **URL**: http://localhost:9093
- **Features**: Active Alerts, Silences, Status

#### Loki (Log Aggregation)
```bash
kubectl port-forward -n monitoring svc/loki 3100:3100
```
- **URL**: http://localhost:3100
- **API**: http://localhost:3100/loki/api/v1/query

---

### Application & GitOps

#### ArgoCD (GitOps)
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```
- **URL**: http://localhost:8080
- **Username**: admin
- **Password**: Get with:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

#### Hello-World App
```bash
kubectl port-forward -n default svc/hello-world 8081:80
```
- **URL**: http://localhost:8081
- **Endpoints**:
  - `/` - Hello World
  - `/health` - Health check
  - `/ready` - Readiness check
  - `/metrics` - Prometheus metrics

---

## Service Overview

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Grafana** | 3000 | http://localhost:3000 | Dashboards, visualization |
| **Prometheus** | 9090 | http://localhost:9090 | Metrics, alert rules |
| **Alertmanager** | 9093 | http://localhost:9093 | Alert management |
| **Loki** | 3100 | http://localhost:3100 | Log aggregation |
| **ArgoCD** | 8080 | http://localhost:8080 | GitOps deployments |
| **Hello-World** | 8081 | http://localhost:8081 | Application |

---

## Troubleshooting

### Port Already in Use
If you get "address already in use" error:

```bash
# Find process using the port (e.g., 3000)
lsof -ti:3000

# Kill the process
kill $(lsof -ti:3000)
```

### Kill All Port Forwards
```bash
pkill -f "kubectl port-forward"
```

### Check Running Port Forwards
```bash
ps aux | grep "kubectl port-forward"
```

---

## Background Port Forwards

To run port forwards in the background (survive terminal close):

```bash
# Start in background
nohup kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 > /dev/null 2>&1 &

# Check background jobs
jobs -l

# Kill specific background job
kill %1  # where 1 is the job number
```

---

## Quick Access Script

Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
alias pf-all='cd /Users/nsriaditya/Documents/adityaRepo/devops-lcdt && ./scripts/port-forward-all.sh'
alias pf-grafana='kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80'
alias pf-prometheus='kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090'
alias pf-argocd='kubectl port-forward -n argocd svc/argocd-server 8080:443'
alias pf-app='kubectl port-forward -n default svc/hello-world 8081:80'
```

Then just run: `pf-all` or `pf-grafana`
