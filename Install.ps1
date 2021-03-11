Function _InstallProfile {
	$URL = $Response.assets.browser_download_url
	Invoke-WebRequest -Uri $URL -OutFile "$OutputPath\$($Response.assets.name)"
	Expand-Archive -Path "$OutputPath\$($Response.assets.name)" -DestinationPath "$OutputPath" -Force -ErrorAction 'Stop'
	Move-Item -Path "$OutputPath\Profile.ps1" -Destination $ProfilePath -ErrorAction 'Stop' -Force
}

Function _InstallPSR {
	$URL = $Response.assets.browser_download_url
	Invoke-WebRequest -Uri $URL -OutFile "$OutputPath\$($Response.assets.name)"
	Expand-Archive -Path "$OutputPath\$($Response.assets.name)" -DestinationPath "$OutputPath" -Force -ErrorAction 'Stop'
	Move-Item -Path "$OutputPath\PSReadline-Profile.ps1" -Destination "$PSRPath" -ErrorAction 'Stop' -Force
}

If ($IsWindows) {
	$OutputPath = $Env:temp
} Else {
	$OutputPath = $Home
}

$ProfileIncludePath = "$(Split-Path -Path $($Profile.CurrentUserAllHosts) -Parent)\ProfileInclude"
If (-not(Test-Path -Path $ProfileIncludePath)) {
	Write-Host "ProfileInclude folder does not exist"
    New-Item -Path $ProfileIncludePath -ItemType Directory -Force | Out-Null
} Else {
	Write-Host "ProfileInclude folder already exists"
}

$ProfilePath = "$($Profile.CurrentUserAllHosts)"
$PSRPath = "$ProfileIncludePath\PSReadline-Profile.ps1"

$PorfileParams = @{
	'Uri' = 'https://api.github.com/repos/thbiv/Powershell-Profile/releases/latest'
	'Headers' = @{"Accept"="application/json"}
	'Method' = 'Get'
	'UseBasicParsing' = $True
}
$Response = Invoke-RestMethod @PorfileParams

If (Test-Path -Path $ProfilePath) {
	$InstalledProfileBuild = (((Get-Content $ProfilePath)[2] -split ':')[1]).TrimStart()
	If ($InstalledProfileBuild -ne $($Response.tag_name)) {
		_InstallProfile
		Write-Host "[Powershell-Profile] Upgraded to Latest Release: $($Response.name)"
	} Else {
		Write-Host "[Powershell-Profile] Latest Release is already installed"
	}
} Else {
	_InstallProfile
	Write-Host "[Powershell-Profile] Installed Latest Release: $($Response.name)"
}

$PSRParams = @{
	'Uri' = 'https://api.github.com/repos/thbiv/PSReadline-Profile/releases/latest'
	'Headers' = @{"Accept"="application/json"}
	'Method' = 'Get'
	'UseBasicParsing' = $True
}
$Response = Invoke-RestMethod @PSRParams

If (Test-Path -Path $PSRPath) {
	$InstalledPSRBuild = (((Get-Content $PSRPath)[2] -split ':')[1]).TrimStart()
	If ($InstalledPSRBuild -ne $($Response.tag_name)) {
		_InstallPSR
		Write-Host "[PSReadline-Profile] Upgraded to Latest Release: $($Response.name)"
	} Else {
		Write-Host "[PSReadline-Profile] Latest Release is already installed"
	}
} Else {
	_InstallPSR
	Write-Host "[PSReadline-Profile] Installed Latest Release: $($Response.name)"
}


