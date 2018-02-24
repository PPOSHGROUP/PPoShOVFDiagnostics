param(
    $POVFConfiguration,
    $POVFPSSession
)

Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Basic Network Configuration Status" -Tags @('Configuration','Basic') {
    Context "Verify Network Adapter Properties"{
        foreach ($NIC in $POVFConfiguration.NIC) {
            if($NIC.MACAddress) {
                it "Verify NIC {$($NIC.Name)} MACAddress" {
                    $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
                        Get-NetAdapter -name $USING:NIC.Name -ErrorAction SilentlyContinue 
                    }
                    $test.MACAddress | Should Be $NIC.MACAddress
                }
            }
            if($NIC.NetLBFOTeam) {
                it "Verify NIC {$($NIC.Name)} Teaming status" {
                    $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
                        Get-NetLBFOTeam -Name $USING:NIC.NetLBFOTeam -ErrorAction SilentlyContinue 
                    }
                    $NIC.Name  | Should -BeIn $test.Members
                }
            }
            if($NIC.NetAdapterVMQ.Enabled) {
                $propertyKeys = $NIC.NetAdapterVMQ.Keys
                foreach ($key in $propertyKeys) {
                    IT "Verify NIC {$($NIC.Name)} NetAdapterVMQ Property {$key} - {$($NIC.NetAdapterVMQ[$Key])}" {
                        $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
                            Get-NetAdapterVMQ -name $USING:NIC.Name -ErrorAction SilentlyContinue 
                        }
                        $test.$key | Should Be $NIC.NetAdapterVMQ[$Key]
                    }                    
                }
            }
            if($NIC.NetAdapterQoS.Enabled) {
                $propertyKeys = $NIC.NetAdapterQoS.Keys
                foreach ($key in $propertyKeys) {
                    IT "Verify NIC {$($NIC.Name)} NetAdapterQoS Property {$key} - {$($NIC.NetAdapterQoS[$Key])}" {
                        $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
                            Get-NetAdapterQoS -name $USING:NIC.Name -ErrorAction SilentlyContinue
                        }
                        $test.$key | Should Be $NIC.NetAdapterQoS[$Key]
                    }                    
                }
            }
            if($NIC.NetAdapterRSS.Enabled) {
                $propertyKeys = $NIC.NetAdapterRSS.Keys
                foreach ($key in $propertyKeys) {
                    IT "Verify NIC {$($NIC.Name)} NetAdapterRSS Property {$key} - {$($NIC.NetAdapterRSS[$Key])}" {
                        $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
                            Get-NetAdapterRSS -name $USING:NIC.Name -ErrorAction SilentlyContinue 
                        }
                        $test.$key | Should Be $NIC.NetAdapterRSS[$Key]
                    }                    
                }
            }
            if($NIC.NetAdapterRDMA.Enabled) {
                $propertyKeys = $NIC.NetAdapterRDMA.Keys
                foreach ($key in $propertyKeys) {
                    IT "Verify NIC {$($NIC.Name)} NetAdapterRDMA Property {$key} - {$($NIC.NetAdapterRDMA[$Key])}" {
                        $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
                            Get-NetAdapterRDMA -name $USING:NIC.Name -ErrorAction SilentlyContinue 
                        }
                        $test.$key | Should Be $NIC.NetAdapterRDMA[$Key]
                    }                    
                }
            }
            if($NIC.NetAdapterAdvancedProperty){
                foreach ($property in $NIC.NetAdapterAdvancedProperty){
                    IT "Verify NIC {$($NIC.Name)} Advanced Property {$($property.RegistryKeyword)}" {
                        $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
                            Get-NetAdapterAdvancedProperty -name $USING:NIC.Name -RegistryKeyword $USING:property.RegistryKeyword -ErrorAction SilentlyContinue
                        }
                        $property.RegistryValue | Should BeLike $test.RegistryValue
                    }
                }
            }
        }
    }
}