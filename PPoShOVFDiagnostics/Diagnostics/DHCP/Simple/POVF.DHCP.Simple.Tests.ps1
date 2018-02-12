Describe 'DHCP servers in Active Directory' { 
  Context 'Verify DHCP servers' {
    $dhcpFromAD = Get-DhcpServerInDC | Select-Object -ExpandProperty DNSName
    Foreach ($dhcp in dhcpFromAD) {

      it "DHCP {$dhcp} is recheable" {
        Test-Connection $dhcp -Count 1 -ErrorAction SilentlyContinue |
        Should be $true
      }
      it "DHCP {$dhcp} leases IPs" {
        Get-DhcpServerv4FreeIPAddress -ComputerName $dhcp -ScopeId (Get-DhcpServerv4Scope -ComputerName $dhcp)[0].ScopeId |
        Should be $true
      }
    }
  }
}