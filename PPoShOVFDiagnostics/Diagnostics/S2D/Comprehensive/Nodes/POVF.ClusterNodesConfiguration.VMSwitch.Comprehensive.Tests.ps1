param(
    $POVFConfiguration,
    $POVFPSSession
)
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} VMSwitch Configuration Status" -Tags @('Configuration','VMSwitch') {   
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
                        $DNSServers | Should -BeIn $vSwitchVMNetworkAdapter.IPConfiguration.DNSClientServerAddress
                    }
                }
            }
        }
    }
}