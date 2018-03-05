function Get-POVFBaselineHyperVSingleNode {
    [CmdletBinding()]
  param(
    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$false,HelpMessage='Node to test')]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $ComputerName
  )

  begin{
    
  }
  process{ 
    foreach ($computer in $ComputerName) {
    $POVFPSSession = New-PSSessionCustom -ComputerName $ComputerName -Credential $Credential -SessionName "POVF-$ComputerName" 
    $NodeConfiguration = [ordered]@{
        ComputerName = $computer
        ClusterName = ''
        Domain = ''
        NIC = @()
        Registry= @()
        Team = @()
        VmSwitch=@()
        Roles = @{
          Present = @()
          Absent = @()
        }
        HyperVConfiguration = @{}
    }
      
      $NodeConfiguration.NIC += Get-POVFNetAdapterConfiguration -Physical -PSSession $POVFPSSession
      $NodeConfiguration.NetQoS += Get-POVFNetQoSConfiguration  -PSSession $POVFPSSession
      #$NodeConfiguration.Registry += 
      $NodeConfiguration.Team += Get-POVFTeamingConfiguration -PSSession $POVFPSSession
      $NodeConfiguration.VmSwitch += Get-POVFVMSwitchConfiguration -PSSession $POVFPSSession
      #$NodeConfiguration.Roles = @{
      #    Present = @()
      #    Absent = @()
      #}
      $NodeConfiguration.HyperVConfiguration = Get-POVFHyperVConfiguration -PSSession $POVFPSSession

  }
  end{
    Get-PSSession -Name $POVFPSSession.Name | Remove-PSSession -ErrorAction SilentlyContinue 
  }
}