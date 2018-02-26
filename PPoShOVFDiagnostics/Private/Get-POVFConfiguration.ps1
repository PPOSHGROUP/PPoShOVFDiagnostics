function Get-POVFConfiguration {
  <#
  .SYNOPSIS
  Short description
  
  .DESCRIPTION
  Long description
  
  .PARAMETER POVFServiceConfiguration
  Parameter description
  
  .PARAMETER POVFDiagnosticsFolder
  Parameter description
  
  .EXAMPLE
  An example
  
  .NOTES
  General notes
  #>
  [CmdletBinding()]
  param (

    [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [ValidateScript({Test-Path -Path $PSItem})]
    [System.String]
    $POVFServiceConfiguration,

    [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [ValidateScript({Test-Path -Path $PSItem})]
    [System.String]
    $POVFDiagnosticsFolder
  )

  process {
    $POVFData =@{
      Configuration = @{
        AllNodes = @()
        NonNodeData = @()
      }
      Diagnostics =@{
        Simple = @()
        Comprehensive = @()
      }
    }

    #region Get Diagnostics Tests files
    $POVFData.Diagnostics.Simple += (Get-ChildItem -Path (Join-Path -Path $POVFDiagnosticsFolder -ChildPath 'Simple') -Filter '*.Tests.ps1').FullName
    $POVFData.Diagnostics.Comprehensive += (Get-ChildItem -Path (Join-Path -Path $POVFDiagnosticsFolder -ChildPath 'Comprehensive') -Filter '*.Tests.ps1').FullName
    #endregion

    #region Get Service Configuration Data (i.e. your DHCP global configuration)
    $configurationNonNodeDataPath = Join-Path -Path $POVFServiceConfiguration -ChildPath 'NonNodeData'
    $POVFData.Configuration.NonNodeData +=  Get-ConfigurationData -ConfigurationPath $configurationNonNodeDataPath -OutputType HashTable
    #endregion

    #region Get Service Nodes Configuration Data (i.e. your DHCP servers specific configuration)
    $configurationAllNodesPath = Join-Path -Path $POVFServiceConfiguration -ChildPath 'AllNodes'
    $POVFData.Configuration.AllNodes += Get-ConfigurationData -ConfigurationPath $configurationAllNodesPath -OutputType HashTable
    #endregion

    $POVFData
  }
}