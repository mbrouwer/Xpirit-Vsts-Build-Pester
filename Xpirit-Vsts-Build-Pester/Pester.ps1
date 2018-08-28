Param(
    [string] $ItemSpec = "*.tests.ps1",
    [String] $TestParameters = "",
    [string[]] $IncludeTags = "",
    [string[]] $ExcludeTags = "",
    [string] $FailOnError = "true",
    [string] $PesterVersion = "latest"
)

#$WorkingDirectory = "C:\Users\kevbo\source\repos\pestertest"
$WorkingDirectory = $env:BUILD_SOURCESDIRECTORY
if (!$WorkingDirectory){
    $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
}

Write-Output "WorkingDirectory: $WorkingDirectory"
Set-Location $WorkingDirectory

if($PesterVersion -eq "latest") {
    "Find Pester latest version"
    $Pester = Find-Module -Name Pester

    "Latest version is '{0}'" -f $Pester.Version
}

$Module = Get-Module -Name "Pester" -ListAvailable | Select-Object -First 1
"Pester version found is = '{0}'" -f $Module.Version

If($Module.Version -ne $PesterVersion) {
    "Installing Pester..."
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
    $outputFile = "{0}\TEST-{1}.xml" -f $testoutput, [guid]::NewGuid().ToString()
}
Until(!(Test-Path $outputFile))

#Here there is time for a race condition, but should be very rare
New-Item $outputFile -Type File

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

$ScriptHash = @{ 'Path' = "$WorkingDirectory\$ItemSpec"; 'Parameters' = $ParameterHash }
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

Write-Output "Invoke-Pester with the following parameters"
$InvokePesterHash
$result = Invoke-Pester @InvokePesterHash

if ([boolean]::Parse($FailOnError)){
    if ($result.failedCount -ne 0)
    {
        Write-Error "Error Pester: 1 or more tests failed"
        Exit 1 
    }
}

 Exit 0