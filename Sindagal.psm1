

function Test-Elevation {
    $Elevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ( -not $Elevated ) {
      throw "This module requires elevation."
    }
}

#############################################################################################################################################
# Set Environment Variables For Initial Host System State
function Set-EnvState {
    $osArchitectureBits = ($env:PROCESSOR_ARCHITECTURE -split '(?=\d)',2)[1] 
    Set-Item -Path Env:SINDAGAL_OS_BITS -Value ($osArchitectureBits)

    $osArchitecture = ($env:PROCESSOR_ARCHITECTURE -split '(?=\d)',2)[0] 
    Set-Item -Path Env:SINDAGAL_OS_ARCHITECTURE -Value ($osArchitecture)

    $osBuild = [int]((wmic os get BuildNumber) -split  '(?=\d)',2)[3] 
    Set-Item -Path Env:SINDAGAL_OS_BUILD -Value ($osBuild)

    $osVersion = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId 
    Set-Item -Path Env:SINDAGAL_OS_VER -Value ($osVersion)

    $isWslEnabled = ((Get-WindowsOptionalFeature -Online | Where-Object FeatureName -eq Microsoft-Windows-Subsystem-Linux).State) -eq "Enabled"
    Set-Item -Path Env:SINDAGAL_INIT_WSL -Value ($isWslEnabled)
    
    $isVirtualMachineEnabled = ((Get-WindowsOptionalFeature -Online | Where-Object FeatureName -eq VirtualMachinePlatform).State) -eq "Enabled"
    Set-Item -Path Env:SINDAGAL_INIT_VMP -Value ($isVirtualMachineEnabled)
}

#############################################################################################################################################
# Set Environment Variables For Initial System State Pertaining to Windows Terminal & terminal polyfills
function Set-AddonState {
    $isChocoInstalled = Test-Chocolatey
    $isWindowsTerminalInstalled = Test-WindowsTerminal
    $isOhMyPoshInstalled =  Test-OhMyPosh
    $isPoshGitInstalled =  Test-PoshGit
    $isCascadiaCodeInstalled = Test-Glyphs

    Set-Item -Path Env:SINDAGAL_INIT_CHOCO -Value ($isChocoInstalled)
    Set-Item -Path Env:SINDAGAL_INIT_WTER -Value ($isWindowsTerminalInstalled)
    Set-Item -Path Env:SINDAGAL_INIT_OMP -Value ($isOhMyPoshInstalled)
    Set-Item -Path Env:SINDAGAL_INIT_PG -Value ($isPoshGitInstalled)
    Set-Item -Path Env:SINDAGAL_INIT_CCNF -Value ($isCascadiaCodeInstalled)
}

#############################################################################################################################################

function Test-WindowsTerminal {
    [OutputType([boolean])]

    $windowsTerminalCommandOutput = [string](Get-Command -Name wt.exe -ErrorAction SilentlyContinue)
    $isWindowsTerminalInstalled = !([string]::IsNullOrEmpty($windowsTerminalCommandOutput))
    
    return $isWindowsTerminalInstalled
}

function Enable-WindowsTerminal {
	Write-Host "Installing Microsoft Terminal through Chocolatey" -ForegroundColor White -BackgroundColor Black
	choco install microsoft-windows-terminal -y --pre 
    
	$wtSettingsURL = "https://raw.githubusercontent.com/denzii/sindagal/master/settings.json"

	Write-Host "Replacing Windows Terminal settings with pre-configured settings downloaded from github" -ForegroundColor White -BackgroundColor Black
	Write-Host "${wtSettingsURL}"  -ForegroundColor White -BackgroundColor Black

    $windowsTerminalConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    $windowsTerminalBackupConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings-backup.json"
    
    if (!(Test-Path -Path $windowsTerminalBackupConfigPath -PathType Leaf)){
		Write-Host "Backing up windows terminal settings" -ForegroundColor White -BackgroundColor Black
        Rename-Item -LiteralPath $windowsTerminalConfigPath -NewName "settings-backup.json"
    }

    Invoke-WebRequest -uri  "https://raw.githubusercontent.com/denzii/sindagal/master/settings.json" -Method "GET" -Outfile $windowsTerminalConfigPath
}

function Disable-WindowsTerminal {
    Write-Host "Removing Microsoft Windows Terminal Executable through Chocolatey" -ForegroundColor White -BackgroundColor Black

	choco uninstall microsoft-windows-terminal -y --pre 
}

function Restore-WindowsTerminal {
    Write-Host "Restoring Microsoft Windows Terminal to its initial state" -ForegroundColor White -BackgroundColor Black

    $windowsTerminalConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    $windowsTerminalBackupConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings-backup.json"

    Remove-Item $windowsTerminalConfigPath;Rename-Item -Path $windowsTerminalBackupConfigPath -NewName "settings.json"
}

#############################################################################################################################################

function Test-Chocolatey {
    [OutputType([boolean])]

    $chocoCommandOutput = [string](Get-Command -Name choco.exe -ErrorAction SilentlyContinue)
    $isChocoInstalled = !([string]::IsNullOrEmpty($chocoCommandOutput))

    return $isChocoInstalled
}

function Enable-Chocolatey {      
    $InstallDir='C:\ProgramData\chocoportable'
    $env:ChocolateyInstall="$InstallDir"
        
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    Write-Host "Installing Chocolatey using official script @ https://community.chocolatey.org/install.ps1" -ForegroundColor White -BackgroundColor Black

    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))    

   if (!Test-Chocolatey) {
       Write-Host "For some reason chocolatey was not installed " -ForegroundColor Red -BackgroundColor Black
       Write-Host "Bye~~" -ForegroundColor Red -BackgroundColor Black
   }

   choco upgrade chocolatey -y
}

#############################################################################################################################################

function Test-OhMyPosh {
    [OutputType([boolean])]

    $ohMyPoshCommandOutput = [string](Get-Module -ListAvailable -Name oh-my-posh) 
    $isOhMyPoshInstalled =  !([string]::IsNullOrEmpty($ohMyPoshCommandOutput))
    
    return $isOhMyPoshInstalled
}

function Enable-OhMyPosh {
    Write-Host "Installing Oh my posh powershell module through PowerShellGet" -ForegroundColor White -BackgroundColor Black
	Install-Module oh-my-posh -Force -Scope CurrentUser
}

function Disable-OhMyPosh {
    Write-Host "Removing Oh my posh powershell module through PowerShellGet" -ForegroundColor White -BackgroundColor Black
    Get-InstalledModule -Name oh-my-posh | Uninstall-Module 
}

#############################################################################################################################################

function Test-PoshGit {
    [OutputType([boolean])]

    $poshGitCommandOutput = [string](Get-Module -ListAvailable -Name posh-git) 
    $isPoshGitInstalled =  !([string]::IsNullOrEmpty($poshGitCommandOutput))

    return $isPoshGitInstalled
}

function Enable-PoshGit {
    Write-Host "Installing posh git powershell module through PowerShellGet" -ForegroundColor White -BackgroundColor Black
    Install-Module posh-git -Force -Scope CurrentUser
}

function Disable-PoshGit {
    Write-Host "Removing posh git powershell module through PowerShellGet" -ForegroundColor White -BackgroundColor Black
    Get-InstalledModule -Name posh-git | Uninstall-Module 
}

#############################################################################################################################################

function Test-Glyphs {
    [OutputType([boolean])]

    $fontQueryOutput = [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null ;`
    [string]((New-Object System.Drawing.Text.InstalledFontCollection).Families | Where-Object Name -eq "CascadiaCode Nerd Font")
    $isCascadiaCodeInstalled = !([string]::IsNullOrEmpty($fontQueryOutput))

    return $isCascadiaCodeInstalled;
}

function Add-Glyphs {
    $cascadiaCodeURL = "https://github.com/AaronFriel/nerd-fonts/releases/download/v1.2.0/CascadiaCode.Nerd.Font.Complete.ttf"
	$cascadiaDestinationPath = ".\cascadia-code"

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
}

function Remove-Glyphs {
    $cascadiaDestinationPath = ".\cascadia-code"
    Write-Host "Iterating over ${cascadiaDestinationPath} folder contents to delete each font from the Host" -ForegroundColor White -BackgroundColor Black
    $files = Get-ChildItem "${cascadiaDestinationPath}"

    foreach ($f in $files){
        $FontFile = [System.IO.FileInfo]$f
        Remove-Font -FontFile $FontFile
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
        throw "Please run the Set-EnvState function first."
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
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All 

        if (Test-WSL2Support){
            Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
            
            $installFile = ".\wsl_update_x64.msi"
            Invoke-WebRequest -uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -Method "GET"  -OutFile $installFile 
            
            $kernelUpdateFullPath = Resolve-Path $installFile
            
            # silent install
            $installerParams = @("/qn", "/i", $kernelUpdateFullPath)
            Start-Process "msiexec.exe" -ArgumentList $installerParams -Wait -NoNewWindow
        }
    }
    catch {
        Write-Host 'Failed' -ForegroundColor Red
        write-warning $_.exception.message
    }

}

function Disable-WSL {
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All 

        if (Test-WSL2Support){
            Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
            
            $installFile = ".\wsl_update_x64.msi"            
            $kernelUpdateFullPath = Resolve-Path $installFile
            
            # silent uninstall
            $installerParams = @("/qn", "/x", $kernelUpdateFullPath)
            Start-Process "msiexec.exe" -ArgumentList $installerParams -Wait -NoNewWindow
        }
    }
    catch {
        Write-Host 'Failed' -ForegroundColor Red
        write-warning $_.exception.message
    }
}

function New-Distro {
    Invoke-WebRequest -Uri https://aka.ms/wsl-debian-gnulinux -OutFile .\Debian.appx -UseBasicParsing
    Add-AppxPackage .\Debian.appx
}

function Remove-Distro {
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
function Install-Font {
    param  
    (  
         [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$FontFile  
    ) 

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
        Write-Host ('Copying' + [char]32 + $FontFile.Name + '.....') -NoNewline
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
                Write-Host 'Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....' -NoNewline  -ForegroundColor White 
                Write-Host 'Success' -ForegroundColor Yellow
            } else {
                $AddKey = $true
                Remove-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force
                Write-Host 'Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....' -NoNewline  -ForegroundColor White
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
            Write-Host 'Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....' -NoNewline  -ForegroundColor White
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

function Remove-Font {
    param  
    (  
         [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FontFile  
    ) 

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
        Write-Host ('Deleting' + [char]32 + $FontFile.Name + '.....') -NoNewline
        Remove-Item ("C:\Windows\Fonts\" + $FontFile.Name) -Force
         
        $fontIsDeleted = (Test-Path ("C:\Windows\Fonts\" + $FontFile.Name)) -eq $false
        If ($fontIsDeleted) { Write-Host ('Success') -Foreground Yellow }
        else {  Write-Host ('Failed') -ForegroundColor Red }

         $fontRegistryKeyExists = $null -ne (Get-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)
         If ($fontRegistryKeyExists) {
            Write-Host ('Removing key for' + [char]32 + $FontName + [char]32 + 'from the registry.....') -NoNewline  -ForegroundColor White
            Remove-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force

            $registryKeyIsDeleted = !(Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name 
            If ($registryKeyIsDeleted) {  Write-Host ('Success') -ForegroundColor Yellow }
            else {  Write-Host ('Failed') -ForegroundColor Red }             
         } 
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
