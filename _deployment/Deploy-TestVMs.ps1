$ResourceGroupName = "azmonvm-prod-rg"
$Location = "westeurope"
$VMNames = "azmonprodvm03", "azmonprodvm04"
$ShutdownTemplateFile = "C:\Getronics\AzGov\shutdownpolicymultiple.json"
$ShutdownTemplateFileNew = "C:\Getronics\AzGov\shutdownpolicy.json"
$ShutdownTemplateJSON = Get-Content -Path $ShutdownTemplateFile -Raw
az network vnet create --resource-group "$ResourceGroupName" --location "$Location" --name "azmonvm-prod-vnet" --address-prefix 10.10.100.0/24 --subnet-name "azmonvm-prod-vnet-sub1" --subnet-prefix 10.10.100.0/24
az network nsg create --resource-group "$ResourceGroupName" --location "$Location" --name "azmonvm-prod-nsg"
az network nsg rule create --resource-group "$ResourceGroupName" --nsg-name "azmonvm-prod-nsg" --name "AllowRDP" --priority 100 --access "Allow" --direction "Inbound" --source-address-prefixes "Internet" --destination-address-prefixes "VirtualNetwork" --protocol "Tcp" --destination-port-ranges 3389 --description "Allow RDP from internet to virtual network."

$VMNamesJSON = "["
for ($i = 0; $i -lt $VMNames.count; $i++) {
    $PIPName = ($VMNames[$i] + "-pip")
    $NICName = ($VMNames[$i] + "-nic1")
    $OSDiskName = ($VMNames[$i] + "-diskos")
    $VMNamesJSON = $VMNamesJSON + """" + $VMNames[$i] + """"

    az network public-ip create --resource-group "$ResourceGroupName" --location "$Location" --name "$PIPName" --dns-name $VMNames[$i] --allocation-method Dynamic --idle-timeout 5 --sku Basic --version IPV4
    az network nic create --resource-group "$ResourceGroupName" --location "$Location" --name "$NICName" --vnet-name "azmonvm-prod-vnet" --subnet "azmonvm-prod-vnet-sub1" --network-security-group "azmonvm-prod-nsg" --public-ip-address "$PIPName"
    az vm create --resource-group "$ResourceGroupName" --location "$Location" --name $VMNames[$i] --image "win2016datacenter" --size "Standard_DS1_v2" --admin-username "locadmin" --admin-password "P@ssw0rd01 !" --os-disk-name "$OSDiskName" --nics "$NICName"
    
}
$VMNamesJSON = $VMNamesJSON + "]"
$VMNamesJSON = $VMNamesJSON -replace '""', '","'
$ShutdownTemplateJSON -replace "##VMNAMES##", $VMNamesJSON -replace "##NUMBERVMS##", $VMNames.count | Out-File -FilePath $ShutdownTemplateFileNew -Encoding ascii

az group deployment create --resource-group "$ResourceGroupName" --name "azmonvm-vmdeploy" --template-file "$ShutdownTemplateFileNew"