function New-POVFBaselineDHCP {
  [CmdletBinding()]
  param (
        
    [Parameter(Mandatory,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.String]
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
    #region general variable initialization
    if($PSBoundParameters.ContainsKey('ComputerName')) { 
      $sessionParams = @{
        ComputerName = $ComputerName
        SessionName = "POVF-$ComputerName"
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
    #region Get Global Configuration
    $DHCPConfig = Get-POVFConfigurationDHCPGlobal -PSSession $POVFPSSession
    $dhcpFile = Join-Path -Path $nonNodeDataPath -childPath ('DHCP.{0}.Configuration.json' -f $DHCPConfig.Domain)
    $DHCPConfig | ConvertTo-Json -Depth 99 | Out-File -FilePath $dhcpFile
    #endregion
    #region Get Nodes configuration
    foreach ($node in $DHCPConfig.ServersInAD.DNSName) {
      if($PSBoundParameters.ContainsKey('ComputerName')) { 
        $sessionParams = @{
          ComputerName = $node
          SessionName = "POVF-$node"
        }
        if($PSBoundParameters.ContainsKey('ConfigurationName')){
          $sessionParams.ConfigurationName = $ConfigurationName
        }
        if($PSBoundParameters.ContainsKey('Credential')){
          $sessionParams.Credential = $Credential
        }
        $POVFPSSessionNode = New-PSSessionCustom @SessionParams
      }
      if($PSBoundParameters.ContainsKey('PSSession')){
        $POVFPSSessionNode = $PSSession
      }
        
      $nodeConfig = Get-POVFConfigurationDHCPNode -PSSession $POVFPSSessionNode
      $nodeFile = Join-Path -Path $allNodesDataPath -childPath ('{0}.Configuration.json' -f $nodeConfig.ComputerName)
      $nodeConfig |  ConvertTo-Json -Depth 99 | Out-File -FilePath $nodeFile
      Remove-PSSession $POVFPSSessionNode.Name -ErrorAction SilentlyContinue  
    }
    #endregion
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue   
    }
  }
}