# ZavaStorefront Deployment Guide

This guide provides step-by-step instructions for deploying the ZavaStorefront web application to Azure using Azure Developer CLI (AZD).

## Quick Start

For experienced developers who want to deploy quickly:

```bash
# 1. Install Azure Developer CLI (if not installed)
curl -fsSL https://aka.ms/install-azd.sh | bash  # Linux/macOS
# or
winget install microsoft.azd  # Windows

# 2. Login to Azure
azd auth login

# 3. Initialize and deploy (from repository root)
azd up
```

That's it! The application will be provisioned and deployed to Azure in westus3 region.

## Detailed Deployment Steps

### Prerequisites

Before you begin, ensure you have:

1. **Azure Subscription**: Active subscription with Contributor permissions
2. **Azure Developer CLI**: Install from [aka.ms/install-azd](https://aka.ms/azd-install)
3. **Git**: For cloning the repository
4. **.NET 8 SDK** (optional): Only needed for local development

**Note**: You do NOT need Docker installed locally. ACR Tasks will build images in Azure.

### Step 1: Clone the Repository

```bash
git clone https://github.com/seilorjunior/TechWorkshop-L300-GitHub-Copilot-and-platform.git
cd TechWorkshop-L300-GitHub-Copilot-and-platform
```

### Step 2: Authenticate with Azure

```bash
azd auth login
```

This opens a browser window to sign in to your Azure account.

### Step 3: Initialize the Environment

```bash
azd init
```

You'll be prompted to provide:
- **Environment name**: e.g., `dev`, `staging`, `prod`
- **Azure subscription**: Select from your available subscriptions
- **Location**: Confirm or select `westus3`

This creates a `.azure/{env-name}/.env` file with your configuration.

### Step 4: Provision Azure Resources

```bash
azd provision
```

This command deploys:
- Resource Group (westus3)
- Azure Container Registry
- App Service Plan (Linux)
- App Service (Linux with container support)
- Application Insights + Log Analytics Workspace
- Azure AI Services (GPT-4 and Phi models)
- RBAC role assignments

**Duration**: ~5-10 minutes

### Step 5: Deploy the Application

```bash
azd deploy
```

This command:
1. Builds Docker image using ACR Tasks
2. Pushes image to ACR
3. Updates App Service configuration
4. Restarts App Service with new image

**Duration**: ~3-5 minutes

### Step 6: Access Your Application

Get the application URL:

```bash
azd show
```

Or check the output variable:

```bash
azd env get-values | grep AZURE_APP_SERVICE_URL
```

Open the URL in your browser to see the running application.

## Alternative: Single Command Deployment

To provision and deploy in one command:

```bash
azd up
```

This runs `azd provision` followed by `azd deploy`.

## Monitoring and Management

### View Application Logs

Stream live logs from App Service:

```bash
az webapp log tail --name <app-service-name> --resource-group <resource-group-name>
```

Or use the Azure Portal:
1. Navigate to your App Service
2. Go to Monitoring → Log stream

### Open Application Insights

```bash
azd monitor
```

This opens Application Insights in your browser for detailed telemetry.

### View Environment Configuration

```bash
azd env get-values
```

### Update Application

After making code changes:

```bash
azd deploy
```

This rebuilds and redeploys only the application (no infrastructure changes).

## Infrastructure Updates

If you modify Bicep templates in `infra/`:

```bash
azd provision
```

This updates the infrastructure without redeploying the application.

To update both:

```bash
azd up
```

## Cleaning Up

To delete all Azure resources:

```bash
azd down
```

You'll be prompted to confirm deletion. This removes:
- Resource group and all contained resources
- All data (this is irreversible!)

## Troubleshooting

### Deployment Fails with "Location Not Available"

Some Azure services may not be available in westus3. Edit `infra/main.bicep` to use a different location:

```bicep
param location string = 'westus'  // or 'eastus', 'westeurope', etc.
```

### Container Failed to Start

1. Check container logs:
   ```bash
   az webapp log tail --name <app-name> --resource-group <rg-name>
   ```

2. Verify App Service can pull from ACR:
   ```bash
   az webapp config show --name <app-name> --resource-group <rg-name> --query "siteConfig"
   ```

3. Check ACR role assignment:
   ```bash
   az role assignment list --scope /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.ContainerRegistry/registries/{acr}
   ```

### "No Dockerfile Found" Error

Ensure you're running commands from the repository root directory (where `azure.yaml` is located).

### AI Model Deployment Issues

GPT-4 or Phi-3 models may not be available in your region. Options:
1. Change region in `infra/main.bicep`
2. Remove AI Services deployment temporarily
3. Use different model versions

Edit `infra/modules/ai-foundry.bicep` to adjust model deployments.

## Environment Variables

The following environment variables are automatically set by AZD:

| Variable | Description |
|----------|-------------|
| `AZURE_LOCATION` | Deployment region (westus3) |
| `AZURE_CONTAINER_REGISTRY_ENDPOINT` | ACR login server URL |
| `AZURE_CONTAINER_REGISTRY_NAME` | ACR resource name |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights connection |
| `AZURE_APP_SERVICE_NAME` | App Service resource name |
| `AZURE_APP_SERVICE_URL` | Public application URL |
| `AZURE_AI_FOUNDRY_ENDPOINT` | AI Services endpoint |
| `AZURE_AI_FOUNDRY_NAME` | AI Services resource name |

## CI/CD Integration

### GitHub Actions

AZD can generate GitHub Actions workflows:

```bash
azd pipeline config
```

This creates `.github/workflows/azure-dev.yml` for automated deployments.

### Azure DevOps

```bash
azd pipeline config --provider azdo
```

This creates Azure Pipelines YAML for automated deployments.

## Advanced Configuration

### Change App Service SKU

Edit `infra/main.bicep`:

```bicep
module appServicePlan './modules/app-service-plan.bicep' = {
  params: {
    sku: {
      name: 'P1v3'      // Production tier
      tier: 'PremiumV3'
    }
  }
}
```

### Enable VNet Integration

Uncomment VNet sections in `infra/main.bicep` and add VNet module.

### Add Custom Domain

After deployment, configure custom domain in Azure Portal:
1. App Service → Custom domains
2. Add custom domain
3. Configure DNS records

### Enable Auto-scaling

Edit `infra/modules/app-service-plan.bicep` to add auto-scale rules.

## Security Best Practices

This deployment follows Azure security best practices:

✅ **Managed Identity**: No credentials stored  
✅ **RBAC**: Role-based access control for ACR  
✅ **HTTPS Only**: Encrypted traffic  
✅ **TLS 1.2+**: Modern encryption  
✅ **No Admin Passwords**: ACR admin user disabled  
✅ **Private Connections**: Can be enabled via VNet integration  

## Cost Management

**Estimated monthly cost (Development)**:
- App Service (B1): ~$13
- Container Registry (Basic): ~$5
- Application Insights: ~$2-10 (usage-based)
- Log Analytics: ~$2-5 (usage-based)
- AI Services: ~$10-50 (usage-based)

**Total: ~$32-83/month**

To reduce costs:
- Use smaller App Service SKU (Free tier available)
- Delete resources when not in use: `azd down`
- Monitor usage in Azure Cost Management

## Next Steps

After successful deployment:

1. **Set up CI/CD**: Run `azd pipeline config`
2. **Configure monitoring**: Set up alerts in Application Insights
3. **Add custom domain**: Configure DNS and SSL
4. **Enable scaling**: Configure auto-scale rules
5. **Review security**: Run Azure Security Center recommendations

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Infrastructure README](./infra/README.md)
- [Application README](./src/README.md)
- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)

## Support

For issues or questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review infrastructure README: [infra/README.md](./infra/README.md)
3. Open an issue in the repository
4. Contact the development team

---

**Happy Deploying! 🚀**
