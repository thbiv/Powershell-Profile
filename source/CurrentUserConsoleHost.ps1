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

#Variable for checking if this session has Administrator access
New-Variable -Name IsAdmin -Option Constant -Scope Global -Value $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

# Aliases
# calling the gsudo tool with 'sudo'
New-Alias sudo "gsudo"

# Calling Notepad++ using npp
New-Alias npp   "C:\Program Files\Notepad++\notepad++.exe" #Notepad++

# Posh-Git Settings
$GitPromptSettings.WindowTitle = ""
$GitPromptSettings.ShowStatusWhenZero = $false

# Custom Prompt
Function Prompt {
    If ($IsAdmin) {
        Write-Host "Admin" -ForegroundColor White -BackgroundColor Red -NoNewline
        Write-Host " " -NoNewline
    }
    Write-Host "$(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor White -BackgroundColor Blue -NoNewline
    Write-Host " " -NoNewline
    Write-Host ("$env:USERNAME" + '@' + "$env:COMPUTERNAME") -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    If (Get-GitDirectory -ne $Null) {
        Write-Host " " -NoNewline
        Write-Host "$((Get-GitStatus).RepoName)" -ForegroundColor White -BackgroundColor DarkGreen -NoNewline
        Write-Host "$(Write-VcsStatus)"
    } Else {
        Write-Host ""
    }
    Write-Host $((Get-Location).Path) -ForegroundColor Yellow
    Write-Host "$((Get-ChildItem).Count)" -ForegroundColor Blue -NoNewline
    Write-Host " " -NoNewline
    "PS> "
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
If ($IsAdmin) {
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
For ($i = 1; $i -le 5; $i++) {
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

# Check if there is a newer version of Powershell available and ask to install if there is.
If ($($Host.Version) -ne $((Get-PwshLatestRelease).Version)) {
    Write-Host "A new version of Powershell is available: $((Get-PwshLatestRelease).Version)"
    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes'
    $No = New-Object System.Management.Automation.Host.ChoiceDescription '&No'
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)
    $Title = 'Install Powershell'
    $Message = 'Do you want to Install the new veriosn of Powershell?'
    $Result = $host.ui.PromptForChoice($Title, $Message, $Options, 0)
    Switch ($Result) {
        0 { & Sudo Install-Powershell }
        1 {}
    }
}