# PPoShOVFDiagnostics

PPoShOVFDiagnostics
=============

PowerShell module with basic tests for Operation Validation Framework


## Instructions

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the PPoShOVFDiagnostics folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    #Simple alternative, if you have PowerShell 5, or the PowerShellGet module:
        Install-Module PPoShOVFDiagnostics

# Import the module.
    Import-Module PPoShOVFDiagnostics #Alternatively, Import-Module Path_To_PPoSPPoShOVFDiagnosticshOVF

# Get commands in the module
    Get-Command -Module PPoShOVFDiagnostics

# Get help
    Get-Help about_PPoShOVFDiagnostics
```

# Usage Exmples
```powershell

Create hashtable of required parameters
$creds = Get-Credential
$paramsS2D = @{
  ServiceConfiguration = 'C:\AdminTools\Tests\POVFDiagnostics\Configuration\S2D'
  POVFServiceName = 'S2D'
  Show = 'All'
  Credential = $creds
  ReportFilePrefix = 'YourClusterName'
  OutputFolder = 'C:\AdminTools\Tests\POVFDiagnostics\Output\S2D_20180301'
}
Invoke-POVFDiagnostics @paramsS2D
```
---
```powershell

Create hashtable of required parameters
$creds = Get-Credential
$paramsS2D = @{
  ServiceConfiguration = 'C:\AdminTools\Tests\POVFDiagnostics\Configuration\S2D'
  POVFDiagnosticsConfigurationData = 'C:\Repos\GIT\PPoShOVFDiagnostics\PPoShOVFDiagnostics\Configuration\S2D'
  POVFDiagnosticsFolder = 'C:\Repos\GIT\PPoShOVFDiagnostics\PPoShOVFDiagnostics\Diagnostics\S2D'
  Credential = $creds
  ReportFilePrefix = 'YourClusterName'
  TestType = 'Comprehensive'
  Tag = @('Basic')
  NodeName = 'ServerName'
  OutputFolder = 'C:\AdminTools\Tests\POVFDiagnostics\Output\S2D_20180301'
}
Invoke-POVFDiagnostics @paramsS2D
Invoke-POVFReportUnit -InputFolder 'C:\AdminTools\Tests\POVFDiagnostics\Output\S2D_20180301'
```