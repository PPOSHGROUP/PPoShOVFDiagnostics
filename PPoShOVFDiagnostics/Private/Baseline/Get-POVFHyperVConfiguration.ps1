function Get-POVFHyperVConfiguration {
  [CmdletBinding()]
  param (
  
    [Parameter(Mandatory,
    ParameterSetName='ComputerName')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ComputerName,
  
    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [System.Management.Automation.PSCredential]
    $Credential,
  
    [Parameter(Mandatory=$false,
    ParameterSetName='ComputerName')]
    [string]
    $ConfigurationName,

    [Parameter(Mandatory,
    ParameterSetName='PSCustomSession')]
    [System.Management.Automation.Runspaces.PSSession]
    $PSSession


  )
  process{
    #region Variables set
    if($PSBoundParameters.ContainsKey('ComputerName')) { 
      $sessionParams = @{
        ComputerName = $ComputerName
        SessionName = "POVF-$ComputerName"
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

    #endregion
    $hostProperties = Invoke-Command -session $POVFPSSession -scriptBlock {
      Get-VMHost | Select-Object *
    }
    @{
      VirtualHardDiskPath = $hostProperties.VirtualHardDiskPath
      VirtualMachinePath =  $hostProperties.VirtualMachinePath
      LiveMigrations =@{
        Enabled = $hostProperties.VirtualMachineMigrationEnabled
        Simultaneous = $hostProperties.MaximumVirtualMachineMigrations
      }
      StorageMigrations =@{
        Simultaneous = $hostProperties.MaximumStorageMigrations
      }
      NumaSpanning = @{
        Enabled = $hostProperties.NumaSpanningEnabled
      }
    }

    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue | Remove-PSSession -ErrorAction SilentlyContinue  
    }
  }
}