param(
    $POVFConfiguration,
    $POVFPSSession
)

Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Configuration Status" -Tag 'Configuration' {
    #<#
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
    #QoS
    if($POVFConfiguration.Team){ 
        Context "Verify Network Team Configuration" {
            foreach ($team in $POVFConfiguration.Team) {
                $hostTeam = Invoke-Command $POVFPSSession -ScriptBlock {
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
                    Compare-Object -ReferenceObject $team.TeamMembers -DifferenceObject $hostTeam.Members  | Should -BeNullOrEmpty 
                }
            }
        }
    }
    
    if($POVFConfiguration.VmSwitch){
        Context "Verify Virtual Switch Configuration" {
            foreach ($vSwitch in $POVFConfiguration.VmSwitch) {
                $hostVMSwitch = Invoke-Command $POVFPSSession -ScriptBlock {
                    Get-VMSwitch -Name $USING:VSwitch.Name
                }
                it "Verify vSwitch Name {$($vSwitch.Name)} exists" {
                    $hostVMSwitch | Should -Not -BeNullOrEmpty
                }
                it "Verify vSwitch Name {$($vSwitch.Name)} interface bound" {

                }
                it "Verify vSwitch Name {$($vSwitch.Name)} minimum bandwith mode - {$($vSwitch.MinimumBandwidthMode)}" {
                    $hostVMSwitch.BandwidthReservationMode | Should Be $vSwitch.MinimumBandwidthMode
                }
                it "Verify vSwitch Name {$($vSwitch.Name)} default bandwidth weight - {$($vSwitch.DefaultFlowMinimumBandwidthWeight)}" {
                    $hostVMSwitch.DefaultFlowMinimumBandwidthWeight | Should Be $vSwitch.DefaultFlowMinimumBandwidthWeight
                }
                $hostVMNetworkAdapters = Invoke-Command $POVFPSSession -ScriptBlock { 
                    Get-VMNetworkAdapter -SwitchName $USING:vSwitch.Name -ManagementOS:$True
                }
                it "Verify vSwitch Name {$($vSwitch.Name)} has network adapters configured - {$(($vSwitch.VMNetworkAdapters).Count)}" { 
                    $hostVMNetworkAdapters.Count | Should Be ($vSwitch.VMNetworkAdapters).Count
                }
                foreach ($vSwitchVMNetworkAdapter in $vSwitch.VMNetworkAdapters) {
                    it "Verify VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} exists" {
                        $vSwitchVMNetworkAdapter.Name | Should -BeIn $hostVMNetworkAdapters.Name
                    }
                    it "Verify VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} VLANID - {$($vSwitchVMNetworkAdapter.VLANID)}" {
                        $vlanid = Invoke-Command $POVFPSSession -ScriptBlock {
                            Get-VMNetworkAdapterVlan -VMNetworkAdapterName $USING:vSwitchVMNetworkAdapter.Name -ManagementOS:$true 
                        }
                        $vlanid.AccessVlanId | Should Be $vSwitchVMNetworkAdapter.VLANID
                    }
                    it "Verify VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} Minimum Bandwidth Weight - {$($vSwitchVMNetworkAdapter.MinimumBandwidthWeight)}" {
                        ($hostVMNetworkAdapters.Where({$PSItem.Name -eq $vSwitchVMNetworkAdapter.Name})).BandwidthPercentage | Should Be $vSwitchVMNetworkAdapter.MinimumBandwidthWeight
                    }
                    $netAdapterIPConfiguration = Invoke-Command $POVFPSSession -ScriptBlock {
                        Get-NetIPConfiguration | Where-Object {$PSItem.InterfaceAlias -match $USING:vSwitchVMNetworkAdapter.Name} 
                    }
                    it "Verify VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} IP Configuration: IPAddress" {
                        $netAdapterIPConfiguration.IPv4Address.IPAddress | Should Be $vSwitchVMNetworkAdapter.IPConfiguration.IPAddress
                    }
                    it "Verify VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} IP Configuration: DefaultGateway" {
                        $netAdapterIPConfiguration.IPv4DefaultGateway.NextHop | Should Be $vSwitchVMNetworkAdapter.IPConfiguration.DefaultGateway
                    }
                    it "Verify VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} IP Configuration: Prefix" {
                        $netAdapterIPConfiguration.IPv4Address.PrefixLength | Should Be $vSwitchVMNetworkAdapter.IPConfiguration.PrefixLength
                    }
                    it "Verify VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} IP Configuration: DNSClientServerAddress" {
                        $DNSServers = if(($netAdapterIPConfiguration.DNSServer | Where-Object {$PSItem.AddressFamily -eq '2'}).ServerAddresses) {
                            #For IPV4 configuration Get-NetIPConfiguration returns AddressFamily -eq 2
                            ($netAdapterIPConfiguration.DNSServer | Where-Object {$PSItem.AddressFamily -eq '2'} | 
                                Select-Object -ExpandProperty ServerAddresses).Split(',')
                        }
                        else {
                            $DNSServers = $null
                        }
                        #do przerobienia
                        $DNSServers | Should -BeIn $vSwitchVMNetworkAdapter.IPConfiguration.DNSClientServerAddress
                    }
                }
            }
        }
    }
    #>
    if($POVFConfiguration.Roles){
        Context 'Verify Roles configuration' {
            $hostRoles = Invoke-Command $POVFPSSession -ScriptBlock {
                Get-WindowsFeature
            }
            foreach($presentRole in $POVFConfiguration.Roles.Present.Name) {
                $presentRole
                it "Verify role {$presentRole)} is installed" {
                    $testRole = $hostRoles | Where-Object {$PSItem.Name -eq $presentRole}
                    $testRole.Installed |Should Be $true
                }
            }
            if($POVFConfiguration.Roles.Absent) { 
                foreach($absentRole in $POVFConfiguration.Roles.Absent.Name) {
                    it "Verify role {$($absentRole.Name)} is installed" {
                        $testRole = $hostRoles | Where-Object {$PSItem.Name -eq $absentRole.Name}
                        $testRole.Installed |Should Be $false
                    }
                }
            }   
        }
    }

    #HyperV config
}