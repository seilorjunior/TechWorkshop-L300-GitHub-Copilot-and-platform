# GitHub Actions Deployment Setup

## Prerequisites

1. Azure infrastructure provisioned via `azd up`
2. Azure AD App Registration with federated credentials for GitHub OIDC

## Create App Registration

```bash
az ad app create --display-name "github-zava-deploy"
az ad sp create --id <APP_ID>
```

## Configure Federated Credentials

In Azure Portal → App Registration → Certificates & secrets → Federated credentials:

| Setting | Value |
|---------|-------|
| Organization | `your-github-org` |
| Repository | `TechWorkshop-L300-GitHub-Copilot-and-platform` |
| Entity type | Branch |
| Branch | `main` |

## Assign RBAC Roles

```bash
az role assignment create --assignee <APP_ID> --role Contributor --scope /subscriptions/<SUB_ID>/resourceGroups/rg-<ENV_NAME>
az role assignment create --assignee <APP_ID> --role AcrPush --scope /subscriptions/<SUB_ID>/resourceGroups/rg-<ENV_NAME>
```

## GitHub Configuration

### Secrets (Settings → Secrets → Actions)

| Name | Value |
|------|-------|
| `AZURE_CLIENT_ID` | App Registration Client ID |
| `AZURE_TENANT_ID` | Azure AD Tenant ID |

### Variables (Settings → Variables → Actions)

| Name | Value |
|------|-------|
| `AZURE_SUBSCRIPTION_ID` | Your subscription ID |
| `AZURE_ENV_NAME` | Environment name used in `azd up` (e.g., `zavastore-dev-westus3`) |
