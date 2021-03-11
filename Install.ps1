[CmdletBinding()]
Param (
	[switch]$Force
)

If ($IsWindows) {
	$OutputPath = $Env:temp
} Else {
	$OutputPath = $Home
}

$ProfileIncludePath = "$(Split-Path -Path $($Profile.CurrentUserAllHosts) -Parent)\ProfileInclude"
If (-not(Test-Path -Path $ProfileIncludePath)) {
    New-Item -Path $ProfileIncludePath -ItemType Directory -Force | Out-Null
}

$PorfileParams = @{
	'Uri' = 'https://api.github.com/repos/thbiv/Powershell-Profile/releases/latest'
	'Headers' = @{"Accept"="application/json"}
	'Method' = 'Get'
	'UseBasicParsing' = $True
}
$Response = Invoke-RestMethod @PorfileParams
$InstalledProfileBuild = (((Get-Content $Profile.CurrentUserAllHosts)[2] -split ':')[1]).TrimStart()
If (($InstalledProfileBuild -ne $($Response.tag_name)) -or $Force) {
	$URL = $Response.assets.browser_download_url
	Invoke-WebRequest -Uri $URL -OutFile "$OutputPath\$($Response.assets.name)"
	Expand-Archive -Path "$OutputPath\$($Response.assets.name)" -DestinationPath "$OutputPath" -Force -ErrorAction 'Stop'
	Move-Item -Path "$OutputPath\Profile.ps1" -Destination $($Profile.CurrentUserAllHosts) -ErrorAction 'Stop' -Force
	Write-Host "[Powershell-Profile] Installed Latest Release: $($Response.name)"
} Else {
	Write-Host "[Powershell-Profile] Latest Release is already installed"
}

$PSRParams = @{
	'Uri' = 'https://api.github.com/repos/thbiv/PSReadline-Profile/releases/latest'
	'Headers' = @{"Accept"="application/json"}
	'Method' = 'Get'
	'UseBasicParsing' = $True
}
$Response = Invoke-RestMethod @PSRParams
$InstalledPSRBuild = (((Get-Content "$ProfileIncludePath\PSReadline-Profile.ps1")[2] -split ':')[1]).TrimStart()
If (($InstalledPSRBuild -ne $($Response.tag_name)) -or $Force) {
	$URL = $Response.assets.browser_download_url
	Invoke-WebRequest -Uri $URL -OutFile "$OutputPath\$($Response.assets.name)"
	Expand-Archive -Path "$OutputPath\$($Response.assets.name)" -DestinationPath "$OutputPath" -Force -ErrorAction 'Stop'
	Move-Item -Path "$OutputPath\PSReadline-Profile.ps1" -Destination "$(Split-Path -Path $($Profile.CurrentUserAllHosts) -Parent)\ProfileInclude\PSReadline-Profile.ps1" -ErrorAction 'Stop' -Force
	Write-Host "[PSReadline-Profile] Installed Latest Release: $($Response.name)"
} Else {
	Write-Host "[PSReadline-Profile] Latest Release is already installed"
}