#!/bin/bash

# Set variables for VM configuration
RGNAME='deployment-tpch-tpce'
VMNAME='sql-host'
DEPLOYMENT_SUFFIX="${RGNAME#deployment-}"
VNET="$DEPLOYMENT_SUFFIX-network"
MGMT_SUBNET="$DEPLOYMENT_SUFFIX-host-mgmt-subnet"
DATA_SUBNET="$DEPLOYMENT_SUFFIX-host-data-subnet"
LOCATION='westus2' # The snapshot location
ZONE='1'
VMSIZE='Standard_L48s_v3'
IMAGE2USE='microsoftsqlserver:sql2022-ws2022:sqldev-gen2:latest'
VMADMINUSER='flexadm'
VMADMINPASS='loPZ7apx0k4ASXucg_'
#Backup Disk params
snapshot_name="Azure-TPCH-TPCE-backup"
resource_group_snapshot="pathfinder-azure-rg"
new_disk_name="BackupDisk"
new_disk_sku="StandardSSD_LRS"
#disk_size_gb=100

# Function to create a managed disk from a snapshot and attach it to the VM
create_disk_from_snapshot() {
  echo "Creating BackupDisk..."
  # Get the snapshot ID
  local snapshot_id=$(az snapshot show --name $snapshot_name --resource-group $resource_group_snapshot --query [id] -o tsv)

  # Create a managed disk from the snapshot
  az disk create \
    --resource-group $RGNAME\
    --name $new_disk_name \
    --sku $new_disk_sku \
    --source $snapshot_id \
    --zone $ZONE \
    --output table
  #  --size-gb $disk_size_gb \
}

# Function to create NICs
create_nics() {
  echo "Creating NICs..."
  az network nic create \
    --name ${VMNAME}-data \
    --resource-group $RGNAME \
    --vnet-name $VNET \
    --subnet ${DATA_SUBNET} \
    --accelerated-networking true \
    --output table
  az network nic create \
    --name ${VMNAME}-mgmt \
    --resource-group $RGNAME \
    --vnet-name $VNET \
    --subnet ${MGMT_SUBNET} \
    --accelerated-networking true \
    --output table
}

# Function to create VM
create_vm() {
  echo "Creating VM..."
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
    --attach-data-disks $new_disk_name \
    --output table
}

# Function to delete NICs
delete_nics() {
  echo "Deleting NICs..."
  az network nic delete --name ${VMNAME}-data --resource-group $RGNAME
  az network nic delete --name ${VMNAME}-mgmt --resource-group $RGNAME
}

# Function to delete VM
delete_vm() {
  echo "Deleting VM..."
  vm_os_disk_id=$(az vm show --name $VMNAME --resource-group $RGNAME --query 'storageProfile.osDisk.managedDisk.id' -o tsv)
  az vm delete --resource-group $RGNAME --name $VMNAME --yes
}

# Function to delete Disks
delete_disks() {
  echo "Deleting BackupDisk..."
  az disk delete --resource-group $RGNAME --name $new_disk_name --yes
  echo "Deleting VM OS disk..."
  az disk delete --resource-group $RGNAME --name $vm_os_disk_id --yes
}

# Main script
if [[ "$1" == "--create" ]]; then

  create_disk_from_snapshot || { echo "Error creating a BackupDisk. Exiting."; exit 1; }
  create_nics || { echo "Error creating NICs. Exiting."; exit 1; }
  create_vm || { echo "Error creating VM. Exiting."; exit 1; }
  echo "Resources created successfully."
elif [[ "$1" == "--delete" ]]; then
  delete_vm || { echo "Error deleting VM. Exiting."; exit 1; }
  delete_nics || { echo "Error deleting NICs. Exiting."; exit 1; }
  delete_disks || { echo "Error deleting BackupDisk. Exiting."; exit 1; }
  echo "Resources deleted successfully."
else
  echo "Usage: $0 [--create|--delete]"
  echo "  --create: Create resources"
  echo "  --delete: Delete resources"
  exit 1
fi
