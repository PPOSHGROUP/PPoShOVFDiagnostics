param(
  $POVFConfiguration,
  [System.Management.Automation.PSCredential]$POVFCredential
)
$POVFPSSession = New-PSSessionCustom -ComputerName $POVFConfiguration.ComputerName -Credential $POVFCredential -SessionName 'POVF'
Describe "Verify [host] Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Full Network Adapters (Physical) Configuration Status" -Tags @('Configuration','Basic') {
  Context "Verify Network Adapter Properties"{
    $hostNICConfiguration = Get-POVFNetAdapterConfiguration -Physical -PSSession $POVFPSSession
    foreach ($NIC in $POVFConfiguration.NIC) {
      $currentNIC = $hostNICConfiguration | Where-Object {$PSItem.Name -eq $NIC.Name}
      if($NIC.MACAddress) {
        it "Verify [host] NIC {$($NIC.Name)} MACAddress match [baseline]" {
          $currentNIC.MACAddress  | Should -Be $NIC.MACAddress
        }
      }
      if($null -ne $NIC.IPConfiguration.IPAddress) {
        it "Verify [host] NIC {$($NIC.Name)} IP Configuration: IPAddress match [baseline]" {
          $currentNIC.IPConfiguration.IPAddress | Should -Be $NIC.IPConfiguration.IPAddress
        }
        it "Verify [host] NIC {$($NIC.Name)} IP Configuration: DefaultGateway match [baseline]" {
          $currentNIC.IPConfiguration.DefaultGateway | Should -Be $NIC.IPConfiguration.DefaultGateway
        }
        it "Verify [host] NIC {$($NIC.Name)} IP Configuration: Prefix match [baseline]" {
          $currentNIC.IPConfiguration.PrefixLength | Should Be $NIC.IPConfiguration.PrefixLength
        }
        it "Verify [host] NIC {$($NIC.Name)} IP Configuration: DNSClientServerAddress match [baseline]" {
          $currentNIC.IPConfiguration.DNSClientServerAddress | Should -BeIn $NIC.IPConfiguration.DNSClientServerAddress
        }
      }
      if($NIC.NetLBFOTeam) {
        it "Verify [host] NIC {$($NIC.Name)} Teaming status match [baseline]" {
          $currentNIC.Name   | Should -BeIn $NIC.Name
        }
      }
      if($NIC.NetAdapterVMQ.Enabled) {
        $propertyKeys = $NIC.NetAdapterVMQ.Keys
        foreach ($key in $propertyKeys) {
          IT "Verify [host] NIC {$($NIC.Name)} NetAdapterVMQ Property {$key} - {$($NIC.NetAdapterVMQ[$Key])} match [baseline]" {
            $currentNIC.NetAdapterVMQ.$key | Should Be $NIC.NetAdapterVMQ[$Key]
          }                    
        }
      }
      if($NIC.NetAdapterQoS.Enabled) {
        $propertyKeys = $NIC.NetAdapterQoS.Keys
        foreach ($key in $propertyKeys) {
          IT "Verify [host] NIC {$($NIC.Name)} NetAdapterQoS Property {$key} - {$($NIC.NetAdapterQoS[$Key])} match [baseline]" {
            $currentNIC.NetAdapterQoS.$key | Should Be $NIC.NetAdapterQoS[$Key]
          }                    
        }
      }
      if($NIC.NetAdapterRSS.Enabled) {
        $propertyKeys = $NIC.NetAdapterRSS.Keys
        foreach ($key in $propertyKeys) {
          IT "Verify [host] NIC {$($NIC.Name)} NetAdapterRSS Property {$key} - {$($NIC.NetAdapterRSS[$Key])} match [baseline]" {
            $currentNIC.NetAdapterRSS.$key | Should Be $NIC.NetAdapterRSS[$Key]
          }                    
        }
      }
      if($NIC.NetAdapterRDMA.Enabled) {
        $propertyKeys = $NIC.NetAdapterRDMA.Keys
        foreach ($key in $propertyKeys) {
          IT "Verify [host] NIC {$($NIC.Name)} NetAdapterRDMA Property {$key} - {$($NIC.NetAdapterRDMA[$Key])} match [baseline]" {
            $currentNIC.NetAdapterRSS.$key | Should Be $NIC.NetAdapterRDMA[$Key]
          }                    
        }
      }
      if($NIC.NetAdapterAdvancedProperty){
        foreach ($property in $NIC.NetAdapterAdvancedProperty){
          IT "Verify [host] NIC {$($NIC.Name)} Advanced Property {$($property.RegistryKeyword)} match [baseline]" {
            $property.RegistryValue | Should -Be ($currentNIC.NetAdapterAdvancedProperty | Where-Object {$PSItem.RegistryKeyword -eq $property.RegistryKeyword}).RegistryValue 
          }
        }
      }
    }
  }
}
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Registry Configuration Status" -Tags @('Configuration','Registry') {
  if($POVFConfiguration.Registry){ 
    Context "Verify Registry Entries" {
      $hostRegistryConfiguration = Get-POVFRegistryConfiguration -PSSession $POVFPSSession
      foreach ($rEntry in $POVFConfiguration.Registry) {
        it "Verify [host] Registry Entry {$($rEntry.Name)} in {$($rEntry.Path)} match [baseline] - {$($rEntry.Value)}" {
          ($hostRegistryConfiguration | Where-Object {$PSItem.Name -eq $rEntry.Name} ).Value | Should -Be $rEntry.Value
        }
      }
    }
  }
}
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} NetQos Configuration Status" -Tags @('Configuration','NetQoS') {
  $hostNetQoSConfiguration = Get-POVFNetQoSConfiguration -PSSession $POVFPSSession
  Context "Verify NetQos Policies Configuration" { 
    $hostNetQoSPolicies = $hostNetQoSConfiguration.NetQosPolicies
    if ($POVFConfiguration.NetQos.NetQosPolicies){ 
      #Verify if all entries from configuration are deployed to host
      foreach ($cQoSPolicy in $POVFConfiguration.NetQos.NetQosPolicies) {
        it "Verify [baseline] entry for QoS Policy, name - {$($cQoSPolicy.Name)} match [host]" { 
          $cQoSPolicy.Name | Should -BeIn $hostNetQoSPolicies.Name
        }
        it "Verify [baseline] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.PriorityValue8021Action)} match [host]" {
          $cQoSPolicy.PriorityValue8021Action | Should -Be ($hostNetQoSPolicies | Where-Object {$PSItem.Name -eq $cQoSPolicy.Name}).PriorityValue8021Action
        }
        if($null -ne $cQoSPolicy.NetDirectPortMatchCondition) { 
          it "Verify [baseline] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.NetDirectPortMatchCondition)} match [host]" {
            $cQoSPolicy.NetDirectPortMatchCondition | Should -Be ($hostNetQoSPolicies | Where-Object {$PSItem.Name -eq $cQoSPolicy.Name}).NetDirectPortMatchCondition
          }
        }
        if($null -ne $cQoSPolicy.IPProtocolMatchCondition){ 
          it "Verify [baseline] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.IPProtocolMatchCondition)} match [host]" {
            $cQoSPolicy.IPProtocolMatchCondition | Should -Be ($hostNetQoSPolicies | Where-Object {$PSItem.Name -eq $cQoSPolicy.Name}).IPProtocolMatchCondition
          }
        }
      }
      #Verify all entries from host are in configuration
      foreach ($hQosPolicy in $hostNetQoSPolicies){
        it "Verify [host] entry for QoS Policy, name - {$($hQosPolicy.Name)} match [baseline]" { 
          $hQosPolicy.Name | Should -BeIn $POVFConfiguration.NetQos.NetQosPolicies.Name
        }
        it "Verify [host] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.PriorityValue8021Action)} match [baseline]" {
          $hQosPolicy.PriorityValue8021Action | Should -Be ($POVFConfiguration.NetQos.NetQosPolicies | Where-Object {$PSItem.Name -eq $hQosPolicy.Name}).PriorityValue8021Action
        }
        if($hQosPolicy.NetDirectPortMatchCondition -ne '0') { 
          it "Verify [host] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.NetDirectPortMatchCondition)} match [baseline]" {
            $hQosPolicy.NetDirectPortMatchCondition | Should -Be ($POVFConfiguration.NetQos.NetQosPolicies | Where-Object {$PSItem.Name -eq $hQosPolicy.Name}).NetDirectPortMatchCondition
          }
        }
        if($hQosPolicy.IPProtocolMatchCondition -ne 'None'){ 
          it "Verify [host] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.IPProtocolMatchCondition)} match [baseline]" {
            $hQosPolicy.IPProtocolMatchCondition | Should -Be ($POVFConfiguration.NetQos.NetQosPolicies | Where-Object {$PSItem.Name -eq $hQosPolicy.Name}).IPProtocolMatchCondition
          }
        }
      }
    }
  }
  Context "Verify NetQoS DcbxSetting configuration" {
    it "Verify [host] NetQosDCBxSetting configuration - {$($POVFConfiguration.NetQos.NetQosDcbxSetting.Willing)} match [baseline]" {
      $hostNetQoSConfiguration.NetQosDcbxSetting.Willing | Should -Be $POVFConfiguration.NetQos.NetQosDcbxSetting.Willing
    }
  }
  Context 'Verify NetQos Flow Control configuration' { 
    it "Verify [host] QosFlowControl priority - [Enabled] match [baseline]" {
      $hostNetQoSConfiguration.NetQoSFlowControl.Enabled | Should -BeIn  $POVFConfiguration.NetQos.NetQosFlowControl.Enabled
    }
    it "Verify [host] QosFlowControl priority - [Disabled] match [baseline]" {
      $hostNetQoSConfiguration.NetQoSFlowControl.Disabled | Should -BeIn  $POVFConfiguration.NetQos.NetQosFlowControl.Disabled
    }
  }
  Context "Verify NetQos Traffic Class Configuration" { 
    foreach ($hQosTrafficClass in $hostNetQoSConfiguration.NetQosTrafficClass){
      $configQosTrafficClass = $POVFConfiguration.NetQos.NetQosTrafficClass | Where-Object {$PSItem.Name -eq $hQosTrafficClass.Name}
      #verify if all host options are in baseline configuration files. 
      it "Verify [host] entry QoSTrafficClass, name - {$($hQosTrafficClass.Name)} match [baseline]" { 
        $hQosTrafficClass.Name | Should -Be $configQosTrafficClass.Name
      }
      it "Verify [host] entry QoSTrafficClass, name - {$($hQosTrafficClass.Priority)} match [baseline], parameter Priority - {$($hQosTrafficClass.Priority)}" {
        $hQosTrafficClass.Priority | Should -Be $configQosTrafficClass.Priority
      }
      it "Verify [host] entry QoSTrafficClass, name - {$($hQosTrafficClass.BandwidthPercentage)} match [baseline], parameter BandwidthPercentage - {$($hQosTrafficClass.BandwidthPercentage)}" {
        $hQosTrafficClass.BandwidthPercentage | Should -Be $configQosTrafficClass.BandwidthPercentage
      }
      it "Verify [host] entry QoSTrafficClass, name - {$($hQosTrafficClass.Algorithm)} match [baseline], parameter Algorithm - {$($hQosTrafficClass.Algorithm)}" {
        $hQosTrafficClass.Algorithm | Should -Be $configQosTrafficClass.Algorithm
      }
    }
    if ($POVFConfiguration.NetQos.NetQosTrafficClass){
      foreach ($cQoSTrafficClass in $POVFConfiguration.NetQos.NetQosTrafficClass) {
        $currentQosTrafficClass = $hostNetQoSConfiguration.NetQosTrafficClass | Where-Object {$PSItem.Name -eq $cQoSTrafficClass.Name}
        #Verify if all entries from baseline configuration are deployed to host
        it "Verify [baseline] entry QoSTrafficClass, name - {$($cQoSTrafficClass.Name)} match [host]" { 
          $cQoSTrafficClass.Name | Should -Be $currentQosTrafficClass.Name
        }
        it "Verify [baseline] entry QoSTrafficClass, name - {$($cQoSTrafficClass.Name)} match [host], parameter Priority - {$($cQoSTrafficClass.Priority)}" {
          $cQoSTrafficClass.Priority | Should -Be $currentQosTrafficClass.Priority
        }
        it "Verify [baseline] entry QoSTrafficClass, name - {$($cQoSTrafficClass.Name)} match [host], parameter BandwidthPercentage - {$($cQoSTrafficClass.BandwidthPercentage)}" {
          $cQoSTrafficClass.BandwidthPercentage | Should -Be  $currentQosTrafficClass.BandwidthPercentage
        }
        it "Verify [baseline] entry QoSTrafficClass, name - {$($cQoSTrafficClass.Name)} match [host], parameter Algorithm - {$($cQoSTrafficClass.Algorithm)}" {
          $cQoSTrafficClass.Algorithm | Should -Be  $currentQosTrafficClass.Algorithm
        }
      }
    }
  }
  Context "Verify [host] priority match in QosFlowControl, QosPolicies and QosTraffic Class" {
    it "Verify [host] QoSFlowControl entry [Enabled] priorities match QoS Policies "{
      $hostNetQoSConfiguration.NetQoSFlowControl.Enabled | Should -BeIn $hostNetQoSConfiguration.NetQosPolicies.PriorityValue8021Action
    }
    it "Verify [host] QoSFlowControl entry [Enabled] priorities match QoS Traffic Class" {
      $hostNetQoSConfiguration.NetQoSFlowControl.Enabled | Should -BeIn $hostNetQoSConfiguration.NetQosTrafficClass.Priority
    } 
  }
}
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Teaming Configuration Status" -Tags @('Configuration','Teaming') {
  if($POVFConfiguration.Team){ 
    Context "Verify Network Team Configuration" {
      $hostTeamConfiguration = Get-POVFTeamingConfiguration -PSSession $POVFPSSession
      foreach ($cTeam in $POVFConfiguration.Team) {
        $currentTeam = $hostTeamConfiguration | Where-Object {$PSItem.Name -eq $cTeam.Name}
        it "Verify [host] Team {$($cTeam.Name)} exists" {
          $currentTeam | Should -Not -BeNullOrEmpty
        }
        it "Verify [host] Team {$($cTeam.Name)} name matches [baseline]" {
          $currentTeam | Should -Not -BeNullOrEmpty
        }
        it "Verify [host] Team {$($cTeam.Name)} TeamingMode match [baseline]" {
          $currentTeam.TeamingMode  | Should Be $cTeam.TeamingMode 
        }
        it "Verify [host] Team {$($cTeam.Name)} LoadBalancingAlgorithm match [baseline]" {
          $currentTeam.LoadBalancingAlgorithm  | Should Be $cTeam.LoadBalancingAlgorithm
        }
        it "Verify [host] Team {$($cTeam.Name)} TeamMembers match [baseline]" {
          $currentTeam.Members | Should -BeIn $cTeam.Members 
        }
      }
    }
  }
}
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} VMSwitch Configuration Status" -Tags @('Configuration','VMSwitch') {   
  if($POVFConfiguration.VmSwitch){
    Context "Verify Virtual Switch Configuration" {
      $hostVMSwitch = Get-POVFVMSwitchConfiguration -PSSession $POVFPSSession
      foreach ($cvmSwitch in $POVFConfiguration.VmSwitch) {
        $currentVMSwitch = $hostVMSwitch | Where-Object {$PSItem.Name -eq $cvmSwitch.Name}
        it "Verify [host] vSwitch Name {$($cvmSwitch.Name)} exists" {
          $currentVMSwitch | Should -Not -BeNullOrEmpty
        }
        it "Verify [host] vSwitch Name {$($cvmSwitch.Name)} interface bound match [baseline]" {

        }
        it "Verify [host] vSwitch Name {$($cvmSwitch.Name)} minimum bandwith mode - {$($cvmSwitch.MinimumBandwidthMode)} match [baseline]" {
          $currentVMSwitch.MinimumBandwidthMode | Should -Be $cvmSwitch.MinimumBandwidthMode
        }
        it "Verify [host] vSwitch Name {$($cvmSwitch.Name)} default bandwidth weight - {$($cvmSwitch.DefaultFlowMinimumBandwidthWeight)} match [baseline]" {
          $currentVMSwitch.DefaultFlowMinimumBandwidthWeight | Should -Be $cvmSwitch.DefaultFlowMinimumBandwidthWeight
        }
        it "Verify [host] vSwitch Name {$($cvmSwitch.Name)} allow management - {$($cvmSwitch.AllowManagementOS)} match [baseline]" {
          $currentVMSwitch.AllowManagementOS | Should -Be $cvmSwitch.AllowManagementOS
        }
        it "Verify [host] vSwitch Name {$($cvmSwitch.Name)} match [baseline] # of network adapters configured - {$(($cvmSwitch.VMNetworkAdapters).Count)}" { 
          ($currentVMSwitch.VMNetworkAdapters).Count | Should -Be ($cvmSwitch.VMNetworkAdapters).Count
        }
        foreach ($cvmSwitchVMNetworkAdapter in $cvmSwitch.VMNetworkAdapters) {
          $currentVMNetworkAdapter = $currentVMSwitch.VMNetworkAdapters | Where-Object {$PSItem.Name -eq $cvmSwitchVMNetworkAdapter.Name}
          it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} exists" {
            $cvmSwitchVMNetworkAdapter.Name | Should -Be $currentVMNetworkAdapter.Name
          }
          it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} VLANID - {$($cvmSwitchVMNetworkAdapter.VLANID)} match [baseline]" {
            $currentVMNetworkAdapter.VlanId | Should -Be $cvmSwitchVMNetworkAdapter.VLANID
          }
          it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} Bandwidth percentage - {$($cvmSwitchVMNetworkAdapter.BandwidthPercentage)} match [baseline]" {
            $currentVMNetworkAdapter.BandwidthPercentage | Should -Be $cvmSwitchVMNetworkAdapter.BandwidthPercentage
          }
          it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} OperationMode - {$($cvmSwitchVMNetworkAdapter.OperationMode)} match [baseline]" {
            $currentVMNetworkAdapter.OperationMode | Should -Be $cvmSwitchVMNetworkAdapter.OperationMode
          }
          it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} DhcpGuard - {$($cvmSwitchVMNetworkAdapter.DhcpGuard)} match [baseline]" {
            $currentVMNetworkAdapter.DhcpGuard | Should -Be $cvmSwitchVMNetworkAdapter.DhcpGuard
          }
          it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} RouterGuard - {$($cvmSwitchVMNetworkAdapter.RouterGuard)} match [baseline]" {
            $currentVMNetworkAdapter.RouterGuard | Should -Be $cvmSwitchVMNetworkAdapter.RouterGuard
          }
          it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} ExtendedAclList match [baseline]" {
            $currentVMNetworkAdapter.ExtendedAclList | Should -Be $cvmSwitchVMNetworkAdapter.ExtendedAclList
          }
          if($null -ne $cvmSwitchVMNetworkAdapter.IPConfiguration.IPAddress) {
            it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} IP Configuration: [IPAddress] match [baseline]" {
              $currentVMNetworkAdapter.IPConfiguration.IPAddress | Should -Be $cvmSwitchVMNetworkAdapter.IPConfiguration.IPAddress
            }
            it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} IP Configuration: [DefaultGateway] match [baseline]" {
              $currentVMNetworkAdapter.IPConfiguration.DefaultGateway | Should -Be $cvmSwitchVMNetworkAdapter.IPConfiguration.DefaultGateway
            }
            it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} IP Configuration: [Prefix] match [baseline]" {
              $currentVMNetworkAdapter.IPConfiguration.PrefixLength | Should -Be $cvmSwitchVMNetworkAdapter.IPConfiguration.PrefixLength
            }
            it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} IP Configuration: [DNSClientServerAddress] match [baseline]" {
              $currentVMNetworkAdapter.IPConfiguration.DNSClientServerAddress | Should -BeIn $cvmSwitchVMNetworkAdapter.IPConfiguration.DNSClientServerAddress
            }
            it "Verify [host] VMNetworkAdapter {$($cvmSwitchVMNetworkAdapter.Name)} IP Configuration: [DHCP] match [baseline]" {
              $currentVMNetworkAdapter.IPConfiguration.DHCP | Should -Be $cvmSwitchVMNetworkAdapter.IPConfiguration.DHCP
            }
          }
        }
      }
    }
  }
}
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Roles Configuration Status" -Tags @('Configuration','Roles') {
  Context 'Verify Roles configuration' {
    $currentRoles = Get-POVFRolesConfiguration -PSSession $POVFPSSession
    if($POVFConfiguration.Roles.Present){
      it "Verify [host] role [Present] match configuration [baseline]" {
        $currentRoles.Present | Should -BeIn $POVFConfiguration.Roles.Present
      }
    }
    if($POVFConfiguration.Roles.Absent){
      it "Verify [host] role [Absent] match configuration [baseline]" {
        $currentRoles.Absent | Should -BeIn $POVFConfiguration.Roles.Absent
      }
    }
  }
}
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Hyper-V Configuration Status" -Tags @('Configuration','Hyper-V') {
  if($POVFConfiguration.HyperVConfiguration){
    Context "Verify Hyper-V host configuration" {
      $hostHyperVConfiguration = Get-POVFHyperVConfiguration -PSSession $POVFPSSession
      it "Verify [host] Virtual Hard Disks path match [baseline]" {
        $hostHyperVConfiguration.VirtualHardDiskPath | Should -Be $POVFConfiguration.HyperVConfiguration.VirtualHardDiskPath
      }
      it "Verify [host] Virtual Machines path match [baseline]" {
        $hostHyperVConfiguration.VirtualMachinePath | Should -Be $POVFConfiguration.HyperVConfiguration.VirtualMachinePath
      }
      it "Verify [host] Live Migration status - {$($POVFConfiguration.HyperVConfiguration.LiveMigrations.Enabled)} match [baseline]" {
        $hostHyperVConfiguration.LiveMigrations.Enabled | Should -Be $POVFConfiguration.HyperVConfiguration.LiveMigrations.Enabled
      }
      it "Verify [host] number of simultaneous Live Migration status - {$($POVFConfiguration.HyperVConfiguration.LiveMigrations.Simultaneous)} match [baseline]" {
        $hostHyperVConfiguration.LiveMigrations.Simultaneous | Should Be $POVFConfiguration.HyperVConfiguration.LiveMigrations.Simultaneous
      }  
      it "Verify [host] number of simultaneous Storage Migration status - {$($POVFConfiguration.HyperVConfiguration.StorageMigrations.Simultaneous)} match [baseline]" {
        $hostHyperVConfiguration.StorageMigrations.Simultaneous | Should Be $POVFConfiguration.HyperVConfiguration.StorageMigrations.Simultaneous
      }
      it "Verify [host] Numa Spanning status - {$($POVFConfiguration.HyperVConfiguration.NumaSpanning.Enabled)} match [baseline]" {
        $hostHyperVConfiguration.NumaSpanning.Enabled | Should Be $POVFConfiguration.HyperVConfiguration.NumaSpanning.Enabled
      }
    }
  }
}
Get-PSSession -Name 'POVF*' | Remove-PSSession -ErrorAction SilentlyContinue 