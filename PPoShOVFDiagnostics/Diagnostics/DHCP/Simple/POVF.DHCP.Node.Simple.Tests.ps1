param (
  $POVFPSSession,
  $POVFConfiguration
)

Describe "DHCP Service settings on Server {$($POVFConfiguration.ComputerName)}" -Tag 'Operational' {
    Context 'Verify service status' {
      it "Service should be running" {
        (Invoke-Command -Session $POVFPSSession -ScriptBlock {
            Get-Service -Name Dhcp
        }).Status  | Should Be 'Running'
      }
    }
    Context 'Verify service statistics' {
      it 'Should have at least 10% free IP space' {
        (Invoke-Command -Session $POVFPSSession -ScriptBlock { Get-DhcpServerv4Statistics }).PercentageAvailable | Should BeGreaterThan 10
      }
    }
}
