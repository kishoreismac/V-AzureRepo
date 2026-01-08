#!/bin/bash
set -e

# ============================================================================
# Configure Monitoring for Azure Resources
# ============================================================================
# This script configures Log Analytics workspace and diagnostic settings
# for Function App and Storage Account deployed by the infrastructure.
# It is idempotent and safe to run multiple times.
# ============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Azure Monitoring Configuration Script ==="
echo ""

# ============================================================================
# Validate required environment variables
# ============================================================================
if [ -z "$DEPLOYMENT_NAME" ]; then
    echo -e "${RED}❌ DEPLOYMENT_NAME environment variable is required${NC}"
    exit 1
fi

if [ -z "$LOCATION" ]; then
    echo -e "${RED}❌ LOCATION environment variable is required${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Environment variables validated${NC}"

# ============================================================================
# Get deployment outputs
# ============================================================================
echo ""
echo "=== Retrieving Deployment Outputs ==="

OUTPUTS=$(az deployment sub show \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs \
    -o json)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to retrieve deployment outputs${NC}"
    exit 1
fi

# Extract resource information
RESOURCE_GROUP=$(echo "$OUTPUTS" | jq -r '.RESOURCE_GROUP_NAME.value')
FUNCTION_APP_NAME=$(echo "$OUTPUTS" | jq -r '.AZURE_FUNCTION_NAME.value')
STORAGE_ACCOUNT_NAME=$(echo "$OUTPUTS" | jq -r '.STORAGE_ACCOUNT_NAME.value')
LOG_ANALYTICS_NAME=$(echo "$OUTPUTS" | jq -r '.LOG_ANALYTICS_NAME.value')

echo "Resource Group: $RESOURCE_GROUP"
echo "Function App: $FUNCTION_APP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Log Analytics: $LOG_ANALYTICS_NAME"

# ============================================================================
# Get Log Analytics Workspace ID
# ============================================================================
echo ""
echo "=== Getting Log Analytics Workspace ID ==="

WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$LOG_ANALYTICS_NAME" \
    --query id -o tsv)

if [ -z "$WORKSPACE_ID" ]; then
    echo -e "${RED}❌ Failed to get Log Analytics workspace ID${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Log Analytics Workspace ID: $WORKSPACE_ID${NC}"

# ============================================================================
# Configure Diagnostic Settings for Function App
# ============================================================================
echo ""
echo "=== Configuring Diagnostic Settings for Function App ==="

FUNCTION_APP_ID=$(az functionapp show \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query id -o tsv)

# Check if diagnostic setting already exists
EXISTING_DIAG=$(az monitor diagnostic-settings list \
    --resource "$FUNCTION_APP_ID" \
    --query "value[?name=='function-app-diagnostics'].name" -o tsv)

if [ -z "$EXISTING_DIAG" ]; then
    echo "Creating new diagnostic setting for Function App..."
    
    az monitor diagnostic-settings create \
        --name "function-app-diagnostics" \
        --resource "$FUNCTION_APP_ID" \
        --workspace "$WORKSPACE_ID" \
        --logs '[
            {
                "category": "FunctionAppLogs",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            }
        ]' \
        --metrics '[
            {
                "category": "AllMetrics",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            }
        ]' \
        --output none

    echo -e "${GREEN}✅ Diagnostic settings created for Function App${NC}"
else
    echo -e "${YELLOW}ℹ️  Diagnostic settings already exist for Function App (idempotent)${NC}"
fi

# ============================================================================
# Configure Diagnostic Settings for Storage Account
# ============================================================================
echo ""
echo "=== Configuring Diagnostic Settings for Storage Account ==="

STORAGE_ACCOUNT_ID=$(az storage account show \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query id -o tsv)

# Check if diagnostic setting already exists for storage account
EXISTING_STORAGE_DIAG=$(az monitor diagnostic-settings list \
    --resource "$STORAGE_ACCOUNT_ID" \
    --query "value[?name=='storage-account-diagnostics'].name" -o tsv)

if [ -z "$EXISTING_STORAGE_DIAG" ]; then
    echo "Creating new diagnostic setting for Storage Account..."
    
    az monitor diagnostic-settings create \
        --name "storage-account-diagnostics" \
        --resource "$STORAGE_ACCOUNT_ID" \
        --workspace "$WORKSPACE_ID" \
        --metrics '[
            {
                "category": "Transaction",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            }
        ]' \
        --output none

    echo -e "${GREEN}✅ Diagnostic settings created for Storage Account${NC}"
else
    echo -e "${YELLOW}ℹ️  Diagnostic settings already exist for Storage Account (idempotent)${NC}"
fi

# ============================================================================
# Configure Blob Service Diagnostic Settings
# ============================================================================
echo ""
echo "=== Configuring Diagnostic Settings for Blob Service ==="

BLOB_SERVICE_ID="${STORAGE_ACCOUNT_ID}/blobServices/default"

EXISTING_BLOB_DIAG=$(az monitor diagnostic-settings list \
    --resource "$BLOB_SERVICE_ID" \
    --query "value[?name=='blob-service-diagnostics'].name" -o tsv 2>/dev/null || echo "")

if [ -z "$EXISTING_BLOB_DIAG" ]; then
    echo "Creating new diagnostic setting for Blob Service..."
    
    az monitor diagnostic-settings create \
        --name "blob-service-diagnostics" \
        --resource "$BLOB_SERVICE_ID" \
        --workspace "$WORKSPACE_ID" \
        --logs '[
            {
                "category": "StorageRead",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            },
            {
                "category": "StorageWrite",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            },
            {
                "category": "StorageDelete",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            }
        ]' \
        --metrics '[
            {
                "category": "Transaction",
                "enabled": true,
                "retentionPolicy": {"enabled": false, "days": 0}
            }
        ]' \
        --output none 2>&1 || echo -e "${YELLOW}⚠️  Could not configure blob diagnostics (may require additional permissions)${NC}"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Diagnostic settings created for Blob Service${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Diagnostic settings already exist for Blob Service (idempotent)${NC}"
fi

# ============================================================================
# Enable Microsoft Defender for Cloud (best effort)
# ============================================================================
echo ""
echo "=== Enabling Microsoft Defender for Cloud (Best Effort) ==="

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Attempting to enable Defender for Storage..."
az security pricing create \
    --name "StorageAccounts" \
    --tier "Standard" \
    --output none 2>&1 || echo -e "${YELLOW}⚠️  Could not enable Defender for Storage (may require Security Admin role)${NC}"

echo "Attempting to enable Defender for App Service..."
az security pricing create \
    --name "AppServices" \
    --tier "Standard" \
    --output none 2>&1 || echo -e "${YELLOW}⚠️  Could not enable Defender for App Service (may require Security Admin role)${NC}"

echo -e "${YELLOW}ℹ️  Defender configuration completed (errors ignored if permissions missing)${NC}"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=== Configuration Complete ==="
echo -e "${GREEN}✅ Monitoring configuration completed successfully!${NC}"
echo ""
echo "Resources configured:"
echo "  - Log Analytics Workspace: $LOG_ANALYTICS_NAME"
echo "  - Function App diagnostics: $FUNCTION_APP_NAME"
echo "  - Storage Account diagnostics: $STORAGE_ACCOUNT_NAME"
echo ""
echo "You can view logs in Azure Portal:"
echo "  https://portal.azure.com/#resource${WORKSPACE_ID}/logs"
echo ""
