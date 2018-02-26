param(
  $POVFConfiguration,
  $POVFCredential
)
Describe 'Active Directory topology check' -Tag 'Configuration'{
  $ADForest = Get-ADForest
  Context 'Veryfing Forest Configuration' {
    it "Forest FQDN $($POVFConfiguration.Forest.FQDN)" {
      $ADForest.RootDomain |
      Should be $POVFConfiguration.Forest.FQDN
    }
    it "Forest Mode $($POVFConfiguration.Forest.ForestMode)" {
      $ADForest.ForestMode |
      Should be $POVFConfiguration.Forest.ForestMode
    }
    it "Global Catalogs should match configuration file" {
      $compGCfromConfig = $POVFConfiguration.Forest.GlobalCatalogs -split ','
      Compare-Object -ReferenceObject $ADForest.GlobalCatalogs -DifferenceObject $compGCfromConfig | should beNullOrEmpty
    }
    it "Schema Master should match configuration file: $($POVFConfiguration.Forest.SchemaMaster)" {
      $ADForest.SchemaMaster |
      Should be $POVFConfiguration.Forest.SchemaMaster
    }
  }
  Context 'Veryfing Sites Configuration' {
    it "Sites should match configuration file" {
      $sitesfromConfig = $POVFConfiguration.Sites -split ','
      Compare-Object -ReferenceObject $ADForest.Sites -DifferenceObject $sitesfromConfig | should beNullorEmpty
    }
  }
  Context 'Veryfing Domain Trusts Configuration' {
    if ($POVFConfiguration.Trusts) {
      it "Trust domains {$($POVFConfiguration.Trusts)} should match configuration file" {
        $trustsfromConfig = $POVFConfiguration.Trusts -split ','
        $trustsfromAD = Get-ADTrust -filter *| Select-Object -ExpandProperty Name
        Compare-Object -ReferenceObject $trustsfromAD -DifferenceObject $trustsfromConfig | Should beNullorEmpty
      }
    }
    else {
      it "There are no Trusts with this domain" {
        $true | should be $true
      }
    }
  }
}