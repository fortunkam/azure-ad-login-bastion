$RG="mfvm01"
$LOC="centralus"
$VNET="$RG-vnet"
$VM_SUBNET="vm"
$BASTION_SUBNET="AzureBastionSubnet"
$VNET_CIDR="10.0.0.0/16"
$VM_CIDR="10.0.0.0/24"
$BASTION_CIDR="10.0.1.0/24"
$VM_NAME="$RG-vm"
$VM_DISK="$RG-disk"
$VM_NIC="$RG-nic"
$VM_USERNAME="AzureAdmin"

# User needs to provide a password for the VM (Win 2019 Default Password requirements apply)
$VM_PASSWORD=Read-Host -Prompt 'Input your VM Admin Password'

$VM_PRIVATE_IP="10.0.0.5"

$BASTION_PUBLIC_IP_NAME="$RG-bastion-publicip"
$BASTION_NAME="$RG-bastion"


az group create -n $RG -l $LOC
az network vnet create -n $VNET -g $RG --address-prefixes $VNET_CIDR

az network vnet subnet create -n $VM_SUBNET -g $RG `
    --address-prefixes $VM_CIDR --vnet-name $VNET

az network vnet subnet create -n $BASTION_SUBNET -g $RG `
    --address-prefixes $BASTION_CIDR --vnet-name $VNET

az network nic create `
    --resource-group $RG `
    --name $VM_NIC `
    --subnet $VM_SUBNET `
    --private-ip-address $VM_PRIVATE_IP `
    --vnet-name $VNET

az vm create `
    -n $VM_NAME `
    -g $RG `
    --os-disk-name $VM_DISK `
    --admin-username $VM_USERNAME `
    --admin-password $VM_PASSWORD `
    --image "Win2019Datacenter" `
    --assign-identity `
    --nics $VM_NIC

az vm extension set `
    --publisher "Microsoft.Azure.ActiveDirectory" `
    --name "AADLoginForWindows" `
    --resource-group $RG `
    --vm-name $VM_NAME

 az network public-ip create -g $RG -n $BASTION_PUBLIC_IP_NAME -l $LOC --sku "Standard"

 az network bastion create -n $BASTION_NAME -g $RG --vnet-name $VNET --public-ip-address $BASTION_PUBLIC_IP_NAME

 $CURRENT_USER=az account show --query user.name --output tsv
 $VM_ID=az vm show --resource-group $RG --name $VM_NAME --query id -o tsv

 az role assignment create `
    --role "Virtual Machine Administrator Login" `
    --assignee $CURRENT_USER `
    --scope $VM_ID
