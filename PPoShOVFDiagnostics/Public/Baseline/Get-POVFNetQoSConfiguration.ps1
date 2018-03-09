function Get-POVFNetQoSConfiguration {
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
    if($PSBoundParameters.ContainsKey('ComputerName')) { 
      $sessionParams = @{
        ComputerName = $computer
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
    
    $NetQoSParams = [ordered]@{
      NetQoSPolicies = @()
      NetQosTrafficClass = @()
      NetQosDcbxSetting =@{
        Willing= $true
      }
      NetQoSFlowControl = @{
        Enabled= @()
        Disabled = @()
      }
    }
    $hostQosPolicies = Invoke-Command -session $POVFPSSession -scriptBlock {
      Get-NetQosPolicy | ForEach-Object {
        @{
          Name = $PSItem.Name
          PriorityValue8021Action = $PSItem.PriorityValue8021Action.ToString()
          NetDirectPortMatchCondition = $PSItem.NetDirectPortMatchCondition.ToString()
          IPProtocolMatchCondition = $PSItem.IPProtocolMatchCondition.ToString()
        }
      }
    }
    if ($hostQosPolicies){
      $NetQoSParams.NetQoSPolicies +=foreach ($nqPolicy in $hostQosPolicies) {
        $policy = [ordered]@{
          Name = $nqPolicy.Name
          PriorityValue8021Action = $nqPolicy.PriorityValue8021Action.ToString()
        }
        if($nqPolicy.IPProtocolMatchCondition) {
          $policy.IPProtocolMatchCondition = $nqPolicy.IPProtocolMatchCondition.ToString()
        }
        if($nqPolicy.IPPortMatchCondition) {
          $policy.IPPortMatchCondition = $nqPolicy.IPPortMatchCondition.ToString()
        }
        $policy
      }
    }  
    $netQoSTrafficClass += Invoke-Command -session $POVFPSSession -scriptBlock {
      Get-NetQosTrafficClass| ForEach-Object {
        @{
          Name=$PSItem.Name
          Priority=$PSItem.Priority
          BandwidthPercentage=$PSItem.BandwidthPercentage
          Algorithm =$PSItem.Algorithm.ToString()
        }
      }
    }
    if($netQoSTrafficClass){
      $NetQoSParams.NetQosTrafficClass += foreach ($trafficClass in $netQoSTrafficClass) {
        [ordered]@{
          Name = $trafficClass.Name
          Priority = $trafficClass.Priority -Join ','
          BandwidthPercentage= $trafficClass.BandwidthPercentage
          Algorithm= $trafficClass.Algorithm.ToString()
        }
      }
    }
    $NetQosDcbxSetting = Invoke-Command -session $POVFPSSession -scriptBlock {
      Get-NetQosDcbxSetting
    }
    $NetQoSParams.NetQosDcbxSetting.Willing =$NetQosDcbxSetting.Willing
    $flowControl =Invoke-Command -session $POVFPSSession -scriptBlock { 
      Get-NetQosFlowControl
    }
    $NetQoSParams.NetQoSFlowControl.Enabled = @($flowControl| Where-Object {$PSItem.Enabled -eq $true} | Select-Object -ExpandProperty Priority)
    $NetQoSParams.NetQoSFlowControl.Disabled = @($flowControl| Where-Object {$PSItem.Enabled -eq $false} | Select-Object -ExpandProperty Priority)
    $NetQoSParams          
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue| Remove-PSSession -ErrorAction SilentlyContinue  
    }
     
  }
}