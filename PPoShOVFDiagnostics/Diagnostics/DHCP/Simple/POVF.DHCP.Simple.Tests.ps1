param (
   $POVFConfiguration,
   $POVFCredential
)
Describe 'Testing authorized DHCP servers in Active Directory' -Tag 'Operational'{ 
  Context 'Verify DHCP servers operational status' {
    $dhcpFromAD = Get-DhcpServerInDC | Select-Object -ExpandProperty DNSName
    Foreach ($dhcp in $dhcpFromAD) {
      it "Verify if DHCP {$dhcp} is recheable" {
        Test-Connection $dhcp -Count 1 -ErrorAction SilentlyContinue |
        Should be $true
      }
      it "Verify if DHCP {$dhcp} leases IPs" {
        Invoke-Command -ComputerName $dhcp -Credential $POVFCredential -ScriptBlock { 
          Get-DhcpServerv4FreeIPAddress -ScopeId (Get-DhcpServerv4Scope)[0].ScopeId
        } | Should be $true
      }
    }
  }
}