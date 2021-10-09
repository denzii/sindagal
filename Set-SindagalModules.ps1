$userPsModulesDir = ($env:PsModulePath -split '(?=[;])',5)[0]
$singadalModulesDir = "$userPsModulesDir/Sindagal"

If(!(test-path $singadalModulesDir))
{
    New-Item -Path $singadalModulesDir -ItemType Directory
}

Invoke-WebRequest -uri  "https://raw.githubusercontent.com/denzii/sindagal/master/Sindagal.psm1" -Method "GET" -Outfile $singadalModulesDir

Import-Module -Global -Name Sindagal
