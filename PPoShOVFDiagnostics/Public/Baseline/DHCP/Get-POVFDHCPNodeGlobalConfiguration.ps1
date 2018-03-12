function Get-POVFDHCPNodeGlobalConfiguration {
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

    #region Get data
    Invoke-Command -Session $POVFPSSession -ScriptBlock {
      $dhcpServerDatabase = Get-DhcpServerDatabase 
      $dhcpServerDNSCredential =  Get-DhcpServerDnsCredential 
      $dhcpServerDNSCredentialString = "{0}\{1}" -f $dhcpServerDNSCredential.DomainName, $dhcpServerDNSCredential.Username
      $dhcpServerSettings = Get-DhcpServerSetting
      $dhcpServerV4DNSSetting = Get-DhcpServerv4DnsSetting
      [ordered]@{
        DHCPServerDNSCredentials = $dhcpServerDNSCredentialString
        DhcpServerv4Binding = (Get-DhcpServerv4Binding).IPAddress.IPAddressToString
        DhcpServerDatabase = @{
          BackupInterval = $dhcpServerDatabase.BackupInterval
          CleanupInterval = $dhcpServerDatabase.CleanupInterval
          LoggingEnabled = $dhcpServerDatabase.LoggingEnabled
        }
        DhcpServerSetting = @{
          IsDomainJoined = $dhcpServerSettings.isDomainJoined
          IsAuthorized = $dhcpServerSettings.isAuthorized
          NAPEnabled = $dhcpServerSettings.NAPEnabled
          DynamicBoodP = $dhcpServerSettings.DynamicBootP
        }
        DhcpServerv4DnsSetting=@{
          DeleteDnsRROnLeaseExpiry = $dhcpServerv4DnsSetting.DeleteDnsRROnLeaseExpiry
          DisableDnsPtrRRUpdate = $dhcpServerv4DnsSetting.DisableDnsPtrRRUpdate
          DnsSuffix = $dhcpServerv4DnsSetting.DnsSuffix
          DynamicUpdates = $dhcpServerv4DnsSetting.DynamicUpdates
          NameProtection = $dhcpServerv4DnsSetting.NameProtection
          UpdateDnsRRForOlderClients = $dhcpServerv4DnsSetting.UpdateDnsRRForOlderClients
        }
        DhcpServerAuditLog = (Get-DhcpServerAuditLog).Enable
      }      
    }
    #endregion
            
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue  
    }
  }
}