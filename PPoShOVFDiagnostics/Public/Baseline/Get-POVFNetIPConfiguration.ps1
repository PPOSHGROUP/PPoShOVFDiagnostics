function Get-POVFNetIPConfiguration {
  [CmdletBinding()]
  param (
  
    [Parameter(Mandatory=$false)]
    [string[]]
    $InterfaceAlias,

    [Parameter(Mandatory=$false)]
    [switch]
    $Physical,

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
    $interfaceParams = @{
      InterfaceAlias = '*'
    } 
    if($PSBoundParameters.ContainsKey('InterfaceAlias')){
      $interfaceParams.InterfaceAlias = $InterfaceAlias
    }
    if($PSBoundParameters.ContainsKey('Physical')){
      $interfaceParams.Physical = $Physical
    }
    #endregion
    $netAdapters = Invoke-Command -session $POVFPSSession -scriptBlock {
      Get-NetAdapter @USING:interfaceParams -ErrorAction SilentlyContinue
    }
    if($netAdapters) {
      foreach ($interface in $netAdapters.Name){
        #NetIPConfiguration is using Get-NetIPInterface underneath and not respecting -ErrorAction SilentlyContinue. Need to check first
        $NetIPInterface = Invoke-Command -session $POVFPSSession -ScriptBlock { 
          Get-NetIPInterface -InterfaceAlias $USING:interface -ErrorAction SilentlyContinue
        }
        if($NetIPInterface) { 
          $netIPConfiguration = Invoke-Command -session $POVFPSSession -ScriptBlock { 
            Get-NetIPConfiguration -InterfaceAlias $USING:interface -ErrorAction SilentlyContinue
          }
          if($netIPConfiguration) { 
            $DNSServers = @( if(($netIPConfiguration.DNSServer | Where-Object {$PSItem.AddressFamily -eq '2'}).ServerAddresses){
                ($netIPConfiguration.DNSServer | Where-Object {$PSItem.AddressFamily -eq '2'} | 
                Select-Object -ExpandProperty ServerAddresses).Split(',')
            } )
            $interfaceIPConfiguration = [ordered]@{
              IPAddress = $netIPConfiguration.IPv4Address.IPAddress
              PrefixLength = $netIPConfiguration.IPv4Address.PrefixLength
              DefaultGateway=$netIPConfiguration.IPv4DefaultGateway.NextHop
              DNSClientServerAddress = $null
              DHCP = 'Disabled'
            }
            if ($DNSServers) {
              $interfaceIPConfiguration.DNSClientServerAddress = $DNSServers
            }          
            if ($netIPInterface.dhcp -eq 'Enabled') {
              $interfaceIPConfiguration.DHCP = $true
            }
            $interfaceIPConfiguration
          }
        }
      }
    }
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue   
    }
  }
}