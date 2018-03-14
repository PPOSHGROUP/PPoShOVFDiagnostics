function New-POVFBaselineHyperVNode {
  [CmdletBinding()]
  param (
      
    [Parameter(Mandatory,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.String[]]
    $ComputerName,
  
    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [string]
    $ConfigurationName,
      
    [Parameter(Mandatory,
    ParameterSetName='PSCustomSession')]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Runspaces.PSSession]
    $PSSession,
  
    [Parameter(Mandatory=$true)]
    [System.String]
    [ValidateScript({Test-Path -Path $PSItem -IsValid})]
    $POVFConfigurationFolder
    
  )
  process{
    
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
     
    #Get Nodes configuration
    foreach ($computer in $ComputerName) {
      if($PSBoundParameters.ContainsKey('ComputerName')) { 
        $sessionParams = @{
          ComputerName = $computer
          SessionName = "POVF-$computer"
        }
        if($PSBoundParameters.ContainsKey('ConfigurationName')){
          $sessionParams.ConfigurationName = $ConfigurationName
        }
        if($PSBoundParameters.ContainsKey('Credential')){
          $sessionParams.Credential = $Credential
        }
        $POVFPSSession = New-PSSessionCustom @SessionParams
      }
      if($PSBoundParameters.ContainsKey('PSSession')){
        $POVFPSSession = $PSSession
      }
      $computerConfig = Get-POVFConfigurationHyperVNode -PSSession $POVFPSSession 
      $computerFile = Join-Path -Path $allNodesDataPath -childPath ('{0}.Configuration.json' -f $computer)
      $computerConfig | ConvertTo-Json -Depth 99 | Out-File -FilePath $computerFile
    }
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue   
    }
  }
}