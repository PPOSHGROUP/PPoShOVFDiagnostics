param(
    $POVFConfiguration,
    $POVFPSSession
)

Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Configuration Status" -Tag 'Configuration' {
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
    if($POVFConfiguration.RegistryEntry){ 
        Context "Verify Registry Entries" {
            foreach ($rEntry in $POVFConfiguration.RegistryEntry) {
                it "Verify Registry Entry {$($rEntry.Name)} in {$($rEntry.Path)}" {
                    $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
                        Get-ItemProperty -Path $USING:rEntry.Path -Name $USING:rEntry.Name -ErrorAction SilentlyContinue
                    }
                    $rValue = [convert]::ToInt64($rEntry.Value,16)
                    $test.($rEntry.Name) | Should Be $rValue
                }

            }

        }
    }
    if($POVFConfiguration.Team){ 
        Context "Verify Network Team Configuration" {
            foreach ($team in $POVFConfiguration.Team) {
                $hostTeam = Invoke-Command $session -ScriptBlock {
                    Get-NetLbfoTeam -Name $USING:team.TeamName
                }
                it "Verify Team {$($team.TeamName)} exists" {
                    $hostTeam | Should -Not -BeNullOrEmpty
                }
                it "Verify Team {$($team.TeamName)} TeamingMode" {
                    $hostTeam.TeamingMode | Should Be $team.TeamingMode 
                }
                it "Verify Team {$($team.TeamName)} LoadBalancingAlgorithm" {
                    $hostTeam.LoadBalancingAlgorithm | Should Be $team.LoadBalancingAlgorithm
                }
                it "Verify Team {$($team.TeamName)} TeamMembers" {
                    $fromPOVFConfig = $hostTeam.TeamMembers -split ','
                    Compare-Object -ReferenceObject $fromPOVFConfig -DifferenceObject $hostTeam.TeamMembers | Should -BeNullOrEmpty 
                }
            }
        }
    }
    if($POVFConfiguration.VmSwitch){
        Context "Verify Virtual Switch Configuration" {
            foreach ($vSwitch in $POVFConfiguration.VmSwitch) {
                $hostVMSwitch = Invoke-Command $session -ScriptBlock {
                    Get-VMSwitch -Name $USING:VSwitch.Name
                }
                it "Verify vSwitch Name {$($vSwitch.Name)} exists" {
                    $hostVMSwitch | Should -Not -BeNullOrEmpty
                }
                it "Verify vSwitch Name {} interface bound" {

                }

            }
        }
    }
}