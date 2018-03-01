param(
    $POVFConfiguration,
    $POVFPSSession
)
Describe "Verify Active Directory COMPREHENSIVE services in forest {$($POVFConfiguration.Forest.FQDN)}" -Tag 'Operational' {
  Context "Verify Active Directory services for domain {$($ADCUrrentForest.Name)} are recheable" {
    it 'If is a VM should have VMICTmeProvider configured' { 
    #New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider -Name Enabled -Value 0 –Force
    }
    it 'NTP service is responding on DC' {

    }
    it 'check schema master membership' {

    }
    it "check continuos replication"{

    }
  }
}