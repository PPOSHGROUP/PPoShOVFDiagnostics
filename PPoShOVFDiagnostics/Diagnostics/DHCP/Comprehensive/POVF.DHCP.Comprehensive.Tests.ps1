param (
  $POVFPSSession,
  $POVFConfiguration
)
Describe "DHCP Service settings on Server {$($POVFConfiguration.ComputerName)}" -Tag Service {
  Context 'Verify service configuration' {
    it "Service should be running" {
      (Invoke-Command -Session $POVFPSSession -ScriptBlock {
          Get-Service -Name Dhcp
      }).Status  | Should Be 'Running'
    }
    it "DNS Credentials should match configuration {$($POVFConfiguration.DHCPServerDNSCredentials)}" {
      $DNSCredentials = Invoke-Command -Session $POVFPSSession -ScriptBlock {
        Get-DhcpServerDnsCredential
      }
      "$($DNSCredentials.DomainName)\$($DNSCredentials.Username)" | Should Be $POVFConfiguration.DHCPServerDNSCredentials
    }
    it "IP binding should match configuration {$($POVFConfiguration.Binding)}" {
      (Invoke-Command -Session $POVFPSSession -ScriptBlock { 
          Get-DhcpServerv4Binding 
      }).IPAddress | Should Be $POVFConfiguration.Binding
    }
    $dhcpServerSettings = Invoke-Command -Session $POVFPSSession -ScriptBlock {  DhcpServerSetting }
    it "Should be domain joined" {
      $dhcpServerSettings.IsDomainJoined | Should Be $True
    }
    it "Should be authorized in domain" {
      $dhcpServerSettings.IsAuthorized | Should Be $True
    }
    $dhcpServerDatabaseSettings = Invoke-Command -Session $POVFPSSession -ScriptBlock { DhcpServerDatabase }
    it "Database logging should match configuration setting {$($POVFConfiguration.ServerSettings.LoggingEnabled)}" {
      $dhcpServerDatabaseSettings.LoggingEnabled | Should Match $POVFConfiguration.ServerSettings.LoggingEnabled
    }
    it "Database Backup interval should match configuration setting {$($POVFConfiguration.ServerSettings.BackupInterval)}" {
      $dhcpServerDatabaseSettings.BackupInterval | Should Match $POVFConfiguration.ServerSettings.BackupInterval
    }
    it "Database Cleanup interval should match configuration setting {$($POVFConfiguration.ServerSettings.CleanupInterval)}" {
      $dhcpServerDatabaseSettings.CleanupInterval | Should Match $POVFConfiguration.ServerSettings.CleanupInterval
    }
    it "Server AuditLog should match configuration Setting {$($POVFConfiguration.AuditLog)}" { 
      (Invoke-Command -Session $POVFPSSession -ScriptBlock { DhcpServerAuditLog }).AudotLog | Should Match $POVFConfiguration.AuditLog
    }
  }
  Context 'Verify service statistics' {
    it 'Should have at least 10% free IP space' {
      (Invoke-Command -Session $POVFPSSession -ScriptBlock { Get-DhcpServerv4Statistics }).PercentageAvailable | Should BeGreaterThan 10
    }
  }
}
Describe "Scope and Reservation Tests" -Tag ScopeAndReservation {
    $dhcpScopes = Invoke-Command -Session $POVFPSSession -ScriptBlock {
      Get-DhcpServerv4Scope 
    } 
    Context 'Scopes tests' {
      it 'Check if any DHCP v4 scope exists' {
        $dhcpScopes | Should Not BeNullOrEmpty
      }
      foreach ($scopeId in $dhcpScopes.ScopeID) {
        it "Checks if address lease in {$scopeId} is possible" {
          (Invoke-Command -Session $POVFPSSession -ScriptBlock {
              Get-DhcpServerv4FreeIPAddress -ScopeId $USING:scopeId
          }) | Should Be $true
        } 
      }
    }
    foreach ($scopeid in $dhcpScopes.ScopeId) {
      Context "Reservation tests for scope {$scopeid}" {
          $FreeIP= Invoke-Command -Session $POVFPSSession -ScriptBlock {
          Get-DhcpServerv4FreeIPAddress -ScopeId $USING:scopeId
        } 
        it "Checks if any free IP is available in scope {$scopeid}" {
          $FreeIP | Should Not BeNullOrEmpty
        }
        it "Checks if set reservations in {$scopeid} for {$FreeIP} is possible" {
          Invoke-Command -Session $POVFPSSession -ScriptBlock { 
            Add-DhcpServerv4Reservation -IPAddress $USING:FreeIP -ClientId '0000000000AA' -ScopeId $USING:scopeid 
            Get-DhcpServerv4Reservation  -IPAddress $USING:FreeIP 
          } | Should Be $true
        }
        it "Checks if remove reservation in {$scopeid} for {$FreeIP} is possible" {
          Invoke-Command -Session $POVFPSSession -ScriptBlock { 
            Remove-DhcpServerv4Reservation -ScopeId $USING:scopeid -ClientID '0000000000AA' 
            Get-DhcpServerv4Reservation  -IPAddress $USING:FreeIP -ErrorAction SilentlyContinue 
          } | Should Be $null
        }
      }
    }
}