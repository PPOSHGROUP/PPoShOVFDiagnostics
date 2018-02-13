param (
   $POVFConfiguration,
   $POVFCredential
)
Describe 'DHCP servers in Active Directory' { 
  Context 'Verify DHCP servers' {
    $dhcpFromAD = Get-DhcpServerInDC | Select-Object -ExpandProperty DNSName
    Foreach ($dhcp in $dhcpFromAD) {
      it "DHCP {$dhcp} is recheable" {
        Test-Connection $dhcp -Count 1 -ErrorAction SilentlyContinue |
        Should be $true
      }
      it "DHCP {$dhcp} leases IPs" {
        Invoke-Command -ComputerName $dhcp -Credential $POVFCredential -ScriptBlock { 
          Get-DhcpServerv4FreeIPAddress -ScopeId (Get-DhcpServerv4Scope)[0].ScopeId
        } | Should be $true
      }
    }
  }
}