# Azure Infrastructure Quick Start Guide

Quick reference for common Azure infrastructure operations for ZavaStorefront.

## First Time Setup

```bash
# 1. Install Azure Developer CLI
curl -fsSL https://aka.ms/install-azd.sh | bash  # Linux/macOS
# or: winget install microsoft.azd  # Windows

# 2. Login to Azure
azd auth login

# 3. Deploy everything (from repository root)
azd up
```

## Common Commands

### Deploy Everything (Infrastructure + Application)
```bash
azd up
```

### Infrastructure Only
```bash
azd provision
```

### Application Only (after code changes)
```bash
azd deploy
```

### View Application URL
```bash
azd show
# or
azd env get-values | grep AZURE_APP_SERVICE_URL
```

### View All Environment Variables
```bash
azd env get-values
```

### Monitor Application
```bash
azd monitor
```

### Delete All Resources
```bash
azd down
```

## Troubleshooting

### View Application Logs
```bash
# Get resource names
azd env get-values

# Stream logs
az webapp log tail --name <app-name> --resource-group <rg-name>
```

### Check Deployment Status
```bash
# List recent deployments
az deployment group list --resource-group <rg-name> --output table

# Check specific deployment
az deployment group show --name <deployment-name> --resource-group <rg-name>
```

### Validate Bicep Templates
```bash
cd infra
az bicep build --file main.bicep
```

### Test Docker Build Locally
```bash
docker build -t test:latest -f Dockerfile .
docker run --rm -p 8080:8080 test:latest
```

## Configuration

### Change Deployment Region
Edit `infra/main.bicep`:
```bicep
param location string = 'eastus'  // Change from westus3
```

### Change App Service SKU
Edit `infra/main.bicep`:
```bicep
sku: {
  name: 'P1v3'      // Premium v3
  tier: 'PremiumV3'
}
```

### Disable AI Model Deployments
Edit `infra/main.bicep`:
```bicep
module aiFoundry './modules/ai-foundry.bicep' = {
  params: {
    deployGpt4: false  // Disable GPT-4
    deployPhi3: false  // Disable Phi-3
  }
}
```

## CI/CD Setup

### GitHub Actions
```bash
azd pipeline config
```

### Azure DevOps
```bash
azd pipeline config --provider azdo
```

## Resource Naming Convention

Resources follow this pattern:
- Resource Group: `rg-{env}-{token}`
- Container Registry: `cr{token}`
- App Service: `app-{env}-{token}`
- App Insights: `appi-{env}-{token}`
- AI Services: `cog-{env}-{token}`

Where:
- `{env}` = environment name (e.g., dev, staging, prod)
- `{token}` = unique hash for your subscription/environment

## Default Configurations

| Resource | Setting | Value |
|----------|---------|-------|
| Region | Location | westus3 |
| App Service Plan | SKU | B1 (Basic) |
| App Service | OS | Linux |
| App Service | Runtime | Container |
| ACR | SKU | Basic |
| ACR | Admin User | Disabled |
| App Insights | Retention | 30 days |
| AI Services | SKU | S0 (Standard) |

## Security Notes

- ✅ App Service uses system-assigned managed identity
- ✅ ACR pull access via RBAC (no passwords)
- ✅ HTTPS only with TLS 1.2 minimum
- ✅ Application Insights auto-configured
- ✅ No secrets in code or outputs

## Cost Estimates

**Development (Monthly)**
- App Service (B1): ~$13
- ACR (Basic): ~$5
- App Insights: ~$2-10 (usage)
- Log Analytics: ~$2-5 (usage)
- AI Services: ~$10-50 (usage)

**Total: ~$32-83/month**

## Support

- [Full Documentation](./README.md)
- [Deployment Guide](../DEPLOYMENT.md)
- [Application README](../src/README.md)

## Useful Links

- [Azure Developer CLI Docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Docs](https://learn.microsoft.com/azure/app-service/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
