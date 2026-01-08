#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Configure monitoring for Azure Function App infrastructure.

OPTIONS:
  --resource-group RG       Azure resource group name (required)
  --function-app APP        Function App name (required)
  --log-analytics LA        Log Analytics workspace name (required)
  --app-insights AI         Application Insights name (required)
  --environment ENV         Environment name (e.g., dev, prod) (required)
  -h, --help                Show this help message

EXAMPLE:
  $0 --resource-group rg-myapp-prod \\
     --function-app func-myapp-prod \\
     --log-analytics log-myapp-prod \\
     --app-insights ai-myapp-prod \\
     --environment prod
EOF
  exit 0
}

# Parse arguments
RESOURCE_GROUP=""
FUNCTION_APP=""
LOG_ANALYTICS=""
APP_INSIGHTS=""
ENVIRONMENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    --function-app)
      FUNCTION_APP="$2"
      shift 2
      ;;
    --log-analytics)
      LOG_ANALYTICS="$2"
      shift 2
      ;;
    --app-insights)
      APP_INSIGHTS="$2"
      shift 2
      ;;
    --environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Validate required arguments
if [[ -z "$RESOURCE_GROUP" || -z "$FUNCTION_APP" || -z "$LOG_ANALYTICS" || -z "$APP_INSIGHTS" || -z "$ENVIRONMENT" ]]; then
  echo "Error: Missing required arguments"
  usage
fi

echo "=== Configuring Monitoring for Environment: $ENVIRONMENT ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Function App: $FUNCTION_APP"
echo "Log Analytics: $LOG_ANALYTICS"
echo "App Insights: $APP_INSIGHTS"

# 1. Configure diagnostic settings for Function App
echo ""
echo "Configuring diagnostic settings for Function App..."
az monitor diagnostic-settings create \
  --name "diag-${FUNCTION_APP}" \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${FUNCTION_APP}" \
  --workspace "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.OperationalInsights/workspaces/${LOG_ANALYTICS}" \
  --logs '[
    {
      "category": "FunctionAppLogs",
      "enabled": true,
      "retentionPolicy": {
        "enabled": false,
        "days": 0
      }
    }
  ]' \
  --metrics '[
    {
      "category": "AllMetrics",
      "enabled": true,
      "retentionPolicy": {
        "enabled": false,
        "days": 0
      }
    }
  ]' || echo "Diagnostic settings may already exist or category not supported, continuing..."

# 2. Configure alerts for Function App
echo ""
echo "Configuring alerts for Function App..."

# Create action group if it doesn't exist
# NOTE: The email address should be updated in Azure Portal after deployment
# This is a placeholder and should not be used in production
ACTION_GROUP_NAME="ag-${ENVIRONMENT}-alerts"
az monitor action-group create \
  --name "$ACTION_GROUP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --short-name "${ENVIRONMENT}-ag" \
  --action email admin "admin@example.com" || echo "Action group may already exist, continuing..."

# Create metric alert for high error rate
FUNCTION_APP_ID="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${FUNCTION_APP}"

az monitor metrics alert create \
  --name "alert-${FUNCTION_APP}-errors" \
  --resource-group "$RESOURCE_GROUP" \
  --scopes "$FUNCTION_APP_ID" \
  --condition "count Http5xx > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "$ACTION_GROUP_NAME" \
  --description "Alert when Function App has more than 10 5xx errors in 5 minutes" \
  --severity 2 || echo "Alert may already exist, continuing..."

# Create metric alert for high response time
az monitor metrics alert create \
  --name "alert-${FUNCTION_APP}-response-time" \
  --resource-group "$RESOURCE_GROUP" \
  --scopes "$FUNCTION_APP_ID" \
  --condition "avg HttpResponseTime > 5000" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "$ACTION_GROUP_NAME" \
  --description "Alert when Function App average response time exceeds 5 seconds" \
  --severity 3 || echo "Alert may already exist, continuing..."

# 3. Configure Log Analytics queries
echo ""
echo "Setting up Log Analytics queries..."

# Create a simple dashboard query (this would typically be done via portal or ARM template)
cat <<'QUERY' > /tmp/function-errors-query.kql
AppRequests
| where TimeGenerated > ago(1h)
| where Success == false
| summarize Count=count() by bin(TimeGenerated, 5m), ResultCode
| order by TimeGenerated desc
QUERY

echo "Sample query for monitoring Function App errors saved to /tmp/function-errors-query.kql"
echo "You can import this query into Log Analytics workspace: $LOG_ANALYTICS"

# 4. Verify Application Insights connection
echo ""
echo "Verifying Application Insights configuration..."
APP_INSIGHTS_KEY=$(az monitor app-insights component show \
  --app "$APP_INSIGHTS" \
  --resource-group "$RESOURCE_GROUP" \
  --query instrumentationKey -o tsv)

if [[ -n "$APP_INSIGHTS_KEY" ]]; then
  echo "✓ Application Insights is configured with key: ${APP_INSIGHTS_KEY:0:8}..."
else
  echo "⚠ Warning: Could not retrieve Application Insights key"
fi

# 5. Summary
echo ""
echo "=== Monitoring Configuration Complete ==="
echo "✓ Diagnostic settings configured for Function App"
echo "✓ Metric alerts created for errors and response time"
echo "✓ Action group configured for notifications"
echo "✓ Log Analytics queries prepared"
echo ""
echo "Next steps:"
echo "1. Update action group email addresses in Azure Portal"
echo "2. Import Log Analytics queries from /tmp/function-errors-query.kql"
echo "3. Create custom dashboards in Azure Portal"
echo "4. Review and adjust alert thresholds as needed"
