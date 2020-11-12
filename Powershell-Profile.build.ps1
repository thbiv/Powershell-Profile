$Script:ProjectName = Split-Path -Path $PSScriptRoot -Leaf
$Script:SourceRoot = "$BuildRoot\source"
$Script:OutputRoot = "$BuildRoot\_output"
$Script:TestResultsRoot = "$BuildRoot\_testresults"
$Script:TestsRoot = "$BuildRoot\tests"
$Script:DestinationScript = "$OutputRoot\$ScriptFileName"
$Script:ScriptConfig = [xml]$(Get-Content -Path '.\Script.Config.xml')

Task . Clean, Build, Test
Task Testing Clean, Build, Test

# Synopsis: Empty the _output and _testresults folders
Task Clean {
    If (Test-Path -Path $OutputRoot) {
        Get-ChildItem -Path $OutputRoot -Recurse | Remove-Item -Force
    } Else {
        New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
    }
    If (Test-Path -Path $TestResultsRoot) {
        Get-ChildItem -Path $TestResultsRoot -Recurse | Remove-Item -Force
    } Else {
        New-Item -Path $TestResultsRoot -ItemType Directory -Force | Out-Null
    }
}

# Synopsis: Compile and build the project
Task Build {
    "# Project:     $ProjectName" | Add-Content -Path "$OutputRoot\CurrentUserConsoleHost.ps1"
    "# Author:      $($ScriptConfig.config.info.author)" | Add-Content -Path "$OutputRoot\CurrentUserConsoleHost.ps1"
    "# BuildNumber: $NewVersion" | Add-Content -Path "$OutputRoot\CurrentUserConsoleHost.ps1"
    "# Description: $($ScriptConfig.config.info.description)" | Add-Content -Path "$OutputRoot\CurrentUserConsoleHost.ps1"
    Get-Content -Path "$SourceRoot\CurrentUserConsoleHost.ps1" | Add-Content -Path "$OutputRoot\CurrentUserConsoleHost.ps1"    
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

# Synopsis: Deploy Powershell Profiles
Task Deploy {
    Invoke-PSDeploy -Force
}