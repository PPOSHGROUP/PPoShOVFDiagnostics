function Get-POVFHyperVNodeConfiguration {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ComputerNameName,
    
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
    Write-Log -Info -Message "Reading configuration from host {$($POVFPSSession.ComputerName)}"
    Write-Progress -Activity 'Gathering HyperV Node configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} Environment configuration" -PercentComplete 0
    $hostEnvironment = Get-POVFHostEnvironment -PSSession $POVFPSSession
    $NodeConfiguration.ComputerName = ('{0}.{1}' -f $hostEnvironment.ComputerName,$hostEnvironment.Domain)
    $NodeConfiguration.ClusterName = $hostEnvironment.Cluster
    $NodeConfiguration.Domain = $hostEnvironment.Domain
      
    Write-Progress -Activity 'Gathering HyperV Node configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} Network Adapter configuration" -PercentComplete 10
    $NodeConfiguration.NIC += Get-POVFNetAdapterConfiguration -Physical -PSSession $POVFPSSession

    Write-Progress -Activity 'Gathering HyperV Node configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} QoS configuration" -PercentComplete 40
    $NodeConfiguration.NetQoS += Get-POVFNetQoSConfiguration -PSSession $POVFPSSession
      
    Write-Progress -Activity 'Gathering HyperV Node configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} Registry configuration" -PercentComplete 50
    $NodeConfiguration.Registry += Get-POVFRegistryConfiguration  -PSSession $POVFPSSession
      
    Write-Progress -Activity 'Gathering HyperV Node configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} Teaming configuration" -PercentComplete 60
    $NodeConfiguration.Team += Get-POVFTeamingConfiguration -PSSession $POVFPSSession
      
    Write-Progress -Activity 'Gathering HyperV Node configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} VMSwitch configuration" -PercentComplete 70
    $NodeConfiguration.VmSwitch += Get-POVFVMSwitchConfiguration -PSSession $POVFPSSession
      
    Write-Progress -Activity 'Gathering HyperV Node configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} Roles configuration" -PercentComplete 80
    $NodeConfiguration.Roles += Get-POVFRolesConfiguration -PSSession $POVFPSSession

    Write-Progress -Activity 'Gathering HyperV Node configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} HyperV configuration" -PercentComplete 90
    $NodeConfiguration.HyperVConfiguration = Get-POVFHyperVConfiguration -PSSession $POVFPSSession
    $NodeConfiguration

    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue   
    }
  }
}