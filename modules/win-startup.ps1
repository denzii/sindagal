"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Welcome to Sindagal Windows! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
"                                                                                                                        " | Write-Host -BackgroundColor Black
"                                              This script will:                                                         " | Write-Host -ForegroundColor Cyan -BackgroundColor Black
"                                       Download Chocolatey package manager                                              " | Write-Host -ForegroundColor Cyan -BackgroundColor Black
"                                                                                                                        " | Write-Host -BackgroundColor Black
"                                       Download and configure Windows Terminal                                          " | Write-Host -ForegroundColor Cyan -BackgroundColor Black
# "                                       Download and configure Powershell Core Latest                                    " | Write-Host -ForegroundColor Cyan -BackgroundColor Black
"                                       Download and configure Cascadia-Code PL Font family                              " | Write-Host -ForegroundColor Cyan -BackgroundColor Black
"                                       Download and configure Oh My Posh for Powershell                                 " | Write-Host -ForegroundColor Cyan -BackgroundColor Black
"                                                                                                                        " | Write-Host -BackgroundColor Black
"                                       Enable WSL2 and download the Alpine Distro                                       " | Write-Host -ForegroundColor Cyan -BackgroundColor Black
"                                       Download and configure Z shell and Oh My Zsh                                     " | Write-Host -ForegroundColor Cyan -BackgroundColor Black
"                                                                                                                        " | Write-Host -BackgroundColor Black
"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~         Proceed?            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black

 $confirmation = Read-Host "                                                      y/n: "
# $confirmation = "y"
if ($confirmation -eq 'y') {
     $cmdOutput = chocolatey --yes | Out-String
     if(!$cmdOutput) {        
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Setting directory for chocolatey installation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
        "                                                                                                                        " | Write-Host -BackgroundColor Black

		$InstallDir='C:\ProgramData\chocoportable'
        $env:ChocolateyInstall="$InstallDir"
		Set-ExecutionPolicy Bypass -Scope Process -Force;
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  Installing Chocolatey  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
        "                                                                                                                        " | Write-Host -BackgroundColor Black

		iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))    
    }

    $cmdOutput = chocolatey -y | Out-String
    if(!$cmdOutput){
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ For some reason chocolatey was not installed ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor Red -BackgroundColor Black
		"                                          Bye~~                                                                         " | Write-Host -ForegroundColor Red -BackgroundColor Black
    }

	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Upgrading Chocolatey ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
    "                                                                                                                        " | Write-Host -BackgroundColor Black
	choco upgrade chocolatey -y

	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Installing Microsoft Terminal ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	choco install microsoft-windows-terminal -y --pre 
    
	$wtSettingsURL = "https://raw.githubusercontent.com/denzii/sindagal/master/settings.json"
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~ Replacing Windows Terminal settings with pre-configured settings downloaded from github ~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~ ${wtSettingsURL} ~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black

    $windowsTerminalConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    $windowsTerminalBackupConfigPath = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings-backup.json"
    
    if (!(Test-Path -Path $windowsTerminalBackupConfigPath -PathType Leaf)){
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Backing up windows terminal settings ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
		"                                                                                                                        " | Write-Host -BackgroundColor Black
        Rename-Item -LiteralPath $windowsTerminalConfigPath -NewName "settings-backup.json"
    }
    Invoke-WebRequest -uri  "https://raw.githubusercontent.com/denzii/sindagal/master/settings.json" -Method "GET" -Outfile $windowsTerminalConfigPath
	
	# "                                                                                                                        " | Write-Host -BackgroundColor Black
	# "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Installing Powershell Core latest  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	# "                                                                                                                        " | Write-Host -BackgroundColor Black
    # choco install powershell-core -y --pre  

	if (!(Get-Module -ListAvailable -Name oh-my-posh)) {
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Installing OhMyPosh ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		Install-Module oh-my-posh -Force -Scope CurrentUser
	} 

	if (!(Get-Module -ListAvailable -Name posh-git)) {
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Installing PoshGit ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		Install-Module posh-git -Force -Scope CurrentUser
	} 


    $cascadiaCodeURL = "https://github.com/AaronFriel/nerd-fonts/releases/download/v1.2.0/CascadiaCode.Nerd.Font.Complete.ttf"
	$cascadiaDestinationPath = ".\cascadia-code"

	If(!(test-path $cascadiaDestinationPath)){
		New-Item -Path $cascadiaDestinationPath -ItemType "directory"
	}
	
	"                                                                                                                        " | Write-Host -BackgroundColor Black	
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Downloading Cascadia Code NF Patch from ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"  ~~~~~  ${cascadiaCodeURL}\  ~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black

	if(!(test-path "${cascadiaDestinationPath}\CascadiaCode.Nerd.Font.Complete.ttf")){
		Invoke-WebRequest -uri $cascadiaCodeURL -Method "GET" -Outfile "${cascadiaDestinationPath}\CascadiaCode.Nerd.Font.Complete.ttf"
	}

	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~ Iterating over ${cascadiaDestinationPath} folder contents to save each font on the Host ~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
    $files = Get-ChildItem "${cascadiaDestinationPath}"
    foreach ($f in $files){
        $FontFile = [System.IO.FileInfo]$f
	
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
		    If ((Test-Path ("C:\Windows\Fonts\" + $FontFile.Name)) -eq $true) {
    			Write-Host ('Success') -Foreground Yellow
		    } else {
    			Write-Host ('Failed') -ForegroundColor Red
		    }
		    $Copy = $false
		    #Test if font registry entry exists
		    If ($null -ne (Get-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue)) {
    			#Test if the entry matches the font file name
			    If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
    				Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline  -ForegroundColor White 
				    Write-Host ('Success') -ForegroundColor Yellow
			    } else {
    				$AddKey = $true
				    Remove-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -Force
				    Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline  -ForegroundColor White
                    				    New-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
				    If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
    					Write-Host ('Success') -ForegroundColor Yellow
				    } else {
    					Write-Host ('Failed') -ForegroundColor Red
				    }
				$AddKey = $false
			    }
		    } else {
    			$AddKey = $true
			    Write-Host ('Adding' + [char]32 + $FontName + [char]32 + 'to the registry.....') -NoNewline  -ForegroundColor White
			    New-ItemProperty -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $FontFile.Name -Force -ErrorAction SilentlyContinue | Out-Null
			    If ((Get-ItemPropertyValue -Name $FontName -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts") -eq $FontFile.Name) {
    				Write-Host ('Success') -ForegroundColor Yellow
			    } else {
    				Write-Host ('Failed') -ForegroundColor Red
	    		}
    			$AddKey = $false
	    	}
		
    	} catch {
	    	If ($Copy -eq $true) {
		    	Write-Host ('Failed') -ForegroundColor Red
			    $Copy = $false
		    }
		    If ($AddKey -eq $true) {
			    Write-Host ('Failed') -ForegroundColor Red
			    $AddKey = $false
		    }
		    write-warning $_.exception.message
	    } 
    }



	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~ Setting current powershell profile theme to 'darkblood' and sourcing the change ~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
    Set-PoshPrompt -Theme darkblood
	     
	$psHomeSettingsURL = "https://raw.githubusercontent.com/denzii/sindagal/master/Profile.ps1"
	$psProfilePath = "$PSHOME\Profile.ps1"
	$psProfileBackupPath = "$PSHOME\Profile-backup.ps1"
    
	if (!(Test-Path -Path $psProfileBackupPath -PathType Leaf)){
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Backing up powershell profile settings ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
		"                                                                                                                        " | Write-Host -BackgroundColor Black
		Rename-Item -LiteralPath $psProfilePath -NewName "Profile-backup.ps1"
    }
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~ Replacing Powershell profile with pre-configured settings downloaded from github ~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~ ${psHomeSettingsURL} ~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	Invoke-WebRequest -uri $psHomeSettingsURL -Method "GET" -Outfile $psProfilePath
    . $PROFILE
    

	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Enabling Windows Subsystem for Linux on Host  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Enabling Virtualization Feature on Host  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  Downloading Linux Kernel Update Package x64 from  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~  https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi ~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	Invoke-WebRequest -uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -Method "GET"  -OutFile .\wsl_update_x64.msi 

	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  Invoking Linux Kernel Update Package x64  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	.\wsl_update_x64.msi


	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  Installing Alpine Distro on WSL2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	choco install wsl-alpine -y
    
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ All Done <3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor Magenta -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~  Please restart your machine for all changes to take effect!  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor DarkRed -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  But before that...  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor White -BackgroundColor Black
	"  ~~~~~~~~~~~~~~~~~~~ Would you like to list all available OhMyPosh Themes in Windows Terminal? ~~~~~~~~~~~~~~~~~~~~~~  " | Write-Host -ForegroundColor Green -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black
	"                                                                                                                        " | Write-Host -BackgroundColor Black

	$confirmation = Read-Host "                                                      y/n: "
    if ($confirmation -eq 'y') {
		wt powershell -noexit -c Get-PoshThemes
    }
}
