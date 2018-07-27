    Param(
    [string] $ItemSpec = "*.tests.ps1",
	[String] $TestParameters,
	[string[]] $IncludeTags,
	[string[]] $ExcludeTags,
    [string] $FailOnError = "false"
)

$WorkingDirectory = "C:\Users\kevbo\source\repos\pestertest"
#$WorkingDirectory = $env:BUILD_SOURCESDIRECTORY
if (!$WorkingDirectory){
    $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
}

Write-Output "WorkingDirectory: $WorkingDirectory"

$TestFiles=$(get-childitem -path $WorkingDirectory -recurse $ItemSpec).fullname

$packages = get-package
if ($packages.Name  -contains "pester") {
    #pester is installed on the system
} else {
    Write-Output "Installing latest version of pester"

    #install pester
    $installresult = Install-Package pester -Force -Scope CurrentUser -ErrorAction SilentlyContinue
    if (!$installresult){ #Hack for 'hosted vs2017' agent
        $installresult = Install-Package pester -Force -Scope CurrentUser -SkipPublisherCheck 
    }
}

$testoutput = $env:COMMON_TESTRESULTSDIRECTORY
if (!$testoutput){
    $testoutput = $WorkingDirectory    
}

Do {
    [string] $fp1 = "TEST-"
    [string] $fp2 = [guid]::NewGuid()
    [string] $fp3 = ".xml"
    [string] $RandomFileName = -Join ($fp1, $fp2, $fp3)
    $outputFile = Join-Path $testoutput $RandomFileName
}
Until(!(Test-Path $outputFile))

#Here there is time for a race condition, but should be very rare
New-Item $outputFile -Type File

$pesterversion = $(Get-Package pester).Version
Write-Output "Pester installed: $pesterversion"
Write-Output "Test files found:"
Write-Output $TestFiles
Write-Output "Writing pester output: $outputfile"

$InvokeParameters = @{
    PassThru = $True
	Script = $TestFiles
	Outputfile = $outputFile
	Outputformat = "nunitxml"
}


$InvokeParameters.Add('Parameters', @{SqlAzureRegion = 'northeurope';DbAzureRegion = 'North Europe'})

if ($IncludeTags) {
    $IncludeTags = $IncludeTags.Split(',').Replace('"', '').Replace("'", "")
    $InvokeParameters.Add('Tag', $IncludeTags)
    Write-Output "Tags included: $IncludeTags"
}

if ($ExcludeTags) {
    $ExcludeTags = $ExcludeTags.Split(',').Replace('"', '').Replace("'", "")
    $InvokeParameters.Add('ExcludeTag', $ExcludeTags)
    Write-Output "Tags excluded: $ExcludeTags"
}


###Hack
$ParameterHash = @{ SqlAzureRegion = 'westeurope';DbAzureRegion = 'North Europe' }
$ScriptHash = @{ 'Path' = $ItemSpec; 'Parameters' = $ParameterHash }
$InvokePesterHash = @{
	script = $ScriptHash
	PassThru = $True
	Outputfile = $outputFile
	Outputformat = "nunitxml"
}
$result = Invoke-Pester @InvokePesterHash
####



Write-Output "Invoke-Pester @Parameters -PassThru"
#$result = Invoke-Pester @InvokeParameters

if ([boolean]::Parse($FailOnError)){
    if ($result.failedCount -ne 0)
    {
        Write-Error "Error Pester: 1 or more tests failed"
        Exit 1 
    }
}

 Exit 0

