# Azure Infrastructure Documentation

## Overview

This document provides a comprehensive overview of the Azure infrastructure for the ZavaStorefront web application.

## Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          Resource Group (westus3)                     │  │
│  │                                                        │  │
│  │  ┌─────────────────────┐                             │  │
│  │  │  App Service Plan   │                             │  │
│  │  │  (Linux, B1)        │                             │  │
│  │  └──────────┬──────────┘                             │  │
│  │             │                                         │  │
│  │  ┌──────────▼──────────────────────┐                 │  │
│  │  │  App Service                    │                 │  │
│  │  │  - Linux Container              │                 │  │
│  │  │  - System Managed Identity      │                 │  │
│  │  │  - HTTPS Only                   │◄──Pull Image──┐ │  │
│  │  └──────────┬──────────────────────┘                │ │  │
│  │             │                                        │ │  │
│  │             │ Telemetry                             │ │  │
│  │             ▼                                        │ │  │
│  │  ┌─────────────────────┐    ┌──────────────────────┼─┐  │
│  │  │ Application Insights│    │  Container Registry  │ │  │
│  │  │  - 30 day retention │    │  (ACR)              │ │  │
│  │  └──────────┬──────────┘    │  - RBAC Auth        │ │  │
│  │             │                └──────────────────────┘ │  │
│  │             │                                          │  │
│  │  ┌──────────▼──────────┐    ┌─────────────────────┐  │  │
│  │  │ Log Analytics       │    │  Azure AI Services  │  │  │
│  │  │ Workspace           │    │  (Foundry)          │  │  │
│  │  └─────────────────────┘    │  - GPT-4            │  │  │
│  │                              │  - Phi-3            │  │  │
│  │                              └─────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Resource Details

| Resource | Type | Purpose | Configuration |
|----------|------|---------|---------------|
| Resource Group | `Microsoft.Resources/resourceGroups` | Container for all resources | Region: westus3 |
| Container Registry | `Microsoft.ContainerRegistry/registries` | Stores Docker images | SKU: Basic, Admin: Disabled |
| App Service Plan | `Microsoft.Web/serverfarms` | Compute for App Service | SKU: B1, OS: Linux |
| App Service | `Microsoft.Web/sites` | Hosts containerized app | Runtime: Container, Identity: System-Assigned |
| Application Insights | `Microsoft.Insights/components` | Application monitoring | Type: web, Retention: 30 days |
| Log Analytics | `Microsoft.OperationalInsights/workspaces` | Log storage | SKU: PerGB2018 |
| AI Services | `Microsoft.CognitiveServices/accounts` | AI model access | SKU: S0, Models: GPT-4, Phi-3 |

## Security Architecture

### Authentication & Authorization

1. **App Service Identity**
   - System-assigned managed identity automatically created
   - No password or certificate management required
   - Identity used for ACR authentication

2. **ACR Access Control**
   - Admin user disabled (password-less)
   - App Service granted AcrPull role via RBAC
   - Role assignment: `Microsoft.Authorization/roleAssignments`

3. **Network Security**
   - HTTPS enforced on App Service
   - Minimum TLS version: 1.2
   - HTTP to HTTPS redirection enabled

### Security Best Practices Implemented

✅ **No Secrets in Code**: Managed identities eliminate credential storage  
✅ **Least Privilege**: AcrPull role grants only image pull permissions  
✅ **Encryption in Transit**: HTTPS and TLS 1.2+ enforced  
✅ **Audit Trail**: All Azure operations logged  
✅ **Network Protection**: Can be extended with VNet integration  

## Deployment Architecture

### Build & Deploy Flow

```
Developer Machine                  Azure Cloud
─────────────────                  ───────────

1. azd up
   │
   ├──► 2. azd provision
   │    │
   │    └──► Bicep Deployment
   │         │
   │         ├──► Create Resource Group
   │         ├──► Create ACR
   │         ├──► Create App Service Plan
   │         ├──► Create App Service
   │         ├──► Create App Insights
   │         ├──► Create AI Services
   │         └──► Assign RBAC Roles
   │
   └──► 3. azd deploy
        │
        ├──► Build Image (ACR Tasks)
        │    │
        │    ├──► dotnet restore
        │    ├──► dotnet publish
        │    └──► Docker build
        │
        ├──► Push to ACR
        │
        └──► Update App Service
             │
             ├──► Set container image
             ├──► Configure app settings
             └──► Restart service
```

### Infrastructure as Code Structure

```
infra/
├── main.bicep                    # Orchestration template
├── main.parameters.json          # Environment parameters
├── abbreviations.json            # Resource naming standards
├── modules/
│   ├── acr.bicep                # Container Registry
│   ├── acr-role-assignment.bicep # RBAC for ACR
│   ├── app-service-plan.bicep   # Compute plan
│   ├── app-service.bicep        # Web app
│   ├── app-insights.bicep       # Monitoring
│   └── ai-foundry.bicep         # AI Services
├── README.md                     # Detailed documentation
└── QUICKSTART.md                 # Quick reference
```

## Operational Procedures

### Day 1 Operations

1. **Initial Deployment**
   ```bash
   azd auth login
   azd up
   ```

2. **Verify Deployment**
   ```bash
   azd show
   # Test application URL
   curl https://<app-service-url>
   ```

3. **Configure Monitoring**
   ```bash
   azd monitor
   # Set up alerts in Application Insights
   ```

### Day 2 Operations

1. **Application Updates**
   ```bash
   # After code changes
   azd deploy
   ```

2. **Infrastructure Updates**
   ```bash
   # After Bicep changes
   azd provision
   ```

3. **View Logs**
   ```bash
   az webapp log tail --name <app-name> --resource-group <rg-name>
   ```

4. **Scale Application**
   ```bash
   az appservice plan update \
     --name <plan-name> \
     --resource-group <rg-name> \
     --sku P1v3
   ```

### Monitoring & Alerting

**Application Insights Metrics:**
- Request rates and response times
- Dependency calls (database, external APIs)
- Exception tracking
- Custom telemetry

**Recommended Alerts:**
- HTTP 5xx errors > threshold
- Average response time > 2 seconds
- Availability < 99%
- CPU/Memory > 80%

### Backup & Disaster Recovery

**App Service:**
- Built-in backup for configuration
- Container images versioned in ACR
- Infrastructure defined in Bicep (reproducible)

**Recovery Procedure:**
1. Redeploy infrastructure: `azd provision`
2. Redeploy application: `azd deploy`
3. Verify functionality

**RTO (Recovery Time Objective):** < 30 minutes  
**RPO (Recovery Point Objective):** Last deployed version

## Cost Management

### Cost Breakdown (Monthly Estimates)

| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| App Service Plan | B1 Basic | $13.14 |
| Container Registry | Basic | $5.00 |
| Application Insights | Pay-as-you-go | $2-10 |
| Log Analytics | Pay-as-you-go | $2-5 |
| AI Services (GPT-4) | S0 + Usage | $10-50 |
| AI Services (Phi-3) | S0 + Usage | $5-20 |
| **Total** | | **$37-103/month** |

### Cost Optimization Strategies

1. **Development Environment**
   - Use Free tier App Service (F1)
   - Disable AI models when not in use
   - Delete resources outside working hours

2. **Production Environment**
   - Enable auto-scaling to match demand
   - Use reserved instances for predictable workloads
   - Set spending limits and alerts

3. **Monitoring**
   - Set up cost alerts in Azure Cost Management
   - Review spending weekly
   - Tag resources for cost allocation

## Compliance & Governance

### Azure Policies Applied

- Require HTTPS for App Service
- Require minimum TLS version 1.2
- Deny admin access for ACR
- Require managed identity for Azure resources

### Resource Tagging Strategy

| Tag | Purpose | Example |
|-----|---------|---------|
| `azd-env-name` | Environment identifier | `dev`, `staging`, `prod` |
| `environment` | Deployment stage | `development`, `production` |
| `cost-center` | Billing allocation | `engineering` |
| `owner` | Resource owner | `team-platform` |
| `project` | Project identifier | `zavastorefrontapp` |

### Audit & Compliance

- All operations logged to Azure Activity Log
- Resource changes tracked via Bicep deployments
- Managed identities eliminate credential sprawl
- RBAC follows least privilege principle

## Troubleshooting Guide

### Common Issues

**Issue: App Service won't start**
```bash
# Check logs
az webapp log tail --name <app-name> --resource-group <rg-name>

# Verify container configuration
az webapp config show --name <app-name> --resource-group <rg-name>

# Check ACR access
az role assignment list --scope /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.ContainerRegistry/registries/{acr}
```

**Issue: Cannot pull image from ACR**
```bash
# Verify managed identity exists
az webapp identity show --name <app-name> --resource-group <rg-name>

# Check role assignment
az role assignment list --assignee <identity-principal-id>

# Manually test ACR access
az acr login --name <acr-name>
```

**Issue: High costs**
```bash
# View cost analysis
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31

# Check resource utilization
az monitor metrics list --resource <resource-id>

# Consider scaling down
az appservice plan update --name <plan-name> --sku F1
```

## Migration & Evolution

### Scaling Paths

**From Development to Production:**
1. Upgrade App Service Plan to Premium (P1v3+)
2. Enable zone redundancy
3. Add custom domain and SSL
4. Configure VNet integration
5. Enable private endpoints
6. Add Azure Front Door/CDN
7. Implement multi-region deployment

**From Basic to Enterprise:**
1. Add Azure Application Gateway
2. Implement Azure Key Vault for secrets
3. Add Azure Firewall
4. Enable Azure Security Center
5. Implement Azure Policies
6. Add Azure Backup
7. Configure geo-replication

### Infrastructure Evolution

Current (v1):
- Single region deployment
- Basic monitoring
- Public endpoints

Future (v2+):
- Multi-region with Traffic Manager
- Advanced monitoring with custom metrics
- Private endpoints with VNet integration
- WAF with Application Gateway
- Automated scaling policies

## References

### Documentation
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Language](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service](https://learn.microsoft.com/azure/app-service/)
- [Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure AI Services](https://learn.microsoft.com/azure/ai-services/)

### Related Documents
- [Infrastructure README](./infra/README.md) - Detailed setup instructions
- [Deployment Guide](./DEPLOYMENT.md) - Step-by-step deployment
- [Quick Start](./infra/QUICKSTART.md) - Common commands reference
- [Application README](./src/README.md) - Application documentation

### Support Resources
- Azure Support Portal: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade
- Azure Status: https://status.azure.com/
- Azure Pricing Calculator: https://azure.microsoft.com/pricing/calculator/

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-08  
**Maintained By:** Platform Engineering Team
