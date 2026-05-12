#!/usr/bin/env bash
# =============================================================================
# Bootstrap: Create Azure Blob Storage for Terraform Remote State
#
# Run this ONCE before `terraform init`.
# This script is idempotent — safe to re-run.
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — change these to match your environment
# ---------------------------------------------------------------------------
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"          # az account show --query id
RESOURCE_GROUP="rg-tfstate-qr"
LOCATION="eastasia"
STORAGE_ACCOUNT="stqrtfstate$(openssl rand -hex 4)"  # globally unique
CONTAINER_NAME="tfstate"
TAGS="project=qr-code-generator environment=shared managedby=terraform"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { echo "[INFO]  $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Pre-checks
# ---------------------------------------------------------------------------
command -v az >/dev/null 2>&1 || error "Azure CLI not found. Install: https://docs.microsoft.com/cli/azure/install-azure-cli"

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null) || error "Not logged in. Run: az login"
fi

info "Using subscription: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
if az group show --name "$RESOURCE_GROUP" &>/dev/null; then
  info "Resource group '$RESOURCE_GROUP' already exists — skipping"
else
  info "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags $TAGS
fi

# ---------------------------------------------------------------------------
# Storage Account
# If STORAGE_ACCOUNT_NAME is passed as env var, use it (for idempotent re-runs)
# ---------------------------------------------------------------------------
if [[ -n "${STORAGE_ACCOUNT_NAME:-}" ]]; then
  STORAGE_ACCOUNT="$STORAGE_ACCOUNT_NAME"
  info "Using existing storage account name: $STORAGE_ACCOUNT"
fi

if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  info "Storage account '$STORAGE_ACCOUNT' already exists — skipping"
else
  info "Creating storage account '$STORAGE_ACCOUNT'..."
  az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --https-only true \
    --tags $TAGS
fi

# ---------------------------------------------------------------------------
# Blob Container
# ---------------------------------------------------------------------------
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group "$RESOURCE_GROUP" \
  --account-name "$STORAGE_ACCOUNT" \
  --query "[0].value" -o tsv)

if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --account-key "$ACCOUNT_KEY" &>/dev/null; then
  info "Container '$CONTAINER_NAME' already exists — skipping"
else
  info "Creating blob container '$CONTAINER_NAME'..."
  az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT" \
    --account-key "$ACCOUNT_KEY" \
    --public-access off
fi

# ---------------------------------------------------------------------------
# Enable versioning (allows state file recovery)
# ---------------------------------------------------------------------------
info "Enabling blob versioning on storage account..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true \
  --output none

# ---------------------------------------------------------------------------
# Output backend config
# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
echo "  Terraform backend configuration"
echo "  Add this to your main.tf (or backend.hcl):"
echo "============================================================"
echo ""
echo 'terraform {'
echo '  backend "azurerm" {'
echo "    resource_group_name  = \"$RESOURCE_GROUP\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo '    key                  = "terraform.tfstate"'
echo '  }'
echo '}'
echo ""
echo "============================================================"
echo "  Save STORAGE_ACCOUNT_NAME for future re-runs:"
echo "  export STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT"
echo "============================================================"
