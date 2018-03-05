function Get-POVFNetIPConfiguration {
  [CmdletBinding()]
  param (
  
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.String[]]
    $InterfaceAlias,


  )
  begin{
  }
  process{
    foreach ($interface in $InterfaceAlias){
      $netIPInterface = Get-NetIPInterface -InterfaceAlias $interface -AddressFamily IPv4 -ErrorAction SilentlyContinue
      if($netIPInterface) {
        $netIPConfiguration = Get-NetIPConfiguration -InterfaceAlias $interface -ErrorAction SilentlyContinue
        $DNSServers = @( if(($netIPConfiguration.DNSServer | Where-Object {$PSItem.AddressFamily -eq '2'}).ServerAddresses){
            ($netAdapterIPConfiguration.DNSServer | Where-Object {$PSItem.AddressFamily -eq '2'} | 
            Select-Object -ExpandProperty ServerAddresses).Split(',')
        } )
        $interfaceIPConfiguration = @{
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