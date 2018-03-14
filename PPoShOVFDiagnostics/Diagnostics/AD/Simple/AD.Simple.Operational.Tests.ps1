param(
    $POVFConfiguration,
    [System.Management.Automation.PSCredential]$POVFCredential
)
Describe "Verify [environment] Active Directory services in forest {$($POVFConfiguration.FQDN)}" -Tag 'Operational' {
  $queryParams = @{
    Server = $POVFConfiguration.FSMORoles.SchemaMaster
    Credential = $POVFCredential
  }
  $ADCurrentForest = Get-ADForest @queryParams

  Context "Verify [host] DC connectivity in forest {$($ADCUrrentForest.Name)}" {
    Foreach ($globalCatalog in $ADCurrentForest.GlobalCatalogs) {
      it "Verify Domain Controller {$globalCatalog} is [online]" {
        Test-Connection $globalCatalog -Count 1 -ErrorAction SilentlyContinue |
        Should -Be $true
      }
      it "Verify [host] DNS on Domain Controller {$globalCatalog} resolves current host name" {
        Resolve-DnsName -Name $($env:computername) -Server $globalCatalog |
        Should -Not -BeNullOrEmpty
      }
      it "Verify [host] Domain Controller {$globalCatalog} responds to PowerShell Queries" {
        Get-ADDomainController @queryParams |
        Should -Not -BeNullOrEmpty
      }
      it "Verify [host] Domain Controller {$globalCatalog} has no replication failures" {
        (Get-ADReplicationFailure -Target $globalCatalog -Credential $POVFCredential) | ForEach-Object {
          $PSItem.FailureCount | 
          Should -Be 0 }
      }
    }
  }
  Context "Verify [host] default Password Policy for domain {$($ADCUrrentForest.Name)}" {
    $currentDomainDefaultPasswordPolicy = Get-ADDefaultDomainPasswordPolicy @queryParams
    it "Password complexity should be [Enabled]" {
      $currentDomainDefaultPasswordPolicy.ComplexityEnabled |
      Should -Be $true -Because 'It is recommended to have strong passwords'
    }
    it "Lockout Treshold should be greater than [5]" {
      $currentDomainDefaultPasswordPolicy.LockoutThreshold |
      Should -BeGreaterThan 5 -Because 'It delays brute force attempts'
    }
    it "Minimum Password Age should be greater than [0]" {
      $currentDomainDefaultPasswordPolicy.MinPasswordAge |
      Should -BeGreaterThan 0 -Because 'It is not good to allow changing passwords more than once a day'
    }
    it "Password History Count should be greater than [0]" {
      $currentDomainDefaultPasswordPolicy.PasswordHistoryCount |
      Should -BeGreaterThan 0 -Because "It is not safe not to remember previous passwords"
    }
    it "Reversible Encryption should be [Disabled]" {
      $currentDomainDefaultPasswordPolicy.ReversibleEncryptionEnabled | 
      Should -Be $false    

    }
  }
  Context "Verify [host] Crucial Groups membership" {
    it "Verify [{]Enterprise Admins] group should only contain [Administrator]" {
      Get-ADGroupMember -Identity 'Enterprise Admins' @queryParams | Where-Object {$PSItem.samaccountname -ne 'Administrator'} |
      Should -BeNullOrEmpty
    }
    it "Verify [Schema Admins] group should only contain [Administrator]" {
      Get-ADGroupMember -Identity 'Schema Admins' @queryParams | Where-Object {$PSItem.samaccountname -ne 'Administrator'} |
      Should -BeNullOrEmpty
    }
  }
}