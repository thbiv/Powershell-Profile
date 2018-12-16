Deploy PowerhellProfiles {
    By FileSystem CurrentUserConsoleHost {
        FromSource '_output\CurrentUserConsoleHost.ps1'
        To '\\sfhrsd-1624\c$\Users\thomasb-adm\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1',
           '\\sfhrsl-4353\c$\Users\thomasb-adm\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
    }
    By FileSystem AllUsersAllHosts {
        FromSource '_output\CurrentUserAllHosts.ps1'
        To '\\sfhrsd-1624\c$\Windows\System32\WindowsPowerShell\v1.0\profile.ps1',
           '\\sfhrsl-4353\c$\Windows\System32\WindowsPowerShell\v1.0\profile.ps1'
    }
}