function Get-POVFHostEnvironment {
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
      @{
        ComputerName = $ENV:ComputerName
        Domain = $env:USERDNSDOMAIN
      }
    }
    $cluster = Invoke-Command -session $POVFPSSession -scriptBlock {
      Get-Cluster -ErrorAction SilentlyContinue
    }
    $result = [ordered]@{
      ComputerName=$hostProperties.ComputerName
      Domain = $hostProperties.Domain
    }
    if($cluster){
      $result.Cluster = $cluster.Name
    }
    $result
    
    if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
      Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue | Remove-PSSession -ErrorAction SilentlyContinue  
    }
  }
}