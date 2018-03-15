function New-POVFBaselineAD {

  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [System.String]
    $ComputerName,

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$true)]
    [System.String]
    [ValidateScript({Test-Path -Path $PSItem -IsValid})]
    $POVFConfigurationFolder

  )
  process{
    #region PSBound initialization
    $queryParams = @{
      ComputerName = $ComputerName
    }
    if($PSBoundParameters.ContainsKey('Credential')){
      $queryParams.Credential = $Credential
    }
    #endregion
    #region Get Configuration from environment
    $ForestConfig = Get-POVFConfigurationAD @queryParams
    #endregion
    #region path variable initialization
    if(-not (Test-Path $POVFConfigurationFolder)) {
      [void](New-Item -Path $POVFConfigurationFolder -ItemType Directory)
    }
    $nonNodeDataPath = (Join-Path -Path $POVFConfigurationFolder -childPath 'NonNodeData')
    $allNodesDataPath = (Join-Path -Path $POVFConfigurationFolder -childPath 'AllNodes')
    
    if(-not (Test-Path $nonNodeDataPath)) {
      [void](New-Item -Path $nonNodeDataPath -ItemType Directory)
    }
    if(-not (Test-Path $allNodesDataPath)) {
      [void](New-Item -Path $allNodesDataPath -ItemType Directory)
    }
    #endregion
    #region Generate files
    $forestConfigFile = Join-Path -Path $nonNodeDataPath -childPath ('{0}.Configuration.json' -f $ForestConfig.Name)
    $ForestConfig | ConvertTo-Json -Depth 99 | Out-File -FilePath $forestConfigFile 
    #endregion
  }
}