Deploy PowerhellProfiles {
    By FileSystem CurrentUserConsoleHost {
        FromSource '_output\CurrentUserConsoleHost.ps1'
        To '\\localhost\c$\Users\thbarratt\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1',
           '\\localhost\c$\Users\thbarratt\Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    }
    By FileSystem AllUsersAllHosts {
        FromSource '_output\CurrentUserAllHosts.ps1'
        To '\\localhost\c$\Users\thbarratt\Documents\WindowsPowerShell\profile.ps1',
           '\\localhost\c$\Users\thbarratt\Documents\PowerShell\profile.ps1'
    }
}