function Get-POVFVMSwitchConfiguration {
    [CmdletBinding()]
    param (
      
      [Parameter(Mandatory,
      ParameterSetName='ComputerName')]
      [ValidateNotNullOrEmpty()]
      [System.String]
      $ComputerName,
      
      [Parameter(Mandatory=$false,
      ParameterSetName='ComputerName')]
      [System.Management.Automation.PSCredential]
      $Credential,
      
      [Parameter(Mandatory=$false,
      ParameterSetName='ComputerName')]
      [string]
      $ConfigurationName,
    
      [Parameter(Mandatory,
      ParameterSetName='PSCustomSession')]
      [System.Management.Automation.Runspaces.PSSession]
      $PSSession
    
    
    )
    process{
      #region Variables set
      if($PSBoundParameters.ContainsKey('ComputerName')) { 
        $sessionParams = @{
          ComputerName = $ComputerName
          SessionName = "POVF-$ComputerName"
        }
        if($PSBoundParameters.ContainsKey('ConfigurationName')){
          $sessionParams.ConfigurationName = $ConfigurationName
        }
        if($PSBoundParameters.ContainsKey('Credential')){
          $sessionParams.Credential = $Credential
        }
        $POVFPSSession = New-PSSessionCustom @SessionParams
      }
      if($PSBoundParameters.ContainsKey('PSSession')){
        $POVFPSSession = $PSSession
      }
  
      #endregion
      $hostVMSwitch = @()
      $hostVMSwitch += Invoke-Command -session $POVFPSSession -scriptBlock {
        Get-VMSwitch
      }
      foreach ($vSwitch in $hostVMSwitch) {
        $vSwitchResult = [ordered]@{
          Name = $vSwitch.Name
          MinimumBandwidthMode = $vSwitch.BandwidthReservationMode
          DefaultFlowMinimumBandwidthWeight = $vSwitch.DefaultFlowMinimumBandwidthWeight
          AllowManagementOS = $vSwitch.AllowManagementOS
          VMNetworkAdapters = @()
        }
        $hostVMNetworkAdapters = Invoke-Command $POVFPSSession -ScriptBlock { 
          Get-VMNetworkAdapter -SwitchName $USING:vSwitch.Name -ManagementOS:$USING:vSwitchResult.AllowManagementOS
        }  
        if($hostVMNetworkAdapters) {
          $vSwitchResult.VMNetworkAdapters +=foreach ($vmNetworkAdapter in $hostVMNetworkAdapters) {
            $vmNetworkAdapterResult = [ordered]@{
              Name = $vmNetworkAdapter.Name
              VLANID = $null
              OperationMode = $null
              DhcpGuard = $vmNetworkAdapter.DhcpGuard
              RouterGuard = $vmNetworkAdapter.RouterGuard
              ExtendedAclList = $vmNetworkAdapter.ExtendedAclList
              BandwidthPercentage = $vmNetworkAdapter.BandwidthPercentage
              IPConfiguration = @()
            }
            $vlanid = Invoke-Command $POVFPSSession -ScriptBlock {
              Get-VMNetworkAdapterVlan -VMNetworkAdapterName $USING:vmNetworkAdapter.Name -ManagementOS:$USING:vSwitchResult.AllowManagementOS
            }
            if($vlanid){ 
              $vmNetworkAdapterResult.VLANID = $vlanid.AccessVlanId
              $vmNetworkAdapterResult.OperationMode = $vlanid.OperationMode
            }
            $vmNetworkAdapterResult.IPConfiguration = Get-POVFNetIPConfiguration -PSSession $POVFPSSession -InterfaceAlias "*$($vmNetworkAdapter.Name)*"
            $vmNetworkAdapterResult
          }
        }
        $vSwitchResult
      }
      if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
        Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue | Remove-PSSession -ErrorAction SilentlyContinue  
      }
    }
  }