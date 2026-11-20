#!/usr/bin/env bash
# Module 5: create the Data Factory and the Key Vault, and give the Data Factory's
# managed identity access to the data lake and to Key Vault secrets.
# Run in Azure Cloud Shell (Bash). Safe to re-run (idempotent).
#
# Secrets: the SQL password is read from the keyboard with "read -s" (not shown, not
# saved in shell history, not written to any file) and sent straight to Key Vault.

set -euo pipefail

RG="${RG:-rg-banking-dev}"
LOCATION="${LOCATION:-centralindia}"
STORAGE="${STORAGE:-stbankingdevkn}"
ADF="${ADF:-adf-banking-dev-kn}"          # globally unique: change if taken
KV="${KV:-kv-banking-dev-kn}"             # globally unique: change if taken
SECRET_NAME="sql-adf-reader-password"
TAGS=(project=banking-data-engineering environment=dev cost-center=learning)

echo "== 0. Azure CLI extension for Data Factory =="
az extension add --name datafactory --upgrade --only-show-errors

echo "== 1. Data Factory $ADF (with a system-assigned managed identity) =="
if ! az datafactory show -g "$RG" -n "$ADF" -o none 2>/dev/null; then
  az datafactory create -g "$RG" -n "$ADF" -l "$LOCATION" --tags "${TAGS[@]}" -o none
  echo "created"
else
  echo "already exists"
fi
ADF_MI=$(az datafactory show -g "$RG" -n "$ADF" --query identity.principalId -o tsv)
echo "managed identity principalId: (hidden)"

echo "== 2. ADF managed identity -> Storage Blob Data Contributor on $STORAGE =="
ST_ID=$(az storage account show -g "$RG" -n "$STORAGE" --query id -o tsv)
az role assignment create --assignee-object-id "$ADF_MI" --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" --scope "$ST_ID" -o none 2>/dev/null \
  && echo "role assigned" || echo "role already assigned"

echo "== 3. Key Vault $KV (Azure RBAC permission model) =="
if ! az keyvault show -g "$RG" -n "$KV" -o none 2>/dev/null; then
  az keyvault create -g "$RG" -n "$KV" -l "$LOCATION" --enable-rbac-authorization true \
    --tags "${TAGS[@]}" -o none
  echo "created"
else
  echo "already exists"
fi
KV_ID=$(az keyvault show -g "$RG" -n "$KV" --query id -o tsv)

echo "== 4. You -> Key Vault Secrets Officer (to create secrets) =="
ME=$(az ad signed-in-user show --query id -o tsv)
az role assignment create --assignee-object-id "$ME" --assignee-principal-type User \
  --role "Key Vault Secrets Officer" --scope "$KV_ID" -o none 2>/dev/null \
  && echo "role assigned" || echo "role already assigned"

echo "== 5. ADF managed identity -> Key Vault Secrets User (to read secrets) =="
az role assignment create --assignee-object-id "$ADF_MI" --assignee-principal-type ServicePrincipal \
  --role "Key Vault Secrets User" --scope "$KV_ID" -o none 2>/dev/null \
  && echo "role assigned" || echo "role already assigned"

echo "== 6. Secret $SECRET_NAME =="
if az keyvault secret show --vault-name "$KV" -n "$SECRET_NAME" -o none 2>/dev/null; then
  echo "already exists (not changed)"
else
  echo "Waiting 60 seconds for the Key Vault role to take effect..."
  sleep 60
  read -r -s -p "Type the adf_reader SQL password (input is hidden), then Enter: " SQL_PWD; echo
  az keyvault secret set --vault-name "$KV" -n "$SECRET_NAME" --value "$SQL_PWD" -o none
  unset SQL_PWD
  echo "secret stored"
fi

echo "== 7. Summary =="
az resource list -g "$RG" --query "[].{Name:name, Type:type}" -o table
echo "Roles held by the ADF managed identity:"
az role assignment list --assignee "$ADF_MI" --all --query "[].roleDefinitionName" -o tsv
