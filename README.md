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
    Import-Module PPoShOVFDiagnostics #Alternatively, Import-Module \\Path\To\PPoSPPoShOVFDiagnosticshOVF

# Get commands in the module
    Get-Command -Module PPoShOVFDiagnostics

# Get help
    Get-Help about_PPoShOVFDiagnostics
```