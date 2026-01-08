# ArgoCD Pipeline Output Example

When the ArgoCD deployment stage runs, you'll see output like this in your Azure DevOps pipeline logs:

## DEV Environment Output

```
Connecting to DEV AKS cluster...
Merged "aks-capstone-dev" as current context in /home/vsts/.kube/config

Installing ArgoCD namespace...
namespace/argocd created
service/argocd-server-lb created

Installing ArgoCD components...
customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io created
[... more ArgoCD resources created ...]

Waiting for ArgoCD to be ready...
deployment.apps/argocd-server condition met

==========================================
Waiting for ArgoCD LoadBalancer IP...
==========================================
⏳ Waiting for LoadBalancer IP... (1/60)
⏳ Waiting for LoadBalancer IP... (2/60)
⏳ Waiting for LoadBalancer IP... (3/60)
✅ LoadBalancer IP acquired: 20.123.45.67

==========================================
📊 ArgoCD DEV Environment Access Info
==========================================
🌐 ArgoCD UI URL: http://20.123.45.67

👤 Login Credentials:
   Username: admin
   Password: xK9mN2pQ8vR3wL5j

==========================================
```

## QA Environment Output

```
==========================================
📊 ArgoCD QA Environment Access Info
==========================================
🌐 ArgoCD UI URL: http://20.234.56.78

👤 Login Credentials:
   Username: admin
   Password: aB7cD4eF9gH2iJ6k

==========================================
```

## PROD Environment Output

```
==========================================
📊 ArgoCD PROD Environment Access Info
==========================================
🌐 ArgoCD UI URL: http://20.345.67.89

👤 Login Credentials:
   Username: admin
   Password: mN5oP8qR3sT7uV2w

==========================================
```

## How to Use These Outputs

### 1. Copy the URL and Credentials
Simply **copy and paste** the URL and password from the pipeline logs into your browser.

### 2. Access ArgoCD UI
1. Open the URL in your browser: `http://20.123.45.67`
2. Login with:
   - **Username**: `admin`
   - **Password**: (the password shown in logs)

### 3. View Your Applications
Once logged in, you'll see:
- **backends-dev** application (for DEV environment)
- **backends-qa** application (for QA environment)
- **backends-prod** application (for PROD environment)

## What If LoadBalancer IP is Not Assigned?

If you see:
```
⚠️  LoadBalancer IP not yet assigned
   Run: kubectl get svc argocd-server-lb -n argocd
```

Wait a few minutes, then run the suggested command to get the IP once Azure provisions the LoadBalancer.

## What If Password is Not Available?

If you see:
```
⚠️  Password not yet available
   Run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Wait a minute for ArgoCD to fully initialize, then run the suggested command to retrieve the password.

## Security Best Practices

⚠️ **IMPORTANT**: The initial admin password is displayed in pipeline logs and should be changed after first login!

### Change ArgoCD Admin Password

After accessing the UI for the first time:

```bash
# Connect to the cluster
az aks get-credentials --resource-group rg-capstone-dev --name aks-capstone-dev --admin

# Change password using argocd CLI
argocd account update-password \
  --current-password <initial-password> \
  --new-password <your-new-password>
```

Or use the ArgoCD UI:
1. Click on **User Info** (top right)
2. Click **Update Password**
3. Enter current password and new password

## Bookmark These URLs

For easy access, bookmark the ArgoCD UI URLs for each environment:
- **DEV**: http://20.123.45.67 (example IP)
- **QA**: http://20.234.56.78 (example IP)
- **PROD**: http://20.345.67.89 (example IP)

## Next Steps

Once you have access to the ArgoCD UI:
1. ✅ Verify all applications show as "Synced" and "Healthy"
2. ✅ Click on an application to see the resource tree
3. ✅ Make a change to your Git repo and watch ArgoCD auto-deploy
4. ✅ Test self-healing by manually changing a resource
