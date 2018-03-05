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

    $NetQoSParams = @()
    $NetQoSParams = Invoke-Command -session $POVFPSSession -scriptBlock {
        
      #Initilize hashtable 
      $NetQoSParams = @{
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
      $NetQoSParams.NetQoSPolicies +=foreach ($policy in Get-NetQosPolicy) {
        $nqPolicy = [ordered]@{
          Name = $policy.Name
          PriorityValue8021Action = $policy.PriorityValue8021Action.ToString()
        }
        if($policy.IPProtocolMatchCondition) {
          $nqPolicy.IPProtocolMatchCondition = $policy.IPProtocolMatchCondition.ToString()
        }
        if($policy.IPPortMatchCondition) {
          $nqPolicy.IPPortMatchCondition = $policy.IPPortMatchCondition.ToString()
        }
        $nqPolicy
      }
      $NetQoSParams.NetQosTrafficClass += foreach ($trafficClass in Get-NetQosTrafficClass) {
        $priority = $trafficClass.Priority -Join ','
        $nqTrafficClass = [ordered]@{
          Name = $trafficClass.Name
          Priority = $priority
          BandwidthPercentage= $trafficClass.BandwidthPercentage
          Algorithm= $trafficClass.Algorithm.ToString()
        }
        $nqTrafficClass
      }
      $NetQoSParams.NetQosDcbxSetting = (Get-NetQosDcbxSetting | Select-Object -ExpandProperty Willing)
      $flowControl = Get-NetQosFlowControl    
      $NetQoSParams.NetQoSFlowControl.Enabled = @($flowControl| Where-Object {$PSItem.Enabled -eq $true} | Select-Object -ExpandProperty Priority)
      $NetQoSParams.NetQoSFlowControl.Disabled = @($flowControl| Where-Object {$PSItem.Enabled -eq $false} | Select-Object -ExpandProperty Priority)
               
      $NetQoSParams
    }
    $NetQoSParams
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue| Remove-PSSession -ErrorAction SilentlyContinue  
    }
 
  }
}