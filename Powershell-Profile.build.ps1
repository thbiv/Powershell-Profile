$Script:ProjectName = 'Powershell-Profile'
$Script:SourceRoot = "$BuildRoot\source"
$Script:OutputRoot = "$BuildRoot\_output"
$Script:TestResultsRoot = "$BuildRoot\_testresults"
$Script:TestsRoot = "$BuildRoot\tests"
$Script:FileHashRoot = "$BuildRoot\_filehash"
$Script:DestinationScript = "$OutputRoot\$ScriptFileName"

Task . Clean, Build, Test, Hash, Deploy
Task Testing Clean, Build, Test

# Synopsis: Empty the _output and _testresults folders
Task Clean {
    If (Test-Path -Path $OutputRoot) {
        Get-ChildItem -Path $OutputRoot -Recurse | Remove-Item -Force
    }
    If (Test-Path -Path $TestResultsRoot) {
        Get-ChildItem -Path $TestResultsRoot -Recurse | Remove-Item -Force
    }
}

# Synopsis: Compile and build the project
Task Build {
    Copy-Item -Path "$SourceRoot\CurrentUserConsoleHost.ps1" -Destination "$OutputRoot\CurrentUserConsoleHost.ps1"
    Copy-Item -Path "$SourceRoot\CurrentUserAllHosts.ps1" -Destination "$OutputRoot\CurrentUserAllHosts.ps1"
}

# Synopsis: Test the Project
Task Test {
    $PesterPSSA = @{
        OutputFile = "$TestResultsRoot\PSSAResults.xml"
        OutputFormat = 'NUnitXml'
        Script = @{Path="$TestsRoot\PSSA.tests.ps1";Parameters=@{Path=$OutputRoot}}
    }
    $PSSAResults = Invoke-Pester @PesterPSSA -PassThru
    $PesterBasic = @{
        OutputFile = "$TestResultsRoot\BasicResults.xml"
        OutputFormat = 'NUnitXml'
        Script = @{Path="$TestsRoot\Basic.tests.ps1";Parameters=@{Path=$OutputRoot;ProjectName=$ProjectName}}
    }
    $BasicResults = Invoke-Pester @PesterBasic -PassThru
    If ($PSSAResults.FailedCount -ne 0) {Throw "PSScriptAnalyzer Test Failed"}
    ElseIf ($BasicResults.FailedCount -ne 0) {Throw "Basic Test Failed"}
    Else {Write-Host "All tests have passed...Build can continue."}
}

# Synopsis: Produce File Hash for all output files
Task Hash {
    $Files = Get-ChildItem -Path $OutputRoot -File -Recurse
    $HashOutput = @()
    ForEach ($File in $Files) {
        $HashOutput += Get-FileHash -Path $File.fullname
    }
    $HashExportFile = "Files_Hash_Powershell-Profile.xml"
    $HashOutput | Export-Clixml -Path "$FileHashRoot\$HashExportFile" -Force
    Write-Host "Hash Information File: $HashExportFile"
}

# Synopsis: Deploy Powershell Profiles
Task Deploy {
    Invoke-PSDeploy -Force -Verbose
}