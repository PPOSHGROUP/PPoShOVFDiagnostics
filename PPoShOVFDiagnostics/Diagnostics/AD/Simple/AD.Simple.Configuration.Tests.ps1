param(
  $POVFConfiguration,
  [System.Management.Automation.PSCredential]$POVFCredential
)
$queryParams = @{
  Server = $POVFConfiguration.Forest.SchemaMaster 
  Credential = $POVFCredential
}
$currentADForest = Get-ADForest @queryParams
#testing domain against config
Describe 'Active Directory topology check' -Tag 'Configuration'{
  
  Context 'Verify Forest Configuration' {
    it "Forest Name {$($POVFConfiguration.Forest.Name)}" {
      $currentADForest.Name |
      Should -be $POVFConfiguration.Forest.Name
    }
    it "Forest Mode {$($POVFConfiguration.Forest.ForestMode)}" {
      $currentADForest.ForestMode |
      Should -be $POVFConfiguration.Forest.ForestMode
    }
    it "Forest Root Domain {$($POVFConfiguration.Forest.RootDomain)}" {
      $currentADForest.RootDomain |
      Should -be $POVFConfiguration.Forest.RootDomain
    }
    it "Global Catalogs should match configuration" {
      #$compGCfromConfig = $POVFConfiguration.Forest.GlobalCatalogs -split ','
      #Compare-Object -ReferenceObject $ADForest.GlobalCatalogs -DifferenceObject $compGCfromConfig | should beNullOrEmpty
      $currentADForest.GlobalCatalogs | Should -BeIn $POVFConfiguration.Forest.GlobalCatalogs
    }
    it "DomainNaming Master should match configuration file - {$($POVFConfiguration.Forest.DomainNamingMaster)}" {
      $currentADForest.DomainNamingMaster |
      Should -Be $POVFConfiguration.Forest.FMSORoles.DomainNamingMaster
    }
    it "Schema Master should match configuration file - {$($POVFConfiguration.Forest.SchemaMaster)}" {
      $currentADForest.SchemaMaster |
      Should -Be $POVFConfiguration.Forest.FMSORoles.SchemaMaster
    }
  }
  Context 'Verify Sites Configuration' {
    it "Sites should match configuration" {
      #$sitesfromConfig = $POVFConfiguration.Sites -split ','
      #Compare-Object -ReferenceObject currentADForest.Sites -DifferenceObject $sitesfromConfig | should beNullorEmpty
      $currentADForest.Sites | Should -BeIn $POVFConfiguration.Forest.Sites
    }
  }
  Context 'Verify Trusts Configuration' {
    if ($POVFConfiguration.Forest.Trusts) {
      $currentTrusts = Get-ADTrust -filter * @queryParams
      foreach ($trust in $currentTrusts ){
        it "Trust with {$($trust.Name)} should exist in configuration" {
          $trust.Name | Should -BeIn $POVFConfiguration.Forest.Trusts.Name
        }
        it "Trust {$($trust.Name)} should be {$($trust.Direction)}" {
          $trust.Direction | Should -Be ($POVFConfiguration.Forest.Trusts| Where-Object {$PSItem.Name -eq $test.Name}).Direction
        }
      }
    }
    else {
      it "There are no Trusts with this domain" {
        $true | should be $true
      }
    }
  }
}
Describe "Verify Domains Configuration" -Tag 'Configuration' { 
  foreach ($ADdomain in $currentADForest.Domains) {
    $configADDomain = $POVFConfiguration.Forest.Domains | Where-Object {$PSItem.DNSRoot -eq $ADdomain }
    $currentADDomainController = Get-ADDomainController -domainName $ADdomain -Discover
    $domainQueryParams = @{
      Server = $currentADDomainController.HostName[0]
      Credential = $Credential
    }
    $currentADDomain = Get-ADDomain @domainQueryParams
    Context "Verify Domain {$(currentADDomain.DNSRoot)} Configuration" {
      it "Verify DNSRoot for Domain {$(currentADDomain.DNSRoot)} DNSRoot" {
        $currentADDomain.DNSRoot | Should -Be $configADDomain.DNSRoot
      }
      if($currentADDomain.ChildDomains){ 
        it "Verify ChildDomains for Domain {$(currentADDomain.DNSRoot)}" {
          $currentADDomain.ChildDomains | Should -BeIn $configADDomain.ChildDomains
        }
      }
      it "Verify DomainMode for Domain {$(currentADDomain.DNSRoot)}" {
        $currentADDomain.DomainMode | Should -Be $configADDomain.DomainMode
      }
      it "Verify FSMO Roles [InfrastructureMaster] for Domain {$(currentADDomain.DNSRoot)}" {
        $currentADDomain.InfrastructureMaster | Should -Be $configADDomain.FMSORolesInfrastructureMaster
      }
      it "Verify FSMO Roles [RIDMaster] for Domain {$(currentADDomain.DNSRoot)}" {
        $currentADDomain.RIDMaster | Should -Be $configADDomain.RIDMaster
      }
      it "Verify FSMO Roles [PDCEmulator] for Domain {$(currentADDomain.DNSRoot)}" {
        $currentADDomain.PDCEmulator | Should -Be $configADDomain.PDCEmulator
      }
      if($currentADDomain.ReadOnlyReplicaDirectoryServers){ 
        it "Verify ReadOnlyReplicaDirectoryServers for Domain {$(currentADDomain.DNSRoot)}"{
          $currentADDomain.ReadOnlyReplicaDirectoryServers | Should -BeIn $configADDomain.ReadOnlyReplicaDirectoryServers
        }
      }
      it "Verify DHCPServers for Domain {$(currentADDomain.DNSRoot)}" {
        $currentDHCPInAD = @( (Get-ADObject @domainQueryParams -SearchBase $searchBase -Filter "objectclass -eq 'dhcpclass' -AND Name -ne 'dhcproot'" ).Name )
        $currentDHCPInAD | Should -BeIn $configADDomain.DHCPServers
      }
    }
    Context "Verify default Password Policy for domain {$($currentADDomain.DNSRoot)}" {
      $currentDomainDefaultPasswordPolicy = Get-ADDefaultDomainPasswordPolicy @domainQueryParams
      it "Password complexity should be {$($configADDomain.DomainDefaultPasswordPolicy.ComplexityEnabled)}" {
        $currentDomainDefaultPasswordPolicy.ComplexityEnabled |
        Should -Be $configADDomain.DomainDefaultPasswordPolicy.ComplexityEnabled
      }
      it "Password LockoutDuration should be {$($configADDomain.DomainDefaultPasswordPolicy.LockoutDuration)}" {
        ($currentDomainDefaultPasswordPolicy.LockoutDuration).ToString() |
        Should -Be $configADDomain.DomainDefaultPasswordPolicy.LockoutDuration
      }
      it "Password LockoutObservationWindow should be {$($configADDomain.DomainDefaultPasswordPolicy.LockoutObservationWindow)}" {
        ($currentDomainDefaultPasswordPolicy.LockoutObservationWindow).ToString() |
        Should -Be $configADDomain.DomainDefaultPasswordPolicy.LockoutObservationWindow
      }
      it "Password LockoutThreshold should be {$($configADDomain.DomainDefaultPasswordPolicy.LockoutThreshold)}" {
        $currentDomainDefaultPasswordPolicy.LockoutThreshold |
        Should -Be $configADDomain.DomainDefaultPasswordPolicy.LockoutThreshold
      }
      it "Password Minimum Age should be {$($configADDomain.DomainDefaultPasswordPolicy.MinPasswordAge)}" {
        ($currentDomainDefaultPasswordPolicy.MinPasswordAge).ToString() |
        Should -Be $configADDomain.DomainDefaultPasswordPolicy.MinPasswordAge
      }
      it "Password Maxmimum Age should be {$($configADDomain.DomainDefaultPasswordPolicy.MaxPasswordAge)}" {
        ($currentDomainDefaultPasswordPolicy.MaxPasswordAge).ToString() |
        Should -Be $configADDomain.DomainDefaultPasswordPolicy.MaxPasswordAge
      }
      it "Password Minimum Length should be {$($configADDomain.DomainDefaultPasswordPolicy.MinPasswordLength)}" {
        $currentDomainDefaultPasswordPolicy.MinPasswordLength |
        Should -Be $configADDomain.DomainDefaultPasswordPolicy.MinPasswordLength
      }
      it "Password History Count should be {$($configADDomain.DomainDefaultPasswordPolicy.PasswordHistoryCount)}" {
        $currentDomainDefaultPasswordPolicy.PasswordHistoryCount |
        Should -Be $configADDomain.DomainDefaultPasswordPolicy.PasswordHistoryCount
      }
      it "Password Reversible Encryption should be {$($configADDomain.DomainDefaultPasswordPolicy.ReversibleEncryptionEnabled)}" {
        $currentDomainDefaultPasswordPolicy.ReversibleEncryptionEnabled | 
        Should -Be $configADDomain.DomainDefaultPasswordPolicy.ReversibleEncryptionEnabled 
  
      }
    }
    Context "Verify Crucial Groups membership for domain {$($currentADDomain.DNSRoot)}" {
      #foreach group from config
      foreach ($group in $configADDomain.HighGroups) { 
        it "Verify {$($group.Name)} group should match configuration" {
          @((Get-ADGroupMember -Identity $group.Name @domainQueryParams).samaccountname) |
          Should -BeIn $group.Members
        }
      }
    }
  }
}
#testing config against domain
#Describe {}