param(
    $PSSession,
    $NodeConfiguration,
    $ClusterConfiguration

)


Describe "Verifying Cluster {$($ClusterConfiguration.ClusterName)} Operational Status" {
    Context "Verifying Core Cluster Resources"{
        $coreClusterResources = Invoke-Command -Session $pssession -ScriptBlock {
            Get-ClusterResource | Where-Object {$PSItem.OwnerGroup -eq 'Cluster Group'} | Select-Object -Property Name,State,OwnerGroup,ResourceType
        }
        if($coreClusterResources){
            foreach($ccResource in $coreClusterResources){
                IT "Verifying resource {$($ccResource.Name)} state is {Online}" {
                    $ccResource.State.Value | Should Be 'Online'
                }
            }
        }
    }
    Context "Verifying Cluster Core Network Resources" {
        $coreNetworkResources = Invoke-Command -Session $pssession -ScriptBlock { Get-ClusterNetwork }
        if($coreNetworkResources){
            foreach($cnResource in $coreNetworkResources){ 
                IT "Verifying network resource {$($cnResource.Name)} state is {UP}"{
                    $cnResource.State | Should Be 'Up'
                }
            }
        }
    }  
    Context "Verifying Cluster Network Interfaces" {
        $networkInterfaces = Invoke-Command -Session $pssession -ScriptBlock { Get-ClusterNetworkInterface }
        if($networkInterfaces) {
            foreach ($nInterface in $networkInterfaces){
                IT "Verifying network interface {$($nInterface.Name)} from Node {$($nInterface.Node)} State is {Up}" {
                    $nInterface.State | Should Be 'Up'
                }
            }
        }
    }
}
Describe "Verifying Cluster Nodes Operational Status"{
    Context "Verifying Nodes are Online" {
        $clusterNodes = Invoke-Command -Session $pssession -ScriptBlock { Get-ClusterNode }
        foreach($cNode in $clusterNodes){
            IT "Veryfing node {$($cNode.Name)} Status" { 
                $cNode.State | Should Be 'Up'
            }
        }
    }
}
Describe "Verifying Cluster {$($ClusterConfiguration.ClusterName)} Storage" {
    Context "Verifying Cluster Shared Volumes State" {
        $clusterSharedVolumes = Invoke-Command -Session $pssession -ScriptBlock {Get-ClusterSharedVolume}
        if($clusterSharedVolumes) {
            foreach ($csVolume in $clusterSharedVolumes){
                IT "Verifying Volume {$($csVolume.Name)} State is {Online}" {
                    $csVolume.State | Should Be 'Online'
                }
                IT "Verifying Volume {$($csVolume.Name)} is on parent Node" {
                    $csVolume.Name | Should match $csVolume.OwnerNode

                }
            }
        }
    }
    Context "Verifying Storage Job Status" {
        $storageJobs = Invoke-Command -Session $pssession -ScriptBlock { Get-StorageJob }
        IT "There should be no storageJobs running" {
            $storageJobs | Should Be $null
        }
    }
  
}