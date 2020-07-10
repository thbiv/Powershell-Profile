# Import Modules
Import-Module -Name PSReadLine, posh-git
Import-Module -Name Pscx -Function help, less, Show-Tree, Start-PowerShell -Cmdlet ConvertFrom-Base64, ConvertTo-Base64
Import-Module -Name PowerShellCookbook -Function Show-Object

# Variables
# Add the gsudo executable directory to the PATH variable
Add-PathVariable 'C:\ProgramData\chocolatey\lib\gsudo\bin\'

# Variable for the path where this profile script is located
New-Variable -Name PSProfileScriptPath -Value $(Split-Path $Profile) -Option Constant -Scope Script

# Variable for paths to the Powershell Scripts folders (Paths where scripts are installed from the PSGallery)
New-Variable -Name PSScripts -Option Constant -Scope Global -Value @{
    CurrentUser = "$PSProfileScriptPath\Scripts"
    AllUsers = "$Env:ProgramFiles" + "\Powershell\Scripts"
}

# Aliases
# calling the gsudo tool with 'sudo'
New-Alias sudo "gsudo"

# Calling Notepad++ using npp
New-Alias npp   "C:\Program Files\Notepad++\notepad++.exe" #Notepad++

# Posh-Git Settings
# Set the Posh-Git Prompt Suffix to nothing since the current directory is not where the prompt will be.
$GitPromptSettings.DefaultPromptSuffix.text = ""

# Set the Posh-Git Window Title to nothing so it does not change the default window title.
$GitPromptSettings.WindowTitle = ""

# Custom Prompt
Function Prompt {
    $Prompt = @()
    If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		$Prompt += Write-Prompt '[Admin]' -ForegroundColor ([ConsoleColor]::Red)
	}
    $Prompt += Write-Prompt "$(Get-Date -Format 'yyyyMMdd | HH:mm:ss')"
    $Prompt += Write-Prompt ("$env:USERNAME" + '@' + "$env:COMPUTERNAME") -ForegroundColor ([ConsoleColor]::DarkGray)
    $Prompt += & $GitPromptScriptBlock
    $Prompt += Write-Prompt "`n"
    $Prompt += Write-Prompt (Get-ChildItem).Count
    $Prompt += Write-Prompt ("PS" + "$(">" * ($nestedPromptLevel + 1)) ")
    if ($Prompt) {"$Prompt"} else {""}
}

# Load PSReadLine Profile
. $PSProfileScriptPath\PSReadlineProfile.ps1

# Register PSLocalGallery if it does not exist
If (!(Get-PSRepository -Name PSLocalGallery -ErrorAction SilentlyContinue)) {
    $PSLocalGalleryPath = "C:\ProgramData\PSLocaLGallery\Repository"
    $Repo = @{
        Name = 'PSLocalGallery'
        SourceLocation = $PSLocalGalleryPath
        PublishLocation = $PSLocalGalleryPath
        InstallationPolicy = 'Trusted'
    }
    Register-PSRepository @Repo
}

# Update Help if Administrator
If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Start-Job -Name 'Update PS Help' -ScriptBlock {
        Try {Update-Help -Force -ErrorAction Stop}
        Catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning $ErrorMessage
        }
        Write-Output "Job completed successfully"
    } | Out-Null
}

# Profile Functions
# Create functions for moving up the directory tree
# https://matthewmanela.com/blog/quickly-moving-up-a-directory-tree/
For($i = 1; $i -le 5; $i++){
    $u =  "".PadLeft($i,"u")
    $unum =  "u$i"
    $d =  $u.Replace("u","../")
    Invoke-Expression "Function $u { Push-Location $d }"
    Invoke-Expression "Function $unum { Push-Location $d }"
}

# Function for retrieving the latest release version of Powershell
Function Get-PwshLatestRelease {
    $Params = @{
        'Uri' = 'https://api.github.com/repos/Powershell/Powershell/releases/latest'
        'Headers' = @{"Accept"="application/json"}
        'Method' = 'Get'
        'UseBasicParsing' = $True
    }
    $Response = Invoke-RestMethod @Params
    $Winx64Asset = $Response.assets | Where-Object {$_.name -like "*win-x64.zip"}

    $Props = [ordered]@{
        'Name' = $($Response.name)
        'Version' = $(($Response.tag_name).TrimStart('v'))
        'PublishedDate' = $($Response.published_at)
        'DownloadURL' = $($Winx64Asset.browser_download_url)
    }
    New-Object -TypeName PSObject -Property $Props
}

# Function to start and enter a PSRemoting session
Function New-PSRemoteSession {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        $shServerName,
        [PSCredential]$Cred = (Get-Credential)
    )
    If ($pscmdlet.ShouldProcess("$shServerName", "Create Remote Session")) {
	    $shSession = New-PSSession $shServerName -Credential $Cred
        Enter-PSSession -Session $shSession
    }
}
New-Alias -Name psrem -Value New-PSRemoteSession

# Function to output a username from the input of a SID
Function Convert-SIDToUserName {
    Param(
        $SID
    )
    ((((New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount])).Value).Split('\'))[1]
}

# Function to color code the Get-ChildItem output depending on extention of the file.
Function Get-ColoredDir {
    Param ($dir = ".", $all = $false)
    $origFg = $host.ui.rawui.foregroundColor
    If ($all) {$toList = Get-ChildItem -force $dir}
    Else {$toList = Get-ChildItem $dir}
    ForEach ($Item in $toList) {
        Switch ($Item.Extension) {
            ".Exe" {$host.ui.rawui.foregroundColor = "Green"}
            ".cmd" {$host.ui.rawui.foregroundColor = "DarkGreen"}
            ".bat" {$host.ui.rawui.foregroundColor = "DarkGreen"}
            ".ps1" {$host.ui.rawui.foregroundColor = "Magenta"}
            ".vbs" {$host.ui.rawui.foregroundColor = "DarkGreen"}
            ".psm1" {$host.ui.rawui.foregroundColor = "Magenta"}
            ".psd1" {$host.ui.rawui.foregroundColor = "Magenta"}
            ".txt" {$host.ui.rawui.foregroundColor = "Yellow"}
            Default {$host.ui.rawui.foregroundColor = $origFg}
        }
        If ($item.Mode.StartsWith("d")) {$host.ui.rawui.foregroundColor = $origFg}
        $item
    }
    $host.ui.rawui.foregroundColor = $origFg
}
New-Alias -Name LL -Value Get-ColoredDir

# Function to invoke the install-powershell.ps1 script to install the latest version of powershell
Function Install-Powershell {
    If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Invoke-Expression "&{$(Invoke-RestMethod https://aka.ms/install-powershell.ps1)} -UseMSI -Quiet"
    }
}