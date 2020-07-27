$ResourceGroupName = "azmonvm-prod-rg"
$Location = "westeurope"
$VMNames = "azmonprodvm21", "azmonprodvm22", "azmonprodvm23", "azmonprodvm24"

az network vnet create --resource-group "$ResourceGroupName" --location "$Location" --name "azmonvm-prod-vnet" --address-prefix 10.10.100.0/24 --subnet-name "azmonvm-prod-vnet-sub1" --subnet-prefix 10.10.100.0/25
az network nsg create --resource-group "$ResourceGroupName" --location "$Location" --name "azmonvm-prod-nsg"
az network nsg rule create --resource-group "$ResourceGroupName" --nsg-name "azmonvm-prod-nsg" --name "AllowRDP" --priority 100 --access "Allow" --direction "Inbound" --source-address-prefixes "Internet" --destination-address-prefixes "VirtualNetwork" --protocol "Tcp" --destination-port-ranges 3389 --description "Allow RDP from internet to virtual network."


for ($i = 0; $i -lt $VMNames.count; $i++) {
    $PIPName = ($VMNames[$i] + "-pip")
    $NICName = ($VMNames[$i] + "-nic1")
    $OSDiskName = ($VMNames[$i] + "-diskos")

    az network public-ip create --resource-group "$ResourceGroupName" --location "$Location" --name "$PIPName" --dns-name $VMNames[$i] --allocation-method Dynamic --idle-timeout 5 --sku Basic --version IPV4
    az network nic create --resource-group "$ResourceGroupName" --location "$Location" --name "$NICName" --vnet-name "azmonvm-prod-vnet" --subnet "azmonvm-prod-vnet-sub1" --network-security-group "azmonvm-prod-nsg" --public-ip-address "$PIPName"
    az vm create --resource-group "$ResourceGroupName" --location "$Location" --name $VMNames[$i] --image "win2016datacenter" --size "Standard_DS1_v2" --admin-username "locadmin" --admin-password "P@ssw0rd01 !" --os-disk-name "$OSDiskName" --nics "$NICName"
    az vm auto-shutdown --resource-group "$ResourceGroupName" --name $VMNames[$i] --time 1900
    
}
