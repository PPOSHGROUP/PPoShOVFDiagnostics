param (
  $POVFConfiguration,
  [System.Management.Automation.PSCredential]$POVFCredential
)
$POVFPSSession = New-PSSessionCustom -ComputerName $POVFConfiguration.ClusterName -Credential $POVFCredential -SessionName 'POVF'
Describe "Verify [host] Cluster {$($POVFConfiguration.ClusterName)} Operational Status" -Tag 'Operational' {
  Context "Verify [host] Core Cluster Resources"{
    $coreClusterResources = Invoke-Command -Session $POVFPSSession -ScriptBlock {
      Get-ClusterResource | Where-Object {$PSItem.OwnerGroup -eq 'Cluster Group'} | Select-Object -Property Name,State,OwnerGroup,ResourceType
    }
    if($coreClusterResources){
      foreach($ccResource in $coreClusterResources){
        IT "Verify [host] resource {$($ccResource.Name)} state is [Online]" {
          $ccResource.State.Value | Should Be 'Online'
        }
      }
    }
  }
  Context "Verify [host] Cluster Core Network Resources" {
    $coreNetworkResources = Invoke-Command -Session $POVFPSSession -ScriptBlock { Get-ClusterNetwork }
    if($coreNetworkResources){
      foreach($cnResource in $coreNetworkResources){ 
        IT "Verify [host] network resource {$($cnResource.Name)} state is [UP]"{
          $cnResource.State | Should Be 'Up'
        }
      }
    }
  }  
  Context "Verify [host] Cluster Network Interfaces" {
    $networkInterfaces = Invoke-Command -Session $POVFPSSession -ScriptBlock { Get-ClusterNetworkInterface }
    if($networkInterfaces) {
      foreach ($nInterface in $networkInterfaces){
        IT "Verify [host] network interface {$($nInterface.Name)} from Node {$($nInterface.Node)} State is [Up]" {
          $nInterface.State | Should Be 'Up'
        }
      }
    }
  }
}
Describe "Verify [host] Cluster {$($POVFConfiguration.ClusterName)} Nodes Operational Status" -Tag 'Operational' {
  Context "Verify [host] Nodes are Online" {
    $clusterNodes = Invoke-Command -Session $POVFPSSession -ScriptBlock { Get-ClusterNode }
    foreach($cNode in $clusterNodes){
      IT "Verify node {$($cNode.Name)} Status" { 
        $cNode.State | Should Be 'Up'
      }
    }
  }
}
Describe "Verify [host] Cluster {$($POVFConfiguration.ClusterName)} Storage" -Tag 'Operational' {Verify [host]
  Context "Verify [host] Cluster Shared Volumes State" {
    $clusterSharedVolumes = Invoke-Command -Session $POVFPSSession -ScriptBlock {Get-ClusterSharedVolume}
    if($clusterSharedVolumes) {
      foreach ($csVolume in $clusterSharedVolumes){
        IT "Verify [host] Volume {$($csVolume.Name)} State is {Online}" {
          $csVolume.State | Should Be 'Online'
        }
        IT "Verify [host] Volume {$($csVolume.Name)} is on parent Node" {
          $csVolume.Name | Should match $csVolume.OwnerNode

        }
      }
    }
  }
  Context "Verify [host] Storage Job Status" {
    $storageJobs = Invoke-Command -Session $POVFPSSession -ScriptBlock { Get-StorageJob }
    IT "Verify [host] storage Jobs runnin - should be none" {
      $storageJobs | Should Be $null
    }
  }
}
Get-PSSession -Name 'POVF*' | Remove-PSSession -ErrorAction SilentlyContinue 