#!/usr/bin/env bash
# Module 3: create the ADLS Gen2 storage account, the container, the layer folders,
# give yourself data access, and upload the source files to landing/.
# Run in Azure Cloud Shell (Bash) from the root of the cloned repository.
# Safe to re-run (idempotent). No keys, SAS tokens or connection strings are used or stored:
# every data command signs in with your Microsoft Entra ID account (--auth-mode login).

set -euo pipefail

RG="${RG:-rg-banking-dev}"
LOCATION="${LOCATION:-centralindia}"
STORAGE="${STORAGE:-stbankingdevkn}"      # must be globally unique: change if the name is taken
CONTAINER="${CONTAINER:-banking-data-platform}"

LAYERS=(landing bronze silver gold rejected archive metadata)

# local file -> folder under landing/
declare -A LANDING_FILES=(
  [datasets/accounts.csv]=landing/accounts
  [datasets/transactions.csv]=landing/transactions
  [datasets/loans.csv]=landing/loans
  [datasets/credit_card_transactions.csv]=landing/credit_card_transactions
  [datasets/payments.json]=landing/payments
)

echo "== 1. Storage account $STORAGE (ADLS Gen2) =="
az storage account create \
  --name "$STORAGE" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --hns true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags project=banking-data-engineering environment=dev cost-center=learning \
  --query "{name:name, location:location, hns:isHnsEnabled}" -o table

echo "== 2. Give yourself 'Storage Blob Data Contributor' on the account =="
ME=$(az ad signed-in-user show --query id -o tsv)
SCOPE=$(az storage account show --name "$STORAGE" --resource-group "$RG" --query id -o tsv)
az role assignment create \
  --assignee-object-id "$ME" --assignee-principal-type User \
  --role "Storage Blob Data Contributor" --scope "$SCOPE" -o none 2>/dev/null \
  && echo "role assigned" || echo "role already assigned (or assignment pending)"
echo "Waiting 60 seconds for the role to take effect..."
sleep 60

echo "== 3. Container $CONTAINER =="
az storage fs create --name "$CONTAINER" --account-name "$STORAGE" --auth-mode login -o none 2>/dev/null \
  && echo "created" || echo "already exists"

echo "== 4. Layer folders =="
for d in "${LAYERS[@]}"; do
  exists=$(az storage fs directory exists --name "$d" -f "$CONTAINER" --account-name "$STORAGE" --auth-mode login --query exists -o tsv)
  if [ "$exists" = "true" ]; then
    echo "folder exists: $d/"
  else
    az storage fs directory create --name "$d" -f "$CONTAINER" --account-name "$STORAGE" --auth-mode login -o none
    echo "folder created: $d/"
  fi
done

echo "== 5. Uploading landing files =="
for src in "${!LANDING_FILES[@]}"; do
  dest="${LANDING_FILES[$src]}/$(basename "$src")"
  az storage fs file upload --source "$src" --path "$dest" \
    -f "$CONTAINER" --account-name "$STORAGE" --auth-mode login --overwrite -o none
  echo "uploaded: $dest"
done

echo "== 6. Files in landing/ =="
az storage fs file list -f "$CONTAINER" --path landing --recursive \
  --account-name "$STORAGE" --auth-mode login \
  --query "[?!isDirectory].{Name:name, Bytes:contentLength}" -o table
