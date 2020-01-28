    Trace-VstsEnteringInvocation $MyInvocation

    # Get inputs.
    [string] $ItemSpec = Get-VstsInput -Name ItemSpec
    [string] $FailOnError = Get-VstsInput -Name FailOnError

    # Initialize Azure.
    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Initialize-Azure

    # Remove all commands imported from VstsTaskSdk, other than Out-Default.
    # Remove all commands imported from VstsAzureHelpers_.
    Get-ChildItem -LiteralPath function: |
        Where-Object {
            ($_.ModuleName -eq 'VstsTaskSdk' -and $_.Name -ne 'Out-Default') -or
            ($_.Name -eq 'Invoke-VstsTaskScript') -or
            ($_.ModuleName -eq 'VstsAzureHelpers_' )
        } |
        Remove-Item

    # For compatibility with the legacy handler implementation, set the error action
    # preference to continue. An implication of changing the preference to Continue,
    # is that Invoke-VstsTaskScript will no longer handle setting the result to failed.
    $global:ErrorActionPreference = 'Continue'


$scriptPath = (Join-Path -Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -ChildPath "Pester.ps1")

Invoke-Expression "& `"$ScriptPath`" -ItemSpec $ItemSpec -FailOnError $FailOnError" 

if ($lastexitcode -ne 0){
     "##vso[task.complete result=Failed]"
}