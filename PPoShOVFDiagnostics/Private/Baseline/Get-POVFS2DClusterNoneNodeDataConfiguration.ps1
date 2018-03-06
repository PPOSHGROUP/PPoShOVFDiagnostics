function Get-POVFS2DClusterNoneNodeDataConfiguration {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory,
    ParameterSetName='ClusterName')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ClusterName,
      
    [Parameter(Mandatory=$false,
    ParameterSetName='ClusterName')]
    [System.Management.Automation.PSCredential]
    $Credential,
      
    [Parameter(Mandatory=$false,
    ParameterSetName='ClusterName')]
    [string]
    $ConfigurationName,
    
    [Parameter(Mandatory,
    ParameterSetName='PSCustomSession')]
    [System.Management.Automation.Runspaces.PSSession]
    $PSSession
  )
  
  process{ 
    if($PSBoundParameters.ContainsKey('ClusterName')) { 
      $sessionParams = @{
        ComputerName = $ClusterName
        SessionName = "POVF-$ClusterName"
      }
      if($PSBoundParameters.ContainsKey('ConfigurationName')){
        $sessionParams.ConfigurationName = $ConfigurationName
      }
      if($PSBoundParameters.ContainsKey('Credential')){
        $sessionParams.Credential = $Credential
      }
      $POVFPSSession = New-PSSessionCustom @SessionParams
    }
    if($PSBoundParameters.ContainsKey('PSSession')){
      $POVFPSSession = $PSSession
    }
    #region CODE
    #region Invoke-Command
    $clusterConfig = Invoke-Command -Session $POVFPSSession -ScriptBlock  {
      $coreClusterResources = Get-ClusterResource | Where-Object {$PSItem.OwnerGroup -eq 'Cluster Group'} 
      $coreClusterResourcesResults =@{}
      switch($coreClusterResources){
        {$PSitem.Name -eq 'Cloud Witness'}  { 
          $coreClusterResourcesResults.CloudWitness= @{
            AccountName = (Get-ClusterResource -Name $PSitem.Name | Get-ClusterParameter -Name AccountName).Value
            EndpointInfo = (Get-ClusterResource -Name $PSitem.Name | Get-ClusterParameter -Name EndpointInfo).Value
          }
        }
                                                               
        {$PSitem.Name -eq 'Cluster IP Address'} { 
          $coreClusterResourcesResults.ClusterIPAddress =@{
            Network = (Get-ClusterResource -Name $PSitem.Name | Get-ClusterParameter -Name Network).Value                                                                                                                              
            Address    = (Get-ClusterResource -Name $PSitem.Name | Get-ClusterParameter -Name Address).Value
            SubnetMask = (Get-ClusterResource -Name $PSitem.Name | Get-ClusterParameter -Name SubnetMask).Value
            EnableDhcp = (Get-ClusterResource -Name $PSitem.Name | Get-ClusterParameter -Name EnableDhcp).Value
          }
        }
      }
      $volumes = @()
      $volumes += Get-Volume | Where-Object {$PSitem.FileSystem -eq 'CSVFS'} | ForEach-Object {
        @{ 
          Name = $PSItem.FileSystemLabel
          FileSystem = $PSItem.FileSystemType.ToString()
          Size = ($PSItem.Size / 1GB)      
        }
      }
      $sharedVolumes = @()
      $sharedVolumes += Get-ClusterSharedVolume | ForEach-Object {
        @{ 
          Name = $PSItem.Name
          Path = $PSItem.SharedVolumeInfo.ToString()
        }
      }
      @{ 
        Settings =  Get-Cluster 
        CoreNetworkResources = Get-ClusterNetwork 
        CoreClusterResources = $coreClusterResourcesResults 
        Quorum = Get-ClusterQuorum 
        Nodes = Get-ClusterNode 
        StoragePool = Get-StoragePool -IsPrimordial $false 
        StorageHealthSetting = Get-StorageSubSystem -FriendlyName '*Clustered*' | Get-StorageHealthSetting 
        SharedVolumes = $sharedVolumes
        VirtualDisk = Get-VirtualDisk 
        Volume = $volumes
      }
    }
    #endregion
    #region Prepare received Data
    $clusterNetworks = @()
    $clusterNetworks += $clusterConfig.CoreNetworkResources | ForEach-Object {
      @{
        Name = $PSItem.Name
        Address = $PSItem.Address
        AddressMask = $PSItem.AddressMask
        Role = $PSItem.Role
      }
    }
    $storageHealthSetting = @()
    $storageHealthSetting += $clusterConfig.StorageHealthSetting | Where-Object {$PSItem.Name -match 'System.Storage.PhysicalDisk.Unresponsive.Reset'} | ForEach-Object {
      @{
        Name = $PSItem.Name
        Value = $PSItem.Value
      }
    }

    $virtualDisks = @()
    $virtualDisks += $clusterConfig.VirtualDisk | ForEach-Object {
      @{ 
        Name = $PSItem.FriendlyName
        IsTiered = $PSItem.IsTiered
        Size = $PSItem.Size
      }
    }
    #endregion
    #region Fill in object data
    $ClusterBaselineNoneNodeData = [ordered]@{
      Name = $clusterConfig.Settings.Name
      Domain = $clusterConfig.Settings.Domain
      IPAddress = $clusterConfig.CoreClusterResources.ClusterIPAddress
      ClusterNodes = $clusterConfig.Nodes.NodeName
      ClusterQuorum = @{
        QuorumType = $clusterConfig.Quorum.QuorumType
        Configuration = $clusterConfig.CoreClusterResources.CloudWitness
      }
      ClusterNetwork = $clusterNetworks
      StoragePool = @{
        Name = $clusterConfig.StoragePool.FriendlyName
        ThinProvisioningAlertTresholds = $clusterConfig.StoragePool.ThinProvisioningAlertTresholds
        ResiliencySettingNameDefault = $clusterConfig.StoragePool.ResiliencySettingNameDefault
      }
      SharedVolumes = $clusterConfig.SharedVolumes
      VirtualDisk = $virtualDisks
      Volume = $clusterConfig.Volume
      StorageHealthSetting = $storageHealthSetting
      QuarantineDuration =  $clusterConfig.Settings.QuarantineDuration
      QuarantineThreshold = $clusterConfig.Settings.QuarantineThreshold
      ResiliencyDefaultPeriod = $clusterConfig.Settings.ResiliencyDefaultPeriod
      ResiliencyLevel =  $clusterConfig.Settings.ResiliencyLevel
      AutoBalancerMode = $clusterConfig.Settings.AutoBalancerMode
      AutoBalancerLevel = $clusterConfig.Settings.AutoBalancerLevel
      DrainOnShutdown = $clusterConfig.Settings.DrainOnShutdown
      EnableSharedVolumes = $clusterConfig.Settings.EnableSharedVolumes
      DynamicQuorum = $clusterConfig.Settings.DynamicQuorum
      PlacementOptions = $clusterConfig.Settings.PlacementOptions
      SharedVolumesRoot = $clusterConfig.Settings.SharedVolumesRoot
            
    }
    #endregion
    #region Return Data
    $ClusterBaselineNoneNodeData
    #endregion
    #endregion
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue| Remove-PSSession -ErrorAction SilentlyContinue  
    }
  }
}