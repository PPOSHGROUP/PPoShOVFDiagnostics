function Get-POVFRegistryConfiguration {
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

    $registryEntries = @(
      @{ 
        Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\spaceport\Parameters'
        Name ='HwTimeout'
        Value = '0x00002710'
      }
    )
    $registryResults = @()
    $registryResults += foreach ($rKey in $registryEntries){
      $output = @{}
      $value = Get-ItemPropertyValue -Path $rKey.Path -Name $rKey.Name
      $output.Path = $rKey.Path
      $output.Name = $rKey.Name
      $output.Value = $value
      $output
    }
    $registryResults
         
        
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue | Remove-PSSession -ErrorAction SilentlyContinue  
    }
  }
}