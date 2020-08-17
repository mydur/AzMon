$ResourceGroupName = "azmonvm-test-rg"
$Location = "westeurope"
$VMNames = "azmonprodvm27", "azmonprodvm28"

az network vnet create --resource-group "$ResourceGroupName" --location "$Location" --name "azmonvm-test-vnet" --address-prefix 10.10.101.0/24 --subnet-name "azmonvm-test-vnet-sub1" --subnet-prefix 10.10.101.0/25
az network nsg create --resource-group "$ResourceGroupName" --location "$Location" --name "azmonvm-test-nsg"
az network nsg rule create --resource-group "$ResourceGroupName" --nsg-name "azmonvm-test-nsg" --name "AllowRDP" --priority 100 --access "Allow" --direction "Inbound" --source-address-prefixes "Internet" --destination-address-prefixes "VirtualNetwork" --protocol "Tcp" --destination-port-ranges 3389 --description "Allow RDP from internet to virtual network."


for ($i = 0; $i -lt $VMNames.count; $i++) {
    $PIPName = ($VMNames[$i] + "-pip")
    $NICName = ($VMNames[$i] + "-nic1")
    $OSDiskName = ($VMNames[$i] + "-diskos")

    az network public-ip create --resource-group "$ResourceGroupName" --location "$Location" --name "$PIPName" --dns-name $VMNames[$i] --allocation-method Dynamic --idle-timeout 5 --sku Basic --version IPV4
    az network nic create --resource-group "$ResourceGroupName" --location "$Location" --name "$NICName" --vnet-name "azmonvm-test-vnet" --subnet "azmonvm-test-vnet-sub1" --network-security-group "azmonvm-test-nsg" --public-ip-address "$PIPName"
    az vm create --resource-group "$ResourceGroupName" --location "$Location" --name $VMNames[$i] --image "win2016datacenter" --size "Standard_DS1_v2" --admin-username "locadmin" --admin-password "P@ssw0rd01 !" --os-disk-name "$OSDiskName" --nics "$NICName"
    az vm auto-shutdown --resource-group "$ResourceGroupName" --name $VMNames[$i] --time 1900
    
}
