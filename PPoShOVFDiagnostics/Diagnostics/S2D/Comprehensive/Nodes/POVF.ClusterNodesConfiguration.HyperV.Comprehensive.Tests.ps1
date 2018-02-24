param(
    $POVFConfiguration,
    $POVFPSSession
)

Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Hyper-V Configuration Status" -Tags @('Configuration','Hyper-V') {
    if($POVFConfiguration.HyperVConfiguration){
        Context "Verify Hyper-V host configuration" {
            $hostProperties = Invoke-Command $POVFPSSession -ScriptBlock {
                Get-VMHost | Select-Object *
            }
            it "Verify Virtual Hard Disks path configuration" {
                $hostProperties.VirtualHardDiskPath | Should Be $POVFConfiguration.HyperVConfiguration.VirtualHardDiskPath
            }
            it "Verify Virtual Machines path configuration" {
                $hostProperties.VirtualMachinePath | Should Be $POVFConfiguration.HyperVConfiguration.VirtualMachinePath
            }
            it "Verify Live Migration status - {$($POVFConfiguration.HyperVConfiguration.LiveMigrations.Enabled)}" {
                $hostProperties.VirtualMachineMigrationEnabled | Should Be $POVFConfiguration.HyperVConfiguration.LiveMigrations.Enabled
            }
            it "Verify number of simultaneous Live Migration status - {$($POVFConfiguration.HyperVConfiguration.LiveMigrations.Simultaneous)}" {
                $hostProperties.MaximumVirtualMachineMigrations | Should Be $POVFConfiguration.HyperVConfiguration.LiveMigrations.Simultaneous
            }  
            it "Verify number of simultaneous Storage Migration status - {$($POVFConfiguration.HyperVConfiguration.StorageMigrations.Simultaneous)}" {
                $hostProperties.MaximumStorageMigrations | Should Be $POVFConfiguration.HyperVConfiguration.StorageMigrations.Simultaneous
            }
            it "Verify Numa Spanning status - {$($POVFConfiguration.HyperVConfiguration.NumaSpanning.Enabled)}" {
                $hostProperties.NumaSpanningEnabled | Should Be $POVFConfiguration.HyperVConfiguration.NumaSpanning.Enabled
            }
        }
    }
}