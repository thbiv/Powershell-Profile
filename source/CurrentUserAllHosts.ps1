# Register LocalGallery if it does not exist
If (!(Get-PSRepository -Name LocalGallery -ErrorAction SilentlyContinue)) {
    $LocalGalleryPath = "$HOME\LocalGallery"
    If (-not(Test-Path -Path $LocalGalleryPath)) {
        New-Item -Path $LocalGalleryPath -ItemType Directory -Force | Out-Null
    }
    $Repo = @{
        Name = 'LocalGallery'
        SourceLocation = $LocalGalleryPath
        PublishLocation = $LocalGalleryPath
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