function Get-POVFConfigurationDHCPNode {

  [CmdletBinding()]
  param(
    [Parameter(Mandatory,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ComputerName,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
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
    $NodeConfiguration = @{}
    Write-Log -Info -Message "Reading configuration from host {$($POVFPSSession.ComputerName)}"
    Write-Progress -Activity 'Gathering DHCP configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} Environment configuration" -PercentComplete 5
    $hostEnvironment = Get-POVFHostEnvironment -PSSession $POVFPSSession
    $NodeConfiguration.ComputerName = ('{0}.{1}' -f $hostEnvironment.ComputerName,$hostEnvironment.Domain)
    $NodeConfiguration.ClusterName = $hostEnvironment.Cluster
    $NodeConfiguration.Domain = $hostEnvironment.Domain
    
    Write-Progress -Activity 'Gathering DHCP configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} DHCP Server Global configuration" -PercentComplete 30
    $NodeConfiguration += Get-POVFDHCPNodeGlobalConfiguration -PSSession $POVFPSSession
    
    Write-Progress -Activity 'Gathering DHCP configuration' -Status "Get Host {$($POVFPSSession.ComputerName)} Scope configuration" -PercentComplete 70
    $NodeConfiguration.Scopes += Get-POVFDHCPNodeScopeConfiguration -PSSession $POVFPSSession
    $NodeConfiguration
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue   
    }
  }
}