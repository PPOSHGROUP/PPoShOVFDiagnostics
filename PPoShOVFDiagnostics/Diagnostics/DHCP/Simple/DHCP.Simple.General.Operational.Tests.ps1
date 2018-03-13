param (
   [System.Management.Automation.PSCredential]$POVFCredential
)
Describe 'Testing authorized DHCP servers in current Active Directory' -Tag 'Operational'{
  Context 'Verify DHCP servers operational status' {
    $dhcpFromAD = Get-DhcpServerInDC | Select-Object -ExpandProperty DNSName
    Foreach ($dhcp in $dhcpFromAD) {
      it "Verify [host] DHCP {$dhcp} is recheable" {
        Test-Connection $dhcp -Count 1 -ErrorAction SilentlyContinue | Should -Be $true
      }
      it "Verify [host] DHCP {$dhcp} leases IPs" {
        Invoke-Command -ComputerName $dhcp -Credential $POVFCredential -ScriptBlock { 
          Get-DhcpServerv4FreeIPAddress -ScopeId (Get-DhcpServerv4Scope)[0].ScopeId
        } | Should -Be $true
      }
    }
  }
}