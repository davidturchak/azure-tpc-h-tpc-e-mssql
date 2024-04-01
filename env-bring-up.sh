#!/bin/bash

# Set variables for VM configuration
RGNAME='deployment-tpch-tpce'
VMNAME='sql-host'
VNET='tpch-tpce-network'
DATA_SUBNET='flex-cluster-d954-network-external-data1'
MGMT_SUBNET='flex-cluster-d954-network-external-mgmt'
LOCATION='westus2' # The snapshot location
ZONE='1'
VMSIZE='Standard_L48s_v3'
IMAGE2USE='microsoftsqlserver:sql2022-ws2022:sqldev-gen2:latest'
VMADMINUSER='flexadm'
VMADMINPASS='loPZ7apx0k4ASXucg_'

# Function to create NICs
create_nics() {
  az network nic create \
    --name ${VMNAME}-data \
    --resource-group $RGNAME \
    --vnet-name $VNET \
    --subnet ${DATA_SUBNET} \
    --accelerated-networking true \
    --output table
}

# Function to create VM
create_vm() {
  az vm create \
    --resource-group $RGNAME \
    --name $VMNAME \
    --image $IMAGE2USE \
    --admin-username $VMADMINUSER \
    --admin-password $VMADMINPASS \
    --size $VMSIZE \
    --nics ${VMNAME}-mgmt ${VMNAME}-data \
    --location $LOCATION \
    --zone $ZONE \
    --output table
}

# Function to delete NICs
delete_nics() {
  az network nic delete --name ${VMNAME}-data --resource-group $RGNAME --yes
  az network nic delete --name ${VMNAME}-mgmt --resource-group $RGNAME --yes
}

# Function to delete VM
delete_vm() {
  az vm delete --resource-group $RGNAME --name $VMNAME --yes
}

# Main script
if [[ "$1" == "--create" ]]; then
  create_nics || { echo "Error creating NICs. Exiting."; exit 1; }
  create_vm || { echo "Error creating VM. Exiting."; exit 1; }
  echo "Resources created successfully."
elif [[ "$1" == "--delete" ]]; then
  delete_nics || { echo "Error deleting NICs. Exiting."; exit 1; }
  delete_vm || { echo "Error deleting VM. Exiting."; exit 1; }
  echo "Resources deleted successfully."
else
  echo "Usage: $0 [--create|--delete]"
  echo "  --create: Create resources"
  echo "  --delete: Delete resources"
  exit 1
fi
