param(
    $POVFConfiguration,
    $POVFPSSession
)

Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Basic Network Configuration Status" -Tags @('Configuration','Basic') {
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
}
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Registry Configuration Status" -Tags @('Configuration','Registry') {
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
}
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} NetQos Configuration Status" -Tags @('Configuration','NetQoS') {
     Context "Verify NetQos Policies Configuration" { 
        $hostQosPolicies = Invoke-Command -Session $POVFPSSession -ScriptBlock { 
            Get-NetQosPolicy
        }
        if ($POVFConfiguration.NetQos.NetQosPolicies){
            foreach ($cQoSPolicy in ($POVFConfiguration.NetQos.NetQosPolicies| Where-Object {$PSItem.Name -notmatch 'Default'})) {
                it "Configuration entry for QoS Policy, name - {$($cQoSPolicy.Name)} should be on Host" { 
                    $cQoSPolicy.Name | Should -BeIn $hostQosPolicies.Name
                }
                it "Configuration entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority {$($cQoSPolicy.PriorityValue8021Action)} should be on Host" {
                    $cQoSPolicy.PriorityValue8021Action | Should Be ($hostQosPolicies | Where-Object {$PSItem.Name -eq $cQoSPolicy.Name}).PriorityValue8021Action
                }
                if($cQoSPolicy.NetDirectPortMatchCondition -ne $null) { 
                    it "Configuration entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter NetDirectPortMatchCondition {$($cQoSPolicy.NetDirectPortMatchCondition)} should be on Host" {
                        $cQoSPolicy.NetDirectPortMatchCondition | Should Be ($hostQosPolicies | Where-Object {$PSItem.Name -eq $cQoSPolicy.Name}).NetDirectPortMatchCondition
                    }
                }
                if($cQoSPolicy.IPProtocolMatchCondition -ne $null){ 
                    it "Configuration entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter IPProtocolMatchCondition {$($cQoSPolicy.IPProtocolMatchCondition)} should be on Host" {
                        $cQoSPolicy.IPProtocolMatchCondition | Should Be ($hostQosPolicies | Where-Object {$PSItem.Name -eq $cQoSPolicy.Name}).IPProtocolMatchCondition
                    }
                }
            }
            foreach ($hQosPolicy in ($hostQosPolicies| Where-Object {$PSItem.Name -notmatch 'Default'})){
                it "Entry for QoS Policy, name - {$($hQosPolicy.Name)} should be in Configuration" { 
                    $hQosPolicy.Name | Should -BeIn $POVFConfiguration.NetQos.NetQosPolicies.Name
                }
                it "Entry for QoS Policy, name - {$($hQosPolicy.Name)}, parameter PriorityValue8021Action {$($hQosPolicy.PriorityValue8021Action)} should be in Configuration" {
                    $hQosPolicy.PriorityValue8021Action | Should Be ($POVFConfiguration.NetQos.NetQosPolicies | Where-Object {$PSItem.Name -eq $hQosPolicy.Name}).PriorityValue8021Action
                }
                if($hQosPolicy.NetDirectPortMatchCondition -ne '0') { 
                    it "Entry for QoS Policy, name - {$($hQosPolicy.Name)}, parameter NetDirectPortMatchCondition {$($hQosPolicy.NetDirectPortMatchCondition)} should be in Configuration" {
                        $hQosPolicy.NetDirectPortMatchCondition | Should Be ($POVFConfiguration.NetQos.NetQosPolicies | Where-Object {$PSItem.Name -eq $hQosPolicy.Name}).NetDirectPortMatchCondition
                    }
                }
                if($hQosPolicy.IPProtocolMatchCondition -ne 'None'){ 
                    it "Entry for QoS Policy, name - {$($hQosPolicy.Name)}, parameter IPProtocolMatchCondition {$($hQosPolicy.IPProtocolMatchCondition)} should be in Configuration" {
                        $hQosPolicy.IPProtocolMatchCondition | Should Be ($POVFConfiguration.NetQos.NetQosPolicies | Where-Object {$PSItem.Name -eq $hQosPolicy.Name}).IPProtocolMatchCondition
                    }
                }
            }
        }
    }
    Context "Verify NetQoS configuration" {
        it "Verify NetQosDCBxSetting configuration - {$($POVFConfiguration.NetQos.NetQosDcbxSetting.Willing)}" {
            $hostNetQosDcbxSetting = Invoke-Command -Session $POVFPSSession -ScriptBlock { 
                Get-NetQosDcbxSetting | Select-Object -ExpandProperty Willing
            }
            $hostNetQosDcbxSetting | Should Be $POVFConfiguration.NetQos.NetQosDcbxSetting.Willing
        }
    }
    Context 'Verify NetQos Flow Control configuration' { 
        $hostQosFlowControl = Invoke-Command -Session $POVFPSSession -ScriptBlock { 
            Get-NetQosFlowControl
        }
        foreach ($hQosFlowContrlEntry in ($hostQosFlowControl | Where-Object {$PSItem.Enabled -eq $true}) ) {
            it "Verify QosFlowControl priorty {$($hQosFlowContrlEntry.Priority)} - {Enabled}" {
                $hQosFlowContrlEntry.Priority | Should -BeIn  $POVFConfiguration.NetQos.NetQosFlowControl.Enabled
            }
        }
        foreach ($hQosFlowContrlEntry in ($hostQosFlowControl | Where-Object {$PSItem.Enabled -eq $false}) ) {
            it "Verify QosFlowControl priorty {$($hQosFlowContrlEntry.Priority)} - {Disabled}" {
                $hQosFlowContrlEntry.Priority | Should -BeIn  $POVFConfiguration.NetQos.NetQosFlowControl.Disabled
            }
        }
    }
    Context "Verify NetQos Traffic Class Configuration" { 
        $hostQosTrafficClass = Invoke-Command -Session $POVFPSSession -ScriptBlock {
            #During Deserialization value Algorithm goes from string to Byte Value. Need to force String in return object 
            Get-NetQOsTrafficClass | Select-Object Name, Priority, BandwidthPercentage, @{name='Algorithm';expression={($_.Algorithm).ToString()}}
        }
        if ($POVFConfiguration.NetQos.NetQosTrafficClass){
            foreach ($cQoSTrafficClass in $POVFConfiguration.NetQos.NetQosTrafficClass) {
                #Verify if all entries from configuration are deployed to host
                it "Configuration entry for QoSTrafficClass, name - {$($cQoSTrafficClass.Name)} should be on Host" { 
                    $cQoSTrafficClass.Name | Should -BeIn $hostQosTrafficClass.Name
                }
                it "Configuration entry for QoSTrafficClass, name - {$($cQoSTrafficClass.Name)}, parameter Priority {$($cQoSTrafficClass.Priority)} should be on Host" {
                    $cQoSTrafficClass.Priority | Should Be ($hostQosTrafficClass | Where-Object {$PSItem.Name -eq $cQoSTrafficClass.Name}).Priority
                }
                it "Configuration entry for QoSTrafficClass, name - {$($cQoSTrafficClass.Name)}, parameter BandwidthPercentage {$($cQoSTrafficClass.BandwidthPercentage)} should be on Host" {
                    $cQoSTrafficClass.BandwidthPercentage | Should Be ($hostQosTrafficClass | Where-Object {$PSItem.Name -eq $cQoSTrafficClass.Name}).BandwidthPercentage
                }
                it "Configuration entry for QoSTrafficClass, name - {$($cQoSTrafficClass.Name)}, parameter Algorithm {$($cQoSTrafficClass.Algorithm)} should be on Host" {
                    $cQoSTrafficClass.Algorithm | Should Be ($hostQosTrafficClass | Where-Object {$PSItem.Name -eq $cQoSTrafficClass.Name}).Algorithm
                }
            }
            foreach ($hQosTrafficClass in ($hostQosTrafficClass| Where-Object {$PSItem.Name -notmatch 'Default'})){
                #verify if all host options are in configuration files. 
                it "Entry for QoSTrafficClass, name - {$($hQosTrafficClass.Name)} should be in Configuration" { 
                    $hQosTrafficClass.Name | Should -BeIn $POVFConfiguration.NetQos.NetQosTrafficClass.Name
                }
                it "Entry for QoSTrafficClass, name - {$($hQosTrafficClass.Name)}, parameter Priority {$($hQosTrafficClass.Priority)} should be in Configuration" {
                    $hQosTrafficClass.Priority | Should Be ($POVFConfiguration.NetQos.NetQosTrafficClass | Where-Object {$PSItem.Name -eq $hQosTrafficClass.Name}).Priority
                }
                it "Entry for QoSTrafficClass, name - {$($hQosTrafficClass.Name)}, parameter BandwidthPercentage {$($hQosTrafficClass.BandwidthPercentage)} should be in Configuration" {
                    $hQosTrafficClass.BandwidthPercentage | Should Be ($POVFConfiguration.NetQos.NetQosTrafficClass | Where-Object {$PSItem.Name -eq $hQosTrafficClass.Name}).BandwidthPercentage
                }
                it "Entry for QoSTrafficClass, name - {$($hQosTrafficClass.Name)}, parameter Algorithm {$($hQosTrafficClass.Algorithm)} should be in Configuration" {
                    $hQosTrafficClass.Algorithm | Should Be ($POVFConfiguration.NetQos.NetQosTrafficClass | Where-Object {$PSItem.Name -eq $hQosTrafficClass.Name}).Algorithm
                }
            }
        }
    }
    Context "Verify priority match in QosFlowControl, QosPolicies and QosTraffic Class" {
        foreach ($hQosFlowContrlEntry in ($hostQosFlowControl | Where-Object {$PSItem.Enabled -eq $true}) ) {
            it "Verify QoSFlowControl entry {$($hQosFlowContrlEntry.Name)} priority {$($hQosFlowContrlEntry.Priority)} match QoS Policies "{
                $hQosFlowContrlEntry.Priority | Should -BeIn ($hostQosPolicies| Where-Object {$PSItem.Name -notmatch 'Default'}).PriorityValue
            }
            it "Verify QoSFlowControl entry {$($hQosFlowContrlEntry.Name)} priority {$($hQosFlowContrlEntry.Priority)} match QoS Traffic Class "{
                $hQosFlowContrlEntry.Priority | Should -BeIn ($hostQosTrafficClass| Where-Object {$PSItem.Name -notmatch 'Default'}).Priority
            }
        }
    }
}
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Teaming Configuration Status" -Tags @('Configuration','Teaming') {
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
}
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
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Roles Configuration Status" -Tags @('Configuration','Roles') {
    if($POVFConfiguration.Roles){
        Context 'Verify Roles configuration' {
            $hostRoles = Invoke-Command $POVFPSSession -ScriptBlock {
                Get-WindowsFeature
            }
            foreach($presentRole in $POVFConfiguration.Roles.Present.Name) {
                $presentRole
                it "Verify role {$presentRole} is installed" {
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
}
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