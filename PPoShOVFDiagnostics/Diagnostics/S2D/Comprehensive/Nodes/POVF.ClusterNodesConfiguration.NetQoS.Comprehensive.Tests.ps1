param(
    $POVFConfiguration,
    $POVFPSSession
)
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