If ($IsWindows) {
    New-Variable -Name IsAdmin -Option Constant -Scope Global -Value $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
}

If ($($PSVersionTable.PSVersion) -Match "^[1-5]") {
    $IsWindowsPowershell = $True
} Else {
    $IsWindowsPowershell = $False
}

# Import Modules
Import-Module -Name PSReadLine, posh-git
If ($IsWindows) {
    Import-Module -Name PSScriptTools
}

# Variables
# Variable for paths to the Powershell Scripts folders (Paths where scripts are installed from the PSGallery)
If ($IsWindows) {
    If ($IsWindowsPowershell) {
        $CU = "$Home\Documents\WindowsPowershell\Scripts"
        $AU = "$Env:ProgramFiles" + "\WindowsPowershell\Scripts"
    } Else {
        $CU = "$Home\Documents\Powershell\Scripts"
        $AU = "$Env:ProgramFiles" + "\Powershell\Scripts"
    }
} Else {
    $CU = "$Home/.local/share/powershell/Scripts"
    $AU = "/usr/local/share/powershell/Scripts"
}
New-Variable -Name PSScripts -Option Constant -Scope Global -Value @{
    CurrentUser = $CU
    AllUsers = $AU
}
Remove-Variable CU,AU

# Add the Scripts folders to the PATH Environment Variable
$NewPaths = @("$($PSScripts.AllUsers)","$($PSScripts.CurrentUser)")
$PATHArray = $env:Path -split ';'
$Env:PATH = ($PATHArray + $NewPaths) -join ';'
Remove-Variable NewPaths,PATHArray

# Aliases

If ($IsWindows) {
    # Calling Notepad++ using npp
    New-Alias -Name npp -Value "C:\Program Files\Notepad++\notepad++.exe"

    # Use the Less pager utility that comes with Git.
    New-Alias -Name less -Value "C:\Program Files\Git\usr\bin\less.exe"

    # Use the Nano terminal text editor that comes with Git.
    New-Alias -Name nano -Value "C:\Program Files\Git\usr\bin\nano.exe"

    # Winfetch
    Set-Alias -Name winfetch -Value pwshfetch-test-1
}

# Posh-Git Settings
$GitPromptSettings.EnableWindowTitle = ""
$GitPromptSettings.ShowStatusWhenZero = $false

# Custom Prompt
Function Prompt {
    If ($IsAdmin) {
        Write-Host "Admin" -ForegroundColor White -BackgroundColor Red -NoNewline
        Write-Host " " -NoNewline
    }
    Write-Host "$(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor White -BackgroundColor Blue -NoNewline
    Write-Host " " -NoNewline
    Write-Host ("$([environment]::UserName)" + '@' + "$([environment]::MachineName)") -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    If (Get-GitDirectory -ne $Null) {
        Write-Host " " -NoNewline
        Write-Host "$(Split-path -Path $(Get-Location) -Leaf)" -ForegroundColor White -BackgroundColor DarkGreen -NoNewline
        Write-Host "$(Write-VcsStatus)"
    } Else {
        Write-Host ""
    }
    Write-Host $((Get-Location).Path) -ForegroundColor Yellow
    Write-Host "$((Get-ChildItem).Count)" -ForegroundColor Blue -NoNewline
    Write-Host " " -NoNewline
    "PS> "
}

# Load any scripts that i want to include while loading the profile. Scripts planced in the $PSScriptRoot\ProfileInclude
If (Test-Path -Path "$PSScriptRoot\ProfileInclude") {
    ForEach ($Item in $(Get-ChildItem -Path "$PSScriptRoot\ProfileInclude" | Select-Object -ExpandProperty FullName)) {
        . $Item
        Write-Host "Loaded Script: $Item"
    }
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

If ($IsWindows) {
    # Function to output a username from the input of a SID
    Function Convert-SIDToUserName {
        Param(
            $SID
        )
        ((((New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount])).Value).Split('\'))[1]
    }

    # Color Get-ChildItem filesystem Output using PSScriptTools module
    $FormatFile = (Get-Module PSScriptTools).ExportedFormatFiles | where-object {$_ -match 'filesystem-ansi'}
    Update-FormatData -PrependPath $FormatFile
}