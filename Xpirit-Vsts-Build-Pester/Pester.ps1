    Param(
    [string] $ItemSpec = "*.tests.ps1",
	[String] $TestParameters = "",
	[string[]] $IncludeTags = "",
	[string[]] $ExcludeTags = "",
    [string] $FailOnError = "true"
)

#$WorkingDirectory = "C:\Users\kevbo\source\repos\pestertest"
$WorkingDirectory = $env:BUILD_SOURCESDIRECTORY
if (!$WorkingDirectory){
    $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
}

Write-Output "WorkingDirectory: $WorkingDirectory"
Set-Location $WorkingDirectory

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
Write-Output "Writing pester output: $outputfile"
Write-Output "Files: $ItemSpec"


$ParameterHash = @{}
if ($TestParameters) {
	# Parameters need passing to the Pester tests
	$ValuePairs = $TestParameters.Split(',')
	ForEach ($ValuePair in $ValuePairs) {
		Write-Output $ValuePair
		$Values = $ValuePair.Split('=').Replace('"', '').Replace("'", "").Trim()
		$ParameterHash.Add($Values[0],$Values[1])
	}
	Write-Output $ParameterHash
}

$ScriptHash = @{ 'Path' = $ItemSpec; 'Parameters' = $ParameterHash }
$InvokePesterHash = @{
	script = $ScriptHash
	PassThru = $True
	Outputfile = $outputFile
	Outputformat = "nunitxml"
}

if ($IncludeTags) {
	# Apply tag filter to the pester tests that are required to run
    $IncludeTags = $IncludeTags.Split(',').Replace('"', '').Replace("'", "")
    $InvokePesterHash.Add('Tag', $IncludeTags)
    Write-Output "Tags included: $IncludeTags"
}

if ($ExcludeTags) {
	# Apply tag filter to the pester tests that should not be run.  Overrides include Tags
    $ExcludeTags = $ExcludeTags.Split(',').Replace('"', '').Replace("'", "")
    $InvokePesterHash.Add('ExcludeTag', $ExcludeTags)
    Write-Output "Tags excluded: $ExcludeTags"
}

Write-Output "Invoke-Pester $InvokePesterHash"
$result = Invoke-Pester @InvokePesterHash

if ([boolean]::Parse($FailOnError)){
    if ($result.failedCount -ne 0)
    {
        Write-Error "Error Pester: 1 or more tests failed"
        Exit 1 
    }
}

 Exit 0

