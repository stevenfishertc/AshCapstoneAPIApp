#!/bin/bash
# Cleanup failed Prometheus/Grafana installation

set -e

echo "=========================================="
echo "Cleaning up failed monitoring installation"
echo "=========================================="

# Delete Helm release if it exists
echo "Removing Helm release..."
helm uninstall prometheus -n monitoring 2>/dev/null || echo "No Helm release found"

# Delete namespace (this will delete all resources)
echo "Deleting monitoring namespace..."
kubectl delete namespace monitoring --timeout=60s 2>/dev/null || echo "Namespace already deleted or doesn't exist"

# Wait for namespace deletion
echo "Waiting for namespace to be fully deleted..."
kubectl wait --for=delete namespace/monitoring --timeout=120s 2>/dev/null || echo "Namespace deleted"

echo ""
echo "=========================================="
echo "✅ Cleanup complete! Ready for fresh installation."
echo "=========================================="
