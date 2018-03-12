function Get-POVFTeamingConfiguration {
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
      $hostTeams =@()
      $hostTeams += Invoke-Command $POVFPSSession -ScriptBlock {
        Get-NetLbfoTeam | ForEach-Object {
          @{
            Name = $PSItem.Name
            TeamingMode = $PSitem.TeamingMode.ToString()
            LoadBalancingAlgorithm = $PSitem.LoadBalancingAlgorithm.ToString()
            Members =  @($PSItem.Members)
          }
        }
      } 
      #to Avoid issues with PSComputerName and RunspaceId added to each object from invoke-command - I'm reassigning each hashtable
      foreach ($hostTeam in $hostTeams) {   
        [ordered]@{
          Name = $hostTeam.Name
          TeamingMode = $hostTeam.TeamingMode
          LoadBalancingAlgorithm = $hostTeam.LoadBalancingAlgorithm
          Members =  @($hostTeam.Members)
        }
      }
  
      if(-not ($PSBoundParameters.ContainsKey('PSSession'))){
        Remove-PSSession -Name $POVFPSSession.Name -ErrorAction SilentlyContinue  
      }
    }
  }