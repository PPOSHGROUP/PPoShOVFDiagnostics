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
      if (Get-Command Get-Cluster -ErrorAction SilentlyContinue) { 
        Get-Cluster
      }
      else {
        $null
      }
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
      Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue 
    }
  }
}