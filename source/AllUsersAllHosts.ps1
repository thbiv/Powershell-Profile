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

If (!(Get-PSRepository -Name SFGallery -ErrorAction SilentlyContinue)) {
    $SFGalleryPath = "\\sfhrsfile01\horsham-home\thomasb\SFGallery"
    $Repo = @{
        Name = 'SFGallery'
        SourceLocation = $SFGalleryPath
        PublishLocation = $SFGalleryPath
        InstallationPolicy = 'Trusted'
    }
    Register-PSRepository @Repo
}