param (
  [System.Management.Automation.PSCredential]$POVFCredential,
  $POVFConfiguration
)
$POVFPSSession = New-PSSessionCustom -ComputerName $POVFConfiguration.ComputerName -Credential $POVFCredential -SessionName 'POVF'
$currentDHCP = Get-POVFConfigurationDHCPNode -PSSession $POVFPSSession 
Describe "Verify DHCP Service settings on Server - {$($POVFConfiguration.ComputerName)}" -Tags @('Service','Configuration') {
  Context 'Verify service configuration' {
    it "Verify [host] DNS Credentials - {$($POVFConfiguration.DHCPServerDNSCredentials)} match [baseline]" {
      $currentDHCP.DHCPServerDNSCredentials | Should -Be $POVFConfiguration.DHCPServerDNSCredentials
    }
    it "Verify [host] IP binding - {$($POVFConfiguration.DhcpServerv4Binding)} match [baseline]" {
      $currentDHCP.DhcpServerv4Binding | Should -Be $POVFConfiguration.DhcpServerv4Binding
    }
    it "Verify [host] AuditLog - {$($POVFConfiguration.DhcpServerAuditLog)} match [baseline]" {
      $currentDHCP.DhcpServerAuditLog | Should -Be $POVFConfiguration.DhcpServerAuditLog
    }
  }
  Context "Verify Database Settings" {
    it "Verify [host] Database logging setting - {$($POVFConfiguration.DhcpServerDatabase.LoggingEnabled)} match [baseline]" {
      $currentDHCP.DhcpServerDatabase.LoggingEnabled | Should -Be $POVFConfiguration.DhcpServerDatabase.LoggingEnabled
    }
    it "Verify [host] Database Backup interval - {$($POVFConfiguration.DhcpServerDatabase.BackupInterval)} match [baseline]" {
      $currentDHCP.DhcpServerDatabase.BackupInterval | Should -Be $POVFConfiguration.DhcpServerDatabase.BackupInterval
    }
    it "Verify [host] Database Cleanup interval - {$($POVFConfiguration.DhcpServerDatabase.CleanupInterval)} match [baseline]" {
      $currentDHCP.DhcpServerDatabase.CleanupInterval | Should -Be $POVFConfiguration.DhcpServerDatabase.CleanupInterval
    }
  }
  Context "Verify Server Settings" { 
    it "Verify [host] NAPEnabled setting {$($POVFConfiguration.DhcpServerSetting.NAPEnabled)} match [baseline]" { 
      $currentDHCP.DhcpServerSetting.NAPEnabled | Should -Be $POVFConfiguration.DhcpServerSetting.NAPEnabled
    }
    it "Verify [host] NAPEnabled setting {$($POVFConfiguration.DhcpServerSetting.NAPEnabled)} match [baseline]" { 
      $currentDHCP.DhcpServerSetting.NAPEnabled | Should -Be $POVFConfiguration.DhcpServerSetting.NAPEnabled
    }
    it "Verify [host] Is Authorized in Domain {$($POVFConfiguration.DhcpServerSetting.IsAuthorized)} match [baseline]" { 
      $currentDHCP.DhcpServerSetting.IsAuthorized | Should -Be $POVFConfiguration.DhcpServerSetting.IsAuthorized
    }
    it "Verify [host] Is Domain Joined {$($POVFConfiguration.DhcpServerSetting.IsDomainJoined)} match [baseline]" { 
      $currentDHCP.DhcpServerSetting.IsDomainJoined | Should -Be $POVFConfiguration.DhcpServerSetting.IsDomainJoined
    }
    it "Verify [host] DynamicBoodP setting {$($POVFConfiguration.DhcpServerSetting.DynamicBoodP)} match [baseline]" { 
      $currentDHCP.DhcpServerSetting.DynamicBootP | Should -Be $POVFConfiguration.DhcpServerSetting.DynamicBootP
    }
  }
  Context "Verify DNS server settings" {
    it "Verify [host] Dynamic Updates {$($POVFConfiguration.DhcpServerv4DnsSetting.DynamicUpdates)} match [baseline]" { 
      $currentDHCP.DhcpServerv4DnsSetting.DynamicUpdates | Should -Be $POVFConfiguration.DhcpServerv4DnsSetting.DynamicUpdates
    }
    it "Verify [host] UpdateDnsRRForOlderClients {$($POVFConfiguration.DhcpServerv4DnsSetting.UpdateDnsRRForOlderClients)} match [baseline]" { 
      $currentDHCP.DhcpServerv4DnsSetting.UpdateDnsRRForOlderClients | Should -Be $POVFConfiguration.DhcpServerv4DnsSetting.UpdateDnsRRForOlderClients
    }
    it "Verify [host] DeleteDnsRROnLeaseExpiry {$($POVFConfiguration.DhcpServerv4DnsSetting.DeleteDnsRROnLeaseExpiry)} match [baseline]" { 
      $currentDHCP.DhcpServerv4DnsSetting.DeleteDnsRROnLeaseExpiry | Should -Be $POVFConfiguration.DhcpServerv4DnsSetting.DeleteDnsRROnLeaseExpiry
    }
    it "Verify [host] DnsSuffix {$($POVFConfiguration.DhcpServerv4DnsSetting.DnsSuffix)} match [baseline]" { 
      $currentDHCP.DhcpServerv4DnsSetting.DnsSuffix | Should -Be $POVFConfiguration.DhcpServerv4DnsSetting.DnsSuffix
    }
    it "Verify [host] NameProtection {$($POVFConfiguration.DhcpServerv4DnsSetting.NameProtection)} match [baseline]" { 
      $currentDHCP.DhcpServerv4DnsSetting.NameProtection | Should -Be $POVFConfiguration.DhcpServerv4DnsSetting.NameProtection
    }
    it "Verify [host] DisableDnsPtrRRUpdate {$($POVFConfiguration.DhcpServerv4DnsSetting.DisableDnsPtrRRUpdate)} match [baseline]" { 
      $currentDHCP.DhcpServerv4DnsSetting.DisableDnsPtrRRUpdate | Should -Be $POVFConfiguration.DhcpServerv4DnsSetting.DisableDnsPtrRRUpdate
    }
  }
}
Describe "Verify DHCP Scope settings on Server - {$($POVFConfiguration.ComputerName)}" -Tags @('Scope','Configuration') {
  foreach ($currentHostScope in $currentDHCP.Scopes){
    $currentConfigurationScope = $POVFConfiguration.Scopes | Where-Object {$PSItem.ScopeID -eq $currentHostScope.ScopeID}
    Context "Verify scope - {$($currentHostScope.Name)} general settings" {
      it "Verify [host] Name - {${$currentHostScope.Name}} match [baseline]" {
        $currentHostScope.Name | Should -Be $currentConfigurationScope.Name
      }
      it "Verify [host] ScopeID - {${$currentHostScope.ScopeID}} match [baseline]" {
        $currentHostScope.ScopeID | Should -Be $currentConfigurationScope.ScopeID
      }
      it "Verify [host] Description - {${$currentHostScope.Description}} match [baseline]" {
        $currentHostScope.Description | Should -Be $currentConfigurationScope.Description
      }
      it "Verify [host] State - {${$currentHostScope.State}} match [baseline]" {
        $currentHostScope.State | Should -Be $currentConfigurationScope.State
      }
      it "Verify [host] SuperScopeName - {${$currentHostScope.SuperScopeName}} match [baseline]" {
        $currentHostScope.SuperScopeName | Should -Be $currentConfigurationScope.SuperScopeName
      }
      it "Verify [host] SubnetMask - {${$currentHostScope.SubnetMask}} match [baseline]" {
        $currentHostScope.SubnetMask | Should -Be $currentConfigurationScope.SubnetMask
      }
      it "Verify [host] StartRange - {${$currentHostScope.StartRange}} match [baseline]" {
        $currentHostScope.StartRange | Should -Be $currentConfigurationScope.StartRange
      }
      it "Verify [host] EndRange - {${$currentHostScope.EndRange}} match [baseline]" {
        $currentHostScope.EndRange | Should -Be $currentConfigurationScope.EndRange
      }
      it "Verify [host] LeaseDuration - {${$currentHostScope.LeaseDuration}} match [baseline]" {
        $currentHostScope.LeaseDuration | Should -Be $currentConfigurationScope.LeaseDuration
      }
      it "Verify [host] NapEnable - {${$currentHostScope.NapEnable}} match [baseline]" {
        $currentHostScope.NapEnable | Should -Be $currentConfigurationScope.NapEnable
      }
      it "Verify [host] NapProfile - {${$currentHostScope.NapProfile}} match [baseline]" {
        $currentHostScope.NapProfile | Should -Be $currentConfigurationScope.NapProfile
      }
      #Verify if any exlusions range FROM host match baseline (can be on host, not in baseline)
      if($currentHostScope.ExclusionRange){
        foreach ($range in $currentHostScope.ExclusionRange) {
          it "Verify [host] Exclusion Start Range - {$($range.StartRange)} match [baseline]" {
            $range.StartRange | Should -BeIn $currentConfigurationScope.ExclusionRange.StartRange
          }
          it "Verify [host] Exclusion End Range - {$($range.EndRange)} match [baseline]" {
            $range.EndRange | Should -BeIn $currentConfigurationScope.ExclusionRange.EndRange
          }
        }
      }
      #Verify if any exlusions range FROM baseline match host (can be in baseline, but not in host)
      if($currentConfigurationScope.ExclusionRange){
        foreach ($range in $currentConfigurationScope.ExclusionRange) {
          it "Verify [baseline] Exclusion Start Range - {$($range.StartRange)} match [host]" {
            $range.StartRange | Should -BeIn $currentHostScope.ExclusionRange.StartRange
          }
          it "Verify [baseline] Exclusion End Range - {$($range.EndRange)} match [host]" {
            $range.EndRange | Should -BeIn $currentHostScope.ExclusionRange.EndRange
          }
        }
      }      
    }
    Context "Verify scope - {$($currentHostScope.Name)} Scope Options settings" {
      foreach ($sOption in $currentHostScope.ScopeOptions) {
        $currentConfigurationScopeOption = $currentConfigurationScope.ScopeOptions | Where-Object {$PSItem.Name -match $sOption.Name}
        it "Verify Name {$($sOption.Name)} match [baseline]" {
          $sOption.Name | Should -Be $currentConfigurationScopeOption.Name
        }
        it "Verify OptionID {$($sOption.OptionID)} match [baseline]" {
          $sOption.OptionID | Should -Be $currentConfigurationScopeOption.OptionID
        }
        it "Verify Value {$($sOption.Value)} match [baseline]" {
          $sOption.Value | Should -BeIn $currentConfigurationScopeOption.Value
        }
      }
    }
  }
}
Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue    