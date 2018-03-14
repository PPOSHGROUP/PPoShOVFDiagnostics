function Get-POVFConfigurationAD {
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
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ComputerName,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential
  )
  process{
    $queryParams = @{
      Server = $ComputerName
    }
    if($PSBoundParameters.ContainsKey('Credential')){
      $queryParams.Credential = $Credential
    }
    #region Hashtable initialization
    $ForestConfig = [ordered]@{
      Name = $null
      ForestMode = $null
      RootDomain = $null
      GlobalCatalogs = @()
      FSMORoles = [ordered]@{
        SchemaMaster = $null
        DomainNamingMaster = $null
      }
      Domains = @( 
        <#
            [ordered]@{
            ChildDomains =@()
            DNSRoot = $null
            DomainMode = $null
            FSMORoles = @{
            InfrastructureMaster  = $null
            RIDMaster = $null
            PDCEmulator = $null
            }
            ReadOnlyReplicaDirectoryServers = @()
            DHCPServers =@()
            DomainDefaultPasswordPolicy = @{
            ComplexityEnabled = $null
            LockoutDuration = $null
            LockoutObservationWindow = $null
            LockoutThreshold = $null
            MinPasswordAge = $null
            MaxPasswordAge =$null
            MinPasswordLength = $null
            PasswordHistoryCount = $null
            ReversibleEncryptionEnabled = $null
            }
            HighGroups = @(
            @{
            Name = $null
            Members = $null
            }
            )
            }
        #>
      )
      Sites = @()
      Trusts = @(
        <#          
            @{
            Name = $null
            Direction = $null
            }
        #>
      )
      
    }
    #endregion
    #region Forest properties
    $currentADForest = Get-ADForest @queryParams
    Write-Progress -Activity 'Gathering AD Forest configuration' -Status "Get Forest {$($currentADForest.Name)} Environment configuration" -PercentComplete 5
    $currentTrusts = Get-ADTrust -filter * @queryParams 
       
    $ForestConfig.Name = $currentADForest.Name
    $ForestConfig.ForestMode = $currentADForest.ForestMode.ToString()
    $ForestConfig.RootDomain = $currentADForest.RootDomain
    $ForestConfig.FSMORoles.DomainNamingMaster = $currentADForest.DomainNamingMaster
    $ForestConfig.FSMORoles.SchemaMaster = $currentADForest.SchemaMaster
    $ForestConfig.GlobalCatalogs += @($currentADForest.GlobalCatalogs)
    #endregion
    #region domain properties
    Write-Progress -Activity 'Gathering AD Forest configuration' -Status "Get AD Domains configuration" -PercentComplete 30
    $ForestConfig.Domains += foreach ($ADdomain in $currentADForest.Domains) {
      Write-Progress -Activity 'Gathering AD Forest configuration' -Status "Get AD Domain {$($ADdomain)} configuration" -PercentComplete 50 
      $currentADDomainController = Get-ADDomainController -domainName $ADdomain -Discover
      $domainQueryParams = @{
        Server = $currentADDomainController.HostName[0]
        Credential = $Credential
      }
      $currentADdomain = Get-ADDomain @domainQueryParams
      $DomainConfig =[ordered]@{
        ChildDomains =@()
        DNSRoot = $null
        DomainMode = $null
        FSMORoles = @{
          InfrastructureMaster  = $null
          RIDMaster = $null
          PDCEmulator = $null
        }
        ReadOnlyReplicaDirectoryServers = @()
        DHCPServers =@()
        DomainDefaultPasswordPolicy = @{
          ComplexityEnabled = $null
          LockoutDuration = $null
          LockoutObservationWindow = $null
          LockoutThreshold = $null
          MinPasswordAge = $null
          MaxPasswordAge =$null
          MinPasswordLength = $null
          PasswordHistoryCount = $null
          ReversibleEncryptionEnabled = $null
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
      Write-Progress -Activity 'Gathering AD Forest configuration' -Status "Get AD Critical Groups configuration" -PercentComplete 70 
      $groups = @('Enterprise Admins','Schema Admins') 
      $DomainConfig.HighGroups += foreach ($group in $groups){
        $groupMembers = Get-ADGroupMember -Identity $group @domainQueryParams 
        [ordered]@{   
          Name = $group
          Members = @($groupMembers.samaccountname)
        }
      }
      $DomainConfig
    }
    #endregion
    #region sites properties
    Write-Progress -Activity 'Gathering AD Forest configuration' -Status "Get AD Forest sites configuration" -PercentComplete 80
    $ForestConfig.Sites = @($currentADForest.Sites)
    #endregion
    #region Trust properties
    Write-Progress -Activity 'Gathering AD Forest configuration' -Status "Get AD Forest trusts configuration" -PercentComplete 90
    $ForestConfig.Trusts += foreach ($trust in $currentTrusts) {
      @{
        Name = $trust.Name
        Direction = $trust.Direction.ToString()
      }
    }    
    #endregion

    $ForestConfig
  }
}