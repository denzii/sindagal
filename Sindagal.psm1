

function Test-Elevation {
    [OutputType([boolean])]
    $elevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    return $elevated
}

#############################################################################################################################################
# Set Environment Variables For Initial Host System State
# Tested ✓
function Set-EnvState {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges! Please run it through an elevated powershell prompt."
    }
    Write-Host "Setting initial system state..."
    
    $osArchitectureBits = ($env:PROCESSOR_ARCHITECTURE -split '(?=\d)',2)[1]
    Write-Host "System has x${osArchitectureBits} bits" 
    Set-Item -Path Env:SINDAGAL_OS_BITS -Value($osArchitectureBits)

    $osArchitecture = ($env:PROCESSOR_ARCHITECTURE -split '(?=\d)',2)[0] 
    Write-Host "System has ${osArchitecture} processor"
    Set-Item -Path Env:SINDAGAL_OS_ARCHITECTURE -Value($osArchitecture)

    $osBuild = [int]((wmic os get BuildNumber) -split  '(?=\d)',2)[3]
    Write-Host "OS build is ${osBuild}" 
    Set-Item -Path Env:SINDAGAL_OS_BUILD -Value($osBuild)

    $osVersion = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId 
    Write-Host "OS version is ${osVersion}" 
    Set-Item -Path Env:SINDAGAL_OS_VER -Value($osVersion)

    $isWslEnabled = ((Get-WindowsOptionalFeature -Online | Where-Object FeatureName -eq Microsoft-Windows-Subsystem-Linux).State) -eq "Enabled"
    Write-Host "System has WSL enabled?: ${isWslEnabled}"
    Set-Item -Path Env:SINDAGAL_INIT_WSL -Value($isWslEnabled)
    
    $isVirtualMachineEnabled = ((Get-WindowsOptionalFeature -Online | Where-Object FeatureName -eq VirtualMachinePlatform).State) -eq "Enabled"
    Write-Host "System has Virtual Machine Platform enabled?: ${isVirtualMachineEnabled}"
    Set-Item -Path Env:SINDAGAL_INIT_VMP -Value($isVirtualMachineEnabled)
    Set-Item -Path Env:SINDAGAL_CONFIGURED -Value($true)
}

#############################################################################################################################################
# Set Environment Variables For Initial System State Pertaining to Windows Terminal & terminal polyfills
# Tested ✓
function Set-AddonState {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges!"
    }
    Write-Host "Setting initial addon state..."

    $isChocoInstalled = Test-Chocolatey
    Write-Host "System has chocolatey installed?: ${isChocoInstalled}" 

    $isWindowsTerminalInstalled = Test-WindowsTerminal
    Write-Host "System has windows terminal installed?: ${isWindowsTerminalInstalled}" 

    $isOhMyPoshInstalled = Test-OhMyPosh
    Write-Host "Terminal has oh-my-posh polyfill?: ${isOhMyPoshInstalled}"

    $isPoshGitInstalled = Test-PoshGit
    Write-Host "Terminal has posh-git polyfill?: ${isPoshGitInstalled}"

    $isCascadiaCodeInstalled = Test-Glyphs
    Write-Host "Terminal has Cascadia Code Nerd Font glyphs installed?: ${isCascadiaCodeInstalled}"

    Set-Item -Path Env:SINDAGAL_INIT_CHOCO -Value($isChocoInstalled)
    Set-Item -Path Env:SINDAGAL_INIT_WTER -Value($isWindowsTerminalInstalled)
    Set-Item -Path Env:SINDAGAL_INIT_OMP -Value($isOhMyPoshInstalled)
    Set-Item -Path Env:SINDAGAL_INIT_PG -Value($isPoshGitInstalled)
    Set-Item -Path Env:SINDAGAL_INIT_CCNF -Value($isCascadiaCodeInstalled)
}

#############################################################################################################################################
# Tested ✓
function Test-WindowsTerminal {
    [OutputType([boolean])]

    $windowsTerminalCommandOutput = [string](Get-Command -Name wt.exe -ErrorAction SilentlyContinue)
    $isWindowsTerminalInstalled = !([string]::IsNullOrEmpty($windowsTerminalCommandOutput))
    
    return $isWindowsTerminalInstalled
}

# Tested ✓
function Enable-WindowsTerminal {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
     }     
     if (!(Test-Chocolatey)){
     	throw "This requires chocolatey, please run Enable-Chocolatey function first"
     }
     
     Write-Host "Installing Microsoft Terminal through Chocolatey" -ForegroundColor White -BackgroundColor Black
     choco install microsoft-windows-terminal -y --pre 
    
     #TODO: Move settings backup to a separate function so it can be executed after wsl setup
     #$wtSettingsURL = "https://raw.githubusercontent.com/denzii/sindagal/master/settings.json"

     #Write-Host "Replacing Windows Terminal settings with pre-configured settings downloaded from github" -ForegroundColor White -BackgroundColor Black
     #Write-Host "${wtSettingsURL}"  -ForegroundColor White -BackgroundColor Black

    #$windowsTerminalConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    #$windowsTerminalBackupConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings-backup.json"
    
    #if (!(Test-Path -Path $windowsTerminalBackupConfigPath -PathType Leaf)){
	#Write-Host "Backing up windows terminal settings" -ForegroundColor White -BackgroundColor Black
        #Rename-Item -LiteralPath $windowsTerminalConfigPath -NewName "settings-backup.json"
    #}

    #Invoke-WebRequest -uri  "https://raw.githubusercontent.com/denzii/sindagal/master/settings.json" -Method "GET" -Outfile $windowsTerminalConfigPath
}


# Tested ✓
function Disable-WindowsTerminal {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
     }     
     if (!(Test-Chocolatey)) {
     	throw "This requires chocolatey, please run Enable-Choco function first"
     }

     if (Test-WindowsTerminal) {
     Write-Host "Removing Microsoft Windows Terminal Executable through Chocolatey" -ForegroundColor White -BackgroundColor Black
     
     choco uninstall microsoft-windows-terminal -y --pre --force
     
     # remove leftover appx package manually (for some reason choco is not reliably removing it)
     $windowsTerminalFullName = (Get-AppxPackage | Where-Object Name -eq "Microsoft.WindowsTerminalPreview").PackageFullName
     Remove-AppxPackage -Package $windowsTerminalFullName
     }
}

function Restore-WindowsTerminal {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
     }     
    Write-Host "Restoring Microsoft Windows Terminal to its initial state" -ForegroundColor White -BackgroundColor Black

    $windowsTerminalConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    $windowsTerminalBackupConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings-backup.json"

    Remove-Item $windowsTerminalConfigPath;Rename-Item -Path $windowsTerminalBackupConfigPath -NewName "settings.json"
}

#############################################################################################################################################

# Tested ✓
function Test-Chocolatey {
    [OutputType([boolean])]

    $chocoCommandOutput = [string](Get-Command -Name choco.exe -ErrorAction SilentlyContinue)
    $isChocoInstalled = !([string]::IsNullOrEmpty($chocoCommandOutput))

    return $isChocoInstalled
}

# Tested ✓
function Enable-Chocolatey {    
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
     }     
     
    $InstallDir='C:\ProgramData\chocoportable'
    $env:ChocolateyInstall="$InstallDir"
        
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    Write-Host "Installing Chocolatey using official script @ https://community.chocolatey.org/install.ps1" -ForegroundColor White -BackgroundColor Black

    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))    

   if (!(Test-Chocolatey)) {
       Write-Host "For some reason chocolatey was not installed " -ForegroundColor Red -BackgroundColor Black
       Write-Host "Bye~~" -ForegroundColor Red -BackgroundColor Black
   }

   choco upgrade chocolatey -y
}

# Tested ✓
function Disable-Chocolatey {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
     }
     
    if(Test-Chocolatey){
     Write-Host "Uninstalling Chocolatey" -ForegroundColor White -BackgroundColor Black
     $InstallDir='C:\ProgramData\chocoportable'
     
     Get-ChildItem -Path $InstallDir -Recurse | Remove-Item -force -recurse
     Remove-Item $InstallDir -Recurse -Force 
     
     $env:ChocolateyInstall=$null
    }
}

#############################################################################################################################################

# Tested ✓
function Test-OhMyPosh {
    [OutputType([boolean])]

    $ohMyPoshCommandOutput = [string](Get-Module -ListAvailable -Name oh-my-posh) 
    $isOhMyPoshInstalled =  !([string]::IsNullOrEmpty($ohMyPoshCommandOutput))
    
    return $isOhMyPoshInstalled
}

# Tested ✓
function Enable-OhMyPosh {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
     }   
     Write-Host "Installing Oh my posh powershell module through PowerShellGet" -ForegroundColor White -BackgroundColor Black
     ECHO Y | powershell Install-Module oh-my-posh -Force -Scope CurrentUser
}

# Tested ✓
function Disable-OhMyPosh {
    if(Test-OhMyPosh){
    	Write-Host "Removing Oh my posh powershell module through PowerShellGet" -ForegroundColor White -BackgroundColor Black
    	Get-InstalledModule -Name oh-my-posh | Uninstall-Module 
    }
}

#############################################################################################################################################

# Tested ✓
function Test-PoshGit {
    [OutputType([boolean])]

    $poshGitCommandOutput = [string](Get-Module -ListAvailable -Name posh-git) 
    $isPoshGitInstalled =  !([string]::IsNullOrEmpty($poshGitCommandOutput))

    return $isPoshGitInstalled
}

# Tested ✓
function Enable-PoshGit {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
     }   
    Write-Host "Installing posh git powershell module through PowerShellGet" -ForegroundColor White -BackgroundColor Black
     ECHO Y | powershell Install-Module posh-git -Force -Scope CurrentUser
}

# Tested ✓
function Disable-PoshGit {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
     }  
    if (Test-PoshGit){ 
    	Write-Host "Removing posh git powershell module through PowerShellGet" -ForegroundColor White -BackgroundColor Black
    	Get-InstalledModule -Name posh-git | Uninstall-Module 
    }
}

#############################################################################################################################################

# Tested ✓
function Test-Glyphs{
    # For some reason return type annotation does not work if importing library?
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null 
    $fontQueryOutput = ([string]((New-Object System.Drawing.Text.InstalledFontCollection).Families | Where-Object Name -eq "CascadiaCode Nerd Font"))
    $isCascadiaCodeInstalled = (![string]::IsNullOrEmpty($fontQueryOutput))
    
    return $isCascadiaCodeInstalled
}

# Tested ✓
function Add-Glyphs {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
    }
    
    #if(!(Test-Glyphs)){   
    	$cascadiaCodeURL = "https://github.com/AaronFriel/nerd-fonts/releases/download/v1.2.0/CascadiaCode.Nerd.Font.Complete.ttf"
    	
	$cascadiaDestinationPath = "C:\ProgramData\Sindagal\cascadia-code"
	If(!(test-path $cascadiaDestinationPath)){
       	    New-Item -Path $cascadiaDestinationPath -ItemType "directory"
	}
	
	Write-Host "Downloading Cascadia Code NF Patch from" -ForegroundColor White -BackgroundColor Black
	Write-Host "${cascadiaCodeURL}\"  -ForegroundColor White -BackgroundColor Black

	if(!(test-path "${cascadiaDestinationPath}\CascadiaCode.Nerd.Font.Complete.ttf")){
		Invoke-WebRequest -uri $cascadiaCodeURL -Method "GET" -Outfile "${cascadiaDestinationPath}\CascadiaCode.Nerd.Font.Complete.ttf"
	}

	Write-Host "Iterating over ${cascadiaDestinationPath} folder contents to save each font on the Host" -ForegroundColor White -BackgroundColor Black
        $files = Get-ChildItem "${cascadiaDestinationPath}"

        foreach ($f in $files){
            $FontFile = [System.IO.FileInfo]$f
            Install-Font -FontFile $FontFile
        }

	Write-Host "Restarting Powershell session for changes to take effect..." -ForegroundColor White -BackgroundColor Black
	Get-Process -Id $PID | Select-Object -ExpandProperty Path | ForEach-Object { Invoke-Command { & "$_" } -NoNewScope }
    #}
}

# Tested ✓
function Remove-Glyphs {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
    } 
    if(Test-Glyphs){  
	$cascadiaDestinationPath = "C:\ProgramData\Sindagal\cascadia-code"
        Write-Host "Iterating over ${cascadiaDestinationPath} folder contents to delete each font from the Host" -ForegroundColor White -BackgroundColor Black
        $files = Get-ChildItem "${cascadiaDestinationPath}"
	
        foreach ($f in $files){
            $FontFile = [System.IO.FileInfo]$f
            Remove-Font -FontFile $FontFile
        }
	Write-Host "Restarting Powershell session for changes to take effect..." -ForegroundColor White -BackgroundColor Black
	Get-Process -Id $PID | Select-Object -ExpandProperty Path | ForEach-Object { Invoke-Command { & "$_" } -NoNewScope }
    }
}
#############################################################################################################################################


function Test-WSL2Support {
    [OutputType([boolean], [System.Void])]

    $amdRequiredOsVersion = [int]1903 
    $amdRequiredOsBuild = [int]18362 
   
    $armRequiredOsVersion = [int]2004 
    $armRequiredOsBuild = [int]19041 
   
    if ($null -eq $env:SINDAGAL_OS_BITS){
        throw "This requires the initial environment state to be set, please run the Set-EnvState function first."
    }

    $amdWsl2EligibilityCriteria = $env:SINDAGAL_OS_VER -ge $amdRequiredOsVersion -and $env:SINDAGAL_OS_BUILD -ge $amdRequiredOsBuild
    $armWsl2EligibilityCriteria = $env:SINDAGAL_OS_VER -ge $armRequiredOsVersion -and $env:SINDAGAL_OS_BUILD -ge $armRequiredOsBuild

    $isAmd = $env:SINDAGAL_OS_ARCHITECTURE -eq "AMD" 
    $isArm = $env:SINDAGAL_OS_ARCHITECTURE -eq "ARM" 
    $is64Bits = $env:SINDAGAL_OS_BITS -eq "64" 

    $osIsWsl2Eligible = If($isAmd){ $amdWsl2EligibilityCriteria } ElseIf($isArm){$armWsl2EligibilityCriteria} Else {[bool]$false} 
    $hostSupportsWsl2 = $is64Bits -and $osIsWsl2Eligible   

    return $hostSupportsWsl2
}

function Test-WSL {
    [OutputType([boolean])]

    $wslCommandOutput = [string](Get-Command -Name wsl.exe -ErrorAction SilentlyContinue)
    $isWslInstalled = !([string]::IsNullOrEmpty($wslCommandOutput))

    return $isWslInstalled
}


function Enable-WSL {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
    }
    if(!($env:SINDAGAL_CONFIGURED)){
        throw "This requires setting the env, please run Set-EnvState first"
    }
    if(!(Test-WSL)){
    	try {
			Write-Host "Enabling WSL..." -ForegroundColor White -BackgroundColor Black
      	    ECHO N | powershell Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All 

        	if (Test-WSL2Support){
	    		Write-Host "Host Supports WSL2..." -ForegroundColor White -BackgroundColor Black
	   			Write-Host "Enabling Virtual Machine Platform..." -ForegroundColor White -BackgroundColor Black
            	ECHO N | powershell Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
            
            	$installFile = ".\wsl_update_x64.msi"
            	Invoke-WebRequest -uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -Method "GET"  -OutFile $installFile 
            
            	$kernelUpdateFullPath = Resolve-Path $installFile
            
            	# silent install
	    		Write-Host "Silently running the WSL2 Kernel Update" -ForegroundColor White -BackgroundColor Black
            	$installerParams = @("/qn", "/i", $kernelUpdateFullPath)
            	Start-Process "msiexec.exe" -ArgumentList $installerParams -Wait -NoNewWindow
        	}
    	Get-Process -Id $PID | Select-Object -ExpandProperty Path | ForEach-Object { Invoke-Command { & "$_" } -NoNewScope }
    	Write-Host "WSL has been enabled, please restart for the changes to take effect..." -ForegroundColor White -BackgroundColor Black
    	}
    	catch {
        	Write-Host 'Failed' -ForegroundColor Red
        	write-warning $_.exception.message
    	}
    }
}

function Disable-WSL {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
    }   
    if(Test-WSL){
        try {
            Write-Host "Disabling WSL..." -ForegroundColor White -BackgroundColor Black
            Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

            if (Test-WSL2Support){
    		Write-Host "Disabling Virtual Machine Platform..." -ForegroundColor White -BackgroundColor Black                
		Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
             
                $installFile = ".\wsl_update_x64.msi"            
                $kernelUpdateFullPath = Resolve-Path $installFile
            
                # silent uninstall
		Write-Host "Downgrading from WSL2 Kernel Patch..." -ForegroundColor White -BackgroundColor Black                
                $installerParams = @("/qn", "/x", $kernelUpdateFullPath)
                Start-Process "msiexec.exe" -ArgumentList $installerParams -Wait -NoNewWindow
            }
        }
        catch {
            Write-Host 'Failed' -ForegroundColor Red
            write-warning $_.exception.message
        }
    Get-Process -Id $PID | Select-Object -ExpandProperty Path | ForEach-Object { Invoke-Command { & "$_" } -NoNewScope }
    Write-Host "WSL has been disabled, please restart for the changes to take effect..." -ForegroundColor White -BackgroundColor Black
    }
}

function New-Distro {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
    }   
    Invoke-WebRequest -Uri https://aka.ms/wsl-debian-gnulinux -OutFile .\Debian.appx -UseBasicParsing
    Add-AppxPackage .\Debian.appx
}

function Remove-Distro {
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
    }   
    wsl.exe --unregister Debian
    Remove-AppxPackage .\Debian.appx
}

function Register-DistroAddons {

}

#############################################################################################################################################

#region Internal Functions

# Install-Font Function Author: Mick Pletcher
# Published: Tuesday, June 29, 2021
# Source: https://mickitblog.blogspot.com/2021/06/powershell-install-fonts.html
# Tested ✓
function Install-Font {
    param  
    (  
         [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$FontFile  
    ) 
    
    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
    }   
    
    #Get Font Name from the File's Extended Attributes
    $oShell = new-object -com shell.application
    $Folder = $oShell.namespace($FontFile.DirectoryName)
    $Item = $Folder.Items().Item($FontFile.Name)
    $FontName = $Folder.GetDetailsOf($Item, 21)
    try {
        switch ($FontFile.Extension) {
            ".ttf" {$FontName = $FontName + [char]32 + '(TrueType)'}
            ".otf" {$FontName = $FontName + [char]32 + '(OpenType)'}
        }
        $Copy = $true
        Write-Host ('Copying' + $FontFile.Name + '.....') -NoNewline
        Copy-Item -Path $fontFile.FullName -Destination ("C:\Windows\Fonts\" + $FontFile.Name) -Force
        #Test if font is copied over
        If ((Test-Path("C:\Windows\Fonts\" + $FontFile.Name)) -eq $true) {
             Write-Host 'Success' -Foreground Yellow
        } else {
             Write-Host 'Failed' -ForegroundColor Red
        }
        $Copy = $false
        #Test if font registry entry exists
        If ($null -ne (Get-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
             #Test if the entry matches the font file name
            If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
                Write-Host 'Adding' +  $FontName + 'to the registry.....' -NoNewline  -ForegroundColor White 
                Write-Host 'Success' -ForegroundColor Yellow
            } else {
                $AddKey = $true
                Remove-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force
                Write-Host 'Adding' + $FontName + 'to the registry.....' -NoNewline  -ForegroundColor White
                New-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
                
                If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
                    Write-Host 'Success' -ForegroundColor Yellow
                 } else {
                    Write-Host 'Failed' -ForegroundColor Red
                 }
             $AddKey = $false
            }
        } else {
            $AddKey = $true
            Write-Host 'Adding' + $FontName + 'to the registry.....' -NoNewline  -ForegroundColor White
            New-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
            If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
                Write-Host 'Success' -ForegroundColor Yellow
            } else {
                Write-Host 'Failed' -ForegroundColor Red
            }
            $AddKey = $false
        }
    } catch {
        If ($Copy -eq $true) {
            Write-Host 'Failed' -ForegroundColor Red
            $Copy = $false
        }
        If ($AddKey -eq $true) {
            Write-Host 'Failed' -ForegroundColor Red
            $AddKey = $false
        }
        write-warning $_.exception.message
    } 
}

# Tested ✓
function Remove-Font {
    param  
    (  
         [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$FontFile  
    ) 

    if(!(Test-Elevation)){
    	throw "This requires admin privileges, please run it through an elevated powershell prompt"
    }   
    
     #Get Font Name from the File's Extended Attributes
     $oShell = new-object -com shell.application
     $Folder = $oShell.namespace($FontFile.DirectoryName)
     $Item = $Folder.Items().Item($FontFile.Name)
     $FontName = $Folder.GetDetailsOf($Item, 21)
     try {
        switch ($FontFile.Extension) {
            ".ttf" { $FontName = $FontName + [char]32 + '(TrueType)' }
            ".otf" { $FontName = $FontName + [char]32 + '(OpenType)' }
        }
 	$fontRegistryKeyExists = $null -ne (Get-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)
         If ($fontRegistryKeyExists) {
            Write-Host ('Removing key for ' + $FontName + ' from the registry.....') -NoNewline  -ForegroundColor White
            Remove-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force           
         } 

        Write-Host ('Deleting' + $FontFile.Name + '.....') -NoNewline
        Remove-Item ("C:\Windows\Fonts\" + $FontFile.Name) -Force
         
        $fontIsDeleted = (Test-Path ("C:\Windows\Fonts\" + $FontFile.Name)) -eq $false
        If ($fontIsDeleted) { Write-Host ('Success') -Foreground Yellow }
        else {  Write-Host ('Failed') -ForegroundColor Red }
        
     } catch {
        Write-Host ('Failed') -ForegroundColor Red
        write-warning $_.exception.message
     }
} 
#endregion Internal Functions

Export-ModuleMember -function `
    Set-EnvState,`
    Set-AddonState,`
    Test-WindowsTerminal,`
    Enable-WindowsTerminal,`
    Disable-WindowsTerminal,`
    Format-WindowsTerminal,`
    Test-Chocolatey,`
    Enable-Chocolatey,`
    Disable-Chocolatey,`
    Test-OhMyPosh,`
    Enable-OhMyPosh,`
    Disable-OhMyPosh,`
    Test-PoshGit,`
    Enable-PoshGit,`
    Disable-PoshGit,`
    Test-Glyphs,`
    Add-Glyphs,`
    Remove-Glyphs,`
    Test-WSL,`
    Enable-WSL,`
    Disable-WSL,`
    New-Distro,`
    Register-DistroAddons,`
    Remove-Distro,`
    Test-Elevation

# TODO: Get the windows terminal settings path dynamically without hardcode
# TODO: Handle the case where windows terminal initially exists (Write/Delete in settings.json rather than replacing completely)
# TODO: Handle importing custom distro with pre-configured zshell and oh my zsh
# TODO: Configure zshell and oh my zsh for fresh/existing wsl after computer restart with bash scripts 
# TODO: Configure Windows Terminal foreach (wsl.exe --list --all)
