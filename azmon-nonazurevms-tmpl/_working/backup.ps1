cd $PSScriptRoot
$jsondata = get-content -raw -path ".\template.json" | convertfrom-json
$version = $jsondata.variables.TemplateVersion
cd ..
new-item -name $version -ItemType directory -ErrorAction SilentlyContinue
cd _working
$destdir = "..\" + $version
copy-item ".\*.*" -Destination $destdir  -force

sleep 5

