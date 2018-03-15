param (
  [System.Management.Automation.PSCredential]$POVFCredential,
  $POVFConfiguration
)
$POVFPSSession = New-PSSessionCustom -ComputerName $POVFConfiguration.ComputerName -Credential $POVFCredential -SessionName 'POVF'
Describe "Reservation Tests on Server - {$($POVFConfiguration.ComputerName)}" -Tags @('Reservation','Operational') {
  $currentDHCPScopes = Get-POVFDHCPNodeScopeConfiguration -PSSession $POVFPSSession 
  foreach ($scopeid in $currentDHCPScopes.ScopeId) {
    Context "Reservation tests for scope - {$scopeid}" {
      $freeIP= Invoke-Command -Session $POVFPSSession -ScriptBlock {
        Get-DhcpServerv4FreeIPAddress -ScopeId $USING:scopeId
      } 
      it "Verify [host] if any free IP is available in scope - {$scopeid}" {
        $freeIP | Should -Not -BeNullOrEmpty
      }
      it "Verify [host] if it's possible to set reservation in {$scopeid} for IP {$freeIP} using MAC [0000000000AA]" {
        Invoke-Command -Session $POVFPSSession -ScriptBlock { 
          Add-DhcpServerv4Reservation -IPAddress $USING:freeIP -ClientId '0000000000AA' -ScopeId $USING:scopeid 
          Get-DhcpServerv4Reservation  -IPAddress $USING:freeIP 
        } | Should -Be $true
      }
      it "Verify [host] if it's possible to remove reservation in {$scopeid} for IP {$freeIP}, MAC [0000000000AA]" {
        Invoke-Command -Session $POVFPSSession -ScriptBlock { 
          Remove-DhcpServerv4Reservation -ScopeId $USING:scopeid -ClientID '0000000000AA' 
          Get-DhcpServerv4Reservation  -IPAddress $USING:freeIP -ErrorAction SilentlyContinue
         } | Should -Be $null
      }
    }
  }
}
Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue  