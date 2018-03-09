function Get-POVFRolesConfiguration {
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
      $hostRolesConfiguration = Invoke-Command -session $POVFPSSession -scriptBlock {
        Get-WindowsFeature  
      }
      @{
        Present =@($hostRolesConfiguration | Where-Object {$PSItem.InstallState -eq 'Installed'} | Select-Object -ExpandProperty Name)
        Absent = @($hostRolesConfiguration | Where-Object {$PSItem.InstallState -eq 'Removed'} | Select-Object -ExpandProperty Name)
      }
    
      if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
        Get-PSSession $POVFPSSession.Name -ErrorAction SilentlyContinue | Remove-PSSession -ErrorAction SilentlyContinue  
      }
    }
  }