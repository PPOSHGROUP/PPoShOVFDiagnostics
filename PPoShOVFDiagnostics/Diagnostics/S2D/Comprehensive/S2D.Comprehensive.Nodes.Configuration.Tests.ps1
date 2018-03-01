param(
  $POVFConfiguration,
  [System.Management.Automation.PSCredential]$POVFCredential
)
$POVFPSSession = New-PSSessionCustom -ComputerName $POVFConfiguration.ComputerName -Credential $POVFCredential -SessionName 'POVF'
Describe "Verify Server {$($POVFConfiguration.ComputerName)} in Cluster - {$($POVFConfiguration.ClusterName)} Basic Network Configuration Status" -Tags @('Configuration','Basic') {
  Context "Verify Network Adapter Properties"{
    foreach ($NIC in $POVFConfiguration.NIC) {
      if($NIC.MACAddress) {
        it "Verify [baseline] NIC {$($NIC.Name)} MACAddress" {
          $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
            Get-NetAdapter -name $USING:NIC.Name -ErrorAction SilentlyContinue 
          }
          $test.MACAddress | Should Be $NIC.MACAddress
        }
      }
      if($NIC.NetLBFOTeam) {
        it "Verify [baseline] NIC {$($NIC.Name)} Teaming status" {
          $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
            Get-NetLBFOTeam -Name $USING:NIC.NetLBFOTeam -ErrorAction SilentlyContinue 
          }
          $NIC.Name  | Should -BeIn $test.Members
        }
      }
      if($NIC.NetAdapterVMQ.Enabled) {
        $propertyKeys = $NIC.NetAdapterVMQ.Keys
        foreach ($key in $propertyKeys) {
          IT "Verify [baseline] NIC {$($NIC.Name)} NetAdapterVMQ Property {$key} - {$($NIC.NetAdapterVMQ[$Key])}" {
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
          IT "Verify [baseline] NIC {$($NIC.Name)} NetAdapterQoS Property {$key} - {$($NIC.NetAdapterQoS[$Key])}" {
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
          IT "Verify [baseline] NIC {$($NIC.Name)} NetAdapterRSS Property {$key} - {$($NIC.NetAdapterRSS[$Key])}" {
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
          IT "Verify [baseline] NIC {$($NIC.Name)} NetAdapterRDMA Property {$key} - {$($NIC.NetAdapterRDMA[$Key])}" {
            $test = Invoke-Command -Session $POVFPSSession -ScriptBlock {
              Get-NetAdapterRDMA -name $USING:NIC.Name -ErrorAction SilentlyContinue 
            }
            $test.$key | Should Be $NIC.NetAdapterRDMA[$Key]
          }                    
        }
      }
      if($NIC.NetAdapterAdvancedProperty){
        foreach ($property in $NIC.NetAdapterAdvancedProperty){
          IT "Verify [host] NIC {$($NIC.Name)} Advanced Property {$($property.RegistryKeyword)}" {
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
        it "Verify [host] Registry Entry {$($rEntry.Name)} in {$($rEntry.Path)}" {
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
      Get-NetQosPolicy | ForEach-Object {
        @{
          Name = $PSItem.Name
          PriorityValue8021Action = $PSItem.PriorityValue8021Action.ToString()
          NetDirectPortMatchCondition = $PSItem.NetDirectPortMatchCondition.ToString()
          IPProtocolMatchCondition = $PSItem.IPProtocolMatchCondition.ToString()
    }
      }
    }
    if ($POVFConfiguration.NetQos.NetQosPolicies){
      #Verify if all entries from configuration are deployed to host
      foreach ($cQoSPolicy in ($POVFConfiguration.NetQos.NetQosPolicies| Where-Object {$PSItem.Name -notmatch 'Default'})) {
        it "Verify [baseline] entry for QoS Policy, name - {$($cQoSPolicy.Name)} match [host]" { 
          $cQoSPolicy.Name | Should -BeIn $hostQosPolicies.Name
        }
        it "Verify [baseline] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.PriorityValue8021Action)} match [host]" {
          $cQoSPolicy.PriorityValue8021Action | Should Be ($hostQosPolicies | Where-Object {$PSItem.Name -eq $cQoSPolicy.Name}).PriorityValue8021Action
        }
        if($null -ne $cQoSPolicy.NetDirectPortMatchCondition) { 
          it "Verify [baseline] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.NetDirectPortMatchCondition)} match [host]" {
            $cQoSPolicy.NetDirectPortMatchCondition | Should Be ($hostQosPolicies | Where-Object {$PSItem.Name -eq $cQoSPolicy.Name}).NetDirectPortMatchCondition
          }
        }
        if($null -ne $cQoSPolicy.IPProtocolMatchCondition){ 
          it "Verify [baseline] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.IPProtocolMatchCondition)} match [host]" {
            $cQoSPolicy.IPProtocolMatchCondition | Should Be ($hostQosPolicies | Where-Object {$PSItem.Name -eq $cQoSPolicy.Name}).IPProtocolMatchCondition
          }
        }
      }
      foreach ($hQosPolicy in ($hostQosPolicies| Where-Object {$PSItem.Name -notmatch 'Default'})){
        it "Verify [host] entry for QoS Policy, name - {$($hQosPolicy.Name)} match [baseline]" { 
          $hQosPolicy.Name | Should -BeIn $POVFConfiguration.NetQos.NetQosPolicies.Name
        }
        it "Verify [host] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.PriorityValue8021Action)} match [baseline]" {
          $hQosPolicy.PriorityValue8021Action | Should Be ($POVFConfiguration.NetQos.NetQosPolicies | Where-Object {$PSItem.Name -eq $hQosPolicy.Name}).PriorityValue8021Action
        }
        if($hQosPolicy.NetDirectPortMatchCondition -ne '0') { 
          it "Verify [host] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.NetDirectPortMatchCondition)} match [baseline]" {
            $hQosPolicy.NetDirectPortMatchCondition | Should Be ($POVFConfiguration.NetQos.NetQosPolicies | Where-Object {$PSItem.Name -eq $hQosPolicy.Name}).NetDirectPortMatchCondition
          }
        }
        if($hQosPolicy.IPProtocolMatchCondition -ne 'None'){ 
          it "Verify [host] entry for QoS Policy, name - {$($cQoSPolicy.Name)}, parameter Priority - {$($cQoSPolicy.IPProtocolMatchCondition)} match [baseline]" {
            $hQosPolicy.IPProtocolMatchCondition | Should Be ($POVFConfiguration.NetQos.NetQosPolicies | Where-Object {$PSItem.Name -eq $hQosPolicy.Name}).IPProtocolMatchCondition
          }
        }
      }
    }
  }
  Context "Verify NetQoS configuration" {
    it "Verify [baseline] NetQosDCBxSetting configuration - {$($POVFConfiguration.NetQos.NetQosDcbxSetting.Willing)}" {
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
      it "Verify [host] QosFlowControl priority - {$($hQosFlowContrlEntry.Priority)} - {Enabled} match [baseline]" {
        $hQosFlowContrlEntry.Priority | Should -BeIn  $POVFConfiguration.NetQos.NetQosFlowControl.Enabled
      }
    }
    foreach ($hQosFlowContrlEntry in ($hostQosFlowControl | Where-Object {$PSItem.Enabled -eq $false}) ) {
      it "Verify [host] QosFlowControl priority - {$($hQosFlowContrlEntry.Priority)} - {Disabled} match [baseline]" {
        $hQosFlowContrlEntry.Priority | Should -BeIn  $POVFConfiguration.NetQos.NetQosFlowControl.Disabled
      }
    }
  }
  Context "Verify NetQos Traffic Class Configuration" { 
    $hostQosTrafficClass = Invoke-Command -Session $POVFPSSession -ScriptBlock {
      #During Deserialization values goes from string to Byte Value. Need to force String in return object 
      Get-NetQOsTrafficClass | ForEach-Object {
        @{
          Name=$PSItem.Name
          Priority=$PSItem.Priority
          BandwidthPercentage=$PSItem.BandwidthPercentage
          Algorithm =$PSItem.Algorithm.ToString()
    }
      } 
    }
    if ($POVFConfiguration.NetQos.NetQosTrafficClass){
      foreach ($cQoSTrafficClass in $POVFConfiguration.NetQos.NetQosTrafficClass) {
        #Verify if all entries from baseline configuration are deployed to host
        it "Verify [baseline] entry QoSTrafficClass, name - {$($cQoSTrafficClass.Name)} match [host]" { 
          $cQoSTrafficClass.Name | Should -BeIn $hostQosTrafficClass.Name
        }
        it "Verify [baseline] entry QoSTrafficClass, name - {$($cQoSTrafficClass.Name)} match [host], parameter Priority - {$($cQoSTrafficClass.Priority)}" {
          $cQoSTrafficClass.Priority | Should Be ($hostQosTrafficClass | Where-Object {$PSItem.Name -eq $cQoSTrafficClass.Name}).Priority
        }
        it "Verify [baseline] entry QoSTrafficClass, name - {$($cQoSTrafficClass.Name)} match [host], parameter BandwidthPercentage - {$($cQoSTrafficClass.BandwidthPercentage)}" {
          $cQoSTrafficClass.BandwidthPercentage | Should Be ($hostQosTrafficClass | Where-Object {$PSItem.Name -eq $cQoSTrafficClass.Name}).BandwidthPercentage
        }
        it "Verify [baseline] entry QoSTrafficClass, name - {$($cQoSTrafficClass.Name)} match [host], parameter Algorithm - {$($cQoSTrafficClass.Algorithm)}" {
          $cQoSTrafficClass.Algorithm | Should Be ($hostQosTrafficClass | Where-Object {$PSItem.Name -eq $cQoSTrafficClass.Name}).Algorithm
        }
      }
      foreach ($hQosTrafficClass in ($hostQosTrafficClass| Where-Object {$PSItem.Name -notmatch 'Default'})){
        #verify if all host options are in baseline configuration files. 
        it "Verify [host] entry QoSTrafficClass, name - {$($hQosTrafficClass.Name)} match [baseline]" { 
          $hQosTrafficClass.Name | Should -BeIn $POVFConfiguration.NetQos.NetQosTrafficClass.Name
        }
        it "Verify [host] entry QoSTrafficClass, name - {$($hQosTrafficClass.Priority)} match [baseline], parameter Priority - {$($hQosTrafficClass.Priority)}" {
          $hQosTrafficClass.Priority | Should Be ($POVFConfiguration.NetQos.NetQosTrafficClass | Where-Object {$PSItem.Name -eq $hQosTrafficClass.Name}).Priority
        }
        it "Verify [host] entry QoSTrafficClass, name - {$($hQosTrafficClass.BandwidthPercentage)} match [baseline], parameter BandwidthPercentage - {$($hQosTrafficClass.BandwidthPercentage)}" {
          $hQosTrafficClass.BandwidthPercentage | Should Be ($POVFConfiguration.NetQos.NetQosTrafficClass | Where-Object {$PSItem.Name -eq $hQosTrafficClass.Name}).BandwidthPercentage
        }
        it "Verify [host] entry QoSTrafficClass, name - {$($hQosTrafficClass.Algorithm)} match [baseline], parameter Algorithm - {$($hQosTrafficClass.Algorithm)}" {
          $hQosTrafficClass.Algorithm | Should Be ($POVFConfiguration.NetQos.NetQosTrafficClass | Where-Object {$PSItem.Name -eq $hQosTrafficClass.Name}).Algorithm
        }
      }
    }
  }
  Context "Verify [host] priority match in QosFlowControl, QosPolicies and QosTraffic Class" {
    foreach ($hQosFlowContrlEntry in ($hostQosFlowControl | Where-Object {$PSItem.Enabled -eq $true}) ) {
      it "Verify [host] QoSFlowControl entry {$($hQosFlowContrlEntry.Name)} priority {$($hQosFlowContrlEntry.Priority)} match QoS Policies "{
        $hQosFlowContrlEntry.Priority | Should -BeIn ($hostQosPolicies| Where-Object {$PSItem.Name -notmatch 'Default'}).PriorityValue
      }
      it "Verify [host] QoSFlowControl entry {$($hQosFlowContrlEntry.Name)} priority {$($hQosFlowContrlEntry.Priority)} match QoS Traffic Class "{
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
          Get-NetLbfoTeam -Name $USING:team.TeamName | ForEach-Object {
            @{
              TeamingMode = $PSitem.TeamingMode.ToString()
              LoadBalancingAlgorithm = $PSitem.LoadBalancingAlgorithm.ToString()
              Members = $PSItem.Members
            }
          }
        }
        it "Verify [host] Team {$($team.TeamName)} exists" {
          $hostTeam | Should -Not -BeNullOrEmpty
        }
        it "Verify [host] Team {$($team.TeamName)} TeamingMode match [baseline]" {
          $hostTeam.TeamingMode | Should Be $team.TeamingMode 
        }
        it "Verify [host] Team {$($team.TeamName)} LoadBalancingAlgorithm match [baseline]" {
          $hostTeam.LoadBalancingAlgorithm | Should Be $team.LoadBalancingAlgorithm
        }
        it "Verify [host] Team {$($team.TeamName)} TeamMembers match [baseline]" {
          $team.Members | Should -BeIn $hostTeam.Members 
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
        it "Verify [host] vSwitch Name {$($vSwitch.Name)} exists" {
          $hostVMSwitch | Should -Not -BeNullOrEmpty
        }
        it "Verify [host] vSwitch Name {$($vSwitch.Name)} interface bound match [baseline]" {

        }
        it "Verify [host] vSwitch Name {$($vSwitch.Name)} minimum bandwith mode - {$($vSwitch.MinimumBandwidthMode)} match [baseline]" {
          $hostVMSwitch.BandwidthReservationMode | Should Be $vSwitch.MinimumBandwidthMode
        }
        it "Verify [host] vSwitch Name {$($vSwitch.Name)} default bandwidth weight - {$($vSwitch.DefaultFlowMinimumBandwidthWeight)} match [baseline]" {
          $hostVMSwitch.DefaultFlowMinimumBandwidthWeight | Should Be $vSwitch.DefaultFlowMinimumBandwidthWeight
        }
        $hostVMNetworkAdapters = Invoke-Command $POVFPSSession -ScriptBlock { 
          Get-VMNetworkAdapter -SwitchName $USING:vSwitch.Name -ManagementOS:$True
        }
        it "Verify [host] vSwitch Name {$($vSwitch.Name)} match [baseline] network adapters configured - {$(($vSwitch.VMNetworkAdapters).Count)}" { 
          $hostVMNetworkAdapters.Count | Should Be ($vSwitch.VMNetworkAdapters).Count
        }
        foreach ($vSwitchVMNetworkAdapter in $vSwitch.VMNetworkAdapters) {
          it "Verify [host] VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} exists" {
            $vSwitchVMNetworkAdapter.Name | Should -BeIn $hostVMNetworkAdapters.Name
          }
          it "Verify [host] VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} VLANID - {$($vSwitchVMNetworkAdapter.VLANID)} match [baseline]" {
            $vlanid = Invoke-Command $POVFPSSession -ScriptBlock {
              Get-VMNetworkAdapterVlan -VMNetworkAdapterName $USING:vSwitchVMNetworkAdapter.Name -ManagementOS:$true 
            }
            $vlanid.AccessVlanId | Should Be $vSwitchVMNetworkAdapter.VLANID
          }
          it "Verify [host] VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} Minimum Bandwidth Weight - {$($vSwitchVMNetworkAdapter.MinimumBandwidthWeight)} match [baseline]" {
            ($hostVMNetworkAdapters.Where({$PSItem.Name -eq $vSwitchVMNetworkAdapter.Name})).BandwidthPercentage | Should Be $vSwitchVMNetworkAdapter.MinimumBandwidthWeight
          }
          $netAdapterIPConfiguration = Invoke-Command $POVFPSSession -ScriptBlock {
            Get-NetIPConfiguration | Where-Object {$PSItem.InterfaceAlias -match $USING:vSwitchVMNetworkAdapter.Name} 
          }
          it "Verify [host] VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} IP Configuration: IPAddress match [baseline]" {
            $netAdapterIPConfiguration.IPv4Address.IPAddress | Should Be $vSwitchVMNetworkAdapter.IPConfiguration.IPAddress
          }
          it "Verify [host] VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} IP Configuration: DefaultGateway match [baseline]" {
            $netAdapterIPConfiguration.IPv4DefaultGateway.NextHop | Should Be $vSwitchVMNetworkAdapter.IPConfiguration.DefaultGateway
          }
          it "Verify [host] VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} IP Configuration: Prefix match [baseline]" {
            $netAdapterIPConfiguration.IPv4Address.PrefixLength | Should Be $vSwitchVMNetworkAdapter.IPConfiguration.PrefixLength
          }
          it "Verify [host] VMNetworkAdapter {$($vSwitchVMNetworkAdapter.Name)} IP Configuration: DNSClientServerAddress match [baseline]" {
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
        it "Verify [host] role {$presentRole} is installed" {
          $testRole = $hostRoles | Where-Object {$PSItem.Name -eq $presentRole}
          $testRole.Installed |Should -Be $true
        }
      }
      if($POVFConfiguration.Roles.Absent) { 
        foreach($absentRole in $POVFConfiguration.Roles.Absent.Name) {
          it "Verify [host] role {$($absentRole.Name)} is installed" {
            $testRole = $hostRoles | Where-Object {$PSItem.Name -eq $absentRole.Name}
            $testRole.Installed | Should -Be $false
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
      it "Verify [host] Virtual Hard Disks path match [baseline]" {
        $hostProperties.VirtualHardDiskPath | Should Be $POVFConfiguration.HyperVConfiguration.VirtualHardDiskPath
      }
      it "Verify [host] Virtual Machines path match [baseline]" {
        $hostProperties.VirtualMachinePath | Should Be $POVFConfiguration.HyperVConfiguration.VirtualMachinePath
      }
      it "Verify [host] Live Migration status - {$($POVFConfiguration.HyperVConfiguration.LiveMigrations.Enabled)} match [baseline]" {
        $hostProperties.VirtualMachineMigrationEnabled | Should Be $POVFConfiguration.HyperVConfiguration.LiveMigrations.Enabled
      }
      it "Verify [host] number of simultaneous Live Migration status - {$($POVFConfiguration.HyperVConfiguration.LiveMigrations.Simultaneous)} match [baseline]" {
        $hostProperties.MaximumVirtualMachineMigrations | Should Be $POVFConfiguration.HyperVConfiguration.LiveMigrations.Simultaneous
      }  
      it "Verify [host] number of simultaneous Storage Migration status - {$($POVFConfiguration.HyperVConfiguration.StorageMigrations.Simultaneous)} match [baseline]" {
        $hostProperties.MaximumStorageMigrations | Should Be $POVFConfiguration.HyperVConfiguration.StorageMigrations.Simultaneous
      }
      it "Verify [host] Numa Spanning status - {$($POVFConfiguration.HyperVConfiguration.NumaSpanning.Enabled)} match [baseline]" {
        $hostProperties.NumaSpanningEnabled | Should Be $POVFConfiguration.HyperVConfiguration.NumaSpanning.Enabled
      }
    }
  }
}
Get-PSSession -Name 'POVF*' | Remove-PSSession -ErrorAction SilentlyContinue 