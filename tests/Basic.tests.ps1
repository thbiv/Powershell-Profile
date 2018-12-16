Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName
)

Describe "General project validation: $ProjectName" {

    $Scripts = Get-ChildItem $OutputRoot -Include *.ps1, *.psm1, *.psd1 -Recurse

    # TestCases are splatted to the script so we need hashtables
    $TestCase = $Scripts | Foreach-Object {@{File = $_}}
    It "Script <file> should be valid powershell" -TestCases $TestCase {
        param($File)

        $file.fullname | Should Exist

        $Contents = Get-Content -Path $File.FullName -ErrorAction Stop
        $Errors = $Null
        $Null = [System.Management.Automation.PSParser]::Tokenize($Contents, [ref]$Errors)
        $Errors.Count | Should Be 0
    }
}