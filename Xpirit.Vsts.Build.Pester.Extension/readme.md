# Run Pester in VSTS build tasks
This build extension enables your to run Powershell unit test in your build and release pipelines. It uses the Pester Powershell test framework.

## Pester
[Pester](https://github.com/pester/Pester) will enable you to test your Powershell scripts from within Powershell. It is a set of function for unit testing Powershell functions. These functions will allow you to mock and isolate your test cases.

## Pester build extension
This extension will run your pester unit test in a build pipeline. 
The task will first check if Pester is installed. If Pester is installed, it uses the installed Pester version. When Pester is not installed, the task will install the latest stable Pester version.
On failure you can choose to break the build or just show it in the test results.

### Run tests
For running the tests you can configure the task like:

```
Test files: *.tests.ps1
Fail build on error: true
Include Tags: ARM,SQL
Exclude Tags: Database
Testing Parameters: "SqlAzureRegion = 'westeurope',DbAzureRegion = 'West Europe'"
```

![Run tests](https://raw.githubusercontent.com/XpiritBV/Xpirit-Vsts-Build-Pester/master/Xpirit.Vsts.Build.Pester.Extension/images/screenshots/vsts-pester1-pester.png)

This will run all *.tests.ps1 files in your repository

[Read more...](https://pgroene.wordpress.com/2017/01/30/running-powershell-pester-unit-test-in-a-vsts-build-pipeline/)

### Run deployment tests
The task 'Pester powershell deployment tests on Azure' has a connection to azure that enables you to run tests against azure:

```
param(
  [string]$DbAzureRegion,
  [string]$ResourceGroupName,
  [string]$SqlServerName,
  [string]$SqlDatabase
  )

Describe -Name 'Demo SQL Database' -Tags ('ARM','Database') -Fixture {
    Context -Name 'Resource Group' {
        It -name 'Passed Resource Group existence check' -test {
            Get-AzureRmResourceGroup -Name $ResourceGroupName | Should Not Be $null
        }
    }
    
    Context -Name 'Database' {
        $database = Get-AzureRmSqlDatabase -ServerName $SqlServerName -ResourceGroupName $ResourceGroupName -DatabaseName $SqlDatabase
        It -name 'Passed SQL Database existence check' -test {
            $database | Should Not be $null
        }
        It -name 'Passed SQL Database collation check' -test {
            $database.CollationName | Should be 'SQL_Latin1_General_CP1_CI_AS'
        }
        It -name 'Passed SQL Database status check' -test {
            $database.Status | Should be 'Online'
        }
        It -name 'Passed SQL Database Location check' -test {
            $database.Location | Should Be $DbAzureRegion
        }
    }
}
```

This way you can automaticly validate your deployments in your Release Pipelines.

[Read more...](https://pgroene.wordpress.com/2017/09/08/test-azure-deployments-in-your-vsts-release-pipeline/)

### Upload test results VSTS
When you want the test results visible in VSTS, you need to upload the test result file. This can be done with the Upload test results task. Pester will write the test results in nUnit format to a test results file. This test results file is located in the test results directory. That is one directory higher than the working directory of the task.

The following configuration can be used:

```
Test Result Format: nUnit
Test Results Files: ../**/TEST-*.xml
Always run: true
```

![Upload test results VSTS](https://raw.githubusercontent.com/XpiritBV/Xpirit-Vsts-Build-Pester/master/Xpirit.Vsts.Build.Pester.Extension/images/screenshots/vsts-pester2-pester.png)




[See my blog for more tasks](https://pgroene.wordpress.com/)
[Sources](https://github.com/XpiritBV/Xpirit-Vsts-Build-Pester)
