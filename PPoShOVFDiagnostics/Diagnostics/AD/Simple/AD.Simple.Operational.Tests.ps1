param(
    $POVFConfiguration,
    [System.Management.Automation.PSCredential]$POVFCredential
)
Describe "Verify Active Directory services in forest {$($POVFConfiguration.Forest.FQDN)}" -Tag 'Operational' {
  $queryParams = @{
    Server = $POVFConfiguration.Forest.SchemaMaster 
    Credential = $POVFCredential
  }
  $ADCurrentForest = Get-ADForest @queryParams

  Context "Verify DC connectivity in forest {$($ADCUrrentForest.Name)}" {
    Foreach ($globalCatalog in $ADCurrentForest.GlobalCatalogs) {
      it "Verify Domain Controller {$globalCatalog} is online" {
        Test-Connection $globalCatalog -Count 1 -ErrorAction SilentlyContinue |
        Should be $true
      }
      it "Verify DNS on Domain Controller {$globalCatalog} resolves current host name" {
        Resolve-DnsName -Name $($env:computername) -Server $globalCatalog |
        Should Not BeNullOrEmpty
      }
      it "Verify Domain Controller {$globalCatalog} responds to PowerShell Queries" {
        (Get-ADDomainController @queryParams) |
        Should Not BeNullOrEmpty
      }
      it "Verify Domain Controller {$globalCatalog} has no replication failures" {
        (Get-ADReplicationFailure -Target $globalCatalog -Credential $POVFCredential) | ForEach-Object {
          $PSItem.FailureCount | 
          Should Be 0 }
      }
    }
  }
  Context "Verify default Password Policy for domain {$($ADCUrrentForest.Name)}" {
    $currentDomainDefaultPasswordPolicy = Get-ADDefaultDomainPasswordPolicy @queryParams
    it "Password complexity should be Enabled" {
      $currentDomainDefaultPasswordPolicy.ComplexityEnabled |
      Should -Be $true
    }
    it "Lockout Treshold should be greater than {5}" {
      $currentDomainDefaultPasswordPolicy.LockoutThreshold |
      Should -BeGreaterThan 5
    }
    it "Minimum Password Age should be greater than {0}" {
      $currentDomainDefaultPasswordPolicy.MinPasswordAge |
      Should -BeGreaterThan 0
    }
    it "Password History Count should be greater than {0}" {
      $currentDomainDefaultPasswordPolicy.PasswordHistoryCount |
      Should -BeGreaterThan 0 -Because "It is not safe not to remember previous passwords"
    }
    it "Reversible Encryption should be Disabled" {
      $currentDomainDefaultPasswordPolicy.ReversibleEncryptionEnabled | 
      Should -Be $false    

    }
  }
  Context "Verify Crucial Groups membership" {
    it "Verify {Enterprise Admins} group should only contain {Administrator}" {
      Get-ADGroupMember -Identity 'Enterprise Admins' @queryParams | Where-Object {$PSItem.samaccountname -ne 'Administrator'} |
      Should -BeNullOrEmpty
    }
    it "Verify {Schema Admins} group should only contain {Administrator}" {
      Get-ADGroupMember -Identity 'Schema Admins' @queryParams | Where-Object {$PSItem.samaccountname -ne 'Administrator'} |
      Should -BeNullOrEmpty
    }
    
  }
}