#!/usr/bin/env bash
# Module 2: create the project resource group, tag it, and register resource providers.
# Run in Azure Cloud Shell (Bash). Safe to re-run (idempotent).
# No secrets or subscription IDs are stored in this file.

set -euo pipefail

RG="${RG:-rg-banking-dev}"
LOCATION="${LOCATION:-centralindia}"
OWNER="${OWNER:-kn}"   # change to your initials

PROVIDERS=(
  Microsoft.Storage
  Microsoft.DataFactory
  Microsoft.Databricks
  Microsoft.Compute
  Microsoft.Network
  Microsoft.KeyVault
  Microsoft.ManagedIdentity
)

echo "== Active subscription =="
az account show --query "{name:name, state:state}" -o table

echo "== Creating resource group $RG in $LOCATION =="
az group create \
  --name "$RG" \
  --location "$LOCATION" \
  --tags project=banking-data-engineering environment=dev owner="$OWNER" cost-center=learning \
  -o table

echo "== Registering resource providers =="
for p in "${PROVIDERS[@]}"; do
  az provider register --namespace "$p" >/dev/null
  echo "requested: $p"
done

echo "== Registration state (may show 'Registering' for a few minutes) =="
for p in "${PROVIDERS[@]}"; do
  echo "$p: $(az provider show --namespace "$p" --query registrationState -o tsv)"
done

echo "== Resource group =="
az group show --name "$RG" --query "{name:name, location:location, tags:tags}" -o json

# Clean-up at the END of the project only (deletes everything inside the group):
# az group delete --name "$RG" --yes --no-wait
