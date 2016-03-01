    Param(
    [string] $ItemSpec = "**/*.tests.ps1"
)

#Write-Output "ItemSpec: $ItemSpec" 
#Write-Output "Temp folder: $env:temp"

$tempFile = Join-Path $env:temp pester.zip
$modulePath = Join-Path $env:temp pester-master\Pester.psm1

Invoke-WebRequest https://github.com/pester/Pester/archive/master.zip -OutFile $tempFile
 
Add-Type -Assembly System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile, $env:temp)

Import-Module $modulePath -DisableNameChecking -Verbose

$outputFile = Join-Path $env:BUILD_SOURCESDIRECTORY "TEST-pester.xml"

Invoke-Pester $ItemSpec -Outputformat nunitxml -Outputfile $outputFile