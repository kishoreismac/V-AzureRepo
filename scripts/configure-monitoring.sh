#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 --resource-group <rg> --function-app-name <name> --storage-account <name> --log-analytics-name <law>
USAGE
  exit 1
}

RG=""
FUNCTION_APP=""
STORAGE=""
LAW=""

while [ $# -gt 0 ]; do
  case "$1" in
    --resource-group) RG="$2"; shift 2;;
    --function-app-name) FUNCTION_APP="$2"; shift 2;;
    --storage-account) STORAGE="$2"; shift 2;;
    --log-analytics-name) LAW="$2"; shift 2;;
    *) echo "Unknown arg $1"; usage;;
  esac
done

if [ -z "$RG" ] || [ -z "$LAW" ] ; then
  usage
fi

WORKSPACE_ID=$(az monitor log-analytics workspace show --resource-group "$RG" --workspace-name "$LAW" --query id -o tsv 2>/dev/null || true)
if [ -z "$WORKSPACE_ID" ]; then
  LOCATION=$(az group show -n "$RG" --query location -o tsv)
  az monitor log-analytics workspace create --resource-group "$RG" --workspace-name "$LAW" --location "$LOCATION" --sku PerGB2018 --query id -o tsv
  WORKSPACE_ID=$(az monitor log-analytics workspace show --resource-group "$RG" --workspace-name "$LAW" --query id -o tsv)
fi

enable_diag() {
  local resource_id="$1"
  local resource_type="$2"
  
  if [[ "$resource_type" == "functionapp" ]]; then
    az monitor diagnostic-settings create \
      --name "diag-to-law" \
      --resource "$resource_id" \
      --workspace "$WORKSPACE_ID" \
      --logs '[{"category":"FunctionAppLogs","enabled":true},{"category":"AppServiceHTTPLogs","enabled":true}]' \
      --metrics '[{"category":"AllMetrics","enabled":true}]' \
      --only-show-errors || echo "Failed to add diagnostic setting for $resource_id"
  elif [[ "$resource_type" == "storage" ]]; then
    # Storage accounts have different log categories and need resource-specific configuration
    az monitor diagnostic-settings create \
      --name "diag-to-law" \
      --resource "$resource_id" \
      --workspace "$WORKSPACE_ID" \
      --metrics '[{"category":"AllMetrics","enabled":true}]' \
      --only-show-errors || echo "Failed to add diagnostic setting for $resource_id"
  fi
}

if [ -n "$FUNCTION_APP" ]; then
  FA_ID=$(az functionapp show --name "$FUNCTION_APP" --resource-group "$RG" --query id -o tsv 2>/dev/null || true)
  if [ -n "$FA_ID" ]; then
    enable_diag "$FA_ID" "functionapp"
  fi
fi

if [ -n "$STORAGE" ]; then
  SA_ID=$(az storage account show --name "$STORAGE" --resource-group "$RG" --query id -o tsv 2>/dev/null || true)
  if [ -n "$SA_ID" ]; then
    enable_diag "$SA_ID" "storage"
  fi
fi

echo "Attempting to enable Defender for Cloud standard pricing for subscription (may require permission)."
echo "Note: This enables 'default' pricing tier which has cost implications. Ensure this is approved for your subscription."
SUB_ID=$(az account show --query id -o tsv)
az security pricing create --name "default" --tier "Standard" --subscription "$SUB_ID" --only-show-errors || true

echo "Monitoring configuration complete."
