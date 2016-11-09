    Param(
    [string] $ItemSpec = "*.tests.ps1",
	[string] $FailOnError = "false"
)

$TestFiles=$(get-childitem -path $env:BUILD_SOURCESDIRECTORY -recurse $ItemSpec).fullname

Write-Output "Test files found:"
Write-Output $TestFiles

$pesterversion = $(Get-Package pester).Version
if ($pesterversion) {
    #pester is installed on the system
	Write-Output "Pester is installed $pesterversion"
} else {
	Write-Output "Installing latest version of pester"
    
    #install pester
    Install-Package pester -Force

    $pesterversion = $(Get-Package pester).Version
	Write-Output "Pester installed: $pesterversion"
}

[string] $filepart1 = "TEST-pester"
[string] $filepart2 = ".xml"
[string] $filename = -Join ($filepart1, $filepart2)

$outputFile = Join-Path $env:COMMON_TESTRESULTSDIRECTORY $filename

if (Test-Path $outputFile){
    [int]$counter = 1
	while (Test-Path $outputFile){
        $filename = -Join ($filepart1,  (-Join ($counter, $filepart2)))
		$outputFile = Join-Path $env:COMMON_TESTRESULTSDIRECTORY $filename
        $counter = $counter+1
	}
}

Write-Output "Writing pester output to $outputfile"

$result = Invoke-Pester $TestFiles -PassThru -Outputformat nunitxml -Outputfile $outputFile

if ([boolean]::Parse($FailOnError)){
	if ($result.failedCount -ne 0)
	{ 
		Write-Error "Error Pester: 1 or more tests failed"
	}
}
