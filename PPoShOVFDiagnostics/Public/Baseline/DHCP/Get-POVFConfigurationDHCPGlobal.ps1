function Get-POVFConfigurationDHCPGlobal {

  [CmdletBinding()]
  param(
    [Parameter(Mandatory,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ComputerName,

    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
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
    #Invoke-Command -Session $POVFPSSession -ScriptBlock {
      $dhcpInAD = Get-DhcpServerInDC
      $dhcpConfig = [ordered]@{
        Domain = $env:USERDNSDOMAIN
        ServersInAD = @()
      }
      if($dhcpInAD){
        $dhcpConfig.ServersInAD += foreach ($dhcp in $dhcpInAD){
          [ordered]@{
            DnsName = $dhcp.DnsName
            IPAddress = $dhcp.IPAddress.IPAddressToString
          }
        }
      }
      $dhcpConfig
    #}
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue
    }
  }
}