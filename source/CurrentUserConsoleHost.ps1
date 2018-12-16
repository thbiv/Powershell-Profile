#############################################################
#############################################################
# Variables
New-Variable -Name PSProfileScriptPath -Value $(Split-Path $Profile) -Option Constant -Scope Global
New-Variable -Name TranscriptPath -Value "$HOME\Documents\Transcript" -Scope Script
New-Variable -Name PSScripts -Option Constant -Scope Global -Value @{
    CurrentUser = "$PSProfileScriptPath\Scripts"
    AllUsers = "$Env:ProgramFiles" + "\WindowsPowershell\Scripts"
}
#############################################################
#############################################################
# PSDrives
If (!(Test-Path -Path P:\)) {
    New-PSDrive -Name P -PSProvider FileSystem -Persist -Root "\\sfhrsfile01\horsham-home\thomasb\PSProjects" -Description 'Powershell Projects' | Out-Null
}
#############################################################
#############################################################
# Aliases
New-Alias plink "C:\Program Files\PuTTY\plink.exe" #PuTTy CLI
New-Alias npp   "C:\Program Files\Notepad++\notepad++.exe" #Notepad++
#############################################################
#############################################################
# Prompt
Function Prompt {
	If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		Write-Host '[Admin]' -NoNewline -ForegroundColor Red
	}
    Write-Host "$(Get-Date -Format 'yyyyMMdd | HH:mm:ss') " -NoNewline
    Write-Host ("$env:USERNAME" + '@' + "$env:COMPUTERNAME ") -NoNewline -ForegroundColor DarkGray
    Write-Host ($(Get-Location))
    Write-Host (Get-ChildItem).Count -NoNewline
	' PS> '
}
#############################################################
#############################################################
# Import Modules
Import-Module -Name PSReadLine
Import-Module -Name Pscx -Function help, less, Show-Tree, Start-PowerShell -Cmdlet ConvertFrom-Base64, ConvertTo-Base64
Import-Module -Name PowerShellCookbook -Function Show-Object
#############################################################
#############################################################
# Console Configuration
$Console = $Host.UI.RawUI
$ConsoleBuffer = $Console.BufferSize
$ConsoleBuffer.Width = 180
$ConsoleBuffer.Height = 3000
$Console.BufferSize = $ConsoleBuffer
$ConsoleSize = $Console.WindowSize
$ConsoleSize.Width = 180
$ConsoleSize.Height = 60
$Console.WindowSize = $ConsoleSize
#############################################################
#############################################################
# PSReadline Settings
Set-PSReadlineOption -EditMode Windows
$Params = @{
    'Chord' = 'Ctrl+d'
    'BriefDescription' = 'los -locked -LockedDC sfhrsdc01'
    'Description' = 'Check ActiveDirecotry and display locked user accounts'
}
Set-PSReadlineKeyHandler @Params -ScriptBlock {
    Param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('los -locked -LockedDC sfhrsdc01')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
$Params = @{
    'Chord' = 'Ctrl+f'
    'BriefDescription' = 'gci -Force | Format-Wide -Column 3'
    'Description' = 'Displays list of files and folders in 3 columns'
}
Set-PSReadlineKeyHandler @Params -ScriptBlock {
    Param($key, $arg)
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('gci -force | Format-Wide -Column 3')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
#############################################################
#############################################################
# Profile Functions
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
Function Convert-SIDToUserName {
    Param(
        $SID
    )
    ((((New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount])).Value).Split('\'))[1]
}
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
Function Connect-ToExchange {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://SFHOUEX16MB01.selene1.fsroot.com/PowerShell/ -Authentication Kerberos -Name Exchange
    Import-PSSession $Session -AllowClobber -DisableNameChecking | Out-Null
    $Host.UI.RawUI.WindowTitle = "Exchange Powershell Console"
}
New-Alias -Name cte -Value Connect-ToExchange
Function Disconnect-FromExchange {
	Get-PSSession | Where-Object {$_.Name -eq 'Exchange'} | Remove-PSSession
	$Host.UI.RawUI.WindowTitle = 'Windows Powershell'
}
New-Alias -Name dfe -Value Disconnect-FromExchange -Force
Function Connect-ToOffice365 {
    $msolcred = Get-Credential
    Connect-MsolService -Credential $msolcred
}
New-Alias -Name cto365 -Value Connect-ToOffice365
Function Connect-ToExchangeOnline {
    $LiveCred = Get-Credential
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $LiveCred -Authentication Basic -AllowRedirection -Name ExchangeOnline
    Import-PSSession $Session -DisableNameChecking
}
New-Alias -Name cteo -Value Connect-ToExchangeOnline
Function Disconnect-FromExchangeOnline {
	Get-PSSession | Where-Object {$_.Name -eq 'ExchangeOnline'} | Remove-PSSession
	$Host.UI.RawUI.WindowTitle = 'Windows Powershell'
}
New-Alias -Name dfeo -Value Disconnect-FromExchangeOnline -Force
#############################################################
#############################################################
$TranscriptFile = Join-Path -Path $TranscriptPath -ChildPath ("Transcript_{0:yyyMMddTHHmmss}.txt" -f $(Get-Date))
Start-Transcript -Path $TranscriptFile -Force -NoClobber -IncludeInvocationHeader