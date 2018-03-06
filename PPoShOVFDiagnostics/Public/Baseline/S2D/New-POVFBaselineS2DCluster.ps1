function New-POVFBaselineS2DCluster {
    [CmdletBinding()]
    param (
    
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [System.String]
      $ClusterName,

      [Parameter(Mandatory=$false)]
      [System.Management.Automation.PSCredential]
      $Credential,

      [Parameter(Mandatory=$true)]
      [System.String]
      [ValidateScript({Test-Path -Path $PSItem -IsValid})]
      $POVFS2DConfigurationFolder
  
    )
    begin{
    }
    process{
      $path = $POVFS2DConfigurationFolder
      $nonNodeData = (Join-Path -Path $path -childPath 'NonNodeData')
      $allNodesData = (Join-Path -Path $path -childPath 'AllNodes')
      New-Item -Path $nonNodeData -ItemType Directory -force
      New-Item -Path $allNodesData -ItemType Directory -force
        #Get Cluster
        $ClusterConfig = Get-POVFS2DClusterNoneNodeDataConfiguration -ClusterName $ClusterName -Credential $Credential  
        $clusterFile = Join-Path -Path $nonNodeData -childPath ('{0}.Cluster.Configuration.json' -f $ClusterConfig.Name)
        $ClusterConfig |  ConvertTo-Json -Depth 99 | Out-File -FilePath $clusterFile
        #Get Nodes
        foreach ($node in $ClusterConfig.ClusterNodes) {
          $nodeConfig = Get-POVFHyperVNodeConfiguration -ComputerName $node -Credential $Credential 
          $nodeFile = Join-Path -Path $allNodesData -childPath ('{0}.Configuration.json' -f $nodeConfig.ComputerName)
          $nodeConfig |  ConvertTo-Json -Depth 99 | Out-File -FilePath $nodeFile
        }
       
        

        



    }
  }