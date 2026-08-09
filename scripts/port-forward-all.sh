#!/bin/bash
# Port Forward All Services
# Run this script to access all monitoring and application services locally

echo "🚀 Starting port forwards for all services..."
echo ""
echo "Services will be available at:"
echo "  📊 Grafana:        http://localhost:3000  (admin / changeme-use-secret-in-production)"
echo "  📈 Prometheus:     http://localhost:9090"
echo "  🔔 Alertmanager:   http://localhost:9093"
echo "  📝 Loki:           http://localhost:3100"
echo "  🎯 ArgoCD:         http://localhost:8080  (admin / <get password>)"
echo "  🌐 Hello-World:    http://localhost:8081"
echo ""
echo "Press Ctrl+C to stop all port forwards"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping all port forwards..."
    jobs -p | xargs -r kill 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start all port forwards in background
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093 &
kubectl port-forward -n monitoring svc/loki 3100:3100 &
kubectl port-forward -n argocd svc/argocd-server 8080:443 &
kubectl port-forward -n default svc/hello-world 8081:80 &

# Wait for all background jobs
wait
