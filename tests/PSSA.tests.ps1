Param(
    [Parameter(mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
)

Describe 'PSSA Standard Rules' {
	$Scripts = Get-ChildItem -Path $Path -File | Where-Object {$_.Extension -eq '.ps1'}
	ForEach ($Script in $Scripts) {
		Context "$($Script.Name)" {
			$Analysis = Invoke-ScriptAnalyzer -Path  $Script.FullName -ExcludeRule 'PSAvoidUsingWriteHost','PSAvoidUsingInvokeExpression','PSReviewUnusedParameter'
			$ScriptAnalyzerRules = Get-ScriptAnalyzerRule | Where-Object {($_.RuleName -ne 'PSAvoidUsingWriteHost') -and ($_.RuleName -ne 'PSAvoidUsingInvokeExpression') -and ($_.RuleName -ne 'PSReviewUnusedParameter')}
			ForEach ($Rule in $ScriptAnalyzerRules) {
				It "Should pass $Rule" {
					If ($Analysis.RuleName -contains $Rule) {
						$Analysis |	Where-Object RuleName -EQ $Rule -OutVariable Failures | Out-Default
						$Failures.Count | Should Be 0
					}
				}
			}
		}
	}
}