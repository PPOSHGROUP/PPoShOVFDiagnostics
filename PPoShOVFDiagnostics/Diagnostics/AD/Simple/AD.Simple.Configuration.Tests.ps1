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
  
  Context 'Veryfing Forest Configuration' {
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
  Context 'Veryfing Sites Configuration' {
    it "Sites should match configuration" {
      #$sitesfromConfig = $POVFConfiguration.Sites -split ','
      #Compare-Object -ReferenceObject currentADForest.Sites -DifferenceObject $sitesfromConfig | should beNullorEmpty
      $currentADForest.Sites | Should -BeIn $POVFConfiguration.Forest.Sites
    }
  }
  Context 'Veryfing Trusts Configuration' {
    if ($POVFConfiguration.Forest.Trusts) {
      $currentTrusts = Get-ADTrust -filter * @queryParams
      foreach ($trust in $currentTrusts ){
        it "Trust with {$($trust.Name)} should match configuration"
      }
      it "Trust  {$($POVFConfiguration.Forest.Trusts)} should match configuration file" {
        #$trustsfromConfig = $POVFConfiguration.Trusts -split ','
        
        #Compare-Object -ReferenceObject $trustsfromAD -DifferenceObject $trustsfromConfig | Should beNullorEmpty

      }
    }
    else {
      it "There are no Trusts with this domain" {
        $true | should be $true
      }
    }
  }
}
#testing config against domain
#Describe {}