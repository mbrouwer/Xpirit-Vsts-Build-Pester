    Param(
    [string] $ItemSpec = "*.tests.ps1",
    [string] $FailOnError = "false"
)

$TestFiles=$(get-childitem -path $env:BUILD_SOURCESDIRECTORY -recurse $ItemSpec).fullname

Write-Output "Test files found:"
Write-Output $TestFiles

$packages = get-package
if ($packages.Name  -contains "pester") {
    #pester is installed on the system
} else {
    Write-Output "Installing latest version of pester"

    #install pester
    Install-Package pester -Force -Scope CurrentUser 
}
$pesterversion = $(Get-Package pester).Version
Write-Output "Pester installed: $pesterversion"

Do {
    [string] $fp1 = "TEST-"
    [string] $fp2 = [guid]::NewGuid()
    [string] $fp3 = ".xml"
    [string] $RandomFileName = -Join ($fp1, $fp2, $fp3)
    $outputFile = Join-Path $env:COMMON_TESTRESULTSDIRECTORY $RandomFileName
}
Until(!(Test-Path $outputFile))
#Here there is time for a race condition, but should be very rare
New-Item $outputFile -Type File

Write-Output "Writing pester output to $outputfile"

$result = Invoke-Pester $TestFiles -PassThru -Outputformat nunitxml -Outputfile $outputFile

if ([boolean]::Parse($FailOnError)){
    if ($result.failedCount -ne 0)
    {
        Write-Error "Error Pester: 1 or more tests failed"
    }
}

