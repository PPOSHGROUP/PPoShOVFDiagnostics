param (
  [System.Management.Automation.PSCredential]$POVFCredential,
  $POVFConfiguration
)
$POVFPSSession = New-PSSessionCustom -ComputerName $POVFConfiguration.ComputerName -Credential $POVFCredential -SessionName 'POVF'
Describe "DHCP Service settings on Server {$($POVFConfiguration.ComputerName)}" -Tag 'Operational' {
  Context 'Verify service status' {
    it "Service should be running" {
      (Invoke-Command -Session $POVFPSSession -ScriptBlock {
          Get-Service -Name Dhcp
      }).Status  | Should Be 'Running'
    }
    $dhcpServerSettings = Invoke-Command -Session $POVFPSSession -ScriptBlock {  Get-DhcpServerSetting }
    it "Should be domain joined" {
      $dhcpServerSettings.IsDomainJoined | Should Be $True
    }
    it "Should be authorized in domain" {
      $dhcpServerSettings.IsAuthorized | Should Be $True
    }
  }
  Context 'Verify service statistics' {
    it 'Should have at least 10% free IP space' {
      (Invoke-Command -Session $POVFPSSession -ScriptBlock { Get-DhcpServerv4Statistics }).PercentageAvailable | Should BeGreaterThan 10
    }
  }
}
Get-PSSession -Name 'POVF*' | Remove-PSSession -ErrorAction SilentlyContinue  