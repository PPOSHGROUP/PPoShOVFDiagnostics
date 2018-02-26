function Get-POVFConfiguration {
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
    $POVFDiagnosticsConfiguration,

    [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [ValidateScript({Test-Path -Path $PSItem})]
    [System.String]
    $POVFDiagnosticsTestsFolder
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

    $diagnosticsConfiguration = Get-ConfigurationData -ConfigurationPath $POVFDiagnosticsConfiguration -OutputType HashTable
    $testFilesSimple = Get-ChildItem -Path $POVFDiagnosticsTestsFolder\Simple -Filter '*.Tests.ps1'
    $testFilesComprehensive = Get-ChildItem -Path $POVFDiagnosticsTestsFolder\Comprehensive -Filter '*.Tests.ps1'

    #region Get Service Configuration Data (i.e. your DHCP global configuration)
    $configurationNonNodeDataPath = Join-Path -Path $POVFServiceConfiguration -ChildPath 'NonNodeData'
    $configurationNonNodeDataFile = Get-ChildItem -Path "$($configurationNonNodeDataPath)\*" -Include  '*.psd1','*.json'
    if ($configurationNonNodeDataFile) {
      $POVFData.Configuration.NonNodeData += ForEach ($file in $configurationNonNodeDataFile) { 
        Get-ConfigurationData -ConfigurationPath $file.FullName -OutputType HashTable
      }
    }
    #endregion

    #region Get Service Nodes Configuration Data (i.e. your DHCP servers specific configuration)
    $configurationAllNodesPath = Join-Path -Path $POVFServiceConfiguration -ChildPath 'AllNodes'
    $configurationAllNodesFile = Get-ChildItem -Path "$($configurationAllNodesPath)\*" -Include  '*.psd1','*.json'
    if ($configurationAllNodesFile) {
      $POVFData.Configuration.AllNodes += ForEach ($file in $configurationAllNodesFile) { 
        Get-ConfigurationData -ConfigurationPath $file.FullName -OutputType HashTable
      }
      if ($configurationNonNodeData) {
        $POVFData.Configuration.NonNodeData += $configurationNonNodeData
      }
    }
    #endregion



   

  }
        

}