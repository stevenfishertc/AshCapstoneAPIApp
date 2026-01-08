# ArgoCD Setup Guide

This directory contains ArgoCD configuration files for GitOps continuous delivery.

## What is ArgoCD?

ArgoCD is a declarative GitOps continuous delivery tool for Kubernetes. It monitors your Git repository and automatically synchronizes your Kubernetes resources to match the desired state defined in Git.

## Files

- `install.yaml` - ArgoCD namespace and LoadBalancer service
- `app-dev.yaml` - ArgoCD Application for DEV environment
- `app-qa.yaml` - ArgoCD Application for QA environment
- `app-prod.yaml` - ArgoCD Application for PROD environment

## Setup Instructions

### 1. Update Git Repository URLs

**IMPORTANT**: Before deploying, update the `repoURL` in these files with your actual GitHub repository URL:

- `argocd/app-dev.yaml` (line 14)
- `argocd/app-qa.yaml` (line 14)
- `argocd/app-prod.yaml` (line 14)

Replace:
```yaml
repoURL: https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git
```

With your actual repository URL, for example:
```yaml
repoURL: https://github.com/stevenfisher/AshCapstoneAPIApp.git
```

### 2. Pipeline Deployment

The Azure Pipeline will automatically:
1. Install ArgoCD on all three AKS clusters (DEV, QA, PROD)
2. Create the ArgoCD namespace
3. Deploy ArgoCD components
4. Apply the ArgoCD Application manifests for each environment

### 3. Access ArgoCD UI

After deployment, get the ArgoCD server URL and initial admin password:

```bash
# Get LoadBalancer IP (wait a few minutes for Azure to provision)
kubectl get svc argocd-server-lb -n argocd

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Then access ArgoCD UI:
- URL: `http://<LOADBALANCER_IP>`
- Username: `admin`
- Password: (from command above)

### 4. How ArgoCD Works

Once ArgoCD is deployed:

1. **Automated Sync**: ArgoCD automatically monitors your Git repository
2. **Self-Healing**: If someone manually changes resources in Kubernetes, ArgoCD will revert them to match Git
3. **Pruning**: If you delete a resource from Git, ArgoCD will delete it from Kubernetes
4. **Rollback**: You can easily rollback by reverting Git commits

### 5. Application Configuration

Each environment's ArgoCD Application is configured with:

- **Source**: Your Git repository and the environment-specific Kustomize overlay path
  - DEV: `k8s/overlays/dev`
  - QA: `k8s/overlays/qa`
  - PROD: `k8s/overlays/prod`

- **Destination**: The AKS cluster where ArgoCD is installed

- **Sync Policy**:
  - `automated: true` - Auto-sync when Git changes
  - `prune: true` - Delete resources removed from Git
  - `selfHeal: true` - Automatically fix drift from desired state

### 6. Workflow

**Before ArgoCD** (Traditional):
```
Git Commit → Pipeline builds → Pipeline runs kubectl apply → Resources deployed
```

**With ArgoCD** (GitOps):
```
Git Commit → Pipeline builds images → ArgoCD detects change → ArgoCD syncs resources
```

The pipeline only needs to build and push container images. ArgoCD handles all Kubernetes deployments automatically!

## Troubleshooting

### Check ArgoCD Status
```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
```

### View Application Status
```bash
kubectl describe application backends-dev -n argocd
```

### View Sync Logs
Check the ArgoCD UI for detailed sync logs and resource status.

### Reset Admin Password
```bash
# Generate new password hash
argocd admin initial-password -n argocd

# Or update the secret directly
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "YOUR_NEW_BCRYPT_HASH"}}'
```

## Benefits of ArgoCD

✅ **GitOps**: Git is the single source of truth
✅ **Automation**: Continuous deployment without manual kubectl commands
✅ **Visibility**: See deployment status in ArgoCD UI
✅ **Audit Trail**: All changes tracked in Git history
✅ **Rollback**: Easy rollback via Git revert
✅ **Security**: Credentials stored in Kubernetes, not in pipelines
✅ **Multi-Environment**: Manage dev/qa/prod from one place

## Next Steps

After ArgoCD is deployed, you can:
1. Monitor deployments in the ArgoCD UI
2. Remove kubectl apply commands from your pipeline (ArgoCD handles it)
3. Simply commit to Git and watch ArgoCD automatically deploy
4. Use ArgoCD CLI for advanced operations
