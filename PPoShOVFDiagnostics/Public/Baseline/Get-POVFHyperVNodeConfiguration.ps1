function Get-POVFHyperVNodeConfiguration {
  [CmdletBinding()]
  param(
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
    foreach ($computer in $ComputerName) {
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
      $NodeConfiguration = [ordered]@{
        ComputerName = $null
        ClusterName = $null
        Domain = $null
        NIC = @()
        NetQoS = @()
        Registry= @()
        Team = @()
        VmSwitch= @()
        Roles = @{}
        HyperVConfiguration = @{}
      }
      $hostEnvironment = Get-POVFHostEnvironment -PSSession $POVFPSSession
      $NodeConfiguration.ComputerName = $hostEnvironment.ComputerName
      $NodeConfiguration.ClusterName = $hostEnvironment.Cluster
      $NodeConfiguration.Domain = $hostEnvironment.Domain
      $NodeConfiguration.NIC += Get-POVFNetAdapterConfiguration -Physical -PSSession $POVFPSSession
      $NodeConfiguration.NetQoS += Get-POVFNetQoSConfiguration -PSSession $POVFPSSession
      $NodeConfiguration.Registry += Get-POVFRegistryConfiguration  -PSSession $POVFPSSession
      $NodeConfiguration.Team += Get-POVFTeamingConfiguration -PSSession $POVFPSSession
      $NodeConfiguration.VmSwitch += Get-POVFVMSwitchConfiguration -PSSession $POVFPSSession
      $NodeConfiguration.Roles += Get-POVFRolesConfiguration -PSSession $POVFPSSession
      $NodeConfiguration.HyperVConfiguration = Get-POVFHyperVConfiguration -PSSession $POVFPSSession
      $NodeConfiguration
    }
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue| Remove-PSSession -ErrorAction SilentlyContinue  
    }
  }
}