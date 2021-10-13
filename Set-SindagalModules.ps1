$userPsModulesDir = ($env:PsModulePath -split '(?=[;])',5)[0]
$singadalModuleDir = "$userPsModulesDir\Sindagal"

If(!(test-path $singadalModuleDir))
{
    New-Item -Path $singadalModuleDir -ItemType Directory
}

$sindagalModulePath = $singadalModuleDir + "\Sindagal.psm1"
Invoke-WebRequest -uri  "https://raw.githubusercontent.com/denzii/sindagal/master/Sindagal.psm1" -Method "GET" -Outfile $sindagalModulePath

Import-Module -Global -Name Sindagal

Get-Module -ListAvailable | Where-Object Name -eq "Sindagal"
