Describe 'DHCP Service settings' {
    Write-Log -info -Message "Will use session details:"
    $POVFPSSession
    $POVFConfiguration.DHCPServerDNSCredentials
    Context 'Verify service status' {
      it "Service should be running" {
        (Invoke-Command -Session $POVFPSSession -ScriptBlock {
            Get-Service -Name Dhcp
        }).Status  | Should Be 'Running'
      }
      it "DNS Credentials should match configuration {$($POVFConfiguration.DHCPServerDNSCredentials)}" {
        $DNSCredentials = Invoke-Command -Session $POVFPSSession -ScriptBlock {
          Get-DhcpServerDnsCredential
        }
        "$($DNSCredentials.DomainName)\$($DNSCredentials.Username)" | Should be $POVFConfiguration.DHCPServerDNSCredentials
      }
      it "IP binding should match configuration {$($POVFConfiguration.Binding)}" {
        (Invoke-Command -Session $POVFPSSession -ScriptBlock {
            Get-DhcpServerv4Binding 
        }).IPAddress | Should Be $POVFConfiguration.Binding
      }
    }
  }
Describe "Scope and Reservation Tests" {
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