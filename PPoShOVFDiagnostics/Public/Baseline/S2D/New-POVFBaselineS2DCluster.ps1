function New-POVFBaselineS2DCluster {
  [CmdletBinding()]
  param (
    
    [Parameter(Mandatory,
    ParameterSetName='ClusterName')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ClusterName,

    [Parameter(Mandatory=$false,
    ParameterSetName='ClusterName')]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$false,
    ParameterSetName='ClusterName')]
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
    $POVFConfigurationFolderS2D
  
  )
  process{
    if($PSBoundParameters.ContainsKey('ClusterName')) { 
      $sessionParams = @{
        ComputerName = $ClusterName
        SessionName = "POVF-$ClusterName"
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
    if(-not (Test-Path $POVFConfigurationFolderS2D)        ) {
      [void](New-Item -Path $POVFConfigurationFolderS2D -ItemType Directory)
    }
    $nonNodeDataPath = (Join-Path -Path $POVFConfigurationFolderS2D -childPath 'NonNodeData')
    $allNodesDataPath = (Join-Path -Path $POVFConfigurationFolderS2D -childPath 'AllNodes')
    [void](New-Item -Path $nonNodeDataPath -ItemType Directory -force)
    [void](New-Item -Path $allNodesDataPath -ItemType Directory -force)
    #Get Cluster
    $ClusterConfig = Get-POVFS2DClusterConfiguration -PSSession $POVFPSSession
    $clusterFile = Join-Path -Path $nonNodeDataPath -childPath ('{0}.Cluster.Configuration.json' -f $ClusterConfig.Name)
    $ClusterConfig | ConvertTo-Json -Depth 99 | Out-File -FilePath $clusterFile
    #Get Nodes
    foreach ($node in $ClusterConfig.ClusterNodes) {
      if($PSBoundParameters.ContainsKey('ClusterName')) { 
        $sessionParams = @{
          ComputerName = ('{0}.{1}' -f $node,$ClusterConfig.Domain)
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
      
      $nodeConfig = Get-POVFHyperVNodeConfiguration -PSSession $POVFPSSessionNode
      $nodeFile = Join-Path -Path $allNodesDataPath -childPath ('{0}.Configuration.json' -f $nodeConfig.ComputerName)
      $nodeConfig |  ConvertTo-Json -Depth 99 | Out-File -FilePath $nodeFile
      Remove-PSSession $POVFPSSessionNode.Name -ErrorAction SilentlyContinue  
    }
  }
}