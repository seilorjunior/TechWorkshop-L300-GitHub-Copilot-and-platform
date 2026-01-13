# Azure Infrastructure for ZavaStorefront

This folder contains the Bicep templates and modules for provisioning Azure infrastructure for the ZavaStorefront application.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Resource Group: rg-zavastore-dev-westus3             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│  │   Azure AI      │    │  Log Analytics  │    │  Application    │    │
│  │   Services      │    │   Workspace     │◄───│   Insights      │    │
│  │  (GPT-4, Phi)   │    │                 │    │                 │    │
│  └─────────────────┘    └─────────────────┘    └────────▲────────┘    │
│                                                         │              │
│  ┌─────────────────┐         ┌──────────────────────────┴──────┐      │
│  │     Azure       │         │         Web App for             │      │
│  │   Container     │◄────────│         Containers              │      │
│  │   Registry      │  AcrPull│      (Linux App Service)        │      │
│  │                 │  (RBAC) │                                 │      │
│  └─────────────────┘         └──────────────────────────────────┘      │
│                                          │                             │
│                                          ▼                             │
│                              ┌──────────────────────┐                  │
│                              │   User Assigned      │                  │
│                              │  Managed Identity    │                  │
│                              └──────────────────────┘                  │
│                                                                         │
│  ┌─────────────────┐                                                   │
│  │  App Service    │                                                   │
│  │     Plan        │                                                   │
│  │    (Linux)      │                                                   │
│  └─────────────────┘                                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Resources Provisioned

| Resource | Type | SKU | Purpose |
|----------|------|-----|---------|
| Resource Group | Microsoft.Resources/resourceGroups | - | Container for all resources |
| User Assigned Managed Identity | Microsoft.ManagedIdentity/userAssignedIdentities | - | Secure authentication for Web App to ACR |
| Azure Container Registry | Microsoft.ContainerRegistry/registries | Basic | Store Docker container images |
| App Service Plan | Microsoft.Web/serverfarms | B1 | Linux hosting plan |
| Web App for Containers | Microsoft.Web/sites | - | Host the containerized application |
| Log Analytics Workspace | Microsoft.OperationalInsights/workspaces | PerGB2018 | Centralized logging |
| Application Insights | Microsoft.Insights/components | - | Application monitoring |
| Azure AI Services | Microsoft.CognitiveServices/accounts | S0 | AI/ML models (GPT-4, Phi) |

## Folder Structure

```
infra/
├── main.bicep                  # Main deployment template (subscription scope)
├── main.parameters.json        # Default parameters for deployment
├── abbreviations.json          # Resource naming abbreviations
└── modules/
    ├── identity.bicep          # User Assigned Managed Identity
    ├── log-analytics.bicep     # Log Analytics Workspace
    ├── app-insights.bicep      # Application Insights
    ├── container-registry.bicep # Azure Container Registry
    ├── app-service-plan.bicep  # App Service Plan (Linux)
    ├── web-app.bicep           # Web App for Containers
    ├── role-assignment-acr.bicep # ACR Pull role assignment
    ├── ai-services.bicep       # Azure AI Services (Foundry)
    └── diagnostic-settings.bicep # Diagnostic settings for Web App
```

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Azure Developer CLI (azd) installed (`winget install microsoft.azd`)
- Azure subscription with required quotas in westus3

## Deployment

### Using Azure Developer CLI (Recommended)

```bash
# Initialize the environment
azd init

# Set environment variables
azd env set AZURE_LOCATION westus3

# Provision infrastructure
azd provision

# Build and deploy the application
azd deploy
```

### Using Azure CLI

```bash
# Set variables
LOCATION="westus3"
ENV_NAME="zavastore-dev"

# Create deployment
az deployment sub create \
  --location $LOCATION \
  --template-file infra/main.bicep \
  --parameters environmentName=$ENV_NAME location=$LOCATION
```

## Security Features

1. **Managed Identity Authentication**: Web App uses User Assigned Managed Identity to pull images from ACR
2. **No Password Secrets**: ACR admin user is disabled; authentication uses RBAC
3. **HTTPS Only**: Web App enforces HTTPS connections
4. **TLS 1.2 Minimum**: Modern TLS version enforced
5. **FTPS Only**: Secure file transfer only

## Monitoring

- **Application Insights**: Connected via `APPLICATIONINSIGHTS_CONNECTION_STRING`
- **Diagnostic Settings**: HTTP logs, console logs, app logs, and platform logs sent to Log Analytics
- **Metrics**: All metrics collected in Log Analytics

## Estimated Costs (Dev Environment)

| Resource | Estimated Monthly Cost |
|----------|----------------------|
| App Service Plan (B1) | ~$13 |
| Container Registry (Basic) | ~$5 |
| Log Analytics | ~$2-5 (usage-based) |
| Application Insights | ~$0-5 (usage-based) |
| AI Services | Pay-per-use |
| **Total** | **~$20-30/month** |

## CI/CD Workflows

Two GitHub Actions workflows are provided:

1. **provision-infrastructure.yml**: Provisions all Azure resources
2. **build-deploy.yml**: Builds container image in cloud (ACR Tasks) and deploys to Web App

### Required GitHub Secrets/Variables

| Name | Type | Description |
|------|------|-------------|
| `AZURE_CLIENT_ID` | Secret | Service Principal/App Registration Client ID |
| `AZURE_TENANT_ID` | Secret | Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Variable | Azure Subscription ID |
| `AZURE_ENV_NAME` | Variable | Environment name (e.g., zavastore-dev-westus3) |

## Next Steps

1. Deploy GPT-4 and Phi models in Azure AI Services
2. Configure model deployments via Azure Portal or CLI
3. Update application to use AI Services endpoint
