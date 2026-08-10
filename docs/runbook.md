# Operational Runbook

## AWS CLI Setup

### Configure base credentials
```bash
aws configure --profile lcdt-base
# Enter: Access Key ID, Secret Access Key, ap-south-2, json
```

### Configure role assumption profile
Add to `~/.aws/config`:
```ini
[profile lcdt]
role_arn = arn:aws:iam::515230700333:role/lcdt-admin
source_profile = lcdt-base
region = ap-south-2
output = json
```

### Verify
```bash
aws sts get-caller-identity --profile lcdt
```

---

## Infrastructure Operations

### Terraform Plan/Apply
```bash
cd terraform
export AWS_PROFILE=lcdt
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### Update kubeconfig
```bash
aws eks update-kubeconfig --region ap-south-2 --name aditya-eks-cluster --profile lcdt
```

### Scale node group
```bash
# Via Terraform
# Edit terraform.tfvars: node_desired_size, node_min_size, node_max_size
terraform apply

# Via AWS CLI (immediate, temporary)
aws eks update-nodegroup-config \
  --cluster-name aditya-eks-cluster \
  --nodegroup-name aditya-eks-cluster-ng \
  --scaling-config minSize=2,maxSize=6,desiredSize=3 \
  --profile lcdt --region ap-south-2
```

---

## ArgoCD Operations

### Access ArgoCD UI
```bash
kubectl port-forward svc/argocd-server -n argocd 8081:80
# Open http://localhost:8081
# Username: admin
# Get password:
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d
```

### Check application sync status
```bash
# All apps
kubectl get applications -n argocd

# Specific app details
argocd app get hello-world
argocd app get monitoring
```

### Manual sync
```bash
argocd app sync hello-world
argocd app sync monitoring
```

### Disable auto-sync (for maintenance)
```bash
argocd app set hello-world --sync-policy none
# Re-enable:
argocd app set hello-world --sync-policy automated --self-heal --auto-prune
```

### Rollback via ArgoCD
```bash
# List history
argocd app history hello-world

# Rollback to specific revision
argocd app rollback hello-world <REVISION_ID>
```

### Rollback via Git (preferred GitOps approach)
```bash
# Revert the commit in git and push — ArgoCD auto-syncs
git revert HEAD
git push origin main
```

---

## Application Operations

### Deploy / Update (via GitOps)
```bash
# Build and push new image
docker build -t 515230700333.dkr.ecr.ap-south-2.amazonaws.com/lcdt/hello-world:v1.1.0 app/
docker push 515230700333.dkr.ecr.ap-south-2.amazonaws.com/lcdt/hello-world:v1.1.0

# Update image tag — ArgoCD syncs automatically
argocd app set hello-world --helm-set image.tag=v1.1.0

# Or update values-prod.yaml in git and push (preferred)
```

### Check application health
```bash
kubectl get pods -l app.kubernetes.io/name=hello-world -o wide
kubectl get svc hello-world-hello-world
kubectl get hpa
kubectl top pods -l app.kubernetes.io/name=hello-world
```

### View logs
```bash
# All pods
kubectl logs -l app.kubernetes.io/name=hello-world --tail=100 -f

# Specific pod
kubectl logs hello-world-hello-world-<hash> -f
```

### Port-forward for testing
```bash
kubectl port-forward svc/hello-world 8080:80 -n default
curl http://localhost:8080
curl http://localhost:8080/health
curl http://localhost:8080/metrics
```

---

## Monitoring Operations

### Access Grafana
```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
# Open http://localhost:3000
# Username: admin
# Get password:
kubectl get secret grafana-admin-credentials -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
# Default: admin / admin
```

### Access Prometheus
```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
# Open http://localhost:9090
```

### Check firing alerts
```bash
# Alertmanager is disabled for cost optimization
# View alerts in Prometheus UI:
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
# Open http://localhost:9090/alerts
```

### Update monitoring config
```bash
helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/kube-prometheus-stack-values.yaml

kubectl apply -f monitoring/alerts/custom-alerts.yaml -n monitoring
```

---

## Troubleshooting

### Pod won't start
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

### Image pull errors
```bash
# Check ECR login
aws ecr get-login-password --region ap-south-2 --profile lcdt | \
  docker login --username AWS --password-stdin 515230700333.dkr.ecr.ap-south-2.amazonaws.com

# Check image exists
aws ecr describe-images --repository-name lcdt/hello-world --profile lcdt --region ap-south-2
```

### Node issues
```bash
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl top nodes
```

### DNS issues
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes
```

### Network connectivity
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -qO- hello-world:80
```

### CI/CD OIDC Issues
```bash
# Check if GitHub Actions role is in aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml

# Verify IAM role trust policy
aws iam get-role --role-name aditya-eks-cluster-github-actions --profile lcdt

# Check CloudTrail for AssumeRoleWithWebIdentity events
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity --profile lcdt --region ap-south-2
```

### For detailed troubleshooting
See `docs/TROUBLESHOOTING.md` for common issues and solutions including:
- OIDC authentication failures
- Trivy vulnerability scan failures
- EKS API endpoint access issues
- kubectl authentication problems
- ArgoCD sync issues

---

## Cleanup

```bash
# 1. Remove ArgoCD applications (stops GitOps sync and deletes managed resources)
kubectl delete applications hello-world monitoring -n argocd

# 2. Remove ArgoCD
helm uninstall argocd -n argocd
kubectl delete namespace argocd

# 3. Remove monitoring namespace
kubectl delete namespace monitoring

# 4. Destroy infrastructure (includes NAT GW, EKS, IAM roles, security groups)
cd terraform
terraform destroy

# 5. (Optional) Delete ECR repository
aws ecr delete-repository --repository-name lcdt/hello-world \
  --region ap-south-2 --profile lcdt --force

# 6. (Optional) Delete Terraform state resources
aws s3 rb s3://lcdt-terraform-state-515230700333 --force --profile lcdt --region ap-south-2
aws dynamodb delete-table --table-name lcdt-terraform-lock --profile lcdt --region ap-south-2
```
