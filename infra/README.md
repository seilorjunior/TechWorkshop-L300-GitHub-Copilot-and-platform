# Azure Infrastructure for ZavaStorefront

This directory contains the Bicep infrastructure-as-code templates for deploying the ZavaStorefront web application to Azure using Azure Developer CLI (AZD).

## Architecture Overview

The infrastructure provisions the following Azure resources in the **westus3** region:

- **Azure Container Registry (ACR)**: Stores Docker images for the application
- **Azure App Service (Linux)**: Hosts the containerized web application
- **Application Insights**: Provides monitoring and telemetry
- **Azure AI Services (Foundry)**: Provides access to GPT-4 and Phi models
- **Log Analytics Workspace**: Backend for Application Insights
- **Resource Group**: Contains all resources

### Security Features

- **Managed Identity**: App Service uses system-assigned managed identity
- **RBAC Integration**: ACR pull access via Azure RBAC (no passwords/credentials)
- **HTTPS Only**: All traffic to App Service is HTTPS
- **Minimal TLS Version**: TLS 1.2 minimum enforced

## Prerequisites

### Required Tools

1. **Azure Developer CLI (azd)**: [Install AZD](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
   ```bash
   # Windows
   winget install microsoft.azd
   
   # macOS
   brew tap azure/azd && brew install azd
   
   # Linux
   curl -fsSL https://aka.ms/install-azd.sh | bash
   ```

2. **Azure CLI (az)**: [Install Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
   ```bash
   # Windows
   winget install -e --id Microsoft.AzureCLI
   
   # macOS
   brew update && brew install azure-cli
   
   # Linux
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

3. **Docker**: Not required locally! ACR Tasks will build images in the cloud.

4. **.NET 8 SDK**: [Install .NET 8](https://dotnet.microsoft.com/download/dotnet/8.0)

### Azure Subscription

- Active Azure subscription with appropriate permissions to create resources
- Contributor or Owner role on the subscription
- Permission to create service principals (for AZD)

## Getting Started

### 1. Initialize AZD Environment

From the repository root, initialize AZD:

```bash
azd init
```

When prompted:
- **Environment name**: Enter a name (e.g., `dev`, `staging`, `prod`)
- **Subscription**: Select your Azure subscription
- **Location**: Use `westus3` (or confirm when prompted)

This creates a `.azure/` directory with your environment configuration.

### 2. Provision Infrastructure

Deploy all Azure resources:

```bash
azd provision
```

This command:
1. Creates the resource group in westus3
2. Deploys all Bicep templates
3. Sets up role assignments for managed identity
4. Configures Application Insights
5. Provisions AI Services with GPT-4 and Phi models

Expected duration: **5-10 minutes**

### 3. Build and Deploy Application

Build the Docker image and deploy to App Service:

```bash
azd deploy
```

This command:
1. Builds the Docker image using ACR Tasks (no local Docker needed!)
2. Pushes the image to ACR
3. Updates App Service to use the new image
4. Restarts the App Service

Expected duration: **3-5 minutes**

### 4. Access the Application

After deployment, get the application URL:

```bash
azd show
```

Or visit the Azure Portal and find your App Service URL.

## AZD Workflow Commands

### Complete Deployment (Provision + Deploy)

```bash
azd up
```

This runs both `azd provision` and `azd deploy` in sequence.

### Monitor Application

```bash
azd monitor
```

Opens Application Insights in the browser to view telemetry.

### View Environment Variables

```bash
azd env get-values
```

### Clean Up Resources

```bash
azd down
```

Deletes all Azure resources in the resource group.

## Bicep Module Structure

```
infra/
├── main.bicep                      # Main orchestration template
├── abbreviations.json              # Resource naming abbreviations
├── modules/
│   ├── acr.bicep                  # Azure Container Registry
│   ├── acr-role-assignment.bicep  # RBAC for ACR pull
│   ├── app-service-plan.bicep     # App Service Plan (Linux)
│   ├── app-service.bicep          # App Service with container
│   ├── app-insights.bicep         # Application Insights + Log Analytics
│   └── ai-foundry.bicep           # Azure AI Services (GPT-4, Phi)
└── README.md                       # This file
```

### Module Descriptions

#### `acr.bicep`
- Creates Azure Container Registry with Basic SKU
- Disables admin user (uses RBAC only)
- Enables Azure Services bypass for network rules

#### `acr-role-assignment.bicep`
- Assigns AcrPull role to App Service managed identity
- Allows App Service to pull images without credentials

#### `app-service-plan.bicep`
- Creates Linux App Service Plan
- Configurable SKU (default: B1 Basic)
- Reserved for Linux containers

#### `app-service.bicep`
- Creates App Service with system-assigned managed identity
- Configures Docker container deployment from ACR
- Sets up Application Insights integration
- Enforces HTTPS and TLS 1.2

#### `app-insights.bicep`
- Creates Log Analytics Workspace
- Creates Application Insights resource
- Links Application Insights to Log Analytics

#### `ai-foundry.bicep`
- Creates Azure AI Services account
- Deploys GPT-4 model (0613 version)
- Deploys Phi-3 model (latest version)
- Note: Model availability depends on region capacity

## Configuration

### Environment Variables

AZD automatically sets these environment variables from infrastructure outputs:

- `AZURE_LOCATION`: Deployment region (westus3)
- `AZURE_CONTAINER_REGISTRY_ENDPOINT`: ACR login server URL
- `AZURE_CONTAINER_REGISTRY_NAME`: ACR resource name
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: App Insights connection string
- `AZURE_APP_SERVICE_NAME`: App Service resource name
- `AZURE_APP_SERVICE_URL`: App Service public URL
- `AZURE_AI_FOUNDRY_ENDPOINT`: AI Services endpoint
- `AZURE_AI_FOUNDRY_NAME`: AI Services resource name

### Customizing Deployment

Edit `infra/main.bicep` to customize:

- **SKU sizes**: Change App Service Plan or ACR SKU
- **AI model deployments**: Adjust capacity or add new models
- **Tags**: Add custom tags for resource organization
- **Network settings**: Configure VNet integration (advanced)

Example: Change App Service Plan to Production tier:

```bicep
module appServicePlan './modules/app-service-plan.bicep' = {
  // ...
  params: {
    sku: {
      name: 'P1v3'
      tier: 'PremiumV3'
    }
  }
}
```

## Best Practices

### 1. Resource Naming
- Uses Azure naming conventions via `abbreviations.json`
- Includes unique token to prevent name collisions
- Format: `{type}-{env}-{token}` (e.g., `app-dev-abc123`)

### 2. Security
- **No passwords**: ACR uses managed identity + RBAC
- **HTTPS enforced**: All traffic encrypted
- **TLS 1.2+**: Modern security standards
- **Managed identities**: Avoid credential management

### 3. Monitoring
- Application Insights enabled by default
- 30-day log retention
- Automatic dependency tracking
- Performance monitoring

### 4. Scalability
- Linux App Service supports easy scaling
- Container-based for consistent deployments
- Modular Bicep templates for reusability

## Troubleshooting

### AZD Command Fails

```bash
# Check AZD version
azd version

# Re-authenticate
azd auth login

# View detailed logs
azd provision --debug
```

### App Service Not Starting

1. Check container logs in Azure Portal:
   - Navigate to App Service → Monitoring → Log stream

2. Verify ACR role assignment:
   ```bash
   az role assignment list --scope /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
   ```

3. Check Application Insights for errors:
   ```bash
   azd monitor
   ```

### Build Failures

If `azd deploy` fails during build:

1. Check ACR Tasks logs in Azure Portal
2. Verify Dockerfile is valid:
   ```bash
   docker build -f Dockerfile -t test:latest ./src
   ```

3. Ensure .NET 8 SDK is referenced in Dockerfile

### AI Model Deployment Issues

If AI Services deployment fails:
- GPT-4 or Phi models may not be available in westus3
- Check [Azure AI model availability](https://learn.microsoft.com/azure/ai-services/openai/concepts/models)
- Try alternative models or regions

## Cost Estimation

**Development environment (monthly estimate):**
- App Service Plan (B1): ~$13
- Azure Container Registry (Basic): ~$5
- Application Insights: ~$2-10 (usage-based)
- Log Analytics: ~$2-5 (usage-based)
- Azure AI Services (S0): ~$10 (usage-based)

**Total: ~$32-43/month**

Use [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates.

## Additional Resources

### Azure Documentation
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure App Service](https://learn.microsoft.com/azure/app-service/)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure AI Services](https://learn.microsoft.com/azure/ai-services/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

### Best Practices
- [App Service Security Best Practices](https://learn.microsoft.com/azure/app-service/security-recommendations)
- [ACR Best Practices](https://learn.microsoft.com/azure/container-registry/container-registry-best-practices)
- [Managed Identity Best Practices](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/managed-identity-best-practice-recommendations)
- [Azure AI Responsible AI](https://learn.microsoft.com/azure/ai-services/responsible-use-of-ai-overview)

## Support

For issues or questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review [Azure Status](https://status.azure.com/)
3. Open an issue in the repository
4. Contact the development team

## License

This infrastructure code is part of the ZavaStorefront project. See [LICENSE](../LICENSE) for details.
