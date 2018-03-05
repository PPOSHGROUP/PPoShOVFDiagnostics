function New-POVFBaselineADNoneNodeData {
  <#
  .SYNOPSIS
  Short description
  
  .DESCRIPTION
  Long description
  
  .PARAMETER ComputerName
  Parameter description
  
  .PARAMETER Credential
  Parameter description
  
  .PARAMETER POVFADBaselineFile
  Parameter description
  
  .EXAMPLE
  An example
  
  .NOTES
  General notes
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [System.String]
    $ComputerName,

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$true)]
    [System.String]
    [ValidateScript({Test-Path -Path $PSItem -IsValid})]
    $POVFADBaselineFile

  )
  process{
    $queryParams = @{
      Server = $ComputerName
    }
    if($PSBoundParameters.ContainsKey('Credential')){
      $queryParams.Credential = $Credential
    }
    #$ForestConfig = @()
    #region Final PS Hashtable
    $ForestConfig = [ordered]@{
      Forest = [ordered]@{
        Name = ''
        ForestMode = ''
        RootDomain = ''
        GlobalCatalogs = @()
        FSMORoles = [ordered]@{
          SchemaMaster = ''
          DomainNamingMaster = ''
        }
        Domains = @( 
          <#
          [ordered]@{
            ChildDomains =@()
            DNSRoot = ''
            DomainMode = ''
            FSMORoles = @{
              InfrastructureMaster  = ''
              RIDMaster = ''
              PDCEmulator = ''
            }
            ReadOnlyReplicaDirectoryServers = @()
            DHCPServers =@()
            DomainDefaultPasswordPolicy = @{
              ComplexityEnabled = ''
              LockoutDuration = ''
              LockoutObservationWindow = ''
              LockoutThreshold = ''
              MinPasswordAge = ''
              MaxPasswordAge =''
              MinPasswordLength = ''
              PasswordHistoryCount = ''
              ReversibleEncryptionEnabled = ''
            }
            HighGroups = @(
              @{
                Name = ''
                Members = ''
              }
            )
          }
          #>
          
        )
        Sites = @()
        Trusts = @(
          <#          
              @{
              Name = ''
              Direction = ''
              }
          #>
        )
      }
      
    }
    #>
    #endregion
    #region Forest properties
    $currentADForest = Get-ADForest @queryParams
    $currentTrusts = Get-ADTrust -filter * @queryParams 
    
    $ForestConfig.Forest.Name = $currentADForest.Name
    $ForestConfig.Forest.ForestMode = $currentADForest.ForestMode.ToString()
    $ForestConfig.Forest.RootDomain = $currentADForest.RootDomain
    $ForestConfig.Forest.FSMORoles.DomainNamingMaster = $currentADForest.DomainNamingMaster
    $ForestConfig.Forest.FSMORoles.SchemaMaster = $currentADForest.SchemaMaster
    $ForestConfig.Forest.GlobalCatalogs += @($currentADForest.GlobalCatalogs)
    #endregion
    #region domain properties
    foreach ($ADdomain in $currentADForest.Domains) { 
      $currentADDomainController = Get-ADDomainController -domainName $ADdomain -Discover
      $domainQueryParams = @{
        Server = $currentADDomainController.HostName[0]
        Credential = $Credential
      }
      $currentADdomain = Get-ADDomain @domainQueryParams
      $DomainConfig =[ordered]@{
        ChildDomains =@()
        DNSRoot = ''
        DomainMode = ''
        FSMORoles = @{
          InfrastructureMaster  = ''
          RIDMaster = ''
          PDCEmulator = ''
        }
        ReadOnlyReplicaDirectoryServers = @()
        DHCPServers =@()
        DomainDefaultPasswordPolicy = @{
          ComplexityEnabled = ''
          LockoutDuration = ''
          LockoutObservationWindow = ''
          LockoutThreshold = ''
          MinPasswordAge = ''
          MaxPasswordAge =''
          MinPasswordLength = ''
          PasswordHistoryCount = ''
          ReversibleEncryptionEnabled = ''
        }
        HighGroups = @()
      }
      $DomainConfig.ChildDomains = @($currentADdomain.ChildDomains)
      $DomainConfig.DNSRoot = $currentADdomain.DNSRoot
      $DomainConfig.DomainMode = $currentADdomain.DomainMode.ToString()
      $DomainConfig.FSMORoles = @{
        InfrastructureMaster  = $currentADdomain.InfrastructureMaster
        RIDMaster = $currentADdomain.RIDMaster
        PDCEmulator = $currentADdomain.PDCEmulator
      }
      $DomainConfig.ReadOnlyReplicaDirectoryServers = @($currentADdomain.ReadOnlyReplicaDirectoryServers)

      $searchBase = 'cn=configuration,{0}' -f $currentADDomain.DistinguishedName
      $currentDHCPInAD = @( (Get-ADObject @domainQueryParams -SearchBase $searchBase -Filter "objectclass -eq 'dhcpclass' -AND Name -ne 'dhcproot'" ).Name )
      $DomainConfig.DHCPServers =@($currentDHCPInAD)

      $currentDomainDefaultPasswordPolicy = Get-ADDefaultDomainPasswordPolicy @domainQueryParams
      $DomainConfig.DomainDefaultPasswordPolicy = @{
        ComplexityEnabled = $currentDomainDefaultPasswordPolicy.ComplexityEnabled
        LockoutDuration = $currentDomainDefaultPasswordPolicy.LockoutDuration.ToString()
        LockoutObservationWindow = $currentDomainDefaultPasswordPolicy.LockoutObservationWindow.ToString()
        LockoutThreshold = $currentDomainDefaultPasswordPolicy.LockoutThreshold
        MinPasswordAge = $currentDomainDefaultPasswordPolicy.MinPasswordAge.ToString()
        MaxPasswordAge = $currentDomainDefaultPasswordPolicy.MaxPasswordAge.ToString()
        MinPasswordLength = $currentDomainDefaultPasswordPolicy.MinPasswordLength
        PasswordHistoryCount = $currentDomainDefaultPasswordPolicy.PasswordHistoryCount
        ReversibleEncryptionEnabled = $currentDomainDefaultPasswordPolicy.ReversibleEncryptionEnabled
      }
      $groups = @('Enterprise Admins','Schema Admins')
      $DomainConfig.HighGroups = @()
      foreach ($group in $groups){
        $groupTemp = Get-ADGroupMember -Identity $group @domainQueryParams  
        $DomainConfig.HighGroups += [ordered]@{ 
          Name = $group
          Members = @($groupTemp.samaccountname)
        }
      }
      $ForestConfig.Forest.Domains += $DomainConfig
    }
    #endregion
    #region sites properties
    $ForestConfig.Forest.Sites = @($currentADForest.Sites)
    #endregion
    #region Trust properties
    $ForestConfig.Forest.Trusts = @()
    foreach ($trust in $currentTrusts) {
      $ForestConfig.Forest.Trusts += @{
        Name = $trust.Name
        Direction = $trust.Direction.ToString()
      }
    }
    
    #endregion
    $ForestConfig | ConvertTo-Json -Depth 99 | Out-File -FilePath  $POVFADBaselineFile 
  }
}